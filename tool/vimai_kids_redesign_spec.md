# ViMai Kids — Complete Redesign Specification (v3)

**Date:** 2026-09-06  
**Directive:** MASTER IMPLEMENTATION DIRECTIVE v3  
**Status:** Living design contract for implementation

---

## 1. Product vision

ViMai Kids is a premium children's learning product for ages ~3–7.  
The child opens the app and immediately feels:

> Mai đang chờ mình. Có thứ để khám phá, chạm, chơi, học và được thưởng.

Not:

> Đây là một app Flutter với nhiều card chức năng.

**Product model:** Character → Discovery → Activity → Interaction → Learning → Reward → Next discovery.

---

## 2. Target child

- Age: 3–7 (primary: 5)
- Limited reading; responds to character, sound, color, motion, reward
- Parent: trusts calm, clear controls in Parent mode

---

## 3. UX principles

1. **Character first** — Mai is present and reactive on every child screen.
2. **One focal point** — each viewport has one clear thing to look at / touch.
3. **Play before instruction** — learning is embedded in interaction.
4. **Tactile feedback** — every important tap compresses, glows, or celebrates.
5. **Shared language, not identical templates** — Home ≠ Lesson ≠ Parent.
6. **Protect education** — never rewrite generators, curriculum, or production audio for UI.

---

## 4. Navigation architecture

```
Child mode                         Parent mode
─────────                          ───────────
Home (hero + discovery)            Parent (calm dashboard)
  ├─ Today's adventure → lesson      ├─ Today / Learning
  ├─ Subject rooms                   ├─ Settings / Support
  │    ├─ Vietnamese                 └─ About
  │    ├─ Japanese
  │    ├─ Math / Thinking / Creativity / Games
  └─ Stars → Progress (light)
```

- **No world map / winding path / six islands** as primary navigation.
- Desktop: controlled wide composition; content not tiny in empty canvas.
- Mobile: single-focus hero; subjects as scrollable activity stickers.
- Parent visually distinct from child gameplay.

---

## 5. Home composition (CRITICAL)

### Forbidden
- 2×3 card grid  
- Six identical subject cards  
- Winding island map  
- Six floating island thumbnails over a valley photo  
- Generic dashboard header stack  

### Required hierarchy (first viewport)

| Order | Element | Role |
|-------|---------|------|
| 1 | Mai (large) | Character presence |
| 2 | Greeting (in speech) | Personal connection |
| 3 | Today's adventure | Mission + primary CTA |
| 4 | Hero scene / object | Visual focal point |
| 5 | Subject discovery strip | Secondary exploration |
| 6 | Stars / house | Progress + parent chrome |

### Composition concept: **Mai's Play Room**

Original ViMai identity — not a map.

```
┌─────────────────────────────────────────────────────────┐
│  ★ stars                              🏠 parent         │
│                                                         │
│     ┌──────────────┐     ┌─────────────────────────┐   │
│     │              │     │  Speech: Chào {name}!   │   │
│     │  MAI (hero)  │────▶│  Adventure line         │   │
│     │  + room art  │     │  [ CHƠI NGAY ]          │   │
│     │              │     └─────────────────────────┘   │
│     └──────────────┘                                   │
│                                                         │
│  Subject stickers (asymmetric toys, NOT equal cards):  │
│   [JP lantern] [VI book] [Math blocks] …               │
└─────────────────────────────────────────────────────────┘
```

- Hero = Mai + room atmosphere + adventure CTA (one composition).
- Subjects = unique sticker-like activity objects with different silhouettes/sizes — not six copies of one component with different colors.
- Desktop: hero left ~55%, adventure panel right; subjects below in a flowing row.
- Phone: vertical stack — hero + Mai/speech, then horizontal subject scroll.

---

## 6. Lesson composition

Every lesson = **mini experience**:

```
SCENE background
  + Mai (guide)
  + Learning object (letter / kana / number)
  + Interaction (listen / choose / write)
  + Feedback / celebration
  + Progression CTA
```

**Forbidden:** Header + giant isolated letter + speaker icon + button row on blank canvas.

### Vietnamese phonics (child mode)

| Letter | Show | Never show in child look |
|--------|------|--------------------------|
| B | bờ → example | — |
| C | **cờ** → cá | **xê** |
| D | dờ | — |
| Đ | đờ | — |
| Y | **i dài** | — |

Data model keeps `letterName` separate from `phonics`.

**C episode beats:** Discover (fish + C) → Listen → Choose bubbles → Write → Celebrate.

### Japanese

Flow: LOOK → LISTEN → STROKE ORDER → TRACE → WRITE → SUCCESS  
Use KanjiVG only. Remove redundant separate “Thứ tự nét Hiragana” hub entry if duplicate of in-lesson strokes.  
No blank white canvas as the whole experience.

---

## 7. Component architecture

| Component | Purpose |
|-----------|---------|
| `VimaiCharacter` | Mai with mood/state |
| `VimaiSpeechBubble` | Character speech |
| `VimaiHeroScene` | Home / room hero composition |
| `VimaiActivitySticker` | Unique subject discovery object |
| `VimaiPlayButton` | Chunky tactile CTA |
| `VimaiAudioControl` | Alive audio orb (not Material speaker) |
| `VimaiLessonStage` | Scene shell for lessons |
| `VimaiChoiceObject` | Selectable learning prop |
| `VimaiWritingStage` | Guide + canvas + progress |
| `VimaiCelebration` | Short success burst |
| `VimaiReward` / `VimaiProgress` | Stars, rings |

States for interactive: idle / hover / pressed / focused / disabled / playing / success / error / completed.

---

## 8–11. Design tokens

Centralize in `lib/core/theme/` (aliases already via `vimai_kids.dart`):

- **Colors:** sky, coral, mint, grape, peach, honey, teal + subject accents; ink for text. Avoid whole-app beige cream.
- **Typography:** display / greeting / title / body / button / caption — playful weight, readable.
- **Spacing:** xxs→xl; breakpoints phone / tablet / desktop (not only maxWidth 720).
- **Radius:** organic chunky (sm/md/lg), not endless pills.
- **Shadow:** soft depth only; prefer chunky 3D button faces over multi-layer glow.
- **Motion:** idle breathe, press scale, success burst; respect reduced-motion.
- **Illustration:** asset catalog + contracts for poses/objects; no amateur CustomPaint as primary art.

### Breakpoints

| Name | Width | Behavior |
|------|-------|----------|
| phone | <600 | Single-focus vertical |
| tablet | 600–1023 | Larger scene + clusters |
| desktop | ≥1024 | Wide composition, controlled max ~1100–1280 for hero |

---

## 12. Illustration strategy

**Reuse:** `home_world_bg.png` as optional texture only if it supports the room concept; prefer dedicated room/hero art over six `world_*.png` island thumbnails on Home.

**Asset contract (future):**

- Mai: idle, happy, thinking, celebrating, encouraging  
- Subject stickers: 6 unique silhouettes (lantern, book, blocks, puzzle, brush, ball)  
- Lesson objects: fish (cá), more word props  
- Lesson BGs: garden (VI), torii/garden (JA)

**Until art arrives:** UI architecture must accept `Image.asset` paths without rewriting screens. Temporary painted stickers may use carefully designed shapes but must not be the long-term primary art.

---

## 13. Motion system

| Layer | Motion |
|-------|--------|
| Background | Extremely subtle or none |
| Mai | Idle breathe |
| CTA / objects | Press compress + bounce |
| Success | Short celebration (≤800ms) |
| Reduced motion | Static frames |

---

## 14. Interaction system

- Min touch 48dp (kid targets 56+)
- Hover (web) scale/glow; press always feedback
- Correct: celebrate + advance; wrong: gentle wiggle + retry (never scary)

---

## 15. Responsive strategy

Compose per screen — do not stretch phone UI. Desktop hero uses row layout; subjects wrap or scroll. Games keep `GameBoardMetrics`.

---

## 16. Accessibility

Semantics, contrast, font scaling, keyboard where needed, reduced motion, non-color-only feedback.

---

## 17. Migration strategy

| Phase | Work | Protect |
|-------|------|---------|
| 1 | Audit (done) | — |
| 2 | This spec + Canvas | — |
| 3 | Tokens + components | AudioService, WAVs |
| 4 | Home hero | ContinueLearning logic |
| 5 | Vietnamese scene shell | Phonics guide |
| 6 | Japanese scene shell | KanjiVG, modes |
| 7 | Math / Thinking / Creativity shells | Generators |
| 8 | Games chrome only | GameBoardMetrics, FallingLayout |
| 9 | Parent calm mode | Persistence |
| 10 | Responsive + a11y | — |
| 11 | Visual QA | — |
| 12 | Tests + builds | 913 WAV |

**Update tests** that lock `KidsSceneDestination × 6` when Home changes.

---

## 18. Files to protect

- `assets/audio/**` production WAVs (0 delete/rename/overwrite/regenerate)
- `lib/core/audio/audio_service.dart` architecture
- `MathQuestionGenerator`, `GameBoardMetrics`, `FallingLayout`
- Curriculum JSON unless proven bug
- KanjiVG stroke paths
- Progress/persistence semantics

---

## 19. Acceptance (honest)

Engineering PASS ≠ Visual PASS.  
Visual PASS only after web run + screen review against this spec and child experience questions (focal point, Mai, touch, reward, no dashboard feel).

---

*End of redesign specification v3.*
