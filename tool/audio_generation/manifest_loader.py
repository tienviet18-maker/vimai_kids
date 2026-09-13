from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def load_json(rel: str) -> dict | list:
    return json.loads((ROOT / rel).read_text(encoding="utf-8"))


def production_items() -> list[dict]:
    data = load_json("tool/audio_content_v3.json")
    return list(data["items"])


def preview_items() -> list[dict]:
    data = load_json("tool/audio_preview_manifest.json")
    return list(data["items"])


def voice_profiles() -> dict:
    return load_json("tool/audio_voice_profiles.json")


def human_required_ids() -> set[str]:
    human = load_json("tool/human_audio_inventory.json")
    return {x["id"] for x in human["items"] if x["classification"] == "HUMAN_REQUIRED"}


def production_manifest_ids() -> list[str]:
    return [x["id"] for x in load_json("assets/audio/audio_manifest.json")]
