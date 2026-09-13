#!/usr/bin/env python3
"""Download KanjiVG SVGs for the 92 basic kana and extract stroke path `d` strings.

Source: https://github.com/KanjiVG/kanjivg
License: CC BY-SA 3.0 (Ulrich Apel)
Does not invent paths. Fails if a file is missing or has no <path d=>.
"""
from __future__ import annotations

import json
import re
import ssl
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT_SVG = ROOT / "assets" / "content" / "japanese" / "strokes" / "svg"
OUT_JSON = ROOT / "assets" / "content" / "japanese" / "strokes" / "catalog.json"

HIRAGANA = [
    ("h_a", "あ"), ("h_i", "い"), ("h_u", "う"), ("h_e", "え"), ("h_o", "お"),
    ("h_ka", "か"), ("h_ki", "き"), ("h_ku", "く"), ("h_ke", "け"), ("h_ko", "こ"),
    ("h_sa", "さ"), ("h_shi", "し"), ("h_su", "す"), ("h_se", "せ"), ("h_so", "そ"),
    ("h_ta", "た"), ("h_chi", "ち"), ("h_tsu", "つ"), ("h_te", "て"), ("h_to", "と"),
    ("h_na", "な"), ("h_ni", "に"), ("h_nu", "ぬ"), ("h_ne", "ね"), ("h_no", "の"),
    ("h_ha", "は"), ("h_hi", "ひ"), ("h_fu", "ふ"), ("h_he", "へ"), ("h_ho", "ほ"),
    ("h_ma", "ま"), ("h_mi", "み"), ("h_mu", "む"), ("h_me", "め"), ("h_mo", "も"),
    ("h_ya", "や"), ("h_yu", "ゆ"), ("h_yo", "よ"),
    ("h_ra", "ら"), ("h_ri", "り"), ("h_ru", "る"), ("h_re", "れ"), ("h_ro", "ろ"),
    ("h_wa", "わ"), ("h_wo", "を"), ("h_n", "ん"),
]
KATAKANA = [
    ("k_a", "ア"), ("k_i", "イ"), ("k_u", "ウ"), ("k_e", "エ"), ("k_o", "オ"),
    ("k_ka", "カ"), ("k_ki", "キ"), ("k_ku", "ク"), ("k_ke", "ケ"), ("k_ko", "コ"),
    ("k_sa", "サ"), ("k_shi", "シ"), ("k_su", "ス"), ("k_se", "セ"), ("k_so", "ソ"),
    ("k_ta", "タ"), ("k_chi", "チ"), ("k_tsu", "ツ"), ("k_te", "テ"), ("k_to", "ト"),
    ("k_na", "ナ"), ("k_ni", "ニ"), ("k_nu", "ヌ"), ("k_ne", "ネ"), ("k_no", "ノ"),
    ("k_ha", "ハ"), ("k_hi", "ヒ"), ("k_fu", "フ"), ("k_he", "ヘ"), ("k_ho", "ホ"),
    ("k_ma", "マ"), ("k_mi", "ミ"), ("k_mu", "ム"), ("k_me", "メ"), ("k_mo", "モ"),
    ("k_ya", "ヤ"), ("k_yu", "ユ"), ("k_yo", "ヨ"),
    ("k_ra", "ラ"), ("k_ri", "リ"), ("k_ru", "ル"), ("k_re", "レ"), ("k_ro", "ロ"),
    ("k_wa", "ワ"), ("k_wo", "ヲ"), ("k_n", "ン"),
]

MIRRORS = [
    "https://cdn.jsdelivr.net/gh/KanjiVG/kanjivg@master/kanji/{name}",
    "https://cdn.jsdelivr.net/gh/KanjiVG/kanjivg@master/kanji/{name}",
    "https://api.github.com/repos/KanjiVG/kanjivg/contents/kanji/{name}",
]


def hex_name(ch: str) -> str:
    return f"{ord(ch):05x}.svg"


def fetch(url: str) -> bytes:
    ctx = ssl.create_default_context()
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "ViMaiKids-stroke-bundle/1.0 (educational; CC BY-SA 3.0)"},
    )
    with urllib.request.urlopen(req, context=ctx, timeout=30) as resp:
        return resp.read()


def fetch_svg(name: str) -> bytes:
    last_err: Exception | None = None
    jsdelivr = f"https://cdn.jsdelivr.net/gh/KanjiVG/kanjivg@master/kanji/{name}"
    try:
        return fetch(jsdelivr)
    except Exception as exc:  # noqa: BLE001
        last_err = exc
    api = f"https://api.github.com/repos/KanjiVG/kanjivg/contents/kanji/{name}"
    try:
        payload = json.loads(fetch(api).decode("utf-8"))
        import base64

        return base64.b64decode(payload["content"])
    except Exception as exc:  # noqa: BLE001
        last_err = exc
    raise RuntimeError(f"Could not download {name}: {last_err}")


def extract_paths(svg_bytes: bytes) -> tuple[list[str], str | None]:
    text = svg_bytes.decode("utf-8")
    # Stroke paths live under kvg:StrokePaths_*; skip StrokeNumbers text.
    # Parse XML; collect path d in document order inside StrokePaths group.
    ns = {
        "svg": "http://www.w3.org/2000/svg",
        "kvg": "https://kanjivg.tagaini.net/",
    }
    root = ET.fromstring(text)
    paths: list[str] = []
    # Any path with id containing '-s' (KanjiVG stroke id kvg:xxxxx-sN)
    for el in root.iter():
        tag = el.tag.split("}")[-1]
        if tag != "path":
            continue
        pid = el.attrib.get("id") or ""
        d = el.attrib.get("d")
        if d and "-s" in pid:
            paths.append(d)
    if not paths:
        # Fallback: all path d (may include extras — still source data, not invented)
        for el in root.iter():
            if el.tag.split("}")[-1] == "path" and el.attrib.get("d"):
                paths.append(el.attrib["d"])
    view = root.attrib.get("viewBox")
    return paths, view


def main() -> int:
    OUT_SVG.mkdir(parents=True, exist_ok=True)
    catalog: dict = {
        "source": "KanjiVG",
        "sourceUrl": "https://github.com/KanjiVG/kanjivg",
        "license": "CC BY-SA 3.0",
        "attribution": "KanjiVG (c) Ulrich Apel, https://kanjivg.tagaini.net/",
        "viewBoxSize": 109,
        "characters": {},
    }
    missing: list[str] = []
    for kid, ch in HIRAGANA + KATAKANA:
        name = hex_name(ch)
        try:
            raw = fetch_svg(name)
        except Exception as exc:  # noqa: BLE001
            missing.append(f"{kid} {ch} {name}: {exc}")
            continue
        (OUT_SVG / name).write_bytes(raw)
        paths, view = extract_paths(raw)
        if not paths:
            missing.append(f"{kid} {ch} {name}: no path data")
            continue
        catalog["characters"][kid] = {
            "id": kid,
            "character": ch,
            "unicode": f"{ord(ch):04X}",
            "svg": f"assets/content/japanese/strokes/svg/{name}",
            "strokeCount": len(paths),
            "paths": paths,
            "viewBox": view or "0 0 109 109",
        }
        time.sleep(0.05)
        print(f"OK {kid} {ch} strokes={len(paths)}")

    OUT_JSON.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    h_ok = sum(1 for k, _ in HIRAGANA if k in catalog["characters"])
    k_ok = sum(1 for k, _ in KATAKANA if k in catalog["characters"])
    print(f"HIRAGANA: {h_ok}/46")
    print(f"KATAKANA: {k_ok}/46")
    if missing:
        print("MISSING")
        for row in missing:
            print(" ", row)
        return 1
    if h_ok != 46 or k_ok != 46:
        return 1
    print("BUNDLE OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
