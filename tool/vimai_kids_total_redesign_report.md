# ViMai Kids — Total UX/UI Redesign Report

## 1. Executive summary

ViMai Kids was rebuilt as a **children’s learning world**, not a school dashboard. The rejected Home (six identical cards in a 2×3 grid on a flat fill) is gone. Home is now a sky-and-hill environment with Mai, a daily adventure scene, and six visually distinct world islands on a winding path.

Learning hubs use the same world language (illustrated scaffold + activity trail) instead of cloned tile grids. Vietnamese and Japanese lessons are mini-stages: large letter/kana, Mai, a listen orb, a visible step strip, and writing that opens immediately.

Educational engines, curriculum JSON, AudioService, and production WAV files were left intact. Vietnamese child phonics still teach **sound**, not English letter names (C → cờ, never xê on the child look screen).

**Would I put this in front of a 5-year-old and their parents?** Yes, as a coherent Flutter children’s product with a real map/adventure information architecture. It is not a commissioned illustrated storybook; motifs are vector-painted, not hand-drawn assets. That remaining art gap is documented below, not hidden.

## 2. Old UX problems

- Home felt like a database of six rectangular subject cards.
- Identical card chrome across Japanese, Vietnamese, Math, Thinking, Creativity, Games.
- Vietnamese letter lesson: giant glyph + info boxes + tiny chips, no sense of a lesson game.
- Audio controls were easy to miss or looked technical.
- Desktop/web stretched empty cream regions.
- Mai was an icon, not a companion with a job.
- Motion was mostly absent or decorative noise.
- Parent and child worlds were not visually separated enough.

## 3. New UX architecture

**Child loop:** LEARN → PLAY → ACHIEVE → DISCOVER → RETURN

| Layer | Role |
| --- | --- |
| Background | Full-bleed `WorldSky` (sky, sun, clouds, hills). Content stays readable. |
| World | Organic islands / activity stones / winding path. |
| Content | Mission, letter/kana stage, quiz, tools. |
| Feedback | Progress rings, stars, Mai mood, lesson feedback. |

**Home IA (not a grid):** greeting + Mai → **Today’s adventure** (`Chơi ngay`) → **six world islands** on a trail → star collection.

**Subject hubs:** `IllustratedScaffold` + `WorldTrail` of `WorldActivity` stones. Routes and titles unchanged.

**Parent:** stays `PageScaffold` on cream — calmer, data-oriented, not a playground.

**Responsive:** phone immersive/vertical; tablet more air; desktop/web full-bleed sky with a **720px learning stage** (`VimaiSpace.maxContent`) so cards do not stretch across 1366px.

## 4. New design system

Central tokens: `lib/core/theme/vimai_tokens.dart`

- **Color:** skyTop / skyMid / cream / grass / path + subject coral/sky/mint/grape/peach/honey/teal.
- **Type:** greeting, title, cardTitle, button, caption (child-sized, high weight).
- **Space:** 4–32 scale; maxContent 720; maxWide 960 (parent).
- **Radius / shadow / motion / touch:** pill islands, soft lift, 90–420ms, 48–56dp targets.
- **Subject looks:** distinctive glyph + cue + color per world.

Reusable world widgets: `lib/features/shared/widgets/vimai_world.dart`

- `WorldSky`, `IdleMascot`, `MissionScene`, `WorldIsland`, `WorldTrail`, `WorldActivity`, `IllustratedScaffold`

Lesson widgets: `KidsLetterHero`, `KidsAudioButton` (listen orb), `KidsStepStrip`, `KidsExampleCard`, `LessonStage`

## 5. Home redesign

- **Rejected:** 2×3 `SliverGrid` / identical `ExploreCard` dashboard.
- **Shipped:** sky environment (animated unless reduced motion) → greeting with Mai → `MissionScene` (adventure copy + duration + large CTA) → six `WorldIsland`s with unique motifs (sakura-like, letter book, number garden, puzzle, studio, playground) → star strip to progress.
- Tests assert: no `SliverGrid`/`GridView`, exactly six `WorldIsland`s, `Chơi ngay`, child name/age, `Con muốn học gì hôm nay?`

## 6. Learning experience redesign

Every lesson screen answers: what am I learning, what do I do, what happens if I succeed, how far am I, what’s next.

- Vietnamese look: Mai + letter hero + spoken sound + listen orb + example illustration + write CTA + Nhìn / Chọn chữ / Viết.
- Japanese look: same stage language + path `Nhìn → Thứ tự nét → Chọn chữ → Viết` + listen / stroke / write chips.
- Math / Thinking: illustrated scaffold, large question, choice grid, celebrating Mai on completion.
- Creativity: sky behind existing draw/color/dot tools (logic unchanged).
- Games: activity trail into existing playfields (`GameBoardMetrics` / falling layout unchanged).

## 7. Vietnamese pronunciation audit

Curriculum JSON **not rewritten**. Child look uses `VietnamesePhonicsGuide.primarySpoken` / sound audio IDs.

| Letter | Child teaches | Letter-name in data (parent/catalog only) |
| --- | --- | --- |
| A | a | a |
| Ă | ă | ă |
| Â | â | â |
| B | **bờ** | bê |
| C | **cờ** | xê (never shown on child look) |
| D | **dờ** | dê |
| Đ | **đờ** | đê |
| Y | **i dài** | i (curriculum phoneme stays `i`) |

Tests: `test/vietnamese_phonics_guide_test.dart` — C/B/D/Đ/Y, no `xê` on look, autoplay `vi_letter_c_sound`.

Ă was **not** changed to “á” (wrong letter). Â stays â in curriculum.

## 8. Japanese learning redesign

- Hub: illustrated trail; **no** standalone “Thứ tự nét Hiragana” tile; **keep** “Thứ tự nét Katakana”.
- Lesson flow chips: Nhìn, Nghe, Thứ tự nét, Chọn chữ, Viết.
- Stroke mode: existing `StrokeOrderPlayer` + KanjiVG data (no invented paths).
- Write mode: existing `WritePracticeBoard` / `WritingCanvas` — immediate canvas, not a dead button.
- Japanese audio stays ja-JP; Vietnamese phonics not mixed into kana content.

## 9. Responsive strategy

| Breakpoint | Behavior |
| --- | --- |
| Phone (<600) | Vertical trail, large islands (~82% width), kid touch targets |
| Tablet (600–1024) | More padding, same stage language |
| Desktop (≥1024) | Full-bleed sky/hills; content max 720px centered — no stretched cards |

Widget tests pump Home at 360×640 through 1366×768 with no overflow.

## 10. Accessibility

- Semantic labels on islands, mission CTA, listen orb, parent icon.
- Contrast: ink on cream/sky; white on solid subject color.
- Touch ≥48dp (primary 56–80).
- `MediaQuery.disableAnimationsOf` stops sky drift and Mai idle bounce.
- Live-region lesson feedback.

## 11. Performance

- Sky is one `CustomPainter`; islands paint only on kind/color change.
- `const` widgets where possible; lazy `ListView` on hubs.
- No heavy blur, no extra raster illustration atlases.
- Suitable for mid-range Android; APK ~68.5MB (audio bundle unchanged).

## 12. Tests

```
flutter analyze   → No issues found
flutter test      → 155 passed
```

Coverage includes Home architecture, phonics, Japanese flow, games layout, audio registry (913), parent 3–7.

## 13. Build status

| Target | Result |
| --- | --- |
| Android release APK | `build/app/outputs/flutter-apk/app-release.apk` (68.5MB). Gradle AUDIO CHECK OK records=913 |
| Web | `build/web` (exit 0). Pre-existing flutter_tts Wasm dry-run warnings only |

No on-device visual QA in this pass (no attached device in the session).

## 14. Production audio protection verification

Compared `tool/audio_v3_production_snapshot.json` to files on disk:

- Snapshot entries: 914 (913 production + stray `assets/audio/vi/rimes/ao.raw.wav`, left in place)
- Disk WAV: 914
- SHA-256 mismatches: **0**
- Missing files: **0**
- `AudioService` not modified for this redesign
- No generate/rename/move/overwrite of production WAV

```
Production WAV modified: 0
Production WAV deleted: 0
Production WAV renamed: 0
Production WAV regenerated: 0
```

## 15. Remaining limitations

- Islands and motifs are **CustomPaint**, not commissioned picture-book art.
- Japanese / Math hubs still list many curriculum activities; they are stones on a trail, not a 2×3 grid, but the list is long by content.
- Stroke-order completeness is still bounded by KanjiVG coverage; missing data is not fabricated.
- Vietnamese writing is free practice (existing canvas), not scored stroke matching.
- Web Wasm dry-run warnings come from `flutter_tts`, not from this UI work.
- No physical phone/tablet visual sign-off in this session.

## 16. Screens / components changed

**New / core**

- `lib/features/shared/widgets/vimai_world.dart`
- `lib/core/theme/vimai_tokens.dart` (sky/grass/path/cream + subject looks)
- `lib/features/shared/widgets/kids_lesson.dart` (listen orb, step strip)

**Screens**

- `lib/features/home/presentation/home_screen.dart`
- `lib/features/onboarding/presentation/welcome_screen.dart`
- `lib/features/vietnamese/presentation/vietnamese_screen.dart`
- `lib/features/vietnamese/presentation/vietnamese_letter_lesson_screen.dart`
- `lib/features/japanese/presentation/japanese_home_screen.dart`
- `lib/features/japanese/presentation/kana_lesson_screen.dart`
- `lib/features/math/presentation/math_screen.dart`
- `lib/features/thinking/presentation/thinking_screen.dart`
- `lib/features/creativity/presentation/creativity_screen.dart`
- `lib/features/games/presentation/games_screen.dart`
- `lib/features/progress/presentation/progress_screen.dart`
- `lib/core/l10n/app_strings.dart` (adventure / listen / Japanese path copy)

**Intentionally not redesigned as a playground**

- `lib/features/parent/presentation/parent_screen.dart` (calm parent dashboard)

**Untouched on purpose**

- `lib/core/audio/audio_service.dart`
- `assets/audio/**/*.wav`
- `assets/content/**` curriculum JSON
- Math generator, game board metrics, KanjiVG stroke data
