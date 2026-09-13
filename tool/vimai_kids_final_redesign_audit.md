# ViMai Kids — Final Redesign Audit

**Date:** 2026-09-06  
**Status:** Pre-implementation audit (read-only)  
**Directive:** FINAL PRODUCT REDESIGN

---

## 1. Information architecture

| Route | Screen |
|-------|--------|
| `/home` | HomeScreen — **REJECTED visual** |
| `/japanese`, `/japanese/learn/:script`, library | JA hub + unified lesson |
| `/vietnamese`, `/vietnamese/learn`, activities | VI hub + letter lesson + quizzes |
| `/math`, `/math/play/:skill` | Math hub + quiz |
| `/thinking`, `/creativity`, `/games`+ | Direct / hub + games |
| `/parent`, `/progress` | Parent (includes Support/About), Progress |
| Onboarding | welcome, profiles, create_profile |

Support has **no dedicated route** — lives in Parent.

---

## 2. Why current Home is rejected

Current: `KidsPlayRoomBackdrop` (sparse CustomPaint) + **oversized isolated Mai** (120–168px) + speech stack + **horizontal equal-ish sticker strip**.

Fails:

- Not a spatial play room with tappable corner objects  
- Large empty sky/floor on desktop  
- Oversized isolated mascot  
- Strip still reads as “6 destination buttons”  
- World PNGs unused on Home  
- Feels like decorated Flutter column, not children’s game product  

Valley/map already removed from Home wiring — but replacement is still weak.

---

## 3. Modules (visual pattern)

| Module | Pattern | Action |
|--------|---------|--------|
| Home | Column strip | **Replace completely** |
| VI/JA/Math/Games hubs | ActivityGarden glyph circles | Redesign after Home |
| VI/JA lessons | Scene shell + modes | Polish same language |
| Thinking | Worksheet quiz | Later |
| Creativity | Material AppBar | Later |
| Parent | Calm cards | Keep tone (adult) |

---

## 4. Assets

- Illustrations (9): `home_world_bg.png`, 6× `world_*.png`, `lesson_japan.png`, `object_fish.png`  
- Audio: **914** WAV on disk / **913** contract — **PROTECT**  
- KanjiVG: 92 SVG — **PROTECT**  

---

## 5. Design tokens

`lib/core/theme/vimai_tokens.dart` + `vimai_kids.dart` + `vimai_art.dart`

---

## 6. Educational protect list

- MathQuestionGenerator  
- GameBoardMetrics, FallingLayout  
- AudioService architecture  
- VietnamesePhonicsGuide + catalog (B=bờ, C=cờ≠xê, D=dờ, Đ=đờ, Y=i dài)  
- ContinueLearningRecommender (real daily adventure)  
- Curriculum JSON, Hive progress, KanjiVG paths  
- Production WAVs: 0 modify/delete/rename/regenerate  

---

## 7. Tests locking Home

`product_audit_widget_test.dart`: greeting, `Chơi ngay`, 6 activity widgets, no grid, responsive sizes  
`production_quality_test.dart`: Play Room symbols; forbids valley/island  

**Must update** when Home widget names/composition change.

---

## 8. Pro / purchase

Free-only entitlements; no payment UI. Honest.

---

## 9. Redesign target (from gaps)

1. **Spatial Play Room** — full-bleed room art + 6 corner objects at **different scales/positions**  
2. **Compact quest banner** — small Mai + adventure + CTA (not isolated giant mascot)  
3. Reuse `world_*.png` as distinctive room objects  
4. Fill viewport; no blank lower half  
5. Real adventure from ContinueLearningRecommender  

---

## 10. Verdict

Educational backend: **keep**.  
Home presentation: **replace architecture again** (not iterate on sticker strip).  
Hubs/lessons: same visual language after Home lands.
