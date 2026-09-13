# ViMai Kids — Master product audit (before pass)

Date: 2026-08-29  
Git: **not a repository** (no `.git`). No reset/commit possible.  
Method: `lib/`, `assets/` (source), `test/`, `tool/`, prior `phase2_audit.md` / `product_ux_audit.md` / `audio_content_spec.md`.

Severity: **P0** blocker · **P1** major · **P2** important · **P3** polish

---

## A. Architecture

| ID | Sev | Problem | Evidence | Impact | Proposed | Files | Risk |
|---|---|---|---|---|---|---|---|
| A1 | P2 | Dual kana sources (Dart runtime vs JSON dump) | `KanaRepositoryImpl` returns Dart lists; JSON unused by lessons | Stroke/audio tooling can drift | Keep Dart as runtime; JSON only for audio checker | `kana_repository_impl.dart`, `assets/content/japanese/kana/` | Low if we don't rewrite lists |
| A2 | P1 | Stroke catalog is a stub | `StrokeOrderCatalog.pathsFor` → `[]` | Cannot teach real stroke order | Bundle KanjiVG 46+46 | `stroke_order_board.dart` | License ShareAlike |
| A3 | P2 | README.md is Flutter template | `README.md` | Devs misread product | Rewrite README as ViMai Kids | `README.md` | None |
| A4 | P3 | Legacy Japanese screens still in tree | `look/listen/read/recognize/writing` redirected | Dead code | Leave (redirects work); don't rewrite | `app_router.dart` | High if deleted carelessly |
| A5 | P1 | `dailyMinutes` stored, never used | `ChildProfile.dailyMinutes`; no session seconds | Parent setting is fake | Session tracker in `dailyLearningState` | `child_profile.dart`, screens | Don't force-quit app |

**Keep:** Riverpod overrides in `main.dart`, go_router, Hive profiles/mastery, AudioService, Games board math, `MathQuestionGenerator` (range tests pass).

---

## B. Home

| ID | Sev | Problem | Evidence | Impact | Proposed | Files | Risk |
|---|---|---|---|---|---|---|---|
| B1 | P1 | Empty mastery still forces one fallback task | `_fallback` weekday rotation; always `_ContinueCard` | Feels like a homework assignment | Empty mastery → chooser “Con muốn học gì hôm nay?” | `continue_learning.dart`, `home_screen.dart` | Tests expect `Bắt đầu` when mastery empty — update tests |
| B2 | P2 | Greeting not localized | `'Chào $name!'` hard-coded | EN/JA UI still Vietnamese hello | Keep for production test **or** add l10n and update test | `home_screen.dart`, `product_audit_widget_test.dart` | Test lock |
| B3 | P3 | Parent entry is settings icon | 26px icon | Kids may tap; parents may miss | Keep (parent-aware, not child primary) | home header | Low |

Explore cards + mascot + hide-zero progress: **keep**.

---

## C. Japanese

| ID | Sev | Problem | Evidence | Impact | Proposed | Files | Risk |
|---|---|---|---|---|---|---|---|
| C1 | P0 | No real stroke paths | Catalog empty; no SVG in assets | Educational claim false | KanjiVG 92 basic kana | handwriting/* | BLOCKED until bundle |
| C2 | P1 | Lesson is worksheet chips | `Scaffold`+`ChoiceChip`; write = blank canvas | Weak teaching loop | Path demo → trace → free write; PageScaffold | `kana_lesson_screen.dart` | Don't break PageView index tests |
| C3 | P2 | Hub has no Viết / Luyện nét entry | 19 cards, no write route | Kids may never open stroke mode | Add hub tiles mode=strokes / write | `japanese_home_screen.dart` | None |
| C4 | P2 | Non-basic strokeCount defaults to 1 | Dart omits field | Dakuten teaching wrong | After SVG only for **basic 46+46**; leave others | kana data | Don't invent counts |
| C5 | P3 | Library uses raw Scaffold | `kana_library_screen.dart` | Inconsistent chrome | PageScaffold | same | Low |

46+46 characters: **PASS** (`curriculum_completeness_test`).

---

## D. Vietnamese

| ID | Sev | Problem | Evidence | Impact | Proposed | Files | Risk |
|---|---|---|---|---|---|---|---|
| D1 | P0 | Letter audio is Piper, not human | Manifest source Piper; 58 letter IDs | Pronunciation quality | Inventory + spec; **do not regen 913** | `tool/human_audio_*` | HUMAN_AUDIO_BLOCKED |
| D2 | P2 | Activity screens are Scaffold worksheets | `vietnamese_activities.dart`, letter lesson | Dry | PageScaffold + tokens + LessonFeedback | those files | Don't change alphabet JSON |
| D3 | P3 | Hub already good | `vietnamese_screen.dart` PageScaffold+HubTile | — | Light copy only | — | — |

Curriculum 29 letters, names `bê`/`bờ`: **valid**. Do not change pronunciation text to please TTS.

---

## E. Math

| ID | Sev | Problem | Evidence | Impact | Proposed | Files | Risk |
|---|---|---|---|---|---|---|---|
| E1 | — | Generator range/age gating | `math_generator_test`, `production_quality_test` | Keep | **Do not replace generator** | `math_generator.dart` | High if rewritten |
| E2 | P2 | Quiz still text-heavy | `MathQuizScreen` instruction+question+grid | Worksheet feel | Chrome already has goal bar; add mascot/feedback text, not new formulas | `math_screen.dart` | Low |
| E3 | P2 | Play route has no age guard | `/math/play/:skill` | Older skills via deep link | Soft: generator still age-parameterized; optional hub-only | router | Don't break continue routes |
| E4 | P3 | Empty ExploreCard subtitles | `subtitle: ''` | Weak identity | Short age-safe subtitles | math hub | Low |

No evidence of negative subtraction or out-of-range answers in tests.

---

## F. Thinking

| ID | Sev | Problem | Evidence | Impact | Proposed | Files | Risk |
|---|---|---|---|---|---|---|---|
| F1 | P2 | Worksheet Scaffold | `thinking_screen.dart` | Not kid chrome | PageScaffold, round hint, tokens | same | Don't change question bank |
| F2 | P3 | Many odd-one-out variants | 30 `_odds()` + patterns | Enough for ages 3–7 | Keep data | thinking_generator | CONTENT_GAP: no parent explanation of *why* |

---

## G. Creativity

| ID | Sev | Problem | Evidence | Impact | Proposed | Files | Risk |
|---|---|---|---|---|---|---|---|
| G1 | P2 | Material accent palette | `Colors.pinkAccent` etc. | Breaks tokens | Map to VimaiColor | `creativity_screen.dart` | Don't remove modes |
| G2 | — | Catalog size | production test ≥30 each type | Meaningful | Keep | creativity_catalog | — |

---

## H. Games

| ID | Sev | Problem | Evidence | Impact | Proposed | Files | Risk |
|---|---|---|---|---|---|---|---|
| H1 | — | Board architecture | `GameBoardMetrics`, `FallingLayout`, tests 360–1366 | **PROTECT** | No rewrite | `lib/features/games/logic/**` | High |
| H2 | P3 | Hub copy hard-coded VI | `games_screen.dart` | l10n gap | Optional AppStrings later | games hub | Low |

---

## I. Progress

| ID | Sev | Problem | Evidence | Impact | Proposed | Files | Risk |
|---|---|---|---|---|---|---|---|
| I1 | — | IDs stripped | `ProgressLabels.title` uses あ not `h_a` | PASS | Keep | progress_labels.dart | — |
| I2 | P2 | No “Đang luyện” vs “Đã nhớ” split | Only chips + subject lines | Parent/child clarity | Two short lists from mastery | `progress_screen.dart` | Don't show IDs |

---

## J. Parent

| ID | Sev | Problem | Evidence | Impact | Proposed | Files | Risk |
|---|---|---|---|---|---|---|---|
| J1 | P1 | Form-first dashboard | Name field before insight; bars = count/20 | Not 5-second comprehension | Profile → Today → Learning → Strengths → Practice → Settings → Support → About | `parent_screen.dart` | Keep Ôn tập, Lưu, ViMai Kids for tests |
| J2 | P1 | Fake daily minutes | Dropdown unused | Trust | Session seconds + display; soft “enough for today” | profile + parent + home | Don't lock lessons |

---

## K. Support / About

| ID | Sev | Problem | Evidence | Impact | Proposed | Files | Risk |
|---|---|---|---|---|---|---|---|
| K1 | P2 | One blob | Email + licenses in two cards, licenses still a paragraph | Hierarchy | Separate Help / Feedback / About / Licenses cards | parent_screen, AppStrings | Keep `vimai.support@gmail.com` |

---

## L. Audio

| ID | Sev | Problem | Evidence | Impact | Proposed | Files | Risk |
|---|---|---|---|---|---|---|---|
| L1 | P0 | HUMAN_AUDIO_BLOCKED | 0 human files; 505 Piper VI; 408 SAPI JA | Cannot claim native voice | Inventory + recording spec; keep WAV | tool/human_audio_* | Do not regen |
| L2 | — | Architecture | asset-first, isolation, queue, debounce, rate 1.0 | **PROTECT** | Add human layer later same paths | `lib/core/audio/**` | High if rewritten |
| L3 | P3 | README_DEV_AUDIO vs code | README says no TTS fallback; code has SameLanguageTts | Confusion | Align README | README_DEV_AUDIO.md | None |
| L4 | P3 | Inventory UNUSED false negative | `ja_h_a` UNUSED but played via `ja_$id` | Bad ops signal | Note in spec; optional later | audit_audio_ux.py | Don't bulk rewrite inventory |

---

## M. Assets

| ID | Sev | Problem | Evidence | Impact | Proposed | Files | Risk |
|---|---|---|---|---|---|---|---|
| M1 | P0 | No stroke SVGs | assets SVG empty | STROKE_DATA_BLOCKED | Bundle 92 KanjiVG | assets/content/japanese/strokes/ | CC BY-SA 3.0 |
| M2 | P3 | Orphan `ao.raw.wav` | not in manifest | Noise | Leave (do not delete unused audio casually) | assets/audio/vi/rimes | Policy |

---

## N. Curriculum / data quality

Japanese 46+46 unique: PASS. Vietnamese 29 letters: PASS. Math generator bounded: PASS. Thinking/creativity counts: PASS.  
**CONTENT_GAP:** no kanji curriculum (do not bundle full KanjiVG). Yoon combined paths: MISSING_SOURCE. Human VI/JA recordings: missing.

---

## O. Responsive

Games tested at required sizes. Home tests skip 360×640 and 600×960. Japanese lesson untested. Stroke board `fontSize: 96` risk on 360×640.

---

## P. Accessibility

KidButton min 52. ChoiceGrid min 48. Correct/wrong often color + text (Giỏi lắm / Thử lại) — keep text. Missing Semantics on some library cards. Font scaling untested.

---

## Q. Performance

913 WAV not preloaded (AudioPlayer per play). StrokeOrderBoard Timer.periodic — dispose exists. No AnimationController leak found in stroke board (Timer cancelled). Don't load all SVGs as images; parse JSON paths.

---

## R. Offline

Bundled JSON + WAV; no lesson network. Stroke bundle must be local. flutter_tts is fallback only when asset missing — core path is bundled. **PASS** if strokes + audio stay in APK.

---

## S. Localization

AppStrings covers Home/Parent. Modules (Japanese hub, games, math titles, LessonNavBar “Trước/Tiếp tục”) hard-coded VI. P2 to wrap high-traffic strings; P3 for all games.

---

## T. Tests

19 test files. Gaps: stroke coverage, human audio classification, home chooser, parent today minutes, 360×640 home. Do not delete existing tests.

---

## U. Build / release

Last known: analyze clean, 116 tests, release APK, web. Must **re-run** after this pass. Web `flutter_tts` wasm warnings are warnings not errors.

---

## Architecture decisions (this pass)

1. Bundle **only** Hiragana 46 + Katakana 46 KanjiVG SVGs + extracted path JSON. Attribution + ShareAlike.
2. Human audio: **spec + inventory only**. Status `TTS_TEMPORARY`. No Piper regen.
3. Home: chooser when `mastery.isEmpty`; mission card when data exists. Persist `lastWorld` in settings.
4. Parent: dashboard sections; minutes from `dailyLearningState`.
5. MathQuestionGenerator: **untouched**.
6. Games logic: **untouched**.
7. AudioService: **untouched** except no API break.
8. Greeting `'Chào $name!'` stays (production test).

---

## Blocked before code

- HUMAN_AUDIO_BLOCKED until recordings exist.
- STROKE_DATA_BLOCKED until KanjiVG subset is **in the repo**. Next step: download + validate 92/92.
