# ViMai Kids — Visual + UX Redesign Report

Date: 2026-08-31  
Scope: presentation and UX only. Not a rewrite, not a data migration, not a curriculum rewrite.

## 1. What was audited

Inspected before and during the pass:

- `lib/` architecture (routing, theme, tokens, shared widgets, feature screens)
- `assets/` (illustrations unused where none; curriculum JSON; production audio)
- `pubspec.yaml`
- Localization (`lib/core/l10n/app_strings.dart`)
- Routing (`lib/core/routing/app_router.dart`) — routes unchanged
- Theme / tokens (`lib/core/theme/app_theme.dart`, `lib/core/theme/vimai_tokens.dart`)
- Shared widgets (`lib/features/shared/widgets/`)
- Home, Japanese, Vietnamese, Math, Thinking, Creativity, Games, Progress, Parent
- Japanese handwriting / stroke-order (`stroke_order_player.dart`, `write_practice_board.dart`, KanjiVG catalog)
- `AudioService` (read-only)
- Session tracking (`SessionBinder`)
- Tests under `test/` (product audit, Japanese flow, games layout, audio inventory)
- Docs under `tool/` (`master_product_audit*.md`, phase audits, audio/stroke docs)

Existing ViMai tokens were usable. The pass **extended** them instead of creating a second design system.

## 2. What was redesigned

Presentation chrome across child Home, subject hubs, Japanese/Vietnamese lesson surfaces, Math/Thinking quizzes, Creativity studio header, Progress, and Parent Support/About.

Business logic, generators, games board math, audio pipeline, and curriculum JSON were not rewritten.

## 3. Design system changes

Extended `lib/core/theme/vimai_tokens.dart`:

- Typography: `display`, `label` added beside existing greeting/title/subtitle/card/button/caption
- Shadows: `lift` added
- Motion: `hover`, `enter`, `curve`; `VimaiMotion.of` still respects `disableAnimations`
- `SubjectLook` is public (`color`, `soft`, `glyph`, `icon`)
- Subject identities: Japanese coral, Vietnamese sky, Math mint, Thinking grape, Creativity peach, Games honey

Shared widgets in `lib/features/shared/widgets/vimai_ui.dart`:

- `Pressable` hover (web) + press scale
- `SoftSurface`, `HubIntro`, `ProgressRing`, `WorldTile`
- `LessonFeedback` remains icon + text + color (not color-only)

`ChoiceGrid` now supports `lastChoice` / `lastCorrect` with check / retry icons.

No scattered second palette was introduced.

## 4. Home changes

Home is a cream child hub, not a dashboard of identical rectangles:

- Header: mascot, greeting (`Chào {name}!`), age, daily status, parent shortcut
- Hero: `Con muốn học gì hôm nay?` when empty; `Tiếp tục nào!` plus real continue card when progress exists
- Six `WorldTile`s with distinct subject color, icon, glyph, and real mastery progress
- Empty tiles use `Bắt đầu` (not `Khám phá`, not `Học tiếp`, not exact `Tiến bộ`)
- Today ring uses real `todayMinutes / dailyMinutes`
- Internal IDs (`h_he`, `vietnamese.blend`) are not shown

Widget tests cover 360×640 through 1366×768.

## 5. Japanese changes

Hub: `HubIntro` with learning path copy (`Nhìn → Nghe → Thứ tự nét → Viết`). Grouped Hiragana / extra / Katakana. No redundant “Thứ tự nét Hiragana” tile. Katakana stroke-order entry kept.

Lesson: path caption; Look / Listen / Stroke / Pick / Write chips; write mode still opens `WritePracticeBoard`; stroke mode still uses licensed KanjiVG via `StrokeOrderPlayer` (`Nét i/n`). Recognize uses non-color-only feedback. Missing stroke data still uses the honest fallback (no invented SVG).

## 6. Vietnamese changes

Hub: `HubIntro` + existing activities.

Letter lesson: **Tên chữ** and **Âm chữ** are separate visual cards. Write mode shows `Con hãy viết theo mẫu` plus canvas. Recognize uses last-choice icon feedback. Curriculum text and production WAVs were not rewritten.

## 7. Math presentation changes

`lib/data/content/math_generator.dart` **unchanged**.

Hub uses `HubIntro`. Quiz uses a question `SoftSurface`, large number typography, `ChoiceGrid` last-choice feedback, and completion mascot. Age gating and generation logic untouched.

## 8. Thinking changes

Question bank unchanged. Instruction sits on a grape `SoftSurface`. Choice feedback is icon + text. Wrong answers show the real `item.answer` when present. No invented questions.

## 9. Creativity changes

Modes preserved: draw, color, dots, match/pattern, rules, challenge.

Added studio `HubIntro` and a peach mode-chip tray. Canvas, palette, and puzzle logic unchanged.

## 10. Games chrome changes

Hub: `HubIntro` + existing tiles.

`GameBoardMetrics` and `FallingLayout` **unchanged**. Playfield sizing, falling layout, and board calculations untouched. Entry titles/instructions/result (`GameCompletePanel`) already existed; no board-dimension edits.

Games layout tests: PASS.

## 11. Progress changes

Child-facing labels only (`Hôm nay`, `Con đã nhớ`, `Đang luyện`, `Cần ôn`, most-practiced). Rings/bars use real ratios (`todayMinutes/dailyMinutes`, remembered/active, practicing/active, subject counts / active). Internal curriculum IDs are not displayed. Empty state uses the existing mascot + `noProgressYet`.

## 12. Parent changes

Calm adult layout with sections: Today, Learning, Strengths, profile, needs practice, settings, Support, Feedback, About, licenses.

Ages remain 3–7. Support email remains `vimai.support@gmail.com`.

## 13. Support / About changes

Separated (no single giant card):

- Support: help copy + selectable email + send mail
- Feedback: contact CTA
- About: ViMai Kids, version, developer ViMai
- Licenses: existing license body + KanjiVG attribution

## 14. Responsive changes

`PageScaffold` still constrains to `VimaiSpace.maxWide`. Home uses 2–3 columns by width and aspect ratios for phone/tablet/desktop. Hubs use `Breakpoints.gridCount`. Widget overflow tests: Home sizes, Parent/Thinking/Creativity/Progress at 360×800, Japanese lesson sizes, Games sizes.

No separate desktop information architecture was added; large widths constrain rather than stretch.

## 15. Accessibility changes

- Minimum 48dp targets on pressables, chips, color dots, game tokens
- Semantics labels on subject tiles, mode chips, color swatches, live-region feedback
- Web hover + Material ink; focus remains via Material
- Correct/wrong is icon + text + color
- `VimaiMotion.of` zeros animation when `disableAnimations` is on
- Contrast: ink on cream, subject colors used as accents

## 16. Files changed

| File | Role |
|---|---|
| `lib/core/theme/vimai_tokens.dart` | Tokens / subject looks |
| `lib/features/shared/widgets/vimai_ui.dart` | Shared chrome |
| `lib/features/shared/widgets/choice_grid.dart` | Quiz feedback |
| `lib/core/l10n/app_strings.dart` | Child-facing copy |
| `lib/features/home/presentation/home_screen.dart` | Home redesign |
| `lib/features/japanese/presentation/japanese_home_screen.dart` | Japanese hub |
| `lib/features/japanese/presentation/kana_lesson_screen.dart` | Lesson chrome / quiz feedback |
| `lib/features/vietnamese/presentation/vietnamese_screen.dart` | Vietnamese hub |
| `lib/features/vietnamese/presentation/vietnamese_letter_lesson_screen.dart` | Name/sound/write/quiz chrome |
| `lib/features/math/presentation/math_screen.dart` | Hub + quiz chrome |
| `lib/features/thinking/presentation/thinking_screen.dart` | Question/feedback chrome |
| `lib/features/creativity/presentation/creativity_screen.dart` | Studio chrome |
| `lib/features/games/presentation/games_screen.dart` | Games hub intro |
| `lib/features/progress/presentation/progress_screen.dart` | Motivating progress UI |
| `lib/features/parent/presentation/parent_screen.dart` | Parent / Support / About |
| `tool/visual_ux_redesign_report.md` | This report |

## 17. Files protected (unchanged)

- Production WAV under `assets/audio/` (913 manifest records; hashes match `tool/audio_v3_production_snapshot.json`)
- `lib/core/audio/audio_service.dart`
- `lib/data/content/math_generator.dart`
- `lib/features/games/logic/game_board_metrics.dart`
- `lib/features/games/logic/falling_layout.dart`
- Curriculum JSON under `assets/content/`
- `lib/core/routing/app_router.dart` paths
- Android `applicationId` `com.maianlearning.mai_an_learning`
- Branding / `vimai.support@gmail.com`
- KanjiVG licensed stroke paths (consumed, not invented)

Workspace is not a git repository; protection was verified by hash/inventory, not `git diff`.

## 18. Test results

`flutter analyze`: No issues found.

`flutter test`: **145** tests passed, including:

- `product_audit_widget_test` (Home copy + overflow sizes, Parent ages/email)
- `japanese_lesson_flow_test` (no Hiragana stroke tile, write/stroke flow)
- `games_layout_test`
- `audio_v3_test` (913 inventory intact)

## 19. APK result

PASS — `build/app/outputs/flutter-apk/app-release.apk` (~68.4 MB).  
Gradle audio check: `AUDIO CHECK OK records=913 content_ids=749 missing=0`.

Kotlin Gradle Plugin warning from `flutter_tts` is pre-existing plugin metadata, not an APK failure.

## 20. Web result

PASS — `build/web`.  

Pre-existing `flutter_tts` Wasm dry-run warnings; JS compile succeeded.

## 21. Production WAV verification

Compared SHA-256 of snapshot files to disk:

- Production WAV modified: **0**
- Production WAV deleted: **0**
- Production WAV renamed: **0**
- Production WAV regenerated: **0**
- Manifest records: **913**
- Disk WAV count: **914** (913 contract + pre-existing stray `assets/audio/vi/rimes/ao.raw.wav`, not deleted)

`--force-vi` was not run. Google TTS generation was not run.

## 22. Remaining limitations

- Vietnamese pronunciation quality is still the existing TTS_TEMPORARY / Piper inventory. Human recordings: 0. Google Cloud TTS credentials are not configured. This pass did not regenerate audio.
- Extended kana without licensed stroke data still shows the honest “data unavailable” fallback — not fake geometry.
- No interactive device/browser screenshot pass in this environment (widget overflow tests only). Visual polish on a real 3–7-year-old device should still be reviewed by a human.
- Games playfields were intentionally not restyled inside the board.
- This is **not** a claim that the product is “production ready” as a finished commercial SKU; it is a presentation/UX redesign around working logic.

## Status summary

See the closing **VIMAI KIDS — VISUAL UX REDESIGN STATUS** block in the engineering handoff.
