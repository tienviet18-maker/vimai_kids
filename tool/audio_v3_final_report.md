# Audio V3 final report

Date: 2026-08-29

## A. Files inspected

- `tool/human_audio_inventory.json`
- `tool/human_audio_recording_manifest.json`
- `tool/audio_inventory.json`
- `assets/audio/audio_manifest.json`
- `assets/audio/audio_jobs.json`
- `README_DEV_AUDIO.md`
- `lib/core/audio/**` (AudioService left unchanged)
- `tool/generate_audio_assets.py`
- `tool/check_audio_assets.py`
- `lib/core/audio/vietnamese_speech_catalog.dart`
- `test/audio_*.dart`
- Cursor dynamic tools (no Revid MCP)

## B. Files changed

Audio pipeline/docs/tests only:

- `tool/audio_v3_preflight.md`
- `tool/audio_content_v3.json`
- `tool/audio_voice_profiles.json`
- `tool/audio_preview_manifest.json`
- `tool/audio_v3_manifest.json` (empty records)
- `tool/audio_v3_manual_qa.md`
- `tool/vietnamese_pronunciation_v3.md`
- `tool/build_audio_v3_content.py`
- `tool/generate_audio_v3.py`
- `tool/audit_audio_v3.py`
- `tool/audio_generation/**`
- `tool/.env.audio.v3.example`
- `tool/audio_v3_final_report.md`
- `assets/audio_preview/**` (README + gitkeep; no WAV)
- `test/audio_v3_test.dart`
- `README_DEV_AUDIO.md` (V3 section)
- `.gitignore` (`tool/.env.audio.v3`)

## C. Files protected

- All 913 production WAV files
- `lib/core/audio/audio_service.dart` and runtime audio architecture
- Home, Parent, Progress, Games, Math generator, Thinking, Creativity, navigation, curriculum JSON, branding, KanjiVG, stroke-order

## D. Current audio inventory

| Metric | Value |
|---|---|
| Manifest records | 913 |
| Vietnamese | 505 |
| Japanese | 408 |
| Missing files | 0 |
| Inventory VALID | 660 |
| Inventory UNUSED (file exists) | 253 |
| Invalid / NEEDS_REPLACEMENT | 0 |
| Clipping flags | 0 |

Shipped quality: **TTS_TEMPORARY** (Piper / SAPI bake).

## E. Human-required inventory

- HUMAN_REQUIRED: 150 (58 VI letter name+sound, 92 JA basic kana)
- EXISTING_HUMAN: 0
- Recording status: all NOT_RECORDED
- Full table: `tool/audio_v3_preflight.md`

## F. Preview manifest

18 clips in `tool/audio_preview_manifest.json`. **0 WAV generated** (provider unconfigured).

## G. Provider status

**unconfigured.** Revid MCP/API: not available. STOP before production generation.

## H. Voice IDs discovered

**none.** Configure `VIMAI_AUDIO_V3_VI_VOICE_ID` and `VIMAI_AUDIO_V3_JA_VOICE_ID` after choosing a real provider dashboard voice. Do not assume example IDs are Vietnamese or Japanese.

## I. Commands created

```bash
python tool/generate_audio_v3.py --preview
python tool/generate_audio_v3.py --preview --dry-run
python tool/generate_audio_v3.py --production --yes
python tool/audit_audio_v3.py --preview
python tool/check_audio_assets.py
```

`--force-vi` is refused. Preview cannot write `assets/audio/vi` or `assets/audio/ja`.

## J. Tests

`flutter test` — PASS (134 tests), including `test/audio_v3_test.dart`.

## K. Flutter analyze

`flutter analyze` — 1 **info** (`deprecated_member_use` `cacheExtent` on `lib/features/parent/presentation/parent_screen.dart`). No errors in audio code. Parent was **not** modified in this pass.

## L. Build status

APK/Web **not re-run**. No Flutter runtime audio code changed; analyze info is outside this changeset. Existing contract still: 913 records, missing=0 (verified by tests).

## M. Risks

- Without credentials, no listening samples exist yet.
- Â in curriculum is spoken `â`, not `ớ`. Preview `ớ` is a sample only.
- Đúng rồi / Thử lại / じょうず have no production IDs.
- OpenAI/ElevenLabs adapters use documented APIs only if you set env vars; quality still requires manual listening.
- PREMIUM_AI_VOICE is still AI, not a human recording.

## N. Next action

1. Copy `tool/.env.audio.v3.example` → `tool/.env.audio.v3` with a real provider, API key, and VI/JA voice IDs you verified in that provider.
2. `python tool/generate_audio_v3.py --preview`
3. Listen with `tool/audio_v3_manual_qa.md`
4. Only after approval:

```bash
python tool/generate_audio_v3.py --production --yes
```
