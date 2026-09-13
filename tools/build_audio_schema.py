#!/usr/bin/env python3
"""Build tools/audio_schema.json — Single Source of Truth for ViMai Kids audio."""
from __future__ import annotations

import json
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(__file__).resolve().parent / "audio_schema.json"

TELEX = {
    "ă": "aw",
    "â": "aa",
    "đ": "dd",
    "ê": "ee",
    "ô": "oo",
    "ơ": "ow",
    "ư": "uw",
    "á": "as",
    "à": "af",
    "ả": "ar",
    "ã": "ax",
    "ạ": "aj",
    "ắ": "aws",
    "ằ": "awf",
    "ẳ": "awr",
    "ẵ": "awx",
    "ặ": "awj",
    "ấ": "aas",
    "ầ": "aaf",
    "ẩ": "aar",
    "ẫ": "aax",
    "ậ": "aaj",
    "é": "es",
    "è": "ef",
    "ẻ": "er",
    "ẽ": "ex",
    "ẹ": "ej",
    "ế": "ees",
    "ề": "eef",
    "ể": "eer",
    "ễ": "eex",
    "ệ": "eej",
    "í": "is",
    "ì": "if",
    "ỉ": "ir",
    "ĩ": "ix",
    "ị": "ij",
    "ó": "os",
    "ò": "of",
    "ỏ": "or",
    "õ": "ox",
    "ọ": "oj",
    "ố": "oos",
    "ồ": "oof",
    "ổ": "oor",
    "ỗ": "oox",
    "ộ": "ooj",
    "ớ": "ows",
    "ờ": "owf",
    "ở": "owr",
    "ỡ": "owx",
    "ợ": "owj",
    "ú": "us",
    "ù": "uf",
    "ủ": "ur",
    "ũ": "ux",
    "ụ": "uj",
    "ứ": "uws",
    "ừ": "uwf",
    "ử": "uwr",
    "ữ": "uwx",
    "ự": "uwj",
    "ý": "ys",
    "ỳ": "yf",
    "ỷ": "yr",
    "ỹ": "yx",
    "ỵ": "yj",
}

VOICE_VI = "vi-VN-Neural2-A"  # Google Cloud TTS — Northern female; fallback vi-VN-Wavenet-A
VOICE_JA = "ja-JP-NanamiNeural"  # edge-tts
SPEAKING_RATE_VI = 0.9
RATE_VI_LETTER = 0.9
PITCH_VI_LETTER = 0.0
RATE_DEFAULT_VI = 0.9
PITCH_DEFAULT_VI = 0.0
RATE_DEFAULT_JA = "+0%"
PITCH_DEFAULT_JA = "+0Hz"


def vi_slug(text: str) -> str:
    chars: list[str] = []
    for ch in text.strip().lower():
        if ch in TELEX:
            chars.append(TELEX[ch])
        elif ch.isalnum():
            chars.append(ch)
        elif ch in ("-", " "):
            chars.append("_")
    return "".join(chars).strip("_") or "clip"


def main() -> int:
    entries: list[dict] = []
    seen: set[str] = set()

    def add(entry: dict) -> None:
        aid = entry["id"]
        if aid in seen:
            return
        if not aid.isascii():
            raise ValueError(f"Non-ASCII audio id forbidden: {aid!r}")
        seen.add(aid)
        entries.append(entry)

    letters = [
        ("v_a", "a", "a"),
        ("v_aw", "ă", "á"),
        ("v_aa", "â", "ớ"),
        ("v_b", "b", "bờ"),
        ("v_c", "c", "cờ"),
        ("v_d", "d", "dờ"),
        ("v_dd", "đ", "đờ"),
        ("v_e", "e", "e"),
        ("v_ee", "ê", "ê"),
        ("v_g", "g", "gờ"),
        ("v_h", "h", "hờ"),
        ("v_i", "i", "i"),
        ("v_k", "k", "cờ"),
        ("v_l", "l", "lờ"),
        ("v_m", "m", "mờ"),
        ("v_n", "n", "nờ"),
        ("v_o", "o", "o"),
        ("v_oo", "ô", "ô"),
        ("v_ow", "ơ", "ơ"),
        ("v_p", "p", "pờ"),
        ("v_q", "q", "cu"),
        ("v_r", "r", "rờ"),
        ("v_s", "s", "sờ"),
        ("v_t", "t", "tờ"),
        ("v_u", "u", "u"),
        ("v_uw", "ư", "ư"),
        ("v_v", "v", "vờ"),
        ("v_x", "x", "xờ"),
        ("v_y", "y", "i"),
    ]
    for aid, glyph, text in letters:
        add(
            {
                "id": aid,
                "text": text,
                "glyph": glyph,
                "category": "vi_letter",
                "voice": VOICE_VI,
                "rate": RATE_VI_LETTER,
                "pitch": PITCH_VI_LETTER,
                "language": "vi",
            }
        )

    system = [
        ("sys_success_1", "Tuyệt cú mèo! Bé giỏi quá!"),
        ("sys_success_2", "Bé làm tốt lắm! Hoan hô bé nào!"),
        ("sys_success_3", "Xuất sắc luôn! Bé thông minh thật đấy!"),
        ("sys_success_4", "Mai rất tự hào về bé!"),
        ("sys_success_5", "Đúng rồi! Bé thông minh quá!"),
        ("sys_fail_1", "Ôi, thử lại lần nữa nhé!"),
        ("sys_fail_2", "Gần đúng rồi, bé nhìn kỹ lại xem nào!"),
        ("sys_fail_3", "Không sao đâu, mình cùng làm lại nhé!"),
        ("sys_fail_4", "Cùng đếm lại với Mai nhé!"),
        ("sys_math_intro", "Chào mừng bé đến với xưởng số vui nhộn!"),
        ("sys_math_recognize", "Bé hãy tìm số đúng nhé!"),
        ("sys_math_match", "Cùng ghép các thẻ giống nhau nào!"),
        ("sys_math_count", "Cùng đếm số với Mai nhé!"),
        ("sys_creativity_intro", "Bé hãy thỏa sức sáng tạo và vẽ tranh nào!"),
        ("sys_game_memory", "Bé hãy tìm các hình giống nhau nào!"),
        ("sys_game_catch", "Bắt đúng chữ đang rơi xuống nhé!"),
        ("sys_japanese_intro", "Cùng học chữ Nhật với Mai nhé!"),
    ]
    for aid, text in system:
        add(
            {
                "id": aid,
                "text": text,
                "category": "system",
                "voice": VOICE_VI,
                "rate": RATE_DEFAULT_VI,
                "pitch": PITCH_DEFAULT_VI,
                "language": "vi",
            }
        )

    math = [
        ("v_math_1", "Một"),
        ("v_math_2", "Hai"),
        ("v_math_3", "Ba"),
        ("v_math_4", "Bốn"),
        ("v_math_5", "Năm"),
        ("v_math_6", "Sáu"),
        ("v_math_7", "Bảy"),
        ("v_math_8", "Tám"),
        ("v_math_9", "Chín"),
        ("v_math_10", "Mười"),
        ("v_math_cong", "Cộng"),
        ("v_math_tru", "Trừ"),
        ("v_math_bang", "Bằng"),
        ("v_math_lon_hon", "Lớn hơn"),
        ("v_math_nho_hon", "Nhỏ hơn"),
        ("v_math_dem_so", "Đếm số cùng Mai nào!"),
    ]
    for aid, text in math:
        add(
            {
                "id": aid,
                "text": text,
                "category": "vi_math",
                "voice": VOICE_VI,
                "rate": RATE_DEFAULT_VI,
                "pitch": PITCH_DEFAULT_VI,
                "language": "vi",
            }
        )

    explicit_words = {
        "v_word_aasm": "ấm",
        "v_word_ao": "áo",
        "v_word_an": "ăn",
        "v_word_bo": "bố",
        "v_word_ca": "cá",
    }
    for aid, text in explicit_words.items():
        add(
            {
                "id": aid,
                "text": text,
                "category": "vi_word",
                "voice": VOICE_VI,
                "rate": RATE_DEFAULT_VI,
                "pitch": PITCH_DEFAULT_VI,
                "language": "vi",
            }
        )

    word_texts = set(explicit_words.values())
    alpha_path = ROOT / "assets" / "content" / "vietnamese" / "alphabet.json"
    if alpha_path.exists():
        for item in json.loads(alpha_path.read_text(encoding="utf-8")):
            ex = (item.get("metadata") or {}).get("exampleWord")
            if ex:
                word_texts.add(ex)
    for w in ["Ba", "Mẹ", "Bé", "Bà", "Anh", "Chị", "Em", "Nhà", "Cây", "Hoa", "Chó", "Mèo", "Gà", "Bạn"]:
        word_texts.add(w)

    for text in sorted(word_texts, key=vi_slug):
        slug = vi_slug(text)
        canonical = f"v_word_{slug}"
        add(
            {
                "id": canonical,
                "text": text,
                "category": "vi_word",
                "voice": VOICE_VI,
                "rate": RATE_DEFAULT_VI,
                "pitch": PITCH_DEFAULT_VI,
                "language": "vi",
            }
        )
        add(
            {
                "id": f"vi_word_{slug}",
                "text": text,
                "category": "vi_word_alias",
                "voice": VOICE_VI,
                "rate": RATE_DEFAULT_VI,
                "pitch": PITCH_DEFAULT_VI,
                "language": "vi",
                "alias_of": canonical,
            }
        )

    kana_root = ROOT / "assets" / "content" / "japanese" / "kana"
    for fp in sorted(kana_root.glob("*.json")):
        for item in json.loads(fp.read_text(encoding="utf-8")):
            cid = item.get("id")
            ch = item.get("character")
            romaji = item.get("romaji")
            if not cid or not ch:
                continue
            spoken = "ちょうおん" if (ch == "ー" or cid in ("h_choon", "k_choonpu")) else ch
            primary = f"ja_{cid}"
            add(
                {
                    "id": primary,
                    "text": spoken,
                    "glyph": ch,
                    "romaji": romaji,
                    "category": "ja_kana",
                    "voice": VOICE_JA,
                    "rate": RATE_DEFAULT_JA,
                    "pitch": PITCH_DEFAULT_JA,
                    "language": "ja",
                }
            )
            if (
                romaji
                and cid.startswith("h_")
                and cid.count("_") == 1
                and romaji.replace("-", "").isalpha()
                and len(romaji) <= 3
            ):
                add(
                    {
                        "id": f"ja_{romaji}",
                        "text": spoken,
                        "glyph": ch,
                        "romaji": romaji,
                        "category": "ja_alias",
                        "voice": VOICE_JA,
                        "rate": RATE_DEFAULT_JA,
                        "pitch": PITCH_DEFAULT_JA,
                        "language": "ja",
                        "alias_of": primary,
                    }
                )

    add(
        {
            "id": "ja_intro",
            "text": "こんにちは！いっしょに日本語を勉強しましょう！",
            "category": "ja_system",
            "voice": VOICE_JA,
            "rate": RATE_DEFAULT_JA,
            "pitch": PITCH_DEFAULT_JA,
            "language": "ja",
        }
    )

    schema = {
        "version": 2,
        "description": (
            "ViMai Kids audio Single Source of Truth. ASCII IDs only. "
            "Vietnamese: Google Cloud TTS vi-VN-Neural2-A (fallback vi-VN-Wavenet-A) @ rate 0.9. "
            "Japanese: edge-tts ja-JP-NanamiNeural."
        ),
        "defaults": {
            "vi": {
                "voice": VOICE_VI,
                "rate": RATE_DEFAULT_VI,
                "pitch": PITCH_DEFAULT_VI,
                "provider": "google-cloud-tts",
            },
            "vi_letter": {
                "voice": VOICE_VI,
                "rate": RATE_VI_LETTER,
                "pitch": PITCH_VI_LETTER,
                "provider": "google-cloud-tts",
            },
            "ja": {
                "voice": VOICE_JA,
                "rate": RATE_DEFAULT_JA,
                "pitch": PITCH_DEFAULT_JA,
                "provider": "edge-tts",
            },
            "output_dir": "assets/audio",
            "filename_pattern": "{id}.mp3",
        },
        "letter_id_map": {
            "a": "v_a",
            "ă": "v_aw",
            "â": "v_aa",
            "b": "v_b",
            "c": "v_c",
            "d": "v_d",
            "đ": "v_dd",
            "e": "v_e",
            "ê": "v_ee",
            "g": "v_g",
            "h": "v_h",
            "i": "v_i",
            "k": "v_k",
            "l": "v_l",
            "m": "v_m",
            "n": "v_n",
            "o": "v_o",
            "ô": "v_oo",
            "ơ": "v_ow",
            "p": "v_p",
            "q": "v_q",
            "r": "v_r",
            "s": "v_s",
            "t": "v_t",
            "u": "v_u",
            "ư": "v_uw",
            "v": "v_v",
            "x": "v_x",
            "y": "v_y",
        },
        "entries": entries,
    }

    OUT.write_text(json.dumps(schema, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(entries)} entries)")
    required = [
        "v_aw",
        "v_aa",
        "v_c",
        "v_word_aasm",
        "v_word_ao",
        "v_word_an",
        "v_word_bo",
        "v_word_ca",
        "sys_math_intro",
        "sys_creativity_intro",
        "ja_a",
        "ja_h_ga",
        "ja_h_pi",
    ]
    missing = [r for r in required if r not in seen]
    if missing:
        print("MISSING:", ", ".join(missing))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
