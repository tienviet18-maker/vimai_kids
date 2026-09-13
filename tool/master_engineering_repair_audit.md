# ViMai Kids — Master engineering repair audit

Date: 2026-08-30  
No product widgets were edited before this file.

Production WAV snapshot: `tool/audio_v3_production_snapshot.json` — **913** files (excluding pre-existing `ao.raw.wav`).

## A. Architecture

Flutter 3.47.1, Riverpod, go_router, Hive, AudioService (WAV first, same-language TTS fallback). Japanese lesson is `KanaLessonScreen` with chips: look / strokes / recognize / write.

## B. Japanese curriculum source

`lib/data/kana/hiragana_data.dart`, `katakana_data.dart` and JSON under `assets/content/japanese/kana/`. Basic 46+46 plus dakuten/handakuten/yoon/small/sokuon/choon/extended.

## C. Japanese stroke source

KanjiVG CC BY-SA 3.0 in `assets/content/japanese/strokes/catalog.json` (92 entries) + SVG files. License: `assets/licenses/KANJIVG_LICENSE.md`. Catalog check this pass: **0** strokeCount vs path-count mismatches, **0** empty path lists.

## D. Current stroke rendering

`StrokeOrderCatalog` loads catalog paths. `StrokeOrderBoard` + `SvgPathParser` + `PathMetricsHelper.extract`. Animation exists but the same board also mixes tracing and free writing. Label is “Chữ này có N nét” rather than current stroke “Nét i/N”. Ghost of the current stroke is drawn in full while extractPath animates.

## E. Current writing architecture

`WritingCanvas` already uses `Listener` pointer down/move (web-capable). **Write mode in `KanaLessonScreen` renders `StrokeOrderBoard` identically to stroke-order mode.** The canvas only appears after guided tracing completes (`_freeWrite`) or when paths are missing. That is the dead “Viết” tab.

## F. Current audio architecture

Runtime: bundled WAV via AudioService. Build-time Google Cloud TTS in `tool/` only. Production `assets/audio/` protected (913).

## G. Pronunciation map

Existing generation-only file: `tool/audio_generation/vimai_kids_pronunciation_map.json`. Do not duplicate as a second source of truth.

## H. Google TTS configuration

`tool/.env.audio.v3` absent. `VI_VOICE_NAME` / `JA_VOICE_NAME` / `GOOGLE_CLOUD_PROJECT` unset. ADC missing. Package `google-cloud-texttospeech` may be installed. **Not ready to generate.**

## I. Production audio inventory

Manifest 913 (505 vi, 408 ja). Snapshot 913 hashes written. One stray `assets/audio/vi/rimes/ao.raw.wav` is not in the contract.

## J. Tests

Previously 139 passing. Stroke catalog test expects 46+46 KanjiVG paths.

## K. Build state

Previous pass: analyze PASS, APK 68.4MB, web `build/web`.

## L–M. Defects and root causes

1. **Stroke UX looks like a count, not individual strokes** — teaching UI conflated with tracing/write; primary label is total count; ghost full-stroke can obscure start→end drawing.
2. **Viết is dead** — `mode == 'write'` uses the same widget as strokes; practice canvas not shown.
3. **Redundant Hiragana stroke menu** — Japanese home tile “Thứ tự nét Hiragana” duplicates in-lesson stroke mode (`mode=strokes`).
4. **Vietnamese sounds robotic** — production WAVs are TTS_TEMPORARY; Google preview cannot run without credentials. Not a Flutter playback-rate bug.

## N. Files proposed for modification

- `lib/features/japanese/presentation/japanese_home_screen.dart`
- `lib/features/japanese/presentation/kana_lesson_screen.dart`
- `lib/features/japanese/handwriting/stroke_order_board.dart`
- `lib/features/japanese/handwriting/stroke_order_player.dart` (new)
- `lib/features/japanese/handwriting/write_practice_board.dart` (new)
- `lib/features/japanese/writing/presentation/widgets/writing_canvas.dart` (pointer/clear only if needed)
- `lib/core/l10n/app_strings.dart` (instruction strings)
- tests for Japanese lesson / catalog path=count
- docs under `tool/`

## O. Protected

AudioService, Games/GameBoardMetrics/FallingLayout, MathQuestionGenerator, Home, Parent, Creativity, Thinking, curriculum JSON, branding, support email, applicationId, `assets/audio/**` production WAV, KanjiVG SVGs (read-only).
