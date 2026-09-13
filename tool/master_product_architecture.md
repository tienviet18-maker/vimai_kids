# ViMai Kids — Product architecture

Date: 2026-08-30  
Source of truth: current `lib/`, `assets/`, `test/`, `tool/`.

## 1. Application entry

`lib/main.dart` → Hive init → load kana/content/profile/mastery/audio/stroke catalog → `ProviderScope` → `ViMaiKidsApp` (`MaterialApp.router`, title `AppBrand.productDisplayName`).

## 2. Routing

`go_router` in `lib/core/routing/app_router.dart`. Gatekeeper `/` → welcome or profiles. Child worlds: `/japanese`, `/vietnamese`, `/math`, `/thinking`, `/creativity`, `/games`, `/progress`, `/parent`. Legacy `/kana/:id/*` routes redirect into `/japanese/learn/:script`.

## 3. State management

Riverpod. Providers in `lib/core/providers.dart`. Profile, mastery, content, kana, audio.

## 4. Persistence

Hive boxes via `ProfileRepository` and `MasteryRepository`. Local only.

## 5. Localization

`lib/core/l10n/app_strings.dart` — Vietnamese / English / Japanese UI strings. Profile `settings.uiLang`. Curriculum content remains Vietnamese/Japanese educational data, not mechanically translated.

## 6. Audio architecture

Runtime: bundled WAV (`AudioService`) → same-language device TTS fallback → silence. No VI↔JA/EN fallback. `playbackRate` 1.0. Flutter never calls Google Cloud TTS.

Build-time: `tool/generate_audio_v3.py` Google Cloud preview → `tool/audio_v3_preview/` only. Production 913 WAV protected. Pronunciation map is generation-only.

## 7. Japanese curriculum

JSON under `assets/content/japanese/kana/` (basic, dakuten, handakuten, yoon, small, sokuon, choon, extended). Lesson UX: look / listen / strokes / trace / write in `kana_lesson_screen.dart`. Stroke paths: KanjiVG 92 basic kana. Honest `strokeMissing` when paths absent. No AI handwriting score.

## 8. Vietnamese curriculum

29 letters in `VietnameseSpeechCatalog`. Activities: alphabet, phonics, rimes, words, sentences, choose, game. Letter name vs sound are distinct in the catalog (e.g. B name `bê`, sound `bờ`). Generation overlay lives in `tool/audio_generation/vimai_kids_pronunciation_map.json` (Â sound `ơ`, Y `i dài`) without rewriting curriculum JSON.

## 9. Math

`lib/data/content/math_generator.dart` (`MathQuestionGenerator`) — protected. Age 3–7 gating, counting/add/sub/missing/word/recognition. UI: `math_screen.dart`.

## 10. Thinking

`thinking_generator.dart` — 10 categories × 10 questions, age-gated. UI: `thinking_screen.dart`.

## 11. Creativity

`creativity_catalog.dart` + `creativity_screen.dart`: free draw, coloring, connect-the-dots, match, patterns, drawing challenges. Age-filtered. Not an empty shell.

## 12. Games

Hub + 7 games. Playfield: `GameBoardMetrics`, `FallingLayout` (protected). Scaffold: `game_play_scaffold.dart`.

## 13. Progress

`progress_screen.dart` + `ProgressLabels` (never show raw IDs). Mastery via `MasteryEngine` / Hive.

## 14. Parent

`parent_screen.dart`: Today, Learning, Strengths, Needs practice, Settings, Support (email visible), About + licenses/KanjiVG credit.

## 15. Support / About

`AppBrand`: ViMai Kids, ViMai, `vimai.support@gmail.com`, version 1.0.0. Mail via `FeedbackMail` + `url_launcher`.

## 16. Purchase / Pro

Not implemented. No IAP plugin. Core lessons are bundled offline. Future: `AppEntitlements` + `PurchasePort` abstraction only — no fake checkout.

## 17. Offline

Curriculum, production audio, stroke SVG bundled. No network required for lessons. Email launch is optional and fails with a dialog.

## 18. Responsive

`lib/core/responsive/breakpoints.dart`. Home/games tests cover 360×640 through desktop. Bounded `maxWidth` on Home. Games use a bounded playfield.

## 19. Accessibility

`Pressable` semantics, 48dp `VimaiSize.touchMin`, `VimaiMotion.of` respects reduce-motion. Feedback widgets use icon + text (`check_circle` / `refresh`), not color alone, in shared UI. Some older unused kana screens still tint green/red.

## 20. Testing

Widget + unit tests under `test/`. Audio isolation, 913 inventory, games layout, Home/Parent overflow, stroke catalog, Audio V3 preview protection.
