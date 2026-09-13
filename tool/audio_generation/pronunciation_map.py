"""Generation-only pronunciation maps. Never rewrite curriculum JSON."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VI_MAP = ROOT / "tool" / "audio_generation" / "vimai_kids_pronunciation_map.json"
JA_MAP = ROOT / "tool" / "audio_generation" / "japanese_pronunciation_map.json"


def _index(path: Path) -> dict[str, dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    items = data.get("items") or []
    out: dict[str, dict] = {}
    for item in items:
        eid = item.get("id")
        if eid:
            out[eid] = item
    return out


def load_vi_map() -> dict[str, dict]:
    return _index(VI_MAP)


def load_ja_map() -> dict[str, dict]:
    return _index(JA_MAP)


def spoken_text_for(item_id: str, language: str, fallback: str) -> tuple[str, str]:
    """Return (spokenText, category). Fallback is the existing preview/curriculum spoken text."""
    table = load_vi_map() if language.lower().startswith("vi") else load_ja_map()
    row = table.get(item_id)
    if not row:
        return fallback, "WORD"
    return str(row.get("spokenText") or fallback), str(row.get("category") or "WORD")


def display_text_for(item_id: str, language: str, fallback: str = "") -> str:
    """Display/curriculum text. Never used as the TTS spoken form."""
    table = load_vi_map() if language.lower().startswith("vi") else load_ja_map()
    row = table.get(item_id) or {}
    return str(
        row.get("displayText")
        or row.get("displayGlyph")
        or row.get("originalCurriculumText")
        or fallback
    )
