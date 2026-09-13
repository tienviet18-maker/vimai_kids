# ViMai Kids — Master product audit (final)

Date: 2026-08-31  
Scope: design system, Home playground, child lesson stage, Vietnamese pronunciation domain, Japanese writing/stroke validation, Google TTS preview isolation.

This report does **not** claim native human audio. Google Cloud TTS is premium synthetic / neural TTS when configured. It is not configured in this environment.

---

## PRODUCT

- **Overall status:** PARTIAL — coherent child learning app with a real design system, Home playground, and lesson stages. Not a store-ready “native teacher voice” product.
- **Design status:** PASS for shared tokens/components (`VimaiColor`, `VimaiType`, `LessonStage`, `WorldTile`, `PlaygroundBackdrop`, `KidButton`, feedback). Not a generic Material dashboard. Not a copy of another app.
- **Home status:** PASS for architecture and copy. Mai greeting, today’s invitation, six distinct subject worlds, continue/mission, reward ring. Decorative playground blobs (static, not infinite animation). Widget tests still require `Chào {name}!`, age, `Hôm nay mình học gì nhỉ?`, `Con muốn học gì hôm nay?`.
- **Lesson UX status:** PASS vs previous empty beige canvas. Vietnamese look/listen uses `LessonStage` + mascot + teaching sound + primary CTA `Nghe âm`. Japanese look/listen uses the same stage. Write/stroke modes keep real canvases/players. Device visual QA was not run this pass (widget/responsive tests only).

---

## VIETNAMESE

- **Pronunciation architecture:** PASS. Layers stay separate:
  - Curriculum JSON (`assets/content/vietnamese/alphabet.json`) — **not rewritten**
  - Runtime catalog (`VietnameseSpeechCatalog` / `teachingSound`)
  - Phonics guide (`VietnamesePhonicsGuide.primarySpoken`)
  - Generation map (`tool/audio_generation/vimai_kids_pronunciation_map.json`, `curriculumModified: false`)
- **Pronunciation map:** PASS and testable. Phonics overlay is explicit. Curriculum phoneme for Y remains `i`. Teaching display/generation overlay is `i dài`.
- **Known corrections:**
  - B phonics → **bờ** (letter name bê)
  - C phonics → **cờ** (letter name xê) — UI no longer presents C as “Xê” in phonics look
  - D phonics → **dờ** (letter name dê)
  - Đ phonics → **đờ** (letter name đê)
  - Y phonics → **i dài** (curriculum name/phoneme still `i`; I stays `i`, no invented “i ngắn”)
- **Audio status:** PARTIAL. Runtime plays existing production sound IDs (`vi_letter_*_sound`), never raw-letter TTS. Production Y sound WAV was **not** regenerated; the child may still **hear** the old clip while the UI shows `i dài`. Replacement requires a later approved Google preview → production stage.

---

## JAPANESE

- **Stroke-order status:** PASS for basic 46 hiragana + 46 katakana using bundled KanjiVG CC BY-SA 3.0 paths. Tests check asset files, stroke counts, parseable paths, no empty paths, license metadata. Dakuten/yoon/small/extended: honest fallback, **no invented SVG**.
- **Writing status:** PASS. `Viết` uses `WritePracticeBoard` (canvas ink, clear/reset, ghost model). Stroke mode uses `StrokeOrderPlayer` (replay, step, licensed paths). Redundant standalone **“Thứ tự nét Hiragana”** tile remains removed; Katakana stroke tile kept. No fake AI handwriting scoring.
- **Licensed data status:** PASS for basic kana. `assets/licenses/KANJIVG_LICENSE.md` present. Catalog attribution: Ulrich Apel / KanjiVG.

---

## AUDIO

```
AUDIO_V3_GOOGLE_STATUS

Provider: Google Cloud Text-to-Speech
Project: MISSING
Credentials: MISSING
VI Voice: MISSING
JA Voice: MISSING
Preview Manifest: FOUND (exactly 18)
Ready for preview: NO
Reason: no ADC, no GOOGLE_CLOUD_PROJECT, empty VI_VOICE_NAME and JA_VOICE_NAME (voices not invented)
Production WAV modified: 0
```

- **Provider:** Google Cloud Text-to-Speech (tool-only). Not in Flutter. No credentials in Dart/assets/git.
- **Model:** not invented; unused until voices are configured.
- **VI voice / JA voice:** empty by design until `list_voices` verification.
- **Preview status:** STOPPED. Output root `tool/audio_v3_preview/` only. Generated **0/18**. No Piper/SAPI fallback for this preview. `--force-vi` refused. Production generation **not** executed.
- **Technical QA:** NOT_RUN (no files to inspect). Distinct from MANUAL_LISTENING_QA.
- **Manual listening QA:** NOT_RUN. READY_FOR_MANUAL_QA: NO.
- **Production status:** 913 contract WAVs unchanged (sha256 vs `tool/audio_v3_production_snapshot.json`). Disk has 914 files because of pre-existing stray `assets/audio/vi/rimes/ao.raw.wav` (not in the 913 contract; not deleted). Human recordings: 0.

---

## ENGINEERING

- **Architecture:** Protected systems left intact: `AudioService`, Games board / `GameBoardMetrics` / `FallingLayout`, `MathQuestionGenerator`, routes, branding, support email `vimai.support@gmail.com`, Android `applicationId` `com.maianlearning.mai_an_learning`.
- **Tests:** PASS — **154** tests (phonics map, Y overlay, stroke SVG catalog, write interaction, preview isolation, Home/Parent/responsive preserved).
- **Analyzer:** PASS — 0 issues.
- **APK:** PASS — `build/app/outputs/flutter-apk/app-release.apk` (68.4MB). `AUDIO CHECK OK records=913 missing=0`.
- **Web:** PASS — `build/web`. flutter_tts wasm dry-run warnings only (plugin, pre-existing).
- **Responsive:** PASS in widget tests (360×640 through 1366×768, Home 600×960, Japanese lesson sizes). No live device pass this session.

---

## SAFETY

- 913 WAV modified: **0**
- 913 WAV deleted: **0**
- 913 WAV renamed: **0**
- production generation executed: **NO**

---

## REMAINING BLOCKERS

1. **Google Cloud TTS preview** — ADC, project, and verified `VI_VOICE_NAME` / `JA_VOICE_NAME` missing. Cannot generate the 18 preview clips honestly.
2. **Human / approved premium voice** — 0 human recordings; production WAVs remain TTS_TEMPORARY / Piper-era. Do not market as a native kindergarten teacher voice.
3. **Y production sound clip** — UI/generation map say `i dài`; existing `vi_letter_y_sound.wav` was not replaced (forbidden this task).
4. **Extended kana stroke data** — no licensed combined paths; fallback only.
5. **On-device visual QA** — not run this session (no attached Android device).

---

## COMMANDS THIS PASS

| Command | Result |
|---|---|
| `flutter analyze` | PASS — No issues found |
| `flutter test` | PASS — **154** tests |
| `python tool/generate_audio_v3.py --preview` | STOP — Google not ready; 0 preview WAVs; production unmodified |
| `flutter build apk --release` | PASS 68.4MB; AUDIO CHECK OK 913 missing=0 |
| `flutter build web` | PASS `build/web` |

Protected and untouched: AudioService internals, Games metrics, MathQuestionGenerator, curriculum JSON, 913 production WAVs, applicationId, support email.
