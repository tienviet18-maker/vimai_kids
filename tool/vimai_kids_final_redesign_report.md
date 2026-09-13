# ViMai Kids — Final Redesign Report

**Date:** 2026-09-06  
**Directive:** FINAL PRODUCT REDESIGN  
**Honest product status:** Architecture replaced; **Visual QA NOT PASS** (live inspection required)

---

## Deliverables

| Doc | Path |
|-----|------|
| Audit | `tool/vimai_kids_final_redesign_audit.md` |
| Spec | `tool/vimai_kids_final_redesign_spec.md` |
| Report | `tool/vimai_kids_final_redesign_report.md` (this file) |

---

## 1. What changed (product architecture)

### Home — replaced completely (not iterated strip/hero)

**Before (rejected):** CustomPaint room + oversized isolated Mai + horizontal equal sticker strip.

**After:** Spatial **Play Room**

- Full-bleed `home_world_bg.png` room backdrop  
- **6 `KidsRoomObject`** at asymmetric slots/scales with distinct `world_*.png` art  
- Compact **`KidsQuestBanner`** (Mai 64px + greeting + real adventure + CHƠI NGAY)  
- No map, path, islands, 2×3 cards, or sticker strip  

Files:

- `lib/features/shared/widgets/kids_room.dart` **NEW**  
- `lib/features/home/presentation/home_screen.dart` **REWRITE**

Daily adventure still from `ContinueLearningRecommender` (real curriculum/progress).

---

## 2. Gate status

| Gate | Status | Evidence |
|------|--------|----------|
| ENGINEERING | **PASS** | analyze 0 issues; 156 tests + 1 skipped |
| EDUCATIONAL | **PASS** | Phonics tests; generators untouched |
| AUDIO STATUS | **PARTIAL** | Pipeline safe; listening QA not done; not “native human” |
| PRODUCTION AUDIO SAFETY | **PASS** | WAV modified/deleted/renamed/regenerated = **0** |
| VISUAL QA | **FAIL / NOT VERIFIED** | Automated `toImage` capture hung; live Chrome inspect required |
| STORE READINESS | **NOT READY** | Visual + audio listening gates open |

---

## 3. Tests

```
flutter analyze → 0 issues
flutter test → 156 passed, 1 skipped (visual capture harness)
```

Production inventory tests still lock 913 WAV contract.

---

## 4. Builds

| Artifact | Result |
|----------|--------|
| `flutter build web --release` | **PASS** → `build/web` |
| `flutter build apk --release` | **PASS** → `build/app/outputs/flutter-apk/app-release.apk` (82.6 MB) |

---

## 5. Production WAV

```
PRODUCTION WAV MODIFIED = 0
PRODUCTION WAV DELETED = 0
PRODUCTION WAV RENAMED = 0
PRODUCTION WAV REGENERATED = 0
```

---

## 6. Files changed

- `tool/vimai_kids_final_redesign_audit.md`  
- `tool/vimai_kids_final_redesign_spec.md`  
- `tool/vimai_kids_final_redesign_report.md`  
- `lib/features/shared/widgets/kids_room.dart`  
- `lib/features/home/presentation/home_screen.dart`  
- `test/product_audit_widget_test.dart`  
- `test/production_quality_test.dart`  
- `test/visual_qa_capture_test.dart` (skipped placeholder)

---

## 7. Files protected

- `assets/audio/**` production WAVs  
- `AudioService`  
- MathQuestionGenerator / GameBoardMetrics / FallingLayout  
- Curriculum JSON / KanjiVG / Hive progress  

---

## 8. Visual QA status (honest)

| Screen | Captured? | Verdict |
|--------|-----------|---------|
| Home | **No PNG** (harness hung) | **Must inspect live Chrome** after hot restart |
| VI hub / lesson / JA / Math / Parent | Not captured this pass | Open |

**Do not claim Visual PASS.**

Acceptance A–R from directive: Engineering/educational/audio-safety/build items met; **visual criteria A–H / R not met without screenshot review**.

---

## 9. Remaining issues

1. Live Visual QA on Home (hot restart `flutter run -d chrome`) — iterate if still “6 floating dioramas”  
2. Subject hubs still ActivityGarden  
3. VI/JA lessons not full mini-game stages  
4. Parent/Creativity Material leftovers  
5. Screenshot automation needs a non-hanging harness  

---

## 10. Next action for product owner

1. In the running Chrome session: press **`R`** (hot restart)  
2. Judge Home: Does it feel like Mai’s play room, or still a destination picker?  
3. If reject again: next iteration must change object placement/art density, not tokens  

---

*No false Visual PASS.*
