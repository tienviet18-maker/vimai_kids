# ViMai Kids — Master engineering baseline

Captured: 2026-08-30  
Rule: no product code was modified before this file was written.

## Toolchain

| Item | Value |
|---|---|
| Flutter | 3.47.1 (stable) |
| Dart | 3.13.1 |
| DevTools | 2.60.0 |
| pubspec name | `mai_an_learning` (internal package; not child-facing) |
| Display name | ViMai Kids |
| Version | 1.0.0+1 |

## Commands

| Command | Result |
|---|---|
| `flutter analyze` | 1 **info**: `cacheExtent` deprecated in `lib/features/parent/presentation/parent_screen.dart:87` (`deprecated_member_use`). Exit code 1. No errors/warnings. |
| `flutter test` | **138 passed**, 0 failed |
| `flutter build apk --debug` | Not run at baseline (deferred to post-change release validation) |
| `flutter build web` | Not run at baseline (deferred to post-change release validation) |

## Package versions (pubspec)

- flutter_riverpod ^2.4.3
- flutter_tts ^4.2.5
- audioplayers ^6.5.1
- go_router ^12.1.1
- hive ^2.2.3 / hive_flutter ^1.1.0
- shared_preferences ^2.5.5
- uuid ^4.6.0
- url_launcher ^6.3.1

No Google Cloud / in-app-purchase packages.

## Assets

| Item | Count |
|---|---|
| Production audio manifest | 913 (505 vi, 408 ja) |
| WAV on disk under `assets/audio` | 914 (913 contract + 1 stray `vi/rimes/ao.raw.wav`) |
| Japanese kana JSON files | 15 (244 items) |
| KanjiVG stroke SVG | 92 |
| Vietnamese phonics JSON | 104 |
| Content JSON files | 26 |
| License files | 3 |
| `lib/**/*.dart` | 85 |
| `test/*.dart` | 21 |

## Known issues at baseline (do not treat as new)

1. Parent `cacheExtent` deprecation (analyzer info).
2. Home empty state shows both a 6-tile chooser and a 6-tile Explore grid (duplicate actions).
3. Home greeting hard-coded `Chào $name!` (Vietnamese only).
4. Home parent entry uses a settings icon.
5. Creativity color dots can be 28dp (below 48dp).
6. No purchase/Pro provider; core content is fully bundled (honest free app).
7. Android `applicationId` is `com.maianlearning.mai_an_learning` (store-sensitive; do not change blindly).
8. Google Cloud TTS preview is STOPPED (no ADC / project / voice names). Production WAV protected.
9. Human recordings: 0. 150 HUMAN_REQUIRED still TTS_TEMPORARY.
10. Extended kana (dakuten/yoon/small) have no licensed combined stroke paths.

## Protected

- `assets/audio/**` production WAV (913)
- `lib/core/audio/audio_service.dart`
- Games `GameBoardMetrics` / `FallingLayout`
- `MathQuestionGenerator`
- Branding: ViMai / ViMai Kids / vimai.support@gmail.com
