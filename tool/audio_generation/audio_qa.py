from __future__ import annotations

from pathlib import Path

from .audio_postprocess import measure_wav

DURATION_LIMITS_MS = {
    "LETTER_NAME": (70, 1600),
    "PHONICS": (70, 1600),
    "SYLLABLE": (90, 1800),
    "WORD": (120, 2200),
    "SENTENCE": (280, 3200),
    "PRAISE": (280, 3200),
}


def _category_key(category: str) -> str:
    raw = (category or "").upper()
    if "PRAISE" in raw or raw.endswith("PHRASE") or "PHRASE" in raw:
        return "PRAISE"
    if "SENTENCE" in raw:
        return "SENTENCE"
    if "SYLLABLE" in raw or "PHONICS" in raw:
        return "PHONICS" if "PHONICS" in raw or raw.endswith("_SOUND") else "SYLLABLE"
    if "LETTER" in raw:
        return "LETTER_NAME"
    if raw in DURATION_LIMITS_MS:
        return raw
    return "WORD"


def classify(path: Path, *, language: str, category: str) -> dict:
    if not path.exists():
        return {
            "status": "MISSING",
            "durationMs": 0,
            "peakDb": 0,
            "rmsDb": 0,
            "sampleRate": 0,
            "channels": 0,
            "clipping": False,
            "leadingSilenceMs": 0,
            "trailingSilenceMs": 0,
            "readable": False,
            "headerValid": False,
        }
    try:
        m = measure_wav(path)
    except Exception as exc:
        return {
            "status": "INVALID_WAV",
            "durationMs": 0,
            "peakDb": 0,
            "rmsDb": 0,
            "sampleRate": 0,
            "channels": 0,
            "clipping": False,
            "leadingSilenceMs": 0,
            "trailingSilenceMs": 0,
            "readable": False,
            "headerValid": False,
            "error": str(exc),
        }
    status = "PASS"
    ms = m["durationMs"]
    key = _category_key(category)
    lo, hi = DURATION_LIMITS_MS[key]
    if m.get("empty"):
        status = "EMPTY"
    elif m["clipping"]:
        status = "CLIPPING"
    elif m.get("nearClipping"):
        status = "NEAR_CLIPPING"
    elif m["peakDb"] < -24:
        status = "LOW_VOLUME"
    elif m["sampleRate"] < 16000:
        status = "SAMPLE_RATE"
    elif m["channels"] != 1:
        status = "CHANNEL_COUNT"
    elif ms < lo:
        status = "TOO_SHORT"
    elif ms > hi:
        status = "TOO_LONG"
    elif m.get("leadingSilenceMs", 0) > 400:
        status = "LEADING_SILENCE"
    elif m.get("trailingSilenceMs", 0) > 700:
        status = "TRAILING_SILENCE"
    elif abs(m.get("dcOffset", 0)) > 2500:
        status = "DC_OFFSET"
    m["status"] = status
    m["language"] = language
    m["category"] = key
    m["readable"] = True
    m["headerValid"] = True
    m["note"] = (
        "Technical QA only. Naturalness and educational pronunciation require manual listening. "
        "Google Cloud TTS is synthetic speech, not a human recording."
    )
    return m
