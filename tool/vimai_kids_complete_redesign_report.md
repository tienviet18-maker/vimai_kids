# ViMai Kids — Complete Redesign Report (Directive v3)

**Date:** 2026-09-06  
**Directive:** MASTER IMPLEMENTATION DIRECTIVE v3  
**Honest status:** Engineering gates advanced; visual product redesign **IN PROGRESS / NOT ACCEPTED**

---

## 1. Initial audit

Educational core is sound and protected:

- MathQuestionGenerator, GameBoardMetrics, FallingLayout — keep
- Curriculum JSON — keep
- AudioService + 913 manifest / 914 on-disk WAV — keep / protect
- Vietnamese phonics guide (B=bờ, C=cờ not xê, D=dờ, Đ=đờ, Y=i dài) — keep
- Hive progress / profiles — keep
- KanjiVG stroke paths — keep

Presentation was still a **valley + 6 island destinations + mission strip**, failing the hero-scene brief. Subject hubs used ActivityGarden glyph circles. Parent/Creativity leaked Material forms.

---

## 2. Problems discovered

1. Home = map/island mental model despite “not a card” comments  
2. Six identical destination components with different PNGs/colors  
3. Dual world widget stacks (`kids_valley` + `vimai_world`)  
4. Lesson screens still stage-stacked rather than full mini-stories  
5. Japanese hub had redundant Katakana stroke-only entry  
6. Tests locked 6× island widgets  
7. `maxWidth: 720` used as universal desktop clamp  
8. Illustration PNGs underused / wrong architecture (thumbnails vs hotspots)

---

## 3. Product strategy

Character → Discovery → Activity → Interaction → Learning → Reward.

Home identity: **Mai’s Play Room** (not a world map).

Spec: `tool/vimai_kids_redesign_spec.md`  
Canvas: `canvases/vimai-kids-v3-compositions.canvas.tsx`

---

## 4. New information architecture

```
Home (Play Room hero + activity stickers)
  → Subject rooms (hubs — still garden pattern; next phase)
    → Lesson mini-experience
Parent = calm mode (unchanged this pass)
```

---

## 5. Design system

| Token | Status |
|-------|--------|
| VimaiKidsColors / Typography / Spacing / Radius / Shadow / Motion | Existing via `vimai_kids.dart` |
| VimaiKidsBreakpoints | **Added** (`phone` 600 / `tablet` 1024 / `maxHero` 1180) |
| Illustration catalog | Exists; Home no longer mounts 6 island PNGs |

---

## 6. Component architecture (this pass)

| Component | File | Role |
|-----------|------|------|
| `KidsPlayRoomBackdrop` | `kids_playroom.dart` | Soft room scene (not valley map) |
| `KidsPlayRoomHero` | same | Mai + greeting + adventure + CTA |
| `KidsActivitySticker` | same | Unique silhouette per subject |
| `KidsActivityStrip` | same | Horizontal discovery strip |
| `ActivityShape` | same | lantern / book / blocks / puzzle / brush / ball |

---

## 7. Home redesign

**DONE (architecture):** Replaced `KidsValleyScene` / `KidsSceneDestination` with Play Room hero + asymmetric stickers.

**PARTIAL (visual quality):** Backdrop is painted composition (not premium illustration pack). Stickers are CustomPaint silhouettes — temporary until art contract filled. **Visual QA on running web: NOT VERIFIED this session.**

---

## 8. Vietnamese redesign

**PARTIAL:** Look speech embeds phonics sound + example (`cờ`, `i dài`). Scene stack improved earlier; full pond mini-story beats not complete. Phonics tests PASS.

---

## 9. Japanese redesign

**PARTIAL:** Removed redundant “Thứ tự nét Katakana” hub tile (stroke remains inside lesson modes). Path copy updated. Full lantern-garden lesson shell **not done**.

---

## 10–15. Writing / Math / Thinking / Creativity / Games / Parent

**NOT REDESIGNED** this pass (protected logic; presentation deferred).

---

## 16. Responsive strategy

Home uses `VimaiBreakpoints` + `maxHero` 1180; wide = row hero. Phone = stacked hero. Not yet fully QA’d on live web.

---

## 17–18. Accessibility / Motion

Touch targets / semantics retained on stickers. Reduced motion respected for backdrop drift. Full a11y pass **NOT DONE**.

---

## 19. Audio presentation

AudioService untouched. Presentation polish (alive orb) **PARTIAL** (existing KidsAudioButton). Listening QA **NOT PERFORMED**.

---

## 20. Data changes

None to curriculum JSON. Copy strings updated for subject discovery actions. Phonics presentation unchanged at data layer.

---

## 21. Files changed (this pass)

- `tool/vimai_kids_redesign_spec.md` **NEW**
- `tool/vimai_kids_complete_redesign_report.md` **NEW** (this file)
- `canvases/vimai-kids-v3-compositions.canvas.tsx` **NEW**
- `lib/features/shared/widgets/kids_playroom.dart` **NEW**
- `lib/features/home/presentation/home_screen.dart` **REWRITE**
- `lib/core/theme/vimai_tokens.dart` — breakpoints
- `lib/core/theme/vimai_kids.dart` — breakpoints alias
- `lib/core/l10n/app_strings.dart` — activity copy
- `lib/features/japanese/presentation/japanese_home_screen.dart` — remove stroke tile
- `lib/features/vietnamese/presentation/vietnamese_letter_lesson_screen.dart` — phonics speech
- `test/product_audit_widget_test.dart`
- `test/production_quality_test.dart`
- `test/japanese_lesson_flow_test.dart`

---

## 22. Files protected

- `assets/audio/**` — **0** modified/deleted/renamed/regenerated this pass  
- `audio_service.dart` — untouched  
- MathQuestionGenerator / GameBoardMetrics / FallingLayout — untouched  
- KanjiVG / curriculum JSON — untouched  

---

## 23. Tests

| Gate | Result |
|------|--------|
| `flutter analyze` | **PASS** (0 issues) |
| `flutter test` | **PASS** (156) |

---

## 24. Web build

| Gate | Result |
|------|--------|
| `flutter build web --release` | **PASS** → `build/web` (2026-09-06) |

---

## 25. APK build

**NOT RUN** this pass.

---

## 26. Visual QA

| Screen | Result |
|--------|--------|
| HOME | **NOT VERIFIED** on device — architecture changed; must inspect rendered Play Room |
| VI / JA lessons | **NOT VERIFIED** |
| Math / Thinking / Creativity / Games / Parent | **NOT REDESIGNED** |

**Visual overall: FAIL** (no screenshot / live review evidence).

---

## 27. Remaining issues

1. Subject hubs still ActivityGarden circles  
2. Lesson mini-stories incomplete (VI pond, JA lantern)  
3. CustomPaint stickers / room backdrop need real illustration assets  
4. Parent still Material form  
5. Live web Visual QA mandatory before any Visual PASS  
6. APK rebuild pending  
7. Audio listening QA separate gate  

---

## Acceptance matrix (v3)

| Gate | Status |
|------|--------|
| ENGINEERING | **PASS** (analyze + tests) |
| UX | **PARTIAL** |
| VISUAL | **FAIL** (not verified) |
| INTERACTION | **PARTIAL** |
| RESPONSIVE | **PARTIAL** |
| ACCESSIBILITY | **PARTIAL** |
| EDUCATIONAL CORRECTNESS | **PASS** (phonics tests) |
| AUDIO PRESENTATION | **PARTIAL** |
| PRODUCTION AUDIO SAFETY | **PASS** |

**Product not accepted.** First impression must still be validated on running web: Mai present, adventure CTA, unique activity stickers — not islands/cards — then continue phases 6–15.

---

*No false PASS claims.*
