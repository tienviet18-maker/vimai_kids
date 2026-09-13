# ViMai Kids

Educational app for children (ages 3–7): Japanese kana, Vietnamese, math, thinking, creativity, and games.

Brand: **ViMai Kids** · Support: **vimai.support@gmail.com**

## Run

```bash
flutter pub get
flutter test
flutter run
```

## Audio

Production learning audio is bundled WAV (TTS fallback). See `README_DEV_AUDIO.md`.
There are **no human recordings** in this repository (`HUMAN_AUDIO_BLOCKED`).

## Stroke order

Basic 46 hiragana + 46 katakana paths come from **KanjiVG** (CC BY-SA 3.0).
See `assets/licenses/KANJIVG_LICENSE.md`.

```bash
python tool/check_japanese_stroke_assets.py
```

## Product audits

- `tool/master_product_audit.md`
- `tool/phase2_audit.md`
