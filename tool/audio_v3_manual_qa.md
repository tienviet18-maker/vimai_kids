# Audio V3 manual QA

Quality claim after generation: **PREMIUM_AI_VOICE — pending manual listening approval**

Do not tick "human quality". HUMAN_RECORDING requires a real person on the file.

Play on: laptop speaker, Android phone speaker, headphones.

Score 1–5: Naturalness, Clarity, Warmth, Speed, Pronunciation, Child friendliness, Ending, Volume.

## Vietnamese

- [ ] a — `tool/audio_v3_preview/vi/a.wav` (vi_letter_a_sound)
- [ ] á — `tool/audio_v3_preview/vi/as.wav` (sample only)
- [ ] ớ — `tool/audio_v3_preview/vi/ows.wav` (sample only; in-app Â is still â)
- [ ] bờ — `tool/audio_v3_preview/vi/bo.wav` (vi_letter_b_sound)
- [ ] cờ — `tool/audio_v3_preview/vi/co.wav` (vi_letter_c_sound)
- [ ] dờ — `tool/audio_v3_preview/vi/do.wav` (vi_letter_d_sound)
- [ ] đờ — `tool/audio_v3_preview/vi/ddo.wav` (vi_letter_dd_sound)
- [ ] Giỏi lắm! — `tool/audio_v3_preview/vi/gioi_lam.wav` (vi_phrase_gioi_lam)
- [ ] Đúng rồi! — `tool/audio_v3_preview/vi/dung_roi.wav` (no production ID)
- [ ] Thử lại nhé! — `tool/audio_v3_preview/vi/thu_lai.wav` (no production ID)

Reject a clip if it: sounds English; reads a letter name instead of the teaching sound (C must be cờ, not xê); is robotic; has unnatural rhythm; has excessive pause or elongation; is clipped; is the wrong language or voice.

The 18-clip preview does not include every letter. After voices are approved, listen to the full teaching set before any production replacement:

ă â e ê i o ô ơ u ư y gờ hờ lờ mờ nờ pờ quờ rờ sờ tờ vờ xờ

Y teaching sound must be **i dài**, not a short accidental i.


## Japanese

- [ ] あ — `tool/audio_v3_preview/ja/h_a.wav` (ja_h_a)
- [ ] い — `tool/audio_v3_preview/ja/h_i.wav` (ja_h_i)
- [ ] う — `tool/audio_v3_preview/ja/h_u.wav` (ja_h_u)
- [ ] え — `tool/audio_v3_preview/ja/h_e.wav` (ja_h_e)
- [ ] お — `tool/audio_v3_preview/ja/h_o.wav` (ja_h_o)
- [ ] か — `tool/audio_v3_preview/ja/h_ka.wav` (ja_h_ka)
- [ ] き — `tool/audio_v3_preview/ja/h_ki.wav` (ja_h_ki)
- [ ] じょうず！ — `tool/audio_v3_preview/ja/jouzu.wav` (no production ID)

Approve voices **before**:

```bash
python tool/generate_audio_v3.py --production --yes
```
