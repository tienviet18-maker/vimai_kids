"""Google Cloud TTS readiness — no audio generation, no invented voices."""
from __future__ import annotations

import importlib.util
import json
import os
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = ROOT / "tool" / "audio_generation" / "google_tts_config.json"
ENV_FILE = ROOT / "tool" / ".env.audio.v3"
PREVIEW_MANIFEST = ROOT / "tool" / "audio_preview_manifest.json"


def _load_dotenv(path: Path) -> None:
    if not path.exists():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def adc_paths() -> list[Path]:
    paths: list[Path] = []
    env = (os.environ.get("GOOGLE_APPLICATION_CREDENTIALS") or "").strip()
    if env:
        paths.append(Path(env))
    appdata = os.environ.get("APPDATA")
    if appdata:
        paths.append(Path(appdata) / "gcloud" / "application_default_credentials.json")
    home = Path.home()
    paths.append(home / ".config" / "gcloud" / "application_default_credentials.json")
    return paths


def credentials_present() -> bool:
    for path in adc_paths():
        if path.is_file():
            return True
    return False


def credentials_source() -> str:
    env = (os.environ.get("GOOGLE_APPLICATION_CREDENTIALS") or "").strip()
    if env:
        p = Path(env)
        return f"GOOGLE_APPLICATION_CREDENTIALS={'exists' if p.is_file() else 'MISSING_FILE'} ({p})"
    for path in adc_paths():
        if path.is_file():
            return f"ADC file: {path}"
    return "MISSING"


def package_installed() -> bool:
    try:
        return importlib.util.find_spec("google.cloud.texttospeech") is not None
    except ModuleNotFoundError:
        return False


def load_google_config() -> dict:
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))


def resolve_voice_name(language: str) -> str:
    _load_dotenv(ENV_FILE)
    cfg = load_google_config()
    if language.startswith("vi"):
        return (
            (os.environ.get("VI_VOICE_NAME") or "").strip()
            or (os.environ.get("VIMAI_AUDIO_V3_VI_VOICE_ID") or "").strip()
            or str(cfg.get("vietnamese", {}).get("voice_name") or "").strip()
        )
    if language.startswith("ja"):
        return (
            (os.environ.get("JA_VOICE_NAME") or "").strip()
            or (os.environ.get("VIMAI_AUDIO_V3_JA_VOICE_ID") or "").strip()
            or str(cfg.get("japanese", {}).get("voice_name") or "").strip()
        )
    return ""


def project_id() -> str:
    _load_dotenv(ENV_FILE)
    return (
        (os.environ.get("GOOGLE_CLOUD_PROJECT") or "").strip()
        or (os.environ.get("GCLOUD_PROJECT") or "").strip()
        or (os.environ.get("GOOGLE_CLOUD_PROJECT_ID") or "").strip()
    )


@dataclass
class GoogleTtsStatus:
    package: str
    credentials: str
    project: str
    vi_voice: str
    ja_voice: str
    preview_manifest: str
    api: str = "UNKNOWN"
    ready: bool = False
    reasons: list[str] = field(default_factory=list)

    def format_block(self) -> str:
        lines = [
            "AUDIO_V3_GOOGLE_STATUS",
            "",
            "Provider:",
            "Google Cloud Text-to-Speech",
            "",
            "Project:",
            self.project or "MISSING",
            "",
            "Credentials:",
            self.credentials if self.credentials != "MISSING" else "MISSING",
            "",
            "VI Voice:",
            "CONFIGURED" if self.vi_voice else "MISSING",
            "",
            "JA Voice:",
            "CONFIGURED" if self.ja_voice else "MISSING",
            "",
            "Preview Manifest:",
            self.preview_manifest,
            "",
            "Ready for preview:",
            "YES" if self.ready else "NO",
            "",
            "Reason:",
            "; ".join(self.reasons) if self.reasons else "ok",
            "",
            "Production WAV modified:",
            "0",
        ]
        return "\n".join(lines)


def diagnose(*, probe_api: bool = False) -> GoogleTtsStatus:
    _load_dotenv(ENV_FILE)
    reasons: list[str] = []
    pkg = "INSTALLED" if package_installed() else "NOT_INSTALLED"
    if pkg != "INSTALLED":
        reasons.append("google-cloud-texttospeech is not installed")
    creds = credentials_source() if credentials_present() else "MISSING"
    if creds == "MISSING":
        reasons.append(
            "Google Application Default Credentials not found "
            "(no GOOGLE_APPLICATION_CREDENTIALS file and no gcloud ADC)"
        )
    proj = project_id() or "MISSING"
    if proj == "MISSING":
        reasons.append("GOOGLE_CLOUD_PROJECT is unset")
    vi = resolve_voice_name("vi")
    ja = resolve_voice_name("ja")
    if not vi:
        reasons.append("VI_VOICE_NAME is empty (will not invent a Google voice ID)")
    if not ja:
        reasons.append("JA_VOICE_NAME is empty (will not invent a Google voice ID)")
    preview = "FOUND" if PREVIEW_MANIFEST.is_file() else "MISSING"
    if preview == "MISSING":
        reasons.append("PREVIEW_MANIFEST_NOT_FOUND")
    api = "UNKNOWN"
    if probe_api and not reasons:
        api = "PROBE_SKIPPED_UNTIL_CLIENT_INIT"
    ready = not reasons
    return GoogleTtsStatus(
        package=pkg,
        credentials=creds,
        project=proj,
        vi_voice=vi or "",
        ja_voice=ja or "",
        preview_manifest=preview,
        api=api,
        ready=ready,
        reasons=reasons,
    )
