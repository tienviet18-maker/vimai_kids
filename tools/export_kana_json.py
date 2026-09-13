import json
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]

def parse_kana(file_path: Path, default_script: str):
    text = file_path.read_text(encoding="utf-8")
    pattern = re.compile(r'const KanaItem\((.*?)\)', re.DOTALL)
    items = []
    for match in pattern.finditer(text):
        content = match.group(1).replace('\n', ' ')
        item = {}
        for key in ['id', 'character', 'romaji', 'pronunciation', 'baseCharacter']:
            m = re.search(r"\b" + key + r"\s*:\s*'([^']*)'", content)
            if m:
                item[key] = m.group(1)
        m_stroke = re.search(r'strokeCount\s*:\s*(\d+)', content)
        item['strokeCount'] = int(m_stroke.group(1)) if m_stroke else 1

        m_script = re.search(r'KanaScript\.(\w+)', content)
        item['script'] = m_script.group(1) if m_script else default_script

        m_type = re.search(r'KanaType\.(\w+)', content)
        item['kanaType'] = m_type.group(1) if m_type else 'basic'

        m_conf = re.search(r'confusionGroup\s*:\s*\[(.*?)\]', content)
        if m_conf:
            conf_str = m_conf.group(1)
            item['confusionGroup'] = [s.strip().strip("'") for s in conf_str.split(',') if s.strip()]
        else:
            item['confusionGroup'] = []

        items.append(item)
    return items

h_items = parse_kana(ROOT / "lib" / "data" / "kana" / "hiragana_data.dart", "hiragana")
k_items = parse_kana(ROOT / "lib" / "data" / "kana" / "katakana_data.dart", "katakana")

out_ja = ROOT / "assets" / "data" / "japanese"
out_ja.mkdir(parents=True, exist_ok=True)

(out_ja / "hiragana.json").write_text(json.dumps(h_items, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"Exported {len(h_items)} hiragana items to assets/data/japanese/hiragana.json")

(out_ja / "katakana.json").write_text(json.dumps(k_items, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"Exported {len(k_items)} katakana items to assets/data/japanese/katakana.json")
