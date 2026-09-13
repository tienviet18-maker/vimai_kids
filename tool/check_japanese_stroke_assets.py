#!/usr/bin/env python3
"""Validate bundled KanjiVG stroke paths for basic 46+46 kana."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "assets" / "content" / "japanese" / "strokes" / "catalog.json"

HIRAGANA = [
    "h_a", "h_i", "h_u", "h_e", "h_o", "h_ka", "h_ki", "h_ku", "h_ke", "h_ko",
    "h_sa", "h_shi", "h_su", "h_se", "h_so", "h_ta", "h_chi", "h_tsu", "h_te", "h_to",
    "h_na", "h_ni", "h_nu", "h_ne", "h_no", "h_ha", "h_hi", "h_fu", "h_he", "h_ho",
    "h_ma", "h_mi", "h_mu", "h_me", "h_mo", "h_ya", "h_yu", "h_yo",
    "h_ra", "h_ri", "h_ru", "h_re", "h_ro", "h_wa", "h_wo", "h_n",
]
KATAKANA = [
    "k_a", "k_i", "k_u", "k_e", "k_o", "k_ka", "k_ki", "k_ku", "k_ke", "k_ko",
    "k_sa", "k_shi", "k_su", "k_se", "k_so", "k_ta", "k_chi", "k_tsu", "k_te", "k_to",
    "k_na", "k_ni", "k_nu", "k_ne", "k_no", "k_ha", "k_hi", "k_fu", "k_he", "k_ho",
    "k_ma", "k_mi", "k_mu", "k_me", "k_mo", "k_ya", "k_yu", "k_yo",
    "k_ra", "k_ri", "k_ru", "k_re", "k_ro", "k_wa", "k_wo", "k_n",
]


def main() -> int:
    if not CATALOG.exists():
        print("MISSING catalog.json", file=sys.stderr)
        print("HIRAGANA: 0/46 stroke data")
        print("KATAKANA: 0/46 stroke data")
        return 1
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    chars = data.get("characters") or {}
    h_miss = [k for k in HIRAGANA if k not in chars or not chars[k].get("paths")]
    k_miss = [k for k in KATAKANA if k not in chars or not chars[k].get("paths")]
    print(f"HIRAGANA: {46 - len(h_miss)}/46 stroke data")
    print(f"KATAKANA: {46 - len(k_miss)}/46 stroke data")
    if h_miss:
        print("HIRAGANA missing:", ", ".join(h_miss))
    if k_miss:
        print("KATAKANA missing:", ", ".join(k_miss))
    license_file = ROOT / "assets" / "licenses" / "KANJIVG_LICENSE.md"
    if not license_file.exists():
        print("MISSING KANJIVG_LICENSE.md", file=sys.stderr)
        return 1
    if data.get("license") != "CC BY-SA 3.0":
        print("catalog license field unexpected:", data.get("license"), file=sys.stderr)
        return 1
    return 0 if not h_miss and not k_miss else 1


if __name__ == "__main__":
    sys.exit(main())
