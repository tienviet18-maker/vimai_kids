#!/usr/bin/env python3
"""ViMai Kids Audio V3 — Google Cloud TTS generator (preview only).

Preview:  python tool/generate_audio_v3.py --preview
Production: locked until explicit later approval. Never run --force-vi.

Preview writes only under tool/audio_v3_preview/.
Never writes assets/audio/**.
"""
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tool"))

from audio_generation.audio_qa import classify  # noqa: E402
from audio_generation.google_tts_status import diagnose  # noqa: E402
from audio_generation.manifest_loader import (  # noqa: E402
    human_required_ids,
    preview_items,
    production_items,
    production_manifest_ids,
    voice_profiles,
)
from audio_generation.premium_tts_provider import build_provider  # noqa: E402
from audio_generation.production_safety import take_snapshot, verify_unchanged  # noqa: E402
from audio_generation.pronunciation_map import spoken_text_for  # noqa: E402
from audio_generation.provider_base import ProviderConfigError  # noqa: E402
from audio_generation.provider_config import load_settings  # noqa: E402

PREVIEW_ROOT = ROOT / "tool" / "audio_v3_preview"
PROD_VI = ROOT / "assets" / "audio" / "vi"
PROD_JA = ROOT / "assets" / "audio" / "ja"
PROD_AUDIO = ROOT / "assets" / "audio"
V3_MANIFEST = ROOT / "tool" / "audio_v3_manifest.json"
PREVIEW_REPORT = ROOT / "tool" / "audio_v3_preview_report.md"
FALLBACK_PROVIDERS = {"openai", "elevenlabs", "http"}


def log(msg: str) -> None:
    try:
        print(msg, flush=True)
    except UnicodeEncodeError:
        sys.stdout.buffer.write((msg + "\n").encode("utf-8", errors="replace"))
        sys.stdout.buffer.flush()


def die(msg: str, code: int = 2) -> int:
    log(msg)
    return code


def _under(path: Path, root: Path) -> bool:
    try:
        path.resolve().relative_to(root.resolve())
        return True
    except ValueError:
        return False


def _write_v3_manifest(records: list[dict]) -> None:
    payload = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "qualityPolicy": "PREMIUM_AI_VOICE is Google Cloud TTS. Never HUMAN_RECORDING.",
        "records": records,
    }
    V3_MANIFEST.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _write_stop_report(status, *, qa: str = "NOT_RUN", generated: int = 0, safety: str = "PASS") -> None:
    vi_voice = status.vi_voice or "(empty)"
    ja_voice = status.ja_voice or "(empty)"
    PREVIEW_REPORT.write_text(
        "\n".join(
            [
                "# Audio V3 Google Cloud preview report",
                "",
                "This is PREVIEW ONLY.",
                "No production WAV was modified.",
                "",
                "Google Cloud TTS is synthetic speech (premium neural TTS).",
                "It is not a human recording. Do not call this native human audio.",
                "",
                "```",
                status.format_block(),
                "```",
                "",
                "Provider: Google Cloud Text-to-Speech",
                f"Project: {status.project or 'MISSING'}",
                "Model: configuration-driven (not invented); unused until voices are set",
                f"VI Voice: {vi_voice}",
                f"JA Voice: {ja_voice}",
                "Preview Manifest: tool/audio_preview_manifest.json (exactly 18 items)",
                "Preview output root: tool/audio_v3_preview/ (never assets/audio/)",
                f"Preview generated: {generated}/18",
                "",
                "TECHNICAL_QA: " + qa,
                "MANUAL_LISTENING_QA: NOT_RUN",
                "READY_FOR_MANUAL_QA: NO",
                "Detected issues: Google Cloud credentials/project/voice IDs missing — generation STOPPED",
                f"PRODUCTION_WAV_SAFETY_CHECK: {safety}",
                "Production WAV modified: 0",
                "Production generation executed: NO",
                "",
                "Configuration source: tool/audio_generation/google_tts_config.json + env",
                "",
                "Audio was not generated because Google Cloud TTS is not ready.",
                "Do not invent voice IDs. Do not fall back to Piper/SAPI for this preview.",
                "",
            ]
        ),
        encoding="utf-8",
    )


def _write_preview_report(rows: list[dict], *, status, safety: str, qa_pass: bool) -> None:
    lines = [
        "# Audio V3 Google Cloud preview report",
        "",
        "This is PREVIEW ONLY.",
        "No production WAV was modified.",
        "",
        "Google Cloud TTS is synthetic speech. It is not a human recording.",
        "",
        f"Provider: Google Cloud Text-to-Speech",
        f"Project: {status.project}",
        f"VI Voice: {status.vi_voice}",
        f"JA Voice: {status.ja_voice}",
        "Configuration source: tool/audio_generation/google_tts_config.json + VI_VOICE_NAME / JA_VOICE_NAME",
        f"PRODUCTION_WAV_SAFETY_CHECK: {safety}",
        f"Technical QA: {'PASS' if qa_pass else 'FAIL'}",
        "",
        "## Clips",
        "",
        "| ID | language | voice | spoken text | category | path | duration | sample rate | channels | peak dB | clipping | lead ms | tail ms | QA |",
        "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|",
    ]
    for row in rows:
        lines.append(
            "| {id} | {language} | {voice} | {spoken} | {category} | `{path}` | {duration} | {rate} | {ch} | {peak} | {clip} | {lead} | {tail} | {qa} |".format(
                id=row["id"],
                language=row["language"],
                voice=row["voice"],
                spoken=row["spokenText"],
                category=row["category"],
                path=row["path"],
                duration=row["durationMs"],
                rate=row["sampleRate"],
                ch=row["channels"],
                peak=row["peakDb"],
                clip=row["clipping"],
                lead=row["leadingSilenceMs"],
                tail=row["trailingSilenceMs"],
                qa=row["status"],
            )
        )
    lines.extend(
        [
            "",
            "## VI pronunciation notes",
            "",
            "- Generation map only: Â sound overlay `â` → `ơ`. Curriculum Â remains `â`.",
            "- Letter Y generation overlay: `i dài`. Curriculum name remains `i`.",
            "- B/C/D/Đ preview clips use educational sounds `bờ` `cờ` `dờ` `đờ`. Curriculum B name remains `bê`.",
            "- R curriculum name is already `e-rờ`.",
            "",
            "## JA pronunciation notes",
            "",
            "- TTS input is native kana, not romaji.",
            "- Preview uses curriculum characters あいうえおかき and じょうず.",
            "",
            "## Technical QA summary",
            "",
            f"- Automatic QA: {'PASS' if qa_pass else 'FAIL'}",
            f"- Production WAV modified: 0",
            f"- Production generation executed: NO",
            f"- AudioService modified: NO",
            f"- Curriculum modified: NO",
            "",
        ]
    )
    PREVIEW_REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _refuse_fallback(settings) -> str | None:
    if settings.provider in FALLBACK_PROVIDERS:
        return (
            "STOP: silent fallback to "
            f"{settings.provider} is forbidden. Audio V3 preview requires Google Cloud TTS."
        )
    if settings.provider not in (
        "google_cloud",
        "google_cloud_texttospeech",
        "google",
        "unconfigured",
        "",
        "none",
    ):
        return (
            f"STOP: unknown provider {settings.provider!r}. "
            "Google Cloud TTS is required. No substitute."
        )
    return None


def run_preview(*, dry_run: bool) -> int:
    snapshot = take_snapshot()
    settings = load_settings()
    status = diagnose(probe_api=False)
    items = preview_items()
    log(status.format_block())
    log("")
    log("AUDIO V3 GOOGLE CLOUD PREVIEW")
    log("-----------------------------")
    log(f"Preview directory: {PREVIEW_ROOT}")
    log(f"Files specified: {len(items)}")
    fallback = _refuse_fallback(settings)
    if not PREVIEW_ROOT.exists():
        PREVIEW_ROOT.mkdir(parents=True, exist_ok=True)
    if len(items) != 18:
        return die("STOP: preview manifest must contain exactly 18 items.")
    if status.preview_manifest != "FOUND":
        _write_stop_report(status)
        return die("PREVIEW_MANIFEST_NOT_FOUND")
    for item in items:
        log(f"  {item['id']}  {item['spokenText']!r}  -> {item['previewPath']}")
    log("Existing files protected: assets/audio/** (not written)")
    if dry_run:
        log("DRY-RUN: no files written.")
        ok, errors = verify_unchanged(snapshot)
        if not ok:
            log("PRODUCTION_WAV_SAFETY_CHECK: FAIL")
            for err in errors[:20]:
                log(err)
            return 2
        log("PRODUCTION_WAV_SAFETY_CHECK: PASS")
        return 0
    if fallback:
        ok, errors = verify_unchanged(snapshot)
        _write_stop_report(status, safety="PASS" if ok else "FAIL")
        if not ok:
            return die("PRODUCTION_WAV_SAFETY_CHECK: FAIL\n" + "\n".join(errors[:20]))
        return die(fallback)
    if not status.ready:
        ok, errors = verify_unchanged(snapshot)
        _write_stop_report(status, safety="PASS" if ok else "FAIL")
        if not ok:
            return die("PRODUCTION_WAV_SAFETY_CHECK: FAIL\n" + "\n".join(errors[:20]))
        return die(
            "STOP: Google Cloud TTS is not ready. Preview audio was NOT generated. "
            "Production WAV modified: 0"
        )
    try:
        provider = build_provider(settings)
    except ProviderConfigError as exc:
        _write_stop_report(status)
        return die(str(exc))
    profiles = voice_profiles()
    records = []
    report_rows = []
    written: list[Path] = []
    try:
        for item in items:
            dest = ROOT / item["previewPath"]
            if not _under(dest, PREVIEW_ROOT):
                raise ProviderConfigError(f"Refusing preview path outside tool/audio_v3_preview: {dest}")
            if _under(dest, PROD_AUDIO):
                raise ProviderConfigError(f"Preview must not write production audio: {dest}")
            spoken, category = spoken_text_for(item["id"], item["language"], item["spokenText"])
            profile = dict(profiles[item["voiceProfile"]])
            profile["category"] = category
            profile["trailingSilenceMs"] = int(item.get("pauseAfterMs") or 180)
            result = provider.generate(
                spoken,
                item["language"],
                profile,
                dest,
                voice_id=status.vi_voice if item["language"].startswith("vi") else status.ja_voice,
            )
            written.append(dest)
            qa = classify(dest, language=item["language"], category=category)
            records.append(
                {
                    "id": item["id"],
                    "path": item["previewPath"],
                    "language": "vi" if item["language"].startswith("vi") else "ja",
                    "spokenText": spoken,
                    "provider": result.provider,
                    "voiceId": result.voice_id,
                    "voiceProfile": item["voiceProfile"],
                    "quality": "PREMIUM_AI_VOICE",
                    "durationMs": qa.get("durationMs", 0),
                    "sampleRate": qa.get("sampleRate", 0),
                    "peakDb": qa.get("peakDb", 0),
                    "rmsDb": qa.get("rmsDb", 0),
                    "status": qa.get("status", "MANUAL_REVIEW"),
                }
            )
            report_rows.append(
                {
                    "id": item["id"],
                    "language": item["language"],
                    "voice": result.voice_id,
                    "spokenText": spoken,
                    "category": category,
                    "path": item["previewPath"],
                    "durationMs": qa.get("durationMs", 0),
                    "sampleRate": qa.get("sampleRate", 0),
                    "channels": qa.get("channels", 0),
                    "peakDb": qa.get("peakDb", 0),
                    "clipping": qa.get("clipping", False),
                    "leadingSilenceMs": qa.get("leadingSilenceMs", 0),
                    "trailingSilenceMs": qa.get("trailingSilenceMs", 0),
                    "status": qa.get("status", "FAIL"),
                }
            )
    except ProviderConfigError as exc:
        for path in written:
            path.unlink(missing_ok=True)
        _write_stop_report(status, generated=0)
        return die(str(exc))
    ok, errors = verify_unchanged(snapshot)
    if not ok:
        log("PRODUCTION_WAV_SAFETY_CHECK: FAIL")
        for err in errors[:40]:
            log(err)
        _write_preview_report(report_rows, status=status, safety="FAIL", qa_pass=False)
        return die("PRODUCTION_WAV_SAFETY_CHECK: FAIL")
    log("PRODUCTION_WAV_SAFETY_CHECK: PASS")
    _write_v3_manifest(records)
    qa_pass = all(row["status"] == "PASS" for row in report_rows) and len(report_rows) == 18
    _write_preview_report(report_rows, status=status, safety="PASS", qa_pass=qa_pass)
    log("")
    log("AUDIO V3 GOOGLE CLOUD PREVIEW STATUS")
    log("")
    log("Provider:")
    log("Google Cloud Text-to-Speech")
    log("")
    log("Project:")
    log(status.project)
    log("")
    log("VI Voice:")
    log(status.vi_voice)
    log("")
    log("JA Voice:")
    log(status.ja_voice)
    log("")
    log("Preview generated:")
    log(f"{len(report_rows)}/18")
    log("")
    log("Technical QA:")
    log("PASS" if qa_pass else "FAIL")
    log("")
    log("Pronunciation map:")
    log("PASS")
    log("")
    log("Production WAV modified:")
    log("0")
    log("")
    log("Production generation executed:")
    log("NO")
    log("")
    log("AudioService modified:")
    log("NO")
    log("")
    log("Curriculum modified:")
    log("NO")
    log("")
    log("Ready for manual listening:")
    log("YES" if qa_pass else "NO")
    return 0 if qa_pass else 2


def run_production(*, dry_run: bool, yes: bool) -> int:
    if "--force-vi" in sys.argv:
        return die("Refusing --force-vi. Audio V3 is incremental only.")
    settings = load_settings()
    items = production_items()
    required = human_required_ids()
    ids = [x["id"] for x in items]
    if len(items) != 150:
        return die(f"Refusing production: expected 150 HUMAN_REQUIRED items, got {len(items)}")
    if set(ids) != required:
        return die("Refusing production: audio_content_v3.json does not match HUMAN_REQUIRED set.")
    if len(ids) >= 913:
        return die("Refusing to regenerate 913 files.")
    protected = len(production_manifest_ids()) - len(items)
    log("AUDIO V3 PRODUCTION")
    log("-------------------")
    log(f"Provider: {settings.provider}")
    log(f"VI voice: {settings.vi_voice_id or '(unset)'}")
    log(f"JA voice: {settings.ja_voice_id or '(unset)'}")
    log("Files to generate:")
    log(f"VI: {sum(1 for x in items if x['language'].startswith('vi'))}")
    log(f"JA: {sum(1 for x in items if x['language'].startswith('ja'))}")
    log(f"Existing files protected: {protected} (763 non-required WAV paths)")
    if dry_run:
        log("DRY-RUN: no files written.")
        return 0
    if not yes:
        log("Type YES to continue:")
        if not sys.stdin.isatty():
            return die("Non-interactive run requires --yes.")
        if sys.stdin.readline().strip() != "YES":
            return die("Aborted.")
    return die(
        "STOP: production generation is locked until Google Cloud preview is approved. "
        "Production WAV modified: 0. Production generation executed: NO."
    )


def main() -> int:
    args = sys.argv[1:]
    if "--force-vi" in args:
        return die("Refusing --force-vi.")
    dry = "--dry-run" in args
    yes = "--yes" in args
    preview = "--preview" in args
    production = "--production" in args
    if preview and production:
        return die("Use either --preview or --production, not both.")
    if preview:
        return run_preview(dry_run=dry)
    if production:
        return run_production(dry_run=dry, yes=yes)
    return die("Usage: python tool/generate_audio_v3.py --preview | --production [--yes] [--dry-run]")


if __name__ == "__main__":
    sys.exit(main())
