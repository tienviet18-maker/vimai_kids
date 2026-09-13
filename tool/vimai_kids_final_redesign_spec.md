# ViMai Kids — Final Redesign Spec

**Date:** 2026-09-06  
**Identity:** Mai’s Play Room — premium children’s learning game

---

## Product vision

Child opens app → sees Mai waiting → sees today’s adventure → taps object or CHƠI NGAY → plays → reward → wants to return.

Emotional loop: OPEN → SEE MAI → ADVENTURE → ACTIVITY → PLAY → REWARD → RETURN.

---

## Home composition (mandatory)

### Forbidden
Map, winding path, islands, 2×3 cards, six equal destinations, oversized isolated mascot, giant empty areas, fake decorative game chrome.

### Required layers (single Stack, full viewport)

```
[1] Room backdrop — home_world_bg.png full-bleed cover
[2] Spatial activity objects — 6 distinct illustrations at asymmetric slots/sizes
[3] Top chrome — stars (left), parent (right) — compact
[4] Quest banner — bottom overlay: small Mai + greeting + adventure + CHƠI NGAY
```

### Object slots (normalized, different scale)

| Subject | Slot (L,T,W) phone | Scale feel |
|---------|-------------------|------------|
| Japanese | 0.02, 0.08, 0.42 | Large |
| Vietnamese | 0.52, 0.06, 0.44 | Large |
| Math | 0.00, 0.36, 0.36 | Medium |
| Thinking | 0.58, 0.34, 0.38 | Medium |
| Creativity | 0.08, 0.58, 0.34 | Smaller |
| Games | 0.52, 0.56, 0.40 | Medium-large |

Desktop: same relative slots across max width ~1180; objects larger absolute px.

Each object: unique art (`world_*.png`), label sticker under/on object, press bounce, progress star if earned. **Not** same-sized row.

### Quest banner

- Height compact (~110–140 phone / ~120 desktop)  
- Mai size **56–72** (not 120–168)  
- One greeting line + one adventure line from ContinueLearningRecommender  
- Chunky CHƠI NGAY → real route  
- Semantically a quest, not an info card stack  

### Responsive

| Breakpoint | Behavior |
|------------|----------|
| Phone | Full-height Stack; room fills; scroll only if overflow |
| Tablet/Desktop | Centered maxHero; denser object sizes; no empty lower half |

---

## Learning screens (same language)

- VI: phonics C→cờ not xê; scene with letter + object + listen + write  
- JA: SEE→LISTEN→STROKES→WRITE; KanjiVG only; no duplicate stroke hub tiles  

---

## Audio

No Flutter credentials. Protect 913 production WAVs. Phonics data-driven via VietnamesePhonicsGuide.

---

## Components

| Name | Role |
|------|------|
| `KidsRoomScene` | Full-bleed room + slots |
| `KidsRoomObject` | Spatial tappable subject object |
| `KidsQuestBanner` | Compact Mai + adventure + CTA |
| Existing KidsPlayButton, KidsSpeechBubble, etc. | Reuse |

---

## Migration

1. Replace Home implementation  
2. Update Home-locking tests  
3. Visual capture at key sizes  
4. Hubs later; do not block Home on hub redesign  

---

## Acceptance

Home must look like a play room a 5-year-old wants to touch — not a Flutter column with stickers.
