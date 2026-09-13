# Audio V3 — Vietnamese pronunciation

Source of spoken text: `lib/core/audio/vietnamese_speech_catalog.dart` and letter WAV jobs.

V3 does **not** rewrite curriculum to make TTS easier.

## Letter name vs letter sound

| Glyph | Name (spoken) | Sound (spoken) | Production IDs |
|---|---|---|---|
| A | a | a | vi_letter_a_name / vi_letter_a_sound |
| Ă | ă | ă | vi_letter_aw_* |
| Â | â | â | vi_letter_aa_* |
| B | bê | bờ | vi_letter_b_* |
| C | xê | cờ | vi_letter_c_* |
| D | dê | dờ | vi_letter_d_* |
| Đ | đê | đờ | vi_letter_dd_* |
| E | e | e | vi_letter_e_* |
| Ê | ê | ê | vi_letter_ee_* |
| G | giê | gờ | vi_letter_g_* |
| H | hát | hờ | vi_letter_h_* |
| I | i | i | vi_letter_i_* |
| K | ca | cờ | vi_letter_k_* |
| L | e-lờ | lờ | vi_letter_l_* |
| M | em-mờ | mờ | vi_letter_m_* |
| N | en-nờ | nờ | vi_letter_n_* |
| O | o | o | vi_letter_o_* |
| Ô | ô | ô | vi_letter_oo_* |
| Ơ | ơ | ơ | vi_letter_ow_* |
| P | pê | pờ | vi_letter_p_* |
| Q | quy | quờ | vi_letter_q_* |
| R | e-rờ | rờ | vi_letter_r_* |
| S | ét | sờ | vi_letter_s_* |
| T | tê | tờ | vi_letter_t_* |
| U | u | u | vi_letter_u_* |
| Ư | ư | ư | vi_letter_uw_* |
| V | vê | vờ | vi_letter_v_* |
| X | ích | xờ | vi_letter_x_* |
| Y | i | i | vi_letter_y_* |

Tones a á à ả ã ạ are **not** separate alphabet letters in this curriculum.
Preview may generate `á` and `ớ` as listening samples only.

## Praise (existing production ID)

- Giỏi lắm → `vi_phrase_gioi_lam` → `assets/audio/vi/phrases/gioi_lam.wav`
- Style: gentle teacher, not shouted, not robotic period.
- Đúng rồi / Thử lại nhé / Tuyệt vời / Tiếp tục / Hoàn thành: **no production IDs**. Do not invent them. Preview-only if generated.

## Delivery

Clear, slow, warm, child-friendly. Short letters with natural ending + ~150–250 ms tail. No chipmunk. No pitch shift. No playbackRate compensation.
