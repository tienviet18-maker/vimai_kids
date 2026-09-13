# ViMai Kids — Product UX Audit V1

Date: 2026-08-29  
Scope: existing production-oriented Flutter app at `E:\mai_an_learning`  
Method: read `pubspec.yaml`, `lib/`, assets, routes, theme, l10n, curriculum JSON, audio, tests. No code was changed during this audit.

---

## 1. Critical problems

### 1.1 Progress exposes internal curriculum IDs (child-facing)

`lib/features/progress/presentation/progress_screen.dart` lists every `SkillMastery` as:

- `title: Text(stat.id)` — values such as `h_he`, `h_i`, `h_mu`
- `subtitle: Text('${stat.correct}/${stat.attempts}')` — raw `1/1`
- Section title `Hoạt động` (`AppStrings.activities`)

This is an activity dump, not a child/parent summary. It looks like a debug log.

### 1.2 Japanese handwriting does not teach stroke order

Required flow: SEE → HEAR → WATCH STROKE ORDER → TRACE → WRITE → FEEDBACK.

**What exists**

- `KanaItem.strokeCount` is set in Dart data (e.g. あ = 3). This is real metadata.
- `KanaItem.strokeOrderAsset` is **always null** in `assets/content/japanese/kana/*.json`.
- `WritingCanvas` is freehand ink only. No demonstration, no next-stroke highlight, no path validation.
- Lesson write mode shows the glyph + empty canvas (`kana_lesson_screen.dart`).

**What is missing (do not fake)**

- No SVG/path assets
- No KanjiVG (or equivalent) bundle
- No licensed stroke-order diagrams in `assets/`

KanjiVG (CC BY-SA 3.0) is a valid future source: `https://github.com/KanjiVG/kanjivg`  
A fetch of a sample SVG during this audit returned HTTP 500. Paths must not be invented by hand.

**Safe now:** teach with real `strokeCount` + standard Japanese direction (top→bottom, left→right) + ghost character + stepped “nét 1…N” playback. Animate **actual paths only when assets exist**.

### 1.3 Vietnamese / Japanese audio is not human-quality

Licenses (`assets/licenses/AUDIO_LICENSES.md`) document:

- VI: Piper `vi_VN-vais1000-medium` (CC BY 4.0)
- JA: intended Tsukuyomi-chan / Piper Japanese; this machine often **bakes Windows SAPI `ja-JP`**

Do not claim native human quality. Do not regenerate all 913 files. Inventory-driven replacement only.

AudioService architecture is **correct** and must be preserved (bundled first, same-language TTS only, one player, queue, debounce, lifecycle stop).

---

## 2. Major problems

### 2.1 Home still reads as a dashboard

Identity + continue card + 6 explore cards exist and work.

Gaps vs the product brief:

- Section label is **Học tiếp**, not **Hôm nay**
- Explore cards always show a progress bar (often 0)
- Continue prompts are dynamic (good) but fallback copy still includes fixed “5 chữ Hiragana”
- Greeting `'Chào $name!'` is hard-coded Vietnamese (required by tests; not localized)

### 2.2 Parent is functional but visually dry

One long `ListView` of cards: profile, edit, progress bars, review, settings, reset, support email, licenses.

Missing hierarchy: CHILD / LEARNING / SETTINGS / SUPPORT / ABOUT as intentional sections.

Support is email + button only (no short explanation). Licenses sit in the same visual weight as identity.

`dailyMinutes` is stored, not enforced (known; do not fake a timer).

### 2.3 Math quiz still feels like a worksheet

Hub is age-gated and rich (good). Play screen: `Scaffold` + large `Text` + `ChoiceGrid`. No round goal, no kid chrome, mixed hard-coded `TextStyle`. Generator math is valid — do not change correctness.

### 2.4 Japanese lesson chrome is inconsistent

Uses raw `Scaffold`/`AppBar`/`ChoiceChip` rather than `PageScaffold` + tokens. Modes: Nhìn / Chọn chữ / Viết only — no dedicated stroke-order step.

### 2.5 Localization gaps

Many lesson/game strings are hard-coded Vietnamese (`Giỏi lắm!`, `Nhìn`, `Viết`, math titles). `AppStrings` covers Home/Parent well; modules do not.

### 2.6 Design tokens incomplete

`VimaiColor/Type/Space/Radius/Shadow/Motion` exist. Missing centralized **icon sizes** and **touch minima** (48 / 56). Some screens still use `Colors.white`, `Colors.grey`, `fontSize: 72`.

---

## 3. Minor problems

- Home parent entry is a 26px settings icon (easy to miss for kids; OK for parent).
- Japanese look mode shows `romaji` (helpful for parents, slightly academic for age 3).
- Legacy unused routes: `look/listen/read/recognize/writing` screens still in tree, redirected.
- `ReviewPractice.title` says “Tiếng Nhật” not the actual character.
- Math ExploreCard subtitles are empty strings.
- `LessonCompleteCard` uses emoji in copy.
- Web: `flutter_tts` wasm dry-run warnings (TTS is isolated; learning audio is bundled WAV).

---

## 4. Already good (do not regress)

- Branding: ViMai Kids, `vimai.support@gmail.com`, no personal names in UI
- AudioService: asset-first, language isolation, queue, debounce, one player
- 913 audio records, 0 missing (checker in Gradle)
- Home continue recommendation is **data-driven** (`ContinueLearningRecommender`)
- Games `GameBoardMetrics` / lane layout — keep
- Age clamp 3–7; math/thinking/creativity age gating
- Shared `Pressable`, `KidButton` (min 52), `PageScaffold` max width, mascot
- Vietnamese letter name vs sound catalog (`bê` / `bờ`)
- Tests: analyze/test previously green; games layout tests; production ID/branding tests

---

## 5. Files involved

| Area | Paths |
|---|---|
| Home | `lib/features/home/presentation/home_screen.dart`, `lib/data/content/continue_learning.dart` |
| Progress | `lib/features/progress/presentation/progress_screen.dart` |
| Parent | `lib/features/parent/presentation/parent_screen.dart` |
| Tokens | `lib/core/theme/vimai_tokens.dart`, `app_theme.dart` |
| L10n | `lib/core/l10n/app_strings.dart` |
| Japanese | `kana_lesson_screen.dart`, `writing_canvas.dart`, `lib/data/kana/*`, JSON under `assets/content/japanese/kana/` |
| Math | `lib/features/math/presentation/math_screen.dart`, `math_generator.dart` |
| Audio | `lib/core/audio/**`, `assets/licenses/AUDIO_LICENSES.md` |
| Games | `lib/features/games/**` — **do not rewrite board math** |
| Tests | `test/product_audit_widget_test.dart`, `continue_learning_test.dart`, `games_layout_test.dart` |

---

## 6. Recommended implementation order

1. Audit doc (this file) + audio content spec (no WAV regen)
2. Token extras (icon/touch sizes)
3. Home Hôm nay + hide empty progress bars; dynamic prompts
4. Progress friendly summaries; strip ID log
5. Parent sectioned dashboard
6. Japanese shared handwriting board (strokeCount-based; path player ready for KanjiVG)
7. Math quiz kid chrome; keep generator
8. Tests + analyze + release APK + web

---

## 7. Risks / regressions

| Risk | Mitigation |
|---|---|
| Home test expects `Học tiếp` | Update test to `Hôm nay`; keep `Chào $name!` and forbid `Bài học hôm nay` |
| Invented kana stroke paths | Forbidden. Architecture + count teaching only until KanjiVG is bundled |
| Audio regen of 913 files | Forbidden. Spec only |
| Games board coordinates | Do not touch `FallingLayout` / `GameBoardMetrics` |
| Parent lazy ListView tests | Keep `Ôn tập`, `Lưu`, `ViMai Kids` findable without scrolling off-stage |
| Math answer keys | Do not change `MathQuestionGenerator` formulas |

---

## Stroke-order data status (explicit)

| Item | Status |
|---|---|
| `strokeCount` | Present in Dart kana lists |
| `strokeOrderAsset` | Null in all JSON |
| SVG / path files | **None in repo** |
| KanjiVG bundle | **Not present**; sample download failed |
| Format needed later | One SVG or JSON path list per kana id (`h_a`, `k_a`, …), licensed, attributed in `assets/licenses/` |
| Safe now | Ghost glyph + sequential nét index + freehand trace; load paths when catalog is non-empty |

---

## Audio production status (explicit)

| Category | Spoken intent | Current source | Human recording |
|---|---|---|---|
| VI letter name | `bê`, `xê`, `a` | Piper vais1000 | Recommended |
| VI letter sound | `bờ`, `cờ` | Piper | Recommended |
| VI phonics/rimes/words | syllable/word | Piper | Optional later |
| VI praise | Giỏi lắm | Piper, ~877 ms, valid | Nice-to-have |
| JA kana | character | SAPI ja-JP bake and/or Piper JA | Recommended for “natural” |
| JA examples | example word | same | Recommended |

IDs and paths must stay stable. Replace only inventory-flagged files.
