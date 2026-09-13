# ViMai Kids — Phase 2 audit (read-only)

Date: 2026-08-29  
Workspace: `E:\mai_an_learning`  
Method: source files under `lib/`, `assets/` (not `build/`), `tool/`, `test/`, `pubspec.yaml`, existing audits, GitHub Contents API + recursive git tree for KanjiVG. No product code was changed for this document.

Honesty rules used below:

- **True stroke animation** = ordered SVG/path data driving a stroke player. This repo does **not** have that.
- **Human audio** = a recording of a person. This repo has **none** identified.
- **TTS fallback / temporary audio** = Piper and Windows SAPI-baked WAV. That is what is shipped.

---

## A. Japanese writing — what exists today

Runtime source of truth is **Dart lists**, not JSON:

- `lib/data/kana/hiragana_data.dart` (114 items)
- `lib/data/kana/katakana_data.dart` (130 items)
- `KanaRepositoryImpl.getAllHiragana()` / `getAllKatakana()` return those lists.

JSON under `assets/content/japanese/kana/` (15 files, 244 items) is a **dump** of the same lists (`tool/generate_kana_json.dart`). Lesson screens do **not** load JSON.

### Lesson flow (`KanaLessonScreen`)

Modes as chips: **Nhìn** (`look`), **Thứ tự nét** (`strokes`), **Chọn chữ** (`recognize`), **Viết** (`write`).  
`AppStrings.hearMode` exists but is **not** wired as a chip. Look mode already plays `ja_{id}` and can play example audio.

Japanese hub (`japanese_home_screen.dart`) exposes Học / Chọn chữ / Bảng + dakuten/yoon/etc. It does **not** expose dedicated Viết or Luyện nét cards (those modes are inside the lesson).

### Stroke-order UI (`StrokeOrderBoard`)

- Reads `kana.strokeCount` (minimum 1).
- Ghost glyph: `AnimatedOpacity` on the **whole character** as the step index increases.
- Numbered circles 1…N; tap to set step; Replay button (`KidButton`).
- `StrokeOrderCatalog.pathsFor(id)` **always returns `[]`**. `hasPaths` is always false.
- No SVG, no path player, no arrows, no slow speed, no tracing overlay.

### Free writing (`WritingCanvas`)

- Freehand ink only (`Listener` + `CustomPaint`).
- Write mode shows a 64px glyph + copy `traceNow` + empty canvas.
- `onCleared` is a no-op in the lesson.
- No guided tracing, no path comparison, no stroke-count feedback from ink.

### Required teaching features vs current code

| # | Requirement | In repo today |
|---|---|---|
| 1 | Demo stroke order | Partial: nét index + fading full glyph. **Not** a path demo. |
| 2 | Animate each stroke in order | **No.** Opacity is on the entire glyph. |
| 3 | Arrows / direction if source supports | **No.** No path/`kvg:type` data bundled. Hint text only: top→bottom, left→right. |
| 4 | Stroke numbers | **Yes** (circles 1…N). |
| 5 | Replay | **Yes** (resets step timer 700 ms). |
| 6 | Slow playback | **No.** |
| 7 | Guided tracing | **No.** |
| 8 | Free writing after learning | Partial: write mode is always available, not gated on finishing strokes. |
| 9 | Feedback when the child writes | **No** for handwriting. Recognize mode has Giỏi lắm / Thử lại. |
| 10 | Accurate stroke count | Partial: explicit for **basic 46+46** in Dart. All other types omit `strokeCount` and the constructor **defaults to 1**. |

Legacy screens still in the tree (`look/listen/read/recognize/writing`) are **redirected** by `app_router.dart` to `/japanese/learn/...`.

Tests that **forbid invented paths**: `test/progress_labels_test.dart` expects `StrokeOrderCatalog.pathsFor('h_a')` empty.

---

## B. Which kana have `strokeCount`?

### Dart (runtime)

`KanaItem.strokeCount` defaults to **1** when omitted.

| Set | Count | Explicit `strokeCount:` in source | Default 1 (field omitted) |
|---|---|---|---|
| Hiragana basic | 46 | **46/46** | 0 |
| Katakana basic | 46 | **46/46** | 0 |
| Hiragana non-basic (dakuten 20, handakuten 5, yoon 33, small 8, sokuon 1, choon 1) | 68 | **0/68** | 68 |
| Katakana non-basic (dakuten 20, handakuten 5, yoon 33, small 8, sokuon 1, choon 1, extended 16) | 84 | **0/84** | 84 |

Hiragana basic (character → count), from `hiragana_data.dart`:

あ3 い2 う2 え2 お3 か3 き4 く1 け3 こ2 さ3 し1 す2 せ3 そ1 た4 ち2 つ1 て1 と2 な4 に3 ぬ2 ね2 の1 は3 ひ1 ふ4 へ1 ほ4 ま3 み2 む3 め2 も3 や3 ゆ2 よ2 ら2 り2 る1 れ2 ろ1 わ2 を3 ん1

Katakana basic, from `katakana_data.dart`:

ア2 イ2 ウ3 エ3 オ3 カ2 キ3 ク2 ケ3 コ2 サ3 シ3 ス2 セ2 ソ2 タ3 チ3 ツ3 テ3 ト2 ナ2 ニ2 ヌ2 ネ4 ノ1 ハ2 ヒ2 フ1 ヘ1 ホ4 マ2 ミ3 ム2 メ2 モ3 ヤ2 ユ2 ヨ3 ラ2 リ2 ル2 レ1 ロ3 ワ2 ヲ3 ン2

These counts were **not** verified against KanjiVG for all 92 glyphs in this audit. One check: GitHub Contents API for `kanji/03042.svg` (あ) contains **three** `<path>` elements, matching Dart `strokeCount: 3`.

### JSON (assets, not loaded by lessons)

Every one of 244 JSON rows has a `strokeCount` key. Non-basic files are almost all `1` (same default as Dart). Basic files match the Dart tables above. `strokeOrderAsset` is null on all 244.

---

## C. Which kana have `strokeOrderAsset`?

**None.**

- JSON: `strokeOrderAsset` is `null` on all 244 items.
- Dart lists never set `strokeOrderAsset:` (field stays null).
- `pubspec.yaml` has no stroke-order asset folder.

---

## D. Which kanji have stroke data?

**None in this product.**

- No files matching kanji under `assets/content/` or `lib/`.
- No Dart kanji model, no route, no hub card.
- Curriculum Japanese is **kana only** (hiragana/katakana types listed on `JapaneseHomeScreen`).

**Do not bundle the full KanjiVG kanji set.** There is no kanji curriculum to attach it to.

If a later curriculum adds specific kanji, bundle **only those** codepoints, with attribution.

---

## E. Are there real SVG/path files in the repo?

**No product SVG.**

- `assets/**/*.svg` → **empty**.
- `lib/**/*.svg` → **empty**.
- `assets/licenses/KANJIVG_LICENSE.md` → **does not exist**.
- The only `.svg` hits in the workspace are Gradle distribution docs under `tool/.gradle-home/` (not app assets).

`StrokeOrderCatalog` is a stub for a future path player.

### Legal remote source (not bundled)

KanjiVG: https://github.com/KanjiVG/kanjivg  

- Licence: **CC BY-SA 3.0** (Ulrich Apel). Confirmed on https://kanjivg.tagaini.net/ and in the SVG file comment (GitHub Contents API for `03042.svg`).
- Conditions that matter before bundling: **attribution** (name KanjiVG, link `http://kanjivg.tagaini.net`); **ShareAlike** if you adapt (e.g. convert SVG paths to Flutter JSON — that derivative must stay CC BY-SA 3.0). Do not relicense. Do not invent missing paths.
- `raw.githubusercontent.com/.../03042.svg` returned **HTTP 500** in this session (same as the earlier UX audit). The **GitHub Contents API** succeeded and returned the SVG (base64).
- Recursive git tree (`master`): **2633** `kanji/*.svg` files.
- **Hiragana 46/46** and **katakana 46/46** filenames exist in that tree (Unicode hex padded to 5 digits, e.g. あ → `03042.svg`, ア → `030a2.svg`).
- Also present (spot-checked, not Phase 2 scope): が `0304c.svg`, ガ `030ac.svg`, ぁ `03041.svg`.

**MISSING_SOURCE_DATA:** none for **basic 46+46** on KanjiVG’s public tree.  
**MISSING_IN_REPO:** all of those files — **BLOCKED for true stroke animation until a licensed subset is bundled** with `assets/licenses/KANJIVG_LICENSE.md`.

Yoon (きゃ, etc.) are **two characters**. KanjiVG stores each mora separately. Do not invent a single combined path. Teach as two glyphs or skip path demo until a licensed combined source exists.

Sample `03042.svg` paths had **no** `kvg:type` on `<path>` (stroke-type attribute). Direction arrows are **not** guaranteed from that sample. Ordered paths + `StrokeNumbers` group **are** present. Implementation must use `kvg:type` **only when the file has it**, never invent arrow geometry.

---

## F. Which audio is Piper?

From `assets/audio/audio_manifest.json` (**913** records):

| Source string | Count | Language |
|---|---|---|
| `Piper vi_VN-vais1000-medium` | **505** | all `vi` |

That is **100% of Vietnamese** bundled clips. License recorded as CC BY 4.0 (vais1000).

No Japanese record uses a Piper / Tsukuyomi / hi_fi_captain source string in the current manifest.

---

## G. Which audio is SAPI (Windows ja-JP bake)?

| Source string | Count | Language |
|---|---|---|
| `Windows ja-JP voice (build-time only) / Piper Japanese fallback` | **408** | all `ja` |

That is **100% of Japanese** bundled clips. Runtime does not call SAPI; only the WAV is shipped (`AUDIO_LICENSES.md`, `generate_audio_assets.py`).

Tsukuyomi-chan / Piper Japanese are **preferred in the pipeline** but **not** what this inventory actually contains.

---

## H. Which audio can be identified as a human recording?

**None.**

Evidence:

- Manifest `source` never contains human / studio / native recording.
- `lib/core/audio/vietnamese_recorded_assets.dart`: `kRecordedVietnameseAssets = {}` (comment: generated from real MP3s; set is empty).
- `assets/audio/**/*.mp3` count: **0**.
- All WAV sources are Piper VI or Windows ja-JP bake.

Do **not** call current audio “giọng người thật”, “native human recording”, or “studio quality”. Correct label: **TTS fallback / temporary bundled audio**.

---

## I. Vietnamese audio that needs human recording

Manifest: **505** `vi` IDs. Inventory (`tool/audio_inventory.json`): 496 `VALID` + 9 `UNUSED`. `REQUIRED_MISSING`: 0.

WAV on disk: **914** files = **913** manifest assets + leftover `assets/audio/vi/rimes/ao.raw.wav` (not in manifest).

### HUMAN_REQUIRED (product-critical)

Letter **name** and **sound** for the 29-letter curriculum (58 files). Inventory durations 461–762 ms (none under 400 ms). Spoken catalog already uses school names (`bê`, `xê`) and phonemes (`bờ`, `cờ`) — the **text is right**; the **voice is Piper**.

```
vi_letter_a_name, vi_letter_a_sound,
vi_letter_aw_name, vi_letter_aw_sound,
vi_letter_aa_name, vi_letter_aa_sound,
vi_letter_b_name, vi_letter_b_sound,
vi_letter_c_name, vi_letter_c_sound,
vi_letter_d_name, vi_letter_d_sound,
vi_letter_dd_name, vi_letter_dd_sound,
vi_letter_e_name, vi_letter_e_sound,
vi_letter_ee_name, vi_letter_ee_sound,
vi_letter_g_name, vi_letter_g_sound,
vi_letter_h_name, vi_letter_h_sound,
vi_letter_i_name, vi_letter_i_sound,
vi_letter_k_name, vi_letter_k_sound,
vi_letter_l_name, vi_letter_l_sound,
vi_letter_m_name, vi_letter_m_sound,
vi_letter_n_name, vi_letter_n_sound,
vi_letter_o_name, vi_letter_o_sound,
vi_letter_oo_name, vi_letter_oo_sound,
vi_letter_ow_name, vi_letter_ow_sound,
vi_letter_p_name, vi_letter_p_sound,
vi_letter_q_name, vi_letter_q_sound,
vi_letter_r_name, vi_letter_r_sound,
vi_letter_s_name, vi_letter_s_sound,
vi_letter_t_name, vi_letter_t_sound,
vi_letter_u_name, vi_letter_u_sound,
vi_letter_uw_name, vi_letter_uw_sound,
vi_letter_v_name, vi_letter_v_sound,
vi_letter_x_name, vi_letter_x_sound,
vi_letter_y_name, vi_letter_y_sound
```

Replace **in place** (same IDs/paths). Do not invent English letter names. Do not use `playbackRate` to fake a human. Do not run `--force-vi`.

### TTS_ACCEPTABLE (keep Piper until a later recording pass)

Inventory type `content`, status `VALID`: **437** IDs (phonics / rimes / words / sentences — inventory does not split `type` further). Disk folders:

- `assets/audio/vi/phonics/` — 113 WAV  
- `assets/audio/vi/rimes/` — 59 WAV (plus untracked `ao.raw.wav`)  
- `assets/audio/vi/words/` — 234 WAV  
- `assets/audio/vi/sentences/` — 41 WAV  

Plus praise:

- `vi_phrase_gioi_lam`

Full ID list: every `language: "vi"` row in `assets/audio/audio_manifest.json` except the 58 letters above and the 9 unused onsets below.

### NOT_NEEDED (shipped, checker-listed, not used by letter curriculum)

```
vi_ph, vi_th, vi_kh, vi_nh, vi_ch, vi_tr, vi_gh, vi_ng, vi_ngh
```

`check_audio_assets.py` still expects these IDs. Do not delete without changing the checker. Do not regenerate them as “human quality”.

### EXISTING_HUMAN

Empty.

---

## J. Japanese audio that needs human recording

Manifest: **408** `ja` IDs. All SAPI-baked. Inventory: 164 `VALID` + 244 `UNUSED`.

**Inventory caveat (do not treat UNUSED as unused in the app):** `audit_audio_ux.py` marks a clip `UNUSED` when `used_by` is empty **unless** the id ends with `_example`. Dart never stores `audioAsset`; runtime uses `KanaItem.audioId` → `ja_$id`. `ja_h_a` is **played** in lessons and is still `UNUSED` in the JSON. Example files are `VALID` because of that suffix rule, often with `used_by: []`.

Disk: `ja/kana` 244 WAV + `ja/examples` 164 WAV = 408.

Durations: kana inventory 100–709 ms, average ~343 ms. **Most character clips are under 400 ms** (あ `ja_h_a` = 220 ms). `ja_h_sokuon` / `ja_k_sokuon` = **100 ms**. That matches the “cụt” problem. Human recs should be longer, child-paced, no clipping (inventory `clipping: false` on sampled rows; peak is not a quality substitute for a native speaker).

Every Dart kana has `ja_{id}` in the manifest (`H_AUDIO_MISSING` / `K_AUDIO_MISSING` empty).

Example audio missing for some **basic** ids (look mode still works; example button absent or fails if called):

- Hiragana: `h_ki`, `h_ke`, `h_ko`, `h_te`, `h_me`, `h_wo`, `h_n`
- Katakana: `k_wo`, `k_n`

All **basic 46+46** have `KanaExamples` map entries.

### HUMAN_REQUIRED — basic 46 hiragana character clips

```
ja_h_a, ja_h_i, ja_h_u, ja_h_e, ja_h_o,
ja_h_ka, ja_h_ki, ja_h_ku, ja_h_ke, ja_h_ko,
ja_h_sa, ja_h_shi, ja_h_su, ja_h_se, ja_h_so,
ja_h_ta, ja_h_chi, ja_h_tsu, ja_h_te, ja_h_to,
ja_h_na, ja_h_ni, ja_h_nu, ja_h_ne, ja_h_no,
ja_h_ha, ja_h_hi, ja_h_fu, ja_h_he, ja_h_ho,
ja_h_ma, ja_h_mi, ja_h_mu, ja_h_me, ja_h_mo,
ja_h_ya, ja_h_yu, ja_h_yo,
ja_h_ra, ja_h_ri, ja_h_ru, ja_h_re, ja_h_ro,
ja_h_wa, ja_h_wo, ja_h_n
```

### HUMAN_REQUIRED — basic 46 katakana character clips

```
ja_k_a, ja_k_i, ja_k_u, ja_k_e, ja_k_o,
ja_k_ka, ja_k_ki, ja_k_ku, ja_k_ke, ja_k_ko,
ja_k_sa, ja_k_shi, ja_k_su, ja_k_se, ja_k_so,
ja_k_ta, ja_k_chi, ja_k_tsu, ja_k_te, ja_k_to,
ja_k_na, ja_k_ni, ja_k_nu, ja_k_ne, ja_k_no,
ja_k_ha, ja_k_hi, ja_k_fu, ja_k_he, ja_k_ho,
ja_k_ma, ja_k_mi, ja_k_mu, ja_k_me, ja_k_mo,
ja_k_ya, ja_k_yu, ja_k_yo,
ja_k_ra, ja_k_ri, ja_k_ru, ja_k_re, ja_k_ro,
ja_k_wa, ja_k_wo, ja_k_n
```

### HUMAN_REQUIRED (second pass) — example words that already exist

All `ja_*_example` IDs in the manifest (164 files). Same paths under `assets/audio/ja/examples/`.

### TTS_ACCEPTABLE until a later JA pass

Remaining `ja_*` (dakuten, yoon, small, sokuon, choon, extended) — still SAPI, still used when those hub cards are opened. Do not regenerate with Piper and call them human.

### EXISTING_HUMAN / NOT_NEEDED

Empty / none of the 408 are unused at runtime if the child opens that kana type.

---

## K. Screens that still feel dry / worksheet-like

| Surface | Why |
|---|---|
| **Parent** | Sections exist (CHILD / LEARNING / SETTINGS / SUPPORT / ABOUT) but the first learning block is still name `TextField`, age `ChoiceChip`, then raw activity counts and `LinearProgressIndicator` with denominator **20**, not minutes. No “An đang học rất tốt”, no Today activity card as specified. Settings (sound, daily minutes, language) sit in the same scroll as the dashboard. `dailyMinutes` is stored only (`ChildProfile.dailyMinutes`) — **not enforced**. |
| **Support / About** | One support card (email + button) and one about card with version, developer, and licenses in a nested muted box. Not separate Help / Feedback / About / Licenses cards. `licensesBody` is a long paragraph naming Piper/SAPI. |
| **Japanese lesson** | Raw `Scaffold` + `AppBar` + `ChoiceChip` + `LinearProgressIndicator`. Look mode is large glyph + romaji + “Hãy nghe nhé!”. Write mode is glyph + blank canvas. Stroke mode is count + faded glyph. |
| **Kana library** | White grid of character + romaji; `Scaffold`, not `PageScaffold`. |
| **Vietnamese letter lesson + `vietnamese_activities.dart`** | Multiple `Scaffold`s; quiz lists feel like worksheets. Hub itself uses `PageScaffold` + `HubTile` (better). |
| **Thinking** | `Scaffold` + score line + instruction + `ChoiceGrid`. No mascot, no round goal chrome. |
| **Creativity** | `Scaffold` + horizontal chips + Material accent colors (`Colors.pinkAccent`, etc.), not tokens. |
| **Math quiz** | Hub is age-gated `PageScaffold` (good). Play screen is instruction + large question + `ChoiceGrid` + score. Functional kid chrome (goal bar, complete card) exists; still quiz-first. **Do not change `MathQuestionGenerator`.** |
| **Home** | Stronger than Parent. Always shows **one** continue card. Never the empty-state picker “Con muốn học gì hôm nay?” with six subjects. Fallback is weekday×age rotation, not “5 chữ Hiragana”, but also not mastery-empty choice. Greeting is hard-coded `'Chào $name!'` (required by tests). |
| **Progress** | Summaries via `progress_labels.dart` (no raw `stat.id` on the child list). Still a list of cards, not a kid “world map”. |

---

## L. Responsive — facts from code and tests (not a live device lab)

**This audit did not run the Chrome session through 360×640 … 1366×768.** Findings are from layout code + existing widget tests.

### Already structured (do not regress)

- `Breakpoints` + `PageScaffold` max width `VimaiSpace.maxWide` (960) / `maxContent` (720).
- Home grid: 1 col &lt; 360, else 2 / 3 / 3; `ExploreCard` hides progress when `progress == 0`.
- Games: `GameBoardMetrics` / `FallingLayout` — **board coordinates**, `maxWidth 440`, `maxHeight 580`. **No** `x = 40 + random(240)` in `lib/`. Tests include 360×640, 390×844, 412×915, 600×960, 768×1024, 1366×768 (`test/games_layout_test.dart`).

### Gaps / risks

| Item | Evidence |
|---|---|
| Home overflow tests | `360×800`, 390, 412, 768, 1024×768, 1366 — **not** `360×640` or `600×960`. |
| Parent / thinking / creativity / progress | Overflow test at **360×800 only**. |
| Japanese lesson / stroke board / handwriting | **No** viewport widget tests. `StrokeOrderBoard` uses `fontSize: 96` and `maxHeight: 260`. Write canvas clamps 160–280. |
| Japanese hub | 19 `HubTile`s, phone `childAspectRatio: 2.8` — long titles (`Hiragana handakuten`) can clip. |
| `ChoiceGrid` | Always 2 columns, `childAspectRatio: 1.55` — fine on phone; unused width on desktop. |
| Parent bars | `related / 20` is not a layout bug but is a **false progress metaphor** on tablet/desktop too. |
| Extra leftover WAV | `ao.raw.wav` unused; not a layout issue. |

---

## M. What is already good — do **not** change unless a Phase item names it

- Branding: `AppBrand` — ViMai Kids, `vimai.support@gmail.com`, no personal names in UI. Tests forbid `Mai An` / `tienviet18`.
- Navigation / routes in `app_router.dart` (including CatchKana exports from `games_screen.dart`).
- `AudioService`: asset-first, language isolation, one player, queue, debounce, lifecycle stop, dispose, `playbackRate` 1.0. Same-language TTS **only after** bundled play fails (`allowSameLanguageTtsFallback`). Never VI↔JA.
- Audio checker + Gradle preBuild; 913 manifest records, 0 missing required content ids.
- Do **not** regenerate 913 files; do **not** run `--force-vi`.
- Games board architecture (`GameBoardMetrics`, `FallingLayout`, `CatchKanaRound`).
- `MathQuestionGenerator` correctness.
- Curriculum JSON / Dart kana **content** (characters, romaji, examples, confusion groups). Adding stroke **assets** is allowed; rewriting 46-character lists is not.
- Age clamp 3–7; Vietnamese rimes/sentences age gates; math hub age gates.
- Tokens: `VimaiColor/Type/Space/Radius/Shadow/Motion/Size` (icon/touch/mascot).
- Shared `Pressable`, `KidButton` (min 52), `PageScaffold`, mascot.
- Home continue **when mastery exists** uses character glyph, not `h_ka`.
- Progress labels without curriculum IDs.
- `KanaExamples` for all basic 46+46.
- Production tests: greeting `'Chào $name!'`, `Hôm nay`, CTA `Bắt đầu`, forbid `Bài học hôm nay`.

Note: `README_DEV_AUDIO.md` says there is **no** flutter_tts fallback for VI/JA learning audio. **Code disagrees**: missing asset → `SameLanguageTts`. Treat the **code** as the contract; fix the README later, do not remove isolation.

`README.md` is still the default Flutter template. Not a runtime bug.

---

## AudioService vs Phase 4 target chain

Specified: HUMAN WAV → approved bundled TTS → same-language TTS → silence + error.

**Today:** bundled Piper/SAPI WAV → same-language TTS → snackbar `Không phát được âm thanh.`

There is **no HUMAN layer** and no `EXISTING_HUMAN` set. Adding human files must be **same IDs/paths** (or a new overlay that still goes through `AudioAssetRegistry` first). Do not change isolation, queue, debounce, or rate 1.0.

---

## Home recommendation vs Phase 7

`ContinueLearningRecommender`:

1. Mastery needing review → that item.  
2. Else most recent mastery.  
3. Else `_fallback`: `(weekday + age) % 6` rotation (age ≤4 vs older). Prompts are **not** the old “5 chữ Hiragana” fallback.

Missing vs brief:

- No “Con muốn học gì hôm nay?” six-subject chooser when there is no recommendation.
- Always one card; child cannot pick another world from Home without using Explore.
- Does not encode “unfinished lesson” beyond last mastery id.
- Does not use `dailyMinutes`.

Do not restore a **fixed** “Học 5 chữ tiếng Việt” string.

---

## Parent vs Phase 5

Present: mascot, name, age, overall %, section heads, subject bars, ôn tập list, settings, reset, support email, about.

Missing: encouraging one-liner with child name, Today activity count + bar, Learning as two-up **minutes**, Strengths / Need practice as kid-facing chips (ôn tập list is the closest), Support/About split.

Bars use **activity counts / 20**, not minutes. There is **no per-subject minute store**.

---

## Tests / tools that Phase 10 will need (not written yet)

| Gap | Notes |
|---|---|
| `tool/check_japanese_stroke_assets.py` | Does not exist. Must report 46/46 + 46/46 path coverage **after** bundle. Today would be **0/46**. |
| `tool/human_audio_inventory.json` / `human_audio_spec.md` | Do not exist. Classify HUMAN_REQUIRED / TTS_ACCEPTABLE / EXISTING_HUMAN / NOT_NEEDED. |
| Stroke asset tests | Only “catalog empty”. After bundle, invert: paths non-empty **and** licensed. |
| Recommendation tests | `continue_learning_test.dart` exists; no empty-state chooser. |
| Parent dashboard tests | Age chips, Ôn tập, ViMai Kids — not Today/Strengths. |
| Responsive | Games covered; Home missing 360×640 / 600×960. |

`test/kana_content_test.dart` and `curriculum_completeness_test.dart` already lock **46+46 characters**. Keep those.

---

## Implementation blockers (do not fake)

| ID | Blocker | Can still do |
|---|---|---|
| STROKE_ASSETS | True path animation **BLOCKED** until KanjiVG (or other licensed) SVGs are bundled + attributed. Source for 46+46 **exists remotely**. | Keep count UI; do not invent paths. After bundle: player, replay, slow, numbers from SVG, guided trace along paths. |
| STROKE_COUNT_NON_BASIC | Dakuten/yoon/small default **1**. | After SVG: count = number of paths. Do not hand-edit hundreds of counts without source. |
| HUMAN_AUDIO | **BLOCKED** for “human quality”. No recordings. | Keep Piper/SAPI WAV; write inventory/spec; recording checklist. Do not batch-TTS. |
| KANJI | No curriculum. | Do not bundle 2000+ kanji. |
| YOON_AS_ONE_GLYPH | No single KanjiVG file for きゃ. | **MISSING_SOURCE_DATA** for combined yoon paths. Teach two characters or wait. |
| PARENT_MINUTES | No time tracking. | Dashboard copy/layout without fake minutes; or store session time later without claiming history. |

---

## Suggested order after this audit (no code in Phase 0)

1. Bundle KanjiVG **only** U+3042… basic hiragana 46 + basic katakana 46 SVGs; `KANJIVG_LICENSE.md`; parser; `check_japanese_stroke_assets.py`; true stroke player + guided trace + freehand **after** demo.  
2. Parent dashboard layout + Support/About cards (keep email).  
3. Home empty-state chooser + keep existing mastery recommender.  
4. `human_audio_inventory.json` + spec (classification only).  
5. Visual pass on Thinking / Vietnamese activities / Japanese lesson chrome **without** touching Games board math or Math generator.  
6. Tests + analyze + test + release APK + web — only after those steps, and only report PASS if actually run.

**Do not start implementation until this audit is accepted.** Phase 0 ends here.
