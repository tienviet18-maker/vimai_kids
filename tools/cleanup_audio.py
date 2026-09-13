#!/usr/bin/env python3
"""CLEAN SLATE PROTOCOL: Clean up legacy non-prefixed audio files in assets/audio/

SAFEGUARDS:
- ONLY removes .mp3 and .wav files that DO NOT adhere to the new naming rules.
- ABSOLUTELY PRESERVES files starting with:
    - v_   (Vietnamese audio)
    - j_   (Japanese audio)
    - sys_ (System audio)
    - bgm_ (Background music)
- Never touches subdirectories (e.g. assets/audio/vi/, assets/audio/ja/)
- Never touches non-audio files (e.g. JSON metadata)
"""
from __future__ import annotations

import sys
from pathlib import Path

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
AUDIO_DIR = ROOT / "assets" / "audio"

PRESERVED_PREFIXES = ("v_", "j_", "sys_", "bgm_")
AUDIO_EXTENSIONS = (".mp3", ".wav")


def should_delete(file_path: Path) -> bool:
    """Return True only if file is an audio file not matching any preserved prefix."""
    if not file_path.is_file():
        return False
    name_lower = file_path.name.lower()
    if not name_lower.endswith(AUDIO_EXTENSIONS):
        return False
    if any(name_lower.startswith(pfx) for pfx in PRESERVED_PREFIXES):
        return False
    return True


def cleanup() -> int:
    if not AUDIO_DIR.exists():
        print(f"Error: Thư mục không tồn tại: {AUDIO_DIR}", file=sys.stderr)
        return 1

    deleted_count = 0
    # Scan only top-level files in assets/audio/
    for item in sorted(AUDIO_DIR.iterdir()):
        if should_delete(item):
            try:
                item.unlink()
                deleted_count += 1
            except Exception as exc:
                print(f"[Lỗi xóa] {item.name}: {exc}", file=sys.stderr)

    print(f"Đã xóa thành công {deleted_count} file âm thanh rác")
    return 0


if __name__ == "__main__":
    raise SystemExit(cleanup())
