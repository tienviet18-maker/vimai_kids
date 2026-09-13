# -*- coding: utf-8 -*-
"""Sync production audio IDs into Japanese JSON + Vietnamese content fallbacks."""
from __future__ import annotations

import json
import re
import shutil
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(r"e:\mai_an_learning")

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
    "no": ("ノード", "ja_word_noodo", "node"),
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


def patch_list(path: Path, mapping: dict, id_prefix: str) -> int:
    data = json.loads(path.read_text(encoding="utf-8"))
    n = 0
    for item in data:
        iid = item.get("id") or ""
        romaji = item.get("romaji") or ""
        if iid.startswith(id_prefix):
            key = iid[len(id_prefix) :]
        else:
            key = romaji
        if key not in mapping:
            continue
        word, audio_id, meaning = mapping[key]
        item["exampleWord"] = word
        item["exampleMeaningVietnamese"] = meaning
        item["exampleWordAudioId"] = audio_id
        n += 1
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return n


# Japanese JSON sources
h1 = patch_list(ROOT / "assets/data/japanese/hiragana.json", HIRA, "h_")
k1 = patch_list(ROOT / "assets/data/japanese/katakana.json", KATA, "k_")
h2 = patch_list(ROOT / "assets/content/japanese/kana/hiragana_basic.json", HIRA, "h_")
k2 = patch_list(ROOT / "assets/content/japanese/kana/katakana_basic.json", KATA, "k_")
print(f"hiragana data/content: {h1}/{h2}")
print(f"katakana data/content: {k1}/{k2}")

# Merge vocab compounds into phonics + words
vc_path = ROOT / "assets/data/vietnamese/vocabulary_compounds.json"
vc = json.loads(vc_path.read_text(encoding="utf-8"))
for name in ("phonics.json", "words.json"):
    path = ROOT / "assets/data/vietnamese" / name
    data = json.loads(path.read_text(encoding="utf-8"))
    existing = {(i.get("metadata") or {}).get("audioId") for i in data} | {i.get("id") for i in data}
    added = 0
    for item in vc:
        aid = (item.get("metadata") or {}).get("audioId") or item.get("id")
        if aid in existing:
            continue
        data.append(item)
        existing.add(aid)
        added += 1
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"merged into {name}: +{added}")

# Sync production Vietnamese JSON into content fallbacks
for name in ("alphabet.json", "phonics.json", "words.json"):
    src = ROOT / "assets/data/vietnamese" / name
    dst = ROOT / "assets/content/vietnamese" / name
    if src.exists() and dst.parent.exists():
        shutil.copy2(src, dst)
        print(f"synced {dst.relative_to(ROOT)}")

print("OK")
