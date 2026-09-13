"""Emit human-audio inventory from the shipped manifest. Does not mark TTS as HUMAN."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = json.loads((ROOT / "assets" / "audio" / "audio_manifest.json").read_text(encoding="utf-8"))

VI_LETTERS = [e for e in MANIFEST if e["id"].startswith("vi_letter_")]
JA_BASIC = []
for prefix in ("ja_h_", "ja_k_"):
    pass

HIRAGANA_IDS = [
    "ja_h_a", "ja_h_i", "ja_h_u", "ja_h_e", "ja_h_o",
    "ja_h_ka", "ja_h_ki", "ja_h_ku", "ja_h_ke", "ja_h_ko",
    "ja_h_sa", "ja_h_shi", "ja_h_su", "ja_h_se", "ja_h_so",
    "ja_h_ta", "ja_h_chi", "ja_h_tsu", "ja_h_te", "ja_h_to",
    "ja_h_na", "ja_h_ni", "ja_h_nu", "ja_h_ne", "ja_h_no",
    "ja_h_ha", "ja_h_hi", "ja_h_fu", "ja_h_he", "ja_h_ho",
    "ja_h_ma", "ja_h_mi", "ja_h_mu", "ja_h_me", "ja_h_mo",
    "ja_h_ya", "ja_h_yu", "ja_h_yo",
    "ja_h_ra", "ja_h_ri", "ja_h_ru", "ja_h_re", "ja_h_ro",
    "ja_h_wa", "ja_h_wo", "ja_h_n",
]
KATAKANA_IDS = [i.replace("ja_h_", "ja_k_") for i in HIRAGANA_IDS]
JA_BASIC_IDS = HIRAGANA_IDS + KATAKANA_IDS
by_id = {e["id"]: e for e in MANIFEST}

UNUSED_VI = {"vi_ph", "vi_th", "vi_kh", "vi_nh", "vi_ch", "vi_tr", "vi_gh", "vi_ng", "vi_ngh"}

items = []
for rec in MANIFEST:
    rid = rec["id"]
    if rid in UNUSED_VI:
        cls = "NOT_NEEDED"
    elif rid.startswith("vi_letter_") or rid in JA_BASIC_IDS:
        cls = "HUMAN_REQUIRED"
    else:
        cls = "TTS_ACCEPTABLE"
    items.append({
        "id": rid,
        "language": rec["language"],
        "text": rec.get("text"),
        "asset": rec.get("asset"),
        "current_source": rec.get("source"),
        "classification": cls,
        "recording_status": "MISSING_HUMAN",
        "quality_claim": "TTS_TEMPORARY",
    })

out = {
    "human_recordings_present": 0,
    "note": "No files in this repository are human recordings. Piper/SAPI WAVs are TTS_TEMPORARY.",
    "counts": {
        "HUMAN_REQUIRED": sum(1 for i in items if i["classification"] == "HUMAN_REQUIRED"),
        "TTS_ACCEPTABLE": sum(1 for i in items if i["classification"] == "TTS_ACCEPTABLE"),
        "EXISTING_HUMAN": 0,
        "NOT_NEEDED": sum(1 for i in items if i["classification"] == "NOT_NEEDED"),
    },
    "items": items,
}
(ROOT / "tool" / "human_audio_inventory.json").write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

rec_items = []
for rid in [e["id"] for e in VI_LETTERS] + JA_BASIC_IDS:
    rec = by_id[rid]
    rec_items.append({
        "id": rid,
        "language": rec["language"],
        "text": rec.get("text"),
        "pronunciation_note": rec.get("text"),
        "recommended_duration_ms": 700 if rec["language"] == "ja" else 650,
        "recording_status": "NOT_RECORDED",
        "target_path": rec.get("asset"),
    })
(ROOT / "tool" / "human_audio_recording_manifest.json").write_text(
    json.dumps({"human_recordings_present": 0, "items": rec_items}, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
print("inventory", out["counts"], "recording_manifest", len(rec_items))
