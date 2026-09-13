# Human audio recording spec — ViMai Kids

**HUMAN_AUDIO_BLOCKED.** This repository contains **zero** human recordings.

Shipped WAV files are:

- Vietnamese: Piper `vi_VN-vais1000-medium` (TTS_TEMPORARY)
- Japanese: Windows `ja-JP` bake at build time (TTS_TEMPORARY)

Do **not** call them human, native, or studio quality.

Do **not** regenerate the 913-file inventory to “fix” quality.
Do **not** use `playbackRate` or Piper `length_scale` to fake a person.

## Priority

1. **58** Vietnamese letter name + sound clips (`vi_letter_*`)
2. **92** basic kana character clips (`ja_h_*` / `ja_k_*` basic 46+46, no `_example`)

See `tool/human_audio_recording_manifest.json` for id, text, target_path, recommended duration.

## Recording notes

Vietnamese letter names stay as curriculum (`bê`, `xê`, …). Sounds stay (`bờ`, `cờ`, …).
Japanese: one mora, child-clear, ~600–900 ms, no clipping, native speaker.

Replace **the same** `assets/audio/...` path when a take is approved. Keep AudioService asset-first.

Classification of all 913 ids: `tool/human_audio_inventory.json`
(`HUMAN_REQUIRED` / `TTS_ACCEPTABLE` / `EXISTING_HUMAN` / `NOT_NEEDED`).
`EXISTING_HUMAN` is **0**.
