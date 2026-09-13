#!/usr/bin/env python3
"""QA report for Audio V3 preview or production replacement files."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tool"))

from audio_generation.audio_qa import classify  # noqa: E402
from audio_generation.manifest_loader import preview_items, production_items  # noqa: E402


def main() -> int:
    mode = "preview" if "--preview" in sys.argv else "production"
    items = preview_items() if mode == "preview" else production_items()
    rows = []
    for item in items:
        rel = item.get("previewPath") or item.get("productionPath")
        path = ROOT / rel
        qa = classify(path, language=item["language"], category=item.get("category", "preview"))
        rows.append({"id": item["id"], "path": rel, **qa})
        print(f"{qa.get('status','?'):<14} {item['id']:<28} {rel}")
    out = ROOT / "tool" / "audio_v3_qa_report.json"
    out.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {out}  count={len(rows)}")
    print("Naturalness is MANUAL_REVIEW. This script does not claim human quality.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
