#!/usr/bin/env python3
"""Offline validation for Audio V3 Google Cloud tooling. Does not generate audio."""
from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tool"))

from audio_generation.google_tts_status import diagnose  # noqa: E402
from audio_generation.manifest_loader import preview_items  # noqa: E402
from audio_generation.pronunciation_map import spoken_text_for  # noqa: E402


class AudioV3GoogleTests(unittest.TestCase):
    def test_preview_manifest_has_existing_18_ids(self) -> None:
        items = preview_items()
        self.assertEqual(len(items), 18)
        ids = [x["id"] for x in items]
        self.assertEqual(len(set(ids)), 18)
        for item in items:
            self.assertTrue(item["previewPath"].startswith("tool/audio_v3_preview/"))
            self.assertFalse(item["previewPath"].startswith("assets/audio/"))

    def test_google_config_voices_are_empty_until_verified(self) -> None:
        cfg = json.loads((ROOT / "tool/audio_generation/google_tts_config.json").read_text(encoding="utf-8"))
        self.assertEqual(cfg["vietnamese"]["voice_name"], "")
        self.assertEqual(cfg["japanese"]["voice_name"], "")
        self.assertEqual(cfg["vietnamese"]["language_code"], "vi-VN")
        self.assertEqual(cfg["japanese"]["language_code"], "ja-JP")
        self.assertEqual(cfg["pitch"], 0)

    def test_diagnose_not_ready_without_credentials(self) -> None:
        status = diagnose(probe_api=False)
        self.assertFalse(status.ready)
        self.assertIn("FOUND", status.preview_manifest)
        block = status.format_block()
        self.assertIn("AUDIO_V3_GOOGLE_STATUS", block)
        self.assertIn("Ready for preview:", block)
        self.assertIn("NO", block)

    def test_pronunciation_map_overlays(self) -> None:
        spoken, category = spoken_text_for("vi_letter_aa_sound", "vi-VN", "â")
        self.assertEqual(spoken, "ơ")
        self.assertEqual(category, "PHONICS")
        spoken, _ = spoken_text_for("preview_vi_a", "vi-VN", "a")
        self.assertEqual(spoken, "a")
        spoken, _ = spoken_text_for("preview_ja_h_a", "ja-JP", "あ")
        self.assertEqual(spoken, "あ")
        spoken, cat = spoken_text_for("preview_vi_gioi_lam", "vi-VN", "Giỏi lắm")
        self.assertEqual(spoken, "Giỏi lắm")
        self.assertEqual(cat, "PRAISE")

    def test_example_env_has_no_secrets(self) -> None:
        text = (ROOT / "tool/.env.audio.v3.example").read_text(encoding="utf-8")
        self.assertIn("GOOGLE_CLOUD_PROJECT=", text)
        self.assertIn("VI_VOICE_NAME=", text)
        self.assertNotIn("BEGIN PRIVATE KEY", text)


if __name__ == "__main__":
    unittest.main()
