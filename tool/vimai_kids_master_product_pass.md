# ViMai Kids — Master product pass

Date: 2026-09-01

This pass **stopped patching geometric capsules**. Home now composites **real illustration assets** (valley background + six landmarks). That is a different visual architecture than CustomPaint blobs.

## PRODUCT DESIGN

**PARTIAL**

What changed:
- Added `assets/illustrations/` (home valley + 6 world landmarks + fish for “cá”).
- Home sky is a painted valley photo (`home_world_bg.png`), not a gradient pretending to be a world.
- Each subject is a photographed landmark (torii village, letter garden, number valley, puzzle cave, studio, playground), placed on a winding path.
- World visit states (available / in progress / completed / mastered) change badge, Mai presence, and “Đi thôi!” — not just a tint.
- Mission remains a speech-bubble invitation with **Chơi ngay**.
- Lesson C: Mai says “Đây là chữ C!”, teaching sound **cờ**, example **cá** with a fish illustration the child can treat as an object.

What is still not a commercial art-directed app:
- Generated landmarks currently **burn in English titles** (image model ignored “no text”). That is a visual defect. Replace those PNGs with text-free art.
- Only one lesson object PNG exists (`cá`). Other letters still use the small painter cue.
- Hubs (Vietnamese/Japanese lists) are still activity trails, not illustrated rooms.
- No on-device screenshot QA in this session (`flutter run -d chrome` is the user’s process; no screenshot tool attached).

## UX

**PARTIAL**

Loop is clearer: Mai greets → adventure CTA → tap a **place** → lesson scene with character + object + listen orb + write.

Choose-letter is bubbles + “Con tìm chữ C giúp Mai nhé!”. Writing still uses the existing canvas with a faint guide letter.

## ENGINEERING

**PASS** (compile/tests)

- `flutter analyze` — no issues
- `flutter test` — 155 passed
- `AudioService` and production WAVs untouched
- `AudioLessonService` added as a semantic wrapper only (not wired to replace playback yet)
- Illustrations decoded with `cacheWidth` to keep memory reasonable (~12MB of PNG)

APK/Web **not rebuilt in this pass**. Chrome hot-restart is required to load new assets.

## EDUCATIONAL CORRECTNESS

**PASS** (labels / tests)

Child look still teaches sound, not letter-name:
- C → **cờ** (never xê on child look)
- B → **bờ**
- D → **dờ**
- Đ → **đờ**
- Y → **i dài**

Curriculum JSON not rewritten.

## AUDIO

**PIPELINE: PASS (architecture exists)**  
**LISTENING QUALITY: NOT VERIFIED**  
**GOOGLE TTS PREVIEW: BLOCKED** (no credentials; no invented voice IDs)

Production WAV modified/deleted/renamed/regenerated: **0 / 0 / 0 / 0**

## VISUAL QA

**NOT VERIFIED**

No screenshot of the running Chrome app was captured in this session. Widget tests prove structure (6 islands, no Home `GridView`, phonics strings). They do **not** prove picture-book quality.

Self-score without a live capture (do not treat as PASS):

| Criterion | Estimate |
| --- | --- |
| Child appeal | Improved vs capsules; hurt by English text on landmarks |
| Visual hierarchy | Better (photo world + CTA) |
| Character presence | Mai on mission + in-progress world |
| Illustration quality | Real PNGs, but dirty titles |
| Color harmony | Shared warm valley |
| Interaction feedback | Press scale; bubbles |
| Motion | Cloud drift on photo; reduced-motion respected |
| Educational clarity | C/cờ/cá still explicit |
| Touch usability | 48dp+ |
| Premium product quality | Not yet — dirty generated titles, incomplete object set |

## TESTS

**PASS** — 155

## BUILD

Analyze/test PASS. Release APK/Web not re-run after adding illustrations.

## Remaining blockers

1. Re-generate or crop landmark PNGs so they contain **no English captions**.
2. Expand object art beyond `cá`.
3. Live Chrome visual QA after hot restart.
4. TTS preview still blocked until Google project + VI/JA voices exist.
5. Do not lock the six core worlds (all remain enterable).
