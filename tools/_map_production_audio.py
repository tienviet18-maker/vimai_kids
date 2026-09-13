# -*- coding: utf-8 -*-
"""Exhaustive production audio ID mapping for ViMai Kids."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(r"e:\mai_an_learning")

# ---------------------------------------------------------------------------
# 1) Vietnamese alphabet (29 letters)
# ---------------------------------------------------------------------------
VI_LETTER_WORDS = {
    "v_a": ("áo", "v_word_a", "Cái áo"),
    "v_aw": ("ăn", "v_word_aw", "Ăn cơm"),
    "v_aa": ("ấm", "v_word_aa", "Cái ấm"),
    "v_b": ("bố", "v_word_b", "Bố yêu"),
    "v_c": ("cá", "v_word_c", "Con cá"),
    "v_d": ("dù", "v_word_d", "Cái dù"),
    "v_dd": ("đu đủ", "v_word_dd", "Quả đu đủ"),
    "v_e": ("em", "v_word_e", "Em bé"),
    "v_ee": ("ếch", "v_word_ee", "Con ếch"),
    "v_g": ("gà", "v_word_g", "Con gà"),
    "v_h": ("hoa", "v_word_h", "Bông hoa"),
    "v_i": ("bi", "v_word_i", "Hòn bi"),
    "v_k": ("kéo", "v_word_k", "Cái kéo"),
    "v_l": ("lê", "v_word_l", "Quả lê"),
    "v_m": ("mèo", "v_word_m", "Con mèo"),
    "v_n": ("nơ", "v_word_n", "Cái nơ"),
    "v_o": ("ong", "v_word_o", "Con ong"),
    "v_oo": ("ô", "v_word_oo", "Cái ô"),
    "v_ow": ("cờ", "v_word_ow", "Lá cờ"),
    "v_p": ("pin", "v_word_p", "Đèn pin"),
    "v_q": ("quýt", "v_word_q", "Quả quýt"),
    "v_r": ("rùa", "v_word_r", "Con rùa"),
    "v_s": ("sao", "v_word_s", "Ngôi sao"),
    "v_t": ("táo", "v_word_t", "Quả táo"),
    "v_u": ("mũ", "v_word_u", "Cái mũ"),
    "v_uw": ("thư", "v_word_uw", "Bức thư"),
    "v_v": ("voi", "v_word_v", "Con voi"),
    "v_x": ("xe", "v_word_x", "Xe đạp"),
    "v_y": ("y tá", "v_word_y", "Y tá"),
}

alpha_path = ROOT / "assets/data/vietnamese/alphabet.json"
alpha = json.loads(alpha_path.read_text(encoding="utf-8"))
for item in alpha:
    mid = item["id"]
    if mid not in VI_LETTER_WORDS:
        raise SystemExit(f"Missing mapping for alphabet id={mid}")
    word, audio_id, spoken = VI_LETTER_WORDS[mid]
    meta = item.setdefault("metadata", {})
    meta["exampleWord"] = word
    meta["wordAudioId"] = audio_id
    meta["exampleAudioId"] = audio_id
    meta["exampleWordAudioId"] = audio_id
    meta["audioText"] = spoken
alpha_path.write_text(json.dumps(alpha, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"[1] alphabet mapped: {len(alpha)}")

# ---------------------------------------------------------------------------
# 2) Phonics blends + compound vocab
# ---------------------------------------------------------------------------
REQUIRED_BLENDS = [
    ("ba", "b", "a", "v_blend_ba", "bờ - a - ba"),
    ("ca", "c", "a", "v_blend_ca", "cờ - a - ca"),
    ("da", "d", "a", "v_blend_da", "dờ - a - da"),
    ("bo", "b", "o", "v_blend_bo", "bờ - o - bo"),
    ("co", "c", "o", "v_blend_co", "cờ - o - co"),
    ("be", "b", "e", "v_blend_be", "bờ - e - be"),
    ("bi", "b", "i", "v_blend_bi", "bờ - i - bi"),
    ("tu", "t", "u", "v_blend_tu", "tờ - u - tu"),
    ("vu", "v", "u", "v_blend_vu", "vờ - u - vu"),
    ("bà", "b", "a", "v_blend_ba_huyen", "bờ - a - ba - huyền - bà"),
    ("cá", "c", "a", "v_blend_ca_sac", "cờ - a - ca - sắc - cá"),
    ("mẹ", "m", "e", "v_blend_me_nang", "mờ - e - me - nặng - mẹ"),
    ("đỏ", "đ", "o", "v_blend_do_hoi", "đờ - o - đo - hỏi - đỏ"),
    ("sũ", "s", "u", "v_blend_su_nga", "sờ - u - su - ngã - sũ"),
]

REQUIRED_VOCAB = [
    ("ba ba", "v_vocab_baba"),
    ("ca ca", "v_vocab_caca"),
    ("bo bi", "v_vocab_bobi"),
    ("ba mẹ", "v_vocab_bame"),
    ("đo đỏ", "v_vocab_dodo"),
]

phonics_path = ROOT / "assets/data/vietnamese/phonics.json"
phonics = json.loads(phonics_path.read_text(encoding="utf-8"))
by_audio = {}
for item in phonics:
    aid = (item.get("metadata") or {}).get("audioId") or ""
    if aid:
        by_audio[aid] = item

def upsert_blend(syllable, onset, rime, audio_id, spoken):
    meta_base = {
        "onset": onset,
        "rime": rime,
        "syllable": syllable,
        "audioText": spoken,
        "audioLocale": "vi-VN",
        "audioId": audio_id,
        "blendAudioId": audio_id,
        "exampleWordAudioId": audio_id,
    }
    if audio_id in by_audio:
        item = by_audio[audio_id]
        item.setdefault("metadata", {}).update(meta_base)
        item["answer"] = syllable
        item["question"] = f"{onset} + {rime}"
        return False
    item = {
        "id": f"ph_{audio_id.replace('v_blend_', '')}",
        "subject": "vietnamese",
        "ageMin": 3,
        "ageMax": 7,
        "level": 2,
        "skill": "phonics",
        "difficulty": 1,
        "title": "Ghép âm",
        "instruction": f"Ghép âm: {onset} + {rime}",
        "question": f"{onset} + {rime}",
        "answer": syllable,
        "choices": [syllable],
        "metadata": meta_base,
    }
    phonics.append(item)
    by_audio[audio_id] = item
    return True


added = 0
for row in REQUIRED_BLENDS:
    if upsert_blend(*row):
        added += 1

# Force-map any existing plain syllable audioId to v_blend_* when matching required set
required_ids = {r[3] for r in REQUIRED_BLENDS}
for item in phonics:
    meta = item.setdefault("metadata", {})
    aid = meta.get("audioId") or ""
    if aid in required_ids:
        meta["blendAudioId"] = aid
        meta["exampleWordAudioId"] = aid

# Append compound vocab as phonics-adjacent items (skill vietnamese.words usable too)
vocab_path = ROOT / "assets/data/vietnamese/vocabulary_compounds.json"
vocab_items = []
for text, audio_id in REQUIRED_VOCAB:
    vocab_items.append(
        {
            "id": audio_id,
            "subject": "vietnamese",
            "ageMin": 3,
            "ageMax": 7,
            "level": 2,
            "skill": "words",
            "difficulty": 1,
            "title": "Từ ghép",
            "instruction": "Nghe và chọn từ đúng",
            "question": text,
            "answer": text,
            "choices": [text],
            "metadata": {
                "audioText": text,
                "audioLocale": "vi-VN",
                "audioId": audio_id,
                "wordAudioId": audio_id,
                "exampleWordAudioId": audio_id,
                "syllable": text.replace(" ", ""),
            },
        }
    )
vocab_path.write_text(json.dumps(vocab_items, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

phonics_path.write_text(json.dumps(phonics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"[2] phonics blends ensured (+{added} new), vocab compounds={len(vocab_items)}")

# ---------------------------------------------------------------------------
# 3–4) Japanese hiragana / katakana example words
# ---------------------------------------------------------------------------
HIRA = {
    "a": ("あり", "ja_word_ari", "kiến"),
    "i": ("いぬ", "ja_word_inu", "con chó"),
    "u": ("うし", "ja_word_ushi", "con bò"),
    "e": ("えき", "ja_word_eki", "nhà ga"),
    "o": ("おに", "ja_word_oni", "yêu tinh"),
    "ka": ("かさ", "ja_word_kasa", "cái ô"),
    "ki": ("きく", "ja_word_kiku", "hoa cúc"),
    "ku": ("くま", "ja_word_kuma", "con gấu"),
    "ke": ("けいと", "ja_word_keito", "cuộn len"),
    "ko": ("こま", "ja_word_koma", "con quay"),
    "sa": ("さくら", "ja_word_sakura", "hoa anh đào"),
    "shi": ("しか", "ja_word_shika", "con nai"),
    "su": ("すいか", "ja_word_suika", "dưa hấu"),
    "se": ("せみ", "ja_word_semi", "con ve"),
    "so": ("そら", "ja_word_sora", "bầu trời"),
    "ta": ("たこ", "ja_word_tako", "bạch tuộc"),
    "chi": ("ちず", "ja_word_chizu", "bản đồ"),
    "tsu": ("つき", "ja_word_tsuki", "mặt trăng"),
    "te": ("て", "ja_word_te", "bàn tay"),
    "to": ("とけい", "ja_word_tokei", "đồng hồ"),
    "na": ("なつ", "ja_word_natsu", "mùa hè"),
    "ni": ("にじ", "ja_word_niji", "cầu vồng"),
    "nu": ("ぬの", "ja_word_nuno", "vải"),
    "ne": ("ねこ", "ja_word_neko", "con mèo"),
    "no": ("のり", "ja_word_nori", "rong biển"),
    "ha": ("はな", "ja_word_hana", "bông hoa"),
    "hi": ("ひこうき", "ja_word_hikouki", "máy bay"),
    "fu": ("ふね", "ja_word_fune", "con tàu"),
    "he": ("へび", "ja_word_hebi", "con rắn"),
    "ho": ("ほし", "ja_word_hoshi", "ngôi sao"),
    "ma": ("まど", "ja_word_mado", "cửa sổ"),
    "mi": ("みかん", "ja_word_mikan", "quả quýt"),
    "mu": ("むし", "ja_word_mushi", "côn trùng"),
    "me": ("めがね", "ja_word_megane", "mắt kính"),
    "mo": ("もも", "ja_word_momo", "quả đào"),
    "ya": ("やま", "ja_word_yama", "ngọn núi"),
    "yu": ("ゆき", "ja_word_yuki", "tuyết"),
    "yo": ("よる", "ja_word_yoru", "buổi tối"),
    "ra": ("らいおん", "ja_word_raion", "sư tử"),
    "ri": ("りんご", "ja_word_ringo", "quả táo"),
    "ru": ("るす", "ja_word_rusu", "vắng nhà"),
    "re": ("れいぞうこ", "ja_word_reizouko", "tủ lạnh"),
    "ro": ("ろうそく", "ja_word_rousoku", "nến"),
    "wa": ("わに", "ja_word_wani", "cá sấu"),
}

KATA = {
    "a": ("アイス", "ja_word_aisu", "kem"),
    "i": ("イルカ", "ja_word_iruka", "cá heo"),
    "u": ("ウェブ", "ja_word_uebbu", "web"),
    "e": ("エレベーター", "ja_word_erebeetaa", "thang máy"),
    "o": ("オレンジ", "ja_word_orenji", "quả cam"),
    "ka": ("カメラ", "ja_word_kamera", "máy ảnh"),
    "ki": ("キウイ", "ja_word_kiui", "quả kiwi"),
    "ku": ("クリーム", "ja_word_kuriimu", "kem"),
    "ke": ("ケーキ", "ja_word_keeki", "bánh ngọt"),
    "ko": ("コーヒー", "ja_word_koohii", "cà phê"),
    "sa": ("サッカー", "ja_word_sakkaa", "bóng đá"),
    "shi": ("シャツ", "ja_word_shatsu", "áo sơ mi"),
    "su": ("スーツ", "ja_word_suutsu", "vest"),
    "se": ("セーター", "ja_word_seetaa", "áo len"),
    "so": ("ソーセージ", "ja_word_sooseeji", "xúc xích"),
    "ta": ("タオル", "ja_word_taoru", "khăn tắm"),
    "chi": ("チーズ", "ja_word_chiizu", "phô mai"),
    "tsu": ("ツアー", "ja_word_tsuaa", "tour"),
    "te": ("テレビ", "ja_word_terebi", "tivi"),
    "to": ("トマト", "ja_word_tomato", "cà chua"),
    "na": ("ナイフ", "ja_word_naifu", "con dao"),
    "ni": ("ニュース", "ja_word_nyuusu", "tin tức"),
    "no": ("ノート", "ja_word_noodo", "vở / node"),
    "ha": ("ハム", "ja_word_hamu", "thịt nguội"),
    "hi": ("ヒーター", "ja_word_hiitaa", "máy sưởi"),
    "fu": ("フォーク", "ja_word_fooku", "cái nĩa"),
    "he": ("ヘリコプター", "ja_word_herikoputaa", "trực thăng"),
    "ho": ("ホテル", "ja_word_hoteru", "khách sạn"),
    "ma": ("マイク", "ja_word_maiku", "micro"),
    "mi": ("ミルク", "ja_word_miruku", "sữa"),
    "me": ("メロン", "ja_word_meron", "dưa lưới"),
    "mo": ("モーター", "ja_word_motaa", "mô tơ"),
    "yo": ("ヨット", "ja_word_yotto", "du thuyền"),
    "ra": ("ラジオ", "ja_word_rajio", "radio"),
    "ri": ("リボン", "ja_word_ribon", "ruy băng"),
    "ru": ("ルビー", "ja_word_ruubii", "ruby"),
    "re": ("レモン", "ja_word_remon", "chanh"),
    "ro": ("ロケット", "ja_word_oketto", "tên lửa"),
    "wa": ("ワイン", "ja_word_wain", "rượu vang"),
}


def patch_kana_dart(path: Path, mapping: dict, prefix: str) -> int:
    text = path.read_text(encoding="utf-8")
    count = 0

    def repl(match: re.Match) -> str:
        nonlocal count
        head = match.group(0)
        # Extract romaji from id like h_a / k_ka
        id_m = re.search(r"id:\s*'(?:h_|k_)([^']+)'", head)
        if not id_m:
            return head
        romaji = id_m.group(1)
        if romaji not in mapping:
            return head
        word, audio_id, meaning = mapping[romaji]
        # Strip existing example fields then inject
        cleaned = re.sub(r",\s*exampleWord:\s*'[^']*'", "", head)
        cleaned = re.sub(r",\s*exampleMeaningVietnamese:\s*'[^']*'", "", cleaned)
        cleaned = re.sub(r",\s*exampleWordAudioId:\s*'[^']*'", "", cleaned)
        # Insert before closing paren of KanaItem(
        cleaned = cleaned.rstrip()
        if cleaned.endswith("),"):
            body, end = cleaned[:-2], "),"
        elif cleaned.endswith(")"):
            body, end = cleaned[:-1], ")"
        else:
            return head
        # Avoid trailing comma issues
        if not body.rstrip().endswith(","):
            # check if last char before ) needs comma — constructor args already comma-separated
            pass
        injection = f", exampleWord: '{word}', exampleMeaningVietnamese: '{meaning}', exampleWordAudioId: '{audio_id}'"
        count += 1
        return body + injection + end

    # Match each const KanaItem(...) including nested brackets carefully — simple line-oriented
    pattern = re.compile(r"const KanaItem\([^;]*?\),", re.S)
    # The dart file uses one KanaItem per roughly one line or few lines ending with ),
    new_text, n = pattern.subn(repl, text)
    # Fallback line-by-line for single-line entries
    if n == 0:
        lines = []
        for line in text.splitlines(keepends=True):
            if "const KanaItem(" in line and ")," in line:
                line = repl(re.match(r".*", line)) or line  # type: ignore
            lines.append(line)
        new_text = "".join(lines)
    path.write_text(new_text, encoding="utf-8")
    return count


# Better approach: rewrite kana_examples.dart and inject fields via structured rewrite of data files
examples_path = ROOT / "lib/data/kana/kana_examples.dart"
ex_lines = [
    "/// Production example words aligned with ja_word_* MP3 catalog.",
    "class KanaExamples {",
    "  static const Map<String, List<String>> _examples = {",
]
# Map by character for UI lookup
char_to_ex = {}
for romaji, (word, audio_id, meaning) in HIRA.items():
    # find character from hiragana_data later; embed by word first char
    char_to_ex[word[0]] = (word, meaning, audio_id)
for romaji, (word, audio_id, meaning) in KATA.items():
    char_to_ex[word[0]] = (word, meaning, audio_id)

# Build from mapping with known characters from dart files
hira_text = (ROOT / "lib/data/kana/hiragana_data.dart").read_text(encoding="utf-8")
kata_text = (ROOT / "lib/data/kana/katakana_data.dart").read_text(encoding="utf-8")


def romaji_to_char(dart_text: str, romaji: str, prefix: str) -> str | None:
    m = re.search(
        rf"id:\s*'{prefix}{re.escape(romaji)}',\s*script:[^,]+,\s*kanaType:[^,]+,\s*character:\s*'([^']+)'",
        dart_text,
    )
    return m.group(1) if m else None


examples_entries = []
audio_by_char = {}
for romaji, (word, audio_id, meaning) in HIRA.items():
    ch = romaji_to_char(hira_text, romaji, "h_")
    if not ch:
        print("WARN missing hira char", romaji)
        continue
    examples_entries.append(f"    '{ch}': ['{word}', '{meaning}', '{audio_id}'],")
    audio_by_char[ch] = (word, meaning, audio_id)
for romaji, (word, audio_id, meaning) in KATA.items():
    ch = romaji_to_char(kata_text, romaji, "k_")
    if not ch:
        print("WARN missing kata char", romaji)
        continue
    examples_entries.append(f"    '{ch}': ['{word}', '{meaning}', '{audio_id}'],")
    audio_by_char[ch] = (word, meaning, audio_id)

examples_dart = f"""/// Production example words aligned with ja_word_* MP3 catalog.
/// [0]=Japanese word, [1]=Vietnamese meaning, [2]=audio id (no .mp3).
class KanaExamples {{
  static const Map<String, List<String>> _examples = {{
{chr(10).join(examples_entries)}
  }};

  static String wordFor(String character) => _examples[character]?[0] ?? '';
  static String meaningFor(String character) => _examples[character]?[1] ?? '';
  static String audioIdFor(String character) => _examples[character]?[2] ?? '';
}}
"""
examples_path.write_text(examples_dart, encoding="utf-8")
print(f"[3/4] kana_examples entries: {len(examples_entries)}")

# Patch hiragana_data.dart / katakana_data.dart — inject example fields on basic rows


def inject_examples(path: Path, mapping: dict, id_prefix: str) -> int:
    text = path.read_text(encoding="utf-8")
    updated = 0
    for romaji, (word, audio_id, meaning) in mapping.items():
        # Match the KanaItem line containing this id
        pat = re.compile(
            rf"(const KanaItem\(id: '{id_prefix}{re.escape(romaji)}',[^\n]*?)(\),)",
        )

        def _sub(m: re.Match, w=word, a=audio_id, mean=meaning) -> str:
            nonlocal updated
            body = m.group(1)
            # remove old example fields if present
            body = re.sub(r",\s*exampleWord:\s*'[^']*'", "", body)
            body = re.sub(r",\s*exampleMeaningVietnamese:\s*'[^']*'", "", body)
            body = re.sub(r",\s*exampleWordAudioId:\s*'[^']*'", "", body)
            updated += 1
            return (
                body
                + f", exampleWord: '{w}', exampleMeaningVietnamese: '{mean}', exampleWordAudioId: '{a}'"
                + m.group(2)
            )

        text, n = pat.subn(_sub, text)
        if n == 0:
            print("WARN no dart row", path.name, romaji)
    path.write_text(text, encoding="utf-8")
    return updated


h_n = inject_examples(ROOT / "lib/data/kana/hiragana_data.dart", HIRA, "h_")
k_n = inject_examples(ROOT / "lib/data/kana/katakana_data.dart", KATA, "k_")
print(f"[3] hiragana example fields: {h_n}")
print(f"[4] katakana example fields: {k_n}")

# Manifest fragment for compounds route (optional note)
print("OK")
