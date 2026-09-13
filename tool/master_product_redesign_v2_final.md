# ViMai Kids — Master Product Redesign V2 Final Audit

Date: 2026-08-31  
Status: **PARTIAL** (UI/phonics layer shipped; production Vietnamese voice quality still blocked)

This pass did **not** rewrite architecture, curriculum, games board math, MathQuestionGenerator, or AudioService.

## 1. Executive Summary

Home is now Mai-centered (greeting + mascot + real mission + distinctive subject worlds). Vietnamese phonics lessons now speak **âm chữ** (`cờ` for C) as the primary audio, not **tên chữ** (`xê`). Letter-name data remains in curriculum and is available as a secondary control.

Production WAV files were not touched. Google Cloud TTS credentials are not configured, so native-quality Vietnamese regeneration was **not** run.

## 2. Before / After

| Area | Before | After |
|---|---|---|
| Home | Header card + identical-feeling tiles | Mai as visual anchor, mission, cue-based worlds |
| Vietnamese look | Auto-play `vi_letter_*_name`; "Tên chữ" equal to "Âm chữ" | Auto-play sound ID; Âm primary; Tên chữ secondary |
| C | Child hears "xê" first | Child hears "cờ"; sees example "cá"; "Tên chữ: xê" optional |
| World tiles | Material icon as hero | Subject cue (`あ い う`, `A B C`, `1 2 3`) |
| Write (VI) | Canvas existed; dispose crashed tests | Canvas immediate; dispose safe |
| Japanese write/stroke | Already repaired in prior pass | Re-verified by tests; no duplicate Hiragana stroke menu |

## 3. Design System

Extended existing tokens (`VimaiColor`, `VimaiType`, `VimaiSpace`, `VimaiRadius`, `VimaiShadow`, `VimaiMotion`). Added `mascotHero`, `SubjectLook.cue`. World tiles use flat soft fills (no loud gradient). Pressable still has short scale feedback and respects `disableAnimations`.

No second design system. No glassmorphism/neon.

## 4. Home

Mai (120dp) is the above-the-fold anchor. Required copy preserved: `Chào {name}!`, age, `Hôm nay mình học gì nhỉ?`, `Con muốn học gì hôm nay?`. Empty state uses real `noProgressYet` + `Bắt đầu`. Continue uses real recommender prompt + today's activity count. No fake 1/3 missions.

Widget overflow tests: 360×640 through 1366×768 PASS.

## 5. Japanese

Hub still has no redundant "Thứ tự nét Hiragana". Lesson modes Look → Listen → Stroke → Pick → Write. Stroke player uses bundled KanjiVG. Write opens `WritePracticeBoard` immediately. Tests PASS.

## 6. Vietnamese

Phonics runtime layer: `lib/core/audio/vietnamese_phonics_guide.dart`.

- Primary spoken = curriculum `phoneme`
- Primary audio = `audioSoundId`
- Letter name preserved, not used as phonics autoplay
- All 29 letters: catalog name/sound matches curriculum metadata
- Alphabet grid speaker plays sound; 48dp target
- Listen-letter game plays sound
- Dedicated "hear name" quiz modes still play name (that is letter-name practice, not the phonics lesson)

Curriculum JSON **not** modified.

## 7. Math

Presentation only (prior pass). Generator untouched.

## 8. Thinking

Presentation only (prior pass). Bank untouched.

## 9. Creativity

Studio chrome only (prior pass). Modes untouched.

## 10. Games

Hub intro only. `GameBoardMetrics` / `FallingLayout` untouched. Games tests PASS.

## 11. Progress

Child labels + real ratios (prior pass). No internal IDs.

## 12. Parent

Adult sections remain (Today / Learning / Strengths / Settings / Support / Feedback / About). Ages 3–7. Email unchanged.

## 13. Support / About

Separated cards. `vimai.support@gmail.com` unchanged. KanjiVG credit retained.

## 14. Audio

- Production 913 WAV: hashes unchanged
- AudioService architecture: **not modified**
- Generation SoT remains `tool/audio_generation/vimai_kids_pronunciation_map.json` (`curriculumModified: false`)
- Flutter phonics playback uses sound IDs already in the manifest
- **BLOCKED:** Google Cloud TTS credentials / voice IDs not configured. Did not generate preview or production audio. Existing letter WAVs are still the Piper/TTS_TEMPORARY inventory. Human recordings: 0

## 15. Stroke Order

KanjiVG catalog still source of truth. Basic 46+46 covered. Extended kana: honest fallback (DATA_UNAVAILABLE). No invented SVG.

## 16. Responsive

Home / Parent / Japanese / Games overflow tests PASS at required sizes. Mobile-first scroll + max content width.

## 17. Accessibility

48dp targets on letter speaker, pressables, chips. Correct/wrong uses icon + text. Semantics on mascot and tiles. Motion respects reduced-motion helper.

## 18. Localization

New action/mission strings in `AppStrings`. Existing Home assertions unchanged.

## 19. Data Integrity

| Asset | Modified |
|---|---|
| `assets/content/**` curriculum JSON | NO |
| Production WAV | NO (0 modified / deleted / renamed / regenerated) |
| Manifest 913 | YES intact (`AUDIO CHECK OK records=913 missing=0`) |
| MathQuestionGenerator | NO |
| GameBoardMetrics / FallingLayout | NO |
| AudioService | NO |
| Routes | NO |
| applicationId | NO |
| Branding / support email | NO |

## 20. Tests

`flutter analyze`: No issues found.

`flutter test`: **151 PASS / 0 FAIL**

New: `test/vietnamese_phonics_guide_test.dart` (29 letters, C = cờ, autoplay sound id, write canvas).

## 21. APK

PASS — `build/app/outputs/flutter-apk/app-release.apk` (68.4MB)  
`AUDIO CHECK OK records=913 content_ids=749 missing=0`

## 22. Web

PASS — `build/web`  
Pre-existing `flutter_tts` Wasm dry-run warnings.

## 23. Production WAV protection

- PRODUCTION_WAV_MODIFIED: 0
- PRODUCTION_WAV_DELETED: 0
- PRODUCTION_WAV_RENAMED: 0
- PRODUCTION_WAV_REGENERATED: 0
- Snapshot hashes match disk
- Disk WAV count 914 = 913 contract + pre-existing stray `assets/audio/vi/rimes/ao.raw.wav` (not deleted)

## 24. Remaining blockers

1. **Vietnamese production voice quality** — still existing TTS inventory. Google Cloud TTS not configured. Do not overwrite 913 WAVs until credentials + voice IDs are set and preview is approved under `tool/audio_v3_preview/`.
2. **Human recordings** — 0.
3. **Interactive visual QA** — widget tests only this session; a parent/device pass is still needed for the "does a 3-year-old want to tap?" bar.
4. **Extended kana stroke data** — legal source still missing; honest fallback remains.

## 25. Recommended next phase

1. Configure Google Cloud TTS in the **tool** pipeline only; generate **preview** clips for 29 letter sounds; A/B listen; replace production **inventory-driven** only after approval.
2. Record a native kindergarten-teacher voice for letter sounds + praise.
3. Device visual QA of Home V2 and Vietnamese letter C.
4. Optional: richer Mai illustration assets if a licensed set is added (do not invent a new mascot brand).

## Scoreboard

FLUTTER_ANALYZE: PASS  
FLUTTER_TEST: 151 PASS / 0 FAIL  
APK: PASS  
WEB: PASS  
PRODUCTION_WAV_MODIFIED: 0  
PRODUCTION_WAV_DELETED: 0  
PRODUCTION_WAV_RENAMED: 0  
PRODUCTION_WAV_REGENERATED: 0  
CURRICULUM_MODIFIED: NO  
NAVIGATION_MODIFIED: NO  
MATH_GENERATOR_MODIFIED: NO  
GAMES_LOGIC_MODIFIED: NO  
AUDIOSERVICE_MODIFIED: NO  
VIETNAMESE_PRONUNCIATION_FIXED: PARTIAL (UI + playback layer YES; WAV quality NO)  
JAPANESE_STROKE_ORDER: PASS  
WRITE_BUTTON: PASS  
HOME_V2: PASS (widget-tested; human visual QA still recommended)
