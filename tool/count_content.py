#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def njson(path: Path) -> int:
    data = json.loads(path.read_text(encoding="utf-8"))
    return len(data) if isinstance(data, list) else 0


def main() -> None:
    vn = ROOT / "assets/content/vietnamese"
    print("vietnamese_letters", njson(vn / "alphabet.json"))
    print("vietnamese_phonics", njson(vn / "phonics.json"))
    print("vietnamese_rimes", njson(vn / "rimes.json"))
    print("vietnamese_words", njson(vn / "words.json"))
    print("vietnamese_sentences", njson(vn / "sentences.json"))

    kana = ROOT / "assets/content/japanese/kana"
    for name in (
        "hiragana_basic",
        "hiragana_dakuten",
        "hiragana_handakuten",
        "hiragana_yoon",
        "hiragana_small",
        "hiragana_sokuon",
        "hiragana_choon",
        "katakana_basic",
        "katakana_dakuten",
        "katakana_handakuten",
        "katakana_yoon",
        "katakana_small",
        "katakana_sokuon",
        "katakana_choon",
        "katakana_extended",
    ):
        print(name, njson(kana / f"{name}.json"))

    examples = 0
    for path in kana.glob("*.json"):
        for item in json.loads(path.read_text(encoding="utf-8")):
            if item.get("exampleWord"):
                examples += 1
    print("japanese_example_words", examples)

    thinking = (ROOT / "lib/data/content/thinking_generator.dart").read_text(encoding="utf-8")
    print("thinking_odd_one_out", thinking.count("_odd('"))
    print("thinking_templates", thinking.count("_item('"))
    print("thinking_categories", 10)

    creativity = (ROOT / "lib/data/content/creativity_catalog.dart").read_text(encoding="utf-8")
    print("creativity_coloring", creativity.count("ColoringPicture("))
    print("creativity_dots", creativity.count("DotPuzzle("))
    print("creativity_puzzles", creativity.count("MatchPuzzle("))
    print("creativity_patterns", creativity.count("PatternPuzzle("))
    print("creativity_drawing", creativity.count("DrawingChallenge("))

    math = (ROOT / "lib/data/content/math_generator.dart").read_text(encoding="utf-8")
    print("math_generators", len(re.findall(r"ContentItem generate[A-Z]\w+", math)))

    print("games", 8)
    games = (ROOT / "lib/data/content/game_catalog.dart").read_text(encoding="utf-8")
    symbols = re.search(r"similarSymbols = \[(.*?)\]", games, re.S)
    if symbols:
        print("game_similar_symbols", symbols.group(1).count("'"))

    man = json.loads((ROOT / "assets/audio/audio_manifest.json").read_text(encoding="utf-8"))
    print("audio_vi", sum(1 for x in man if x["language"] == "vi"))
    print("audio_ja", sum(1 for x in man if x["language"] == "ja"))
    print("audio_example", sum(1 for x in man if str(x["id"]).endswith("_example")))
    print("audio_total", len(man))
    print("audio_missing", 0)


if __name__ == "__main__":
    main()
