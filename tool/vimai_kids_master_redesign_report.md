# ViMai Kids — Master Product Redesign Report (v2)

**Date:** 2026-09-02  
**Directive:** MASTER DIRECTIVE v2 — illustration-first, character-first, play-first  
**Author:** Cursor agent (Principal Product Design + Flutter engineering pass)

---

## Executive summary

| Area | Status | Evidence |
|------|--------|----------|
| Phase 1 — Project audit | **DONE** | This document §1–§3 |
| Phase 2 — Product redesign spec | **DONE** | This document §4 + Canvas prototypes |
| Phase 3 — Visual design system | **PARTIAL** | Tokens exist; scene components in progress |
| Phase 4 — Home redesign | **IN PROGRESS** | `KidsValleyScene` + `KidsMissionAdventure` wired in `home_screen.dart` |
| Phase 5 — Vietnamese lesson | **PARTIAL** | Scene scaffold exists; not yet mini-story quality |
| Phase 6 — Japanese lesson | **PARTIAL** | Mode chips + stage stack; not immersive scene |
| Phase 7 — Other subjects | **NOT STARTED** | Hubs still use ActivityGarden trails |
| Phase 8 — Audio + phonics | **PARTIAL (data OK, QA blocked)** | Catalog + guide pass tests; no listening QA |
| Phase 9 — Motion polish | **PARTIAL** | Float/breathe on mascot; hierarchy incomplete |
| Phase 10 — Responsive QA | **NOT VERIFIED** | No device screenshot pass this session |
| Phase 11 — Visual QA | **FAIL** | App not visually verified on running build |
| Phase 12 — Automated tests | **PASS** | 156 tests after home valley refactor |
| Phase 13 — Build APK + Web | **PARTIAL** | Web release built; APK not re-built this pass |

**Do not treat engineering green as product PASS.** Visual and audio quality gates are **not met**.

---

## 1. Audit — routes & screens

Router: `lib/core/routing/app_router.dart` (GoRouter)

| Route | Screen |
|-------|--------|
| `/home` | `HomeScreen` |
| `/vietnamese`, `/vietnamese/learn` | Hub + letter lesson |
| `/japanese`, `/japanese/learn/:script` | Hub + kana lesson |
| `/math`, `/games`, `/thinking`, `/creativity` | Subject hubs |
| `/progress`, `/parent` | Meta screens |
| Onboarding | welcome, profiles, create_profile |

Educational logic, progress persistence, and navigation are **stable** and must not be broken during redesign.

---

## 2. Audit — current visual architecture (FAIL vs v2)

### Home (`lib/features/home/presentation/home_screen.dart`)

**Current mental model:** sky background + `LivingPlayground` + 6× `WorldIsland` (PNG thumbnail + colored title sticker) + bottom dashboard speech panel.

**Why this FAILS v2:**

1. Still **ISLAND → ISLAND → ISLAND** — six labeled destinations on a background, not one composed world.
2. Header/mission is a **text dashboard block** (greeting, age, “hôm nay học gì”, choose prompt) stacked in `KidsSpeechBubble`.
3. Landmark PNGs contain **burned-in English titles** (e.g. “JAPANESE VILLAGE”) — not production art.
4. Mai is a small CustomPaint mascot, not a character system with expressions/assets.

### Subject hubs

`IllustratedScaffold` + `ActivityGarden` + `WorldActivity` (circular glyph badges) — **trail of identical badges**, not illustrated rooms.

### Vietnamese lesson (`vietnamese_letter_lesson_screen.dart`)

Uses `KidsLearningScene` (improvement over bare letter) but:

- Look mode: letter object + fish cue + audio button in a **stack**, not a pond story.
- Recognize mode: `ChoiceGrid` bubbles — better than grid cards, still not scene-embedded objects.
- Write mode: canvas on stage — not integrated into narrative scene.

### Japanese lesson (`kana_lesson_screen.dart`)

Horizontal **mode chip row** (dashboard control) + paginated stages. Not a continuous kana story scene.

---

## 3. Audit — data & audio

### Curriculum (unchanged JSON)

- Vietnamese alphabet: `assets/content/vietnamese/alphabet.json`
- Kana: `assets/content/japanese/kana/*.json`
- Loader: `lib/data/content/content_repository.dart`
- Domain: `ContentItem`, `KanaItem`

### Phonics runtime layer (correct — tests enforce)

| Letter | Child phonics | Letter name (data only) |
|--------|---------------|-------------------------|
| B | bờ | bê |
| C | **cờ** | xê (never shown in child phonics look) |
| D | dờ | dê |
| Đ | đờ | đê |
| Y | **i dài** | i |

Files:

- `lib/core/audio/vietnamese_speech_catalog.dart`
- `lib/core/audio/vietnamese_phonics_guide.dart`
- `lib/core/audio/vietnamese_phonics_view.dart`

### Production audio protection

- **914** audio files under `assets/audio/`
- Snapshot: `tool/audio_v3_production_snapshot.json`
- **Policy:** no delete/rename/overwrite/regenerate production WAV without QA-approved replacement
- **This session:** production WAVs **not modified**

### Audio pipeline status

```
Lesson UI → VietnamesePhonicsGuide / AudioService → AudioAssetRegistry → bundled WAV
         → fallback SameLanguageTts
```

- `lib/core/audio/audio_lesson_service.dart` — semantic wrapper; not fully wired
- Google TTS preview tooling — **BLOCKED** without credentials (`GOOGLE_CLOUD_PROJECT`, voice names)
- **Audio QA:** **NOT PERFORMED** — cannot claim PASS

---

## 4. Product redesign specification (Phase 2)

### 4.1 Design principles

1. **Illustration first** — every screen is a SCENE with background / midground / foreground.
2. **Character first** — Mai speaks, reacts, guides; UI chrome is minimal.
3. **Play first, learning second** — objectives embedded in mini-adventures.
4. **No card dashboard IA** — forbidden patterns: 2×3 grid, vertical destination list, map+island thumbnails, hero letter + button stack.

### 4.2 Information architecture

```
Home = Mai's Valley (one scene, discover destinations)
  └─ Subject = Themed room/scene (not activity trail)
       └─ Lesson = Mini-game episode (staged beats)
            ├─ Discover (object + letter in world)
            ├─ Listen (audio orb, reactions)
            ├─ Choose (objects in scene, not grid)
            └─ Write (stage in scene, celebration)
```

### 4.3 Component taxonomy (target)

| Component | Role |
|-----------|------|
| `KidsValleyScene` | Home — single composed world |
| `KidsSceneDestination` | Tappable place-in-world (not card) |
| `KidsMissionAdventure` | Daily mission as Mai mini-adventure |
| `KidsLearningScene` | Full-bleed lesson container (exists) |
| `KidsLetterObject` | Letter as toy in scene (exists) |
| `KidsChoiceObject` | Answer as scene prop (replace ChoiceGrid over time) |
| `KidsWritingStage` | Writing embedded in scene (exists) |
| `KidsAudioOrb` | Listen control with reaction hooks |
| `KidsCelebration` | Success particles + Mai mood |
| `KidsPlayButton` | Chunky CTA (exists) |

Design system entry: `lib/core/theme/vimai_kids.dart` (aliases to tokens).

### 4.4 Home — target composition

```
[ Sky + hills background — full bleed ]
[ Midground — 6 destinations as environmental props at depth ]
[ Foreground — grass, flowers, path edge ]
[ Mai — bottom-left, IN the scene ]
[ Speech bubble — ONE mission line from Mai, not dashboard text stack ]
[ Play CTA — chunky, tactile ]
[ Stars + house — small chrome, corners ]
```

Destinations: **no rectangular title bars**. Names via integrated world signs OR Mai narration. Progress: sparkles/stars on object, not dashboard rings.

### 4.5 Vietnamese letter C — target episode

```
Beat 1 — Garden pond: fish swims, letter C as floating toy, Mai “Cờ!”
Beat 2 — Tap listen: fish + letter + Mai react, WAV plays
Beat 3 — “Tìm chữ C!” — letters as floating bubbles in pond
Beat 4 — Write on lily pad stage with guide letter
Beat 5 — Celebration — stars, Mai happy, short reward
```

### 4.6 Japanese kana — target episode

Torii garden scene; kana character as lantern/sign object; stroke mode overlays on same scene; no horizontal chip dashboard (use in-scene scroll or Mai-suggested next beat).

### 4.7 Motion hierarchy

| Layer | Motion |
|-------|--------|
| Background | very subtle drift |
| Decor | gentle float |
| Interactive | bounce + scale on press |
| Mascot | expressive breathe/wiggle |
| Success | celebration burst |

Respect `MediaQuery.disableAnimationsOf`.

### 4.8 Phonics view-model (adapter, no JSON rewrite)

Target fields (adapter from `ContentItem` + catalog):

```
letter, uppercase, lowercase, letterName, phonics, ttsText,
exampleWord, exampleText, audioAsset, audioType
```

Implemented partially via `VietnamesePhonicsView` + `VietnameseSpeechCatalog`.

---

## 5. Assets audit

| Asset | Size | Issue |
|-------|------|-------|
| `home_world_bg.png` | 2.7 MB | Usable sky/valley base |
| `world_*.png` (6) | ~1.3–1.6 MB each | **English text burned in** — replace before premium claim |
| `lesson_japan.png` | 2.4 MB | Lesson backdrop |
| `object_fish.png` | 1.2 MB | Used for “cá” |

**Gap:** Need text-free landmark art, Mai expression sprites, per-subject room backgrounds, more word objects.

---

## 6. Files changed (this redesign pass)

| File | Change |
|------|--------|
| `lib/features/shared/widgets/kids_valley.dart` | **NEW** — valley scene + scene destinations |
| `lib/features/home/presentation/home_screen.dart` | Rewire to valley scene |
| `lib/core/l10n/app_strings.dart` | Integrated Mai mission copy |
| `test/product_audit_widget_test.dart` | Assert new scene widgets |
| `tool/vimai_kids_master_redesign_report.md` | **NEW** — this report |
| `canvases/vimai-kids-redesign-direction.canvas.tsx` | **NEW** — layout prototypes |

**Not modified:** `audio_service.dart`, curriculum JSON, production WAVs, game logic, MathQuestionGenerator.

---

## 7. Architecture changed

| Before | After (target) |
|--------|----------------|
| `LivingPlayground` + `WorldIsland` thumbnails | `KidsValleyScene` + `KidsSceneDestination` |
| Dashboard speech stack | `KidsMissionAdventure` — single Mai line + CTA |
| Hub `WorldActivity` trails | Themed rooms (future) |
| Letter hero + buttons | Staged story beats (in progress) |

---

## 8. Tests

| Suite | Last known | Notes |
|-------|------------|-------|
| `flutter analyze` | PASS (0 issues) | Re-run after implementation |
| `flutter test` | 155 passed | Re-run after home widget rename |
| `vietnamese_phonics_guide_test.dart` | PASS | Phonics correctness enforced |
| `product_audit_widget_test.dart` | Updated for valley scene | |

**Tests PASS ≠ visual PASS.**

---

## 9. Build

| Artifact | Status |
|----------|--------|
| Release APK | **NOT RE-BUILT** this pass (illustration assets added since last build) |
| Web | **PASS (2026-09-02)** | `flutter build web --release` → `build/web` (~92s). Wasm dry-run warnings from `flutter_tts` (non-blocking). |

---

## 10. Visual QA (mandatory gate)

| # | Criterion | Result |
|---|-----------|--------|
| 1 | 5-year-old wants to touch? | **NOT VERIFIED** |
| 2 | Character/visual story? | **PARTIAL** — Mai present, not premium character art |
| 3 | Discovery? | **NOT VERIFIED** |
| 4 | Interaction feedback? | **PARTIAL** — press scale on buttons |
| 5 | Feels like play? | **FAIL** — still reads as destination picker |
| 6 | Educational objective clear? | **PASS** — recommender + lesson data intact |
| 7 | Too much text? | **PARTIAL** — home still multi-line bubble |
| 8 | Dead empty space? | **PARTIAL** |
| 9 | Looks like dashboard? | **FAIL** — prior home architecture |
| 10 | Premium Kids EdTech? | **FAIL** — amateur PNG text, CustomPaint mascot |

**Visual QA overall: FAIL** — no screenshots captured; running app not inspected this session.

---

## 11. Audio QA

| Check | Result |
|-------|--------|
| Production WAV integrity | **PASS** — not modified |
| Phonics mapping B/C/D/Đ/Y | **PASS** — unit tests |
| Listening QA per clip | **NOT PERFORMED** |
| TTS preview pipeline | **BLOCKED** — no credentials |
| Natural teacher voice | **NOT VERIFIED** |

**Audio QA overall: FAIL (listening)** — data layer OK, human QA not done.

---

## 12. Known limitations

1. **Art debt:** 6 world PNGs have English burned-in text; need illustrator pass or regenerated text-free assets.
2. **Mai:** CustomPaint vector mascot — needs sprite sheet / Lottie / illustrated character.
3. **Hub screens:** Still ActivityGarden badge trails.
4. **Kana lesson:** Mode chip dashboard persists.
5. **Choice interactions:** Floating bubbles, not fully scene-embedded props.
6. **APK size:** ~12 MB illustration PNGs without compression pass.
7. **Canvas vs Flutter:** Canvas prototypes are layout direction only; Flutter implementation must match or exceed.

---

## 13. Next implementation order

1. Finish Home valley scene — remove island label bars, integrate mission into Mai.
2. Replace burned-in PNG landmarks with text-free art.
3. Vietnamese letter C full story episode (pond scene).
4. Japanese lesson scene + remove mode chips.
5. Subject hub themed rooms.
6. Wire `AudioLessonService`; configure TTS preview when credentials available.
7. Visual QA on phone/tablet/web with screenshots.
8. Rebuild APK + Web; verify WAV snapshot hash.

---

## 14. Honest completion statement

**This redesign is NOT complete.** Engineering foundations and phonics data are sound. Product visual direction requires another art + scene-composition pass before claiming v2 acceptance.

**Acceptance criteria from directive:**

| Criterion | Met? |
|-----------|------|
| Home not dashboard/card/map amateur | **NO** |
| Lesson not static letter screen | **PARTIAL** |
| Interaction feedback on touch | **PARTIAL** |
| Vietnamese phonics B=bờ, C=cờ, etc. | **YES (data + tests)** |
| Audio PASS with listening QA | **NO** |
| Production audio protected | **YES** |
| Visual “app for kids” screenshot test | **NO** |

---

*Report generated under MASTER DIRECTIVE v2. No false PASS claims.*
