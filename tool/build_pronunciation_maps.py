#!/usr/bin/env python3
"""Build generation-only pronunciation maps from curriculum JSON. Does not rewrite curriculum."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Curriculum letter names/sounds from vietnamese_speech_catalog.dart (unchanged in app).
CURRICULUM_LETTERS = {
    "a": ("A", "a", "a"),
    "aw": ("Ă", "ă", "ă"),
    "aa": ("Â", "â", "â"),
    "b": ("B", "bê", "bờ"),
    "c": ("C", "xê", "cờ"),
    "d": ("D", "dê", "dờ"),
    "dd": ("Đ", "đê", "đờ"),
    "e": ("E", "e", "e"),
    "ee": ("Ê", "ê", "ê"),
    "g": ("G", "giê", "gờ"),
    "h": ("H", "hát", "hờ"),
    "i": ("I", "i", "i"),
    "k": ("K", "ca", "cờ"),
    "l": ("L", "e-lờ", "lờ"),
    "m": ("M", "em-mờ", "mờ"),
    "n": ("N", "en-nờ", "nờ"),
    "o": ("O", "o", "o"),
    "oo": ("Ô", "ô", "ô"),
    "ow": ("Ơ", "ơ", "ơ"),
    "p": ("P", "pê", "pờ"),
    "q": ("Q", "quy", "quờ"),
    "r": ("R", "e-rờ", "rờ"),
    "s": ("S", "ét", "sờ"),
    "t": ("T", "tê", "tờ"),
    "u": ("U", "u", "u"),
    "uw": ("Ư", "ư", "ư"),
    "v": ("V", "vê", "vờ"),
    "x": ("X", "ích", "xờ"),
    "y": ("Y", "i", "i"),
}

# Generation-only overlays. Curriculum JSON is not modified.
GENERATION_SOUND = {
    "aa": "ơ",
    "y": "i dài",
}


def entry(eid, original, spoken, language, purpose, category, notes=""):
    return {
        "id": eid,
        "originalCurriculumText": original,
        "spokenText": spoken,
        "language": language,
        "purpose": purpose,
        "category": category,
        "ssml": None,
        "notes": notes,
    }


def main() -> None:
    vi: list[dict] = []
    for slug, (glyph, name, sound) in CURRICULUM_LETTERS.items():
        gen_sound = GENERATION_SOUND.get(slug, sound)
        gen_name = GENERATION_SOUND.get(slug, name) if slug == "y" else name
        if slug == "aa":
            gen_name = name
        vi.append(entry(f"vi_letter_{slug}_name", name, gen_name, "vi-VN", "letter_name", "LETTER_NAME",
                        "Curriculum name unchanged in app. Generation overlay only if listed."))
        vi.append(entry(f"vi_letter_{slug}_sound", sound, gen_sound, "vi-VN", "letter_sound", "PHONICS",
                        f"Glyph {glyph}. Generation spokenText may differ from curriculum for TTS naturalness."))
        vi[-1]["displayGlyph"] = glyph

    preview_overlay = {
        "preview_vi_a": ("a", "a", "LETTER_NAME"),
        "preview_vi_as": ("á", "á", "LETTER_NAME"),
        "preview_vi_ows": ("ớ", "ớ", "LETTER_NAME"),
        "preview_vi_bo": ("bờ", "bờ", "PHONICS"),
        "preview_vi_co": ("cờ", "cờ", "PHONICS"),
        "preview_vi_do": ("dờ", "dờ", "PHONICS"),
        "preview_vi_ddo": ("đờ", "đờ", "PHONICS"),
        "preview_vi_gioi_lam": ("Giỏi lắm", "Giỏi lắm", "PRAISE"),
        "preview_vi_dung_roi": ("Đúng rồi", "Đúng rồi", "PRAISE"),
        "preview_vi_thu_lai": ("Thử lại nhé", "Thử lại nhé", "PRAISE"),
    }
    for pid, (orig, spoken, cat) in preview_overlay.items():
        vi.append(entry(pid, orig, spoken, "vi-VN", "preview", cat, "Existing 18-preview ID."))

    phonics_path = ROOT / "assets/content/vietnamese/phonics.json"
    if phonics_path.exists():
        for item in json.loads(phonics_path.read_text(encoding="utf-8")):
            meta = item.get("metadata") or {}
            aid = meta.get("audioId")
            text = meta.get("audioText") or item.get("answer")
            if aid and text:
                vi.append(entry(aid, text, text, "vi-VN", "phonics", "SYLLABLE", "From phonics.json metadata.audioText"))

    onset = {
        "vi_ph": "phờ",
        "vi_th": "thờ",
        "vi_kh": "khờ",
        "vi_nh": "nhờ",
        "vi_ch": "chờ",
        "vi_tr": "trờ",
        "vi_gh": "ghờ",
        "vi_ng": "ngờ",
        "vi_ngh": "nghờ",
    }
    for oid, spoken in onset.items():
        vi.append(entry(oid, spoken, spoken, "vi-VN", "onset", "PHONICS", "Existing onset IDs in audio checker."))

    ja = []
    kana_dir = ROOT / "assets/content/japanese/kana"
    for path in sorted(kana_dir.glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        rows = data if isinstance(data, list) else data.get("items") or []
        for item in rows:
            if not isinstance(item, dict) or not item.get("id"):
                continue
            ch = item.get("character") or item.get("displayText")
            if not ch:
                continue
            kid = item["id"]
            ja.append(entry(f"ja_{kid}", ch, ch, "ja-JP", "kana", "LETTER_NAME",
                            f"From {path.name}. TTS input is kana, not romaji."))
            ja.append(entry(kid, ch, ch, "ja-JP", "kana", "LETTER_NAME", "Curriculum id without ja_ prefix."))

    for pid, ch in [
        ("preview_ja_h_a", "あ"),
        ("preview_ja_h_i", "い"),
        ("preview_ja_h_u", "う"),
        ("preview_ja_h_e", "え"),
        ("preview_ja_h_o", "お"),
        ("preview_ja_h_ka", "か"),
        ("preview_ja_h_ki", "き"),
        ("preview_ja_jouzu", "じょうず"),
    ]:
        ja.append(entry(pid, ch, ch, "ja-JP", "preview", "PRAISE" if "jouzu" in pid else "LETTER_NAME", "Existing 18-preview ID."))

    vi_out = {
        "scope": "AUDIO_GENERATION_ONLY",
        "curriculumModified": False,
        "items": vi,
    }
    ja_out = {
        "scope": "AUDIO_GENERATION_ONLY",
        "curriculumModified": False,
        "ttsInput": "native_kana_not_romaji",
        "items": ja,
    }
    (ROOT / "tool/audio_generation/vimai_kids_pronunciation_map.json").write_text(
        json.dumps(vi_out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (ROOT / "tool/audio_generation/japanese_pronunciation_map.json").write_text(
        json.dumps(ja_out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"VI entries {len(vi)} JA entries {len(ja)}")


if __name__ == "__main__":
    main()
