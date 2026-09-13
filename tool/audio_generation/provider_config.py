from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ENV_FILE = ROOT / "tool" / ".env.audio.v3"


def _load_dotenv(path: Path) -> None:
    if not path.exists():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


@dataclass
class ProviderSettings:
    provider: str
    api_key: str
    api_base: str
    vi_voice_id: str
    ja_voice_id: str
    openai_model: str

    @property
    def is_google(self) -> bool:
        return self.provider in ("google_cloud", "google_cloud_texttospeech", "google")

    @property
    def configured(self) -> bool:
        if self.provider in ("", "none", "unconfigured"):
            return False
        if self.is_google:
            from .google_tts_status import diagnose

            return diagnose(probe_api=False).ready
        if not self.api_key:
            return False
        if not self.vi_voice_id or not self.ja_voice_id:
            return False
        if self.provider == "http" and not self.api_base:
            return False
        return True

    def voice_for(self, language: str) -> str:
        lang = language.lower()
        if lang.startswith("vi"):
            return self.vi_voice_id
        if lang.startswith("ja"):
            return self.ja_voice_id
        raise ValueError(f"Unsupported language {language}")


def load_settings() -> ProviderSettings:
    _load_dotenv(ENV_FILE)
    from .google_tts_status import resolve_voice_name

    provider = (os.environ.get("VIMAI_AUDIO_V3_PROVIDER") or "google_cloud").strip().lower()
    vi = (os.environ.get("VIMAI_AUDIO_V3_VI_VOICE_ID") or "").strip() or resolve_voice_name("vi")
    ja = (os.environ.get("VIMAI_AUDIO_V3_JA_VOICE_ID") or "").strip() or resolve_voice_name("ja")
    return ProviderSettings(
        provider=provider,
        api_key=(os.environ.get("VIMAI_AUDIO_V3_API_KEY") or "").strip(),
        api_base=(os.environ.get("VIMAI_AUDIO_V3_API_BASE") or "").strip().rstrip("/"),
        vi_voice_id=vi,
        ja_voice_id=ja,
        openai_model=(os.environ.get("VIMAI_AUDIO_V3_OPENAI_MODEL") or "gpt-4o-mini-tts").strip(),
    )
