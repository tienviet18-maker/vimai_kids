import os
import asyncio
import edge_tts

AUDIO_DIR = os.path.join("assets", "audio")
VOICE_VI = "vi-VN-HoaiMyNeural"
VOICE_JA = "ja-JP-NanamiNeural"

CATALOG = {
    # ==========================================
    # 1. TỪ VỰNG TIẾNG VIỆT ĐẦY ĐỦ (29 CHỮ CÁI)
    # ==========================================
    "v_word_a": {"text": "Cái áo.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_aw": {"text": "Ăn cơm.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_aa": {"text": "Cái ấm.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_b": {"text": "Bố yêu.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_c": {"text": "Con cá.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_d": {"text": "Cái dù.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_dd": {"text": "Quả đu đủ.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_e": {"text": "Em bé.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_ee": {"text": "Con ếch.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_g": {"text": "Con gà.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_h": {"text": "Bông hoa.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_i": {"text": "Hòn bi.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_k": {"text": "Cái kéo.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_l": {"text": "Quả lê.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_m": {"text": "Con mèo.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_n": {"text": "Cái nơ.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_o": {"text": "Con ong.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_oo": {"text": "Cái ô.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_ow": {"text": "Lá cờ.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_p": {"text": "Đèn pin.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_q": {"text": "Quả quýt.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_r": {"text": "Con rùa.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_s": {"text": "Ngôi sao.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_t": {"text": "Quả táo.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_u": {"text": "Cái mũ.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_uw": {"text": "Bức thư.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_v": {"text": "Con voi.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_x": {"text": "Xe đạp.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_y": {"text": "Y tá.", "voice": VOICE_VI, "rate": "-10%"},

    # ==========================================
    # 2. MA TRẬN GHÉP ÂM (PHONICS BLENDING) & TỪ GHÉP
    # ==========================================
    # Đánh vần cơ bản (Spelling)
    "v_blend_ba": {"text": "bờ - a - ba.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_ca": {"text": "cờ - a - ca.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_da": {"text": "dờ - a - da.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_bo": {"text": "bờ - o - bo.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_co": {"text": "cờ - o - co.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_be": {"text": "bờ - e - be.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_bi": {"text": "bờ - i - bi.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_tu": {"text": "tờ - u - tu.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_vu": {"text": "vờ - u - vu.", "voice": VOICE_VI, "rate": "-15%"},
    
    # Đánh vần có dấu (Tonal Spelling)
    "v_blend_ba_huyen": {"text": "bờ - a - ba - huyền - bà.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_ca_sac": {"text": "cờ - a - ca - sắc - cá.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_me_nang": {"text": "mờ - e - me - nặng - mẹ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_do_hoi": {"text": "đờ - o - đo - hỏi - đỏ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_su_nga": {"text": "sờ - u - su - ngã - sũ.", "voice": VOICE_VI, "rate": "-15%"},

    # Từ ghép phát âm liền (Vocabulary words)
    "v_vocab_baba": {"text": "ba ba.", "voice": VOICE_VI, "rate": "-10%"},
    "v_vocab_caca": {"text": "ca ca.", "voice": VOICE_VI, "rate": "-10%"},
    "v_vocab_bobi": {"text": "bo bi.", "voice": VOICE_VI, "rate": "-10%"},
    "v_vocab_bame": {"text": "ba mẹ.", "voice": VOICE_VI, "rate": "-10%"},
    "v_vocab_dodo": {"text": "đo đỏ.", "voice": VOICE_VI, "rate": "-10%"},

    # ==========================================
    # 3. TỪ VỰNG TIẾNG NHẬT - 46 HIRAGANA 
    # ==========================================
    "ja_word_ari": {"text": "あり", "voice": VOICE_JA, "rate": "-10%"},      # a - kiến
    "ja_word_inu": {"text": "いぬ", "voice": VOICE_JA, "rate": "-10%"},      # i - chó
    "ja_word_ushi": {"text": "うし", "voice": VOICE_JA, "rate": "-10%"},     # u - bò
    "ja_word_eki": {"text": "えき", "voice": VOICE_JA, "rate": "-10%"},      # e - nhà ga
    "ja_word_oni": {"text": "おに", "voice": VOICE_JA, "rate": "-10%"},      # o - quỷ
    "ja_word_kasa": {"text": "かさ", "voice": VOICE_JA, "rate": "-10%"},     # ka - cái ô
    "ja_word_kiku": {"text": "きく", "voice": VOICE_JA, "rate": "-10%"},     # ki - hoa cúc
    "ja_word_kuma": {"text": "くま", "voice": VOICE_JA, "rate": "-10%"},     # ku - con gấu
    "ja_word_keito": {"text": "けいと", "voice": VOICE_JA, "rate": "-10%"},  # ke - cuộn len
    "ja_word_koma": {"text": "こま", "voice": VOICE_JA, "rate": "-10%"},     # ko - con quay
    "ja_word_sakura": {"text": "さくら", "voice": VOICE_JA, "rate": "-10%"}, # sa - anh đào
    "ja_word_shika": {"text": "しか", "voice": VOICE_JA, "rate": "-10%"},    # shi - con nai
    "ja_word_suika": {"text": "すいか", "voice": VOICE_JA, "rate": "-10%"},  # su - dưa hấu
    "ja_word_semi": {"text": "せみ", "voice": VOICE_JA, "rate": "-10%"},     # se - con ve
    "ja_word_sora": {"text": "そら", "voice": VOICE_JA, "rate": "-10%"},     # so - bầu trời
    "ja_word_tako": {"text": "たこ", "voice": VOICE_JA, "rate": "-10%"},     # ta - con bạch tuộc
    "ja_word_chizu": {"text": "ちず", "voice": VOICE_JA, "rate": "-10%"},    # chi - bản đồ
    "ja_word_tsuki": {"text": "つき", "voice": VOICE_JA, "rate": "-10%"},    # tsu - mặt trăng
    "ja_word_te": {"text": "て", "voice": VOICE_JA, "rate": "-10%"},         # te - bàn tay
    "ja_word_tokei": {"text": "とけい", "voice": VOICE_JA, "rate": "-10%"},  # to - đồng hồ
    "ja_word_natsu": {"text": "なつ", "voice": VOICE_JA, "rate": "-10%"},    # na - mùa hè
    "ja_word_niji": {"text": "にじ", "voice": VOICE_JA, "rate": "-10%"},     # ni - cầu vồng
    "ja_word_nuno": {"text": "ぬの", "voice": VOICE_JA, "rate": "-10%"},     # nu - vải
    "ja_word_neko": {"text": "ねこ", "voice": VOICE_JA, "rate": "-10%"},     # ne - con mèo
    "ja_word_nori": {"text": "のり", "voice": VOICE_JA, "rate": "-10%"},     # no - rong biển
    "ja_word_hana": {"text": "はな", "voice": VOICE_JA, "rate": "-10%"},     # ha - bông hoa
    "ja_word_hikouki": {"text": "ひこうき", "voice": VOICE_JA, "rate": "-10%"}, # hi - máy bay
    "ja_word_fune": {"text": "ふね", "voice": VOICE_JA, "rate": "-10%"},     # fu - con tàu
    "ja_word_hebi": {"text": "へび", "voice": VOICE_JA, "rate": "-10%"},     # he - con rắn
    "ja_word_hoshi": {"text": "ほし", "voice": VOICE_JA, "rate": "-10%"},    # ho - ngôi sao
    "ja_word_mado": {"text": "まど", "voice": VOICE_JA, "rate": "-10%"},     # ma - cửa sổ
    "ja_word_mikan": {"text": "みかん", "voice": VOICE_JA, "rate": "-10%"},  # mi - quả quýt
    "ja_word_mushi": {"text": "むし", "voice": VOICE_JA, "rate": "-10%"},    # mu - côn trùng
    "ja_word_megane": {"text": "めがね", "voice": VOICE_JA, "rate": "-10%"}, # me - mắt kính
    "ja_word_momo": {"text": "もも", "voice": VOICE_JA, "rate": "-10%"},     # mo - quả đào
    "ja_word_yama": {"text": "やま", "voice": VOICE_JA, "rate": "-10%"},     # ya - ngọn núi
    "ja_word_yuki": {"text": "ゆき", "voice": VOICE_JA, "rate": "-10%"},     # yu - tuyết
    "ja_word_yoru": {"text": "よる", "voice": VOICE_JA, "rate": "-10%"},     # yo - buổi tối
    "ja_word_raion": {"text": "らいおん", "voice": VOICE_JA, "rate": "-10%"}, # ra - sư tử
    "ja_word_ringo": {"text": "りんご", "voice": VOICE_JA, "rate": "-10%"},  # ri - quả táo
    "ja_word_rusu": {"text": "るす", "voice": VOICE_JA, "rate": "-10%"},     # ru - vắng nhà
    "ja_word_reizouko": {"text": "れいぞうこ", "voice": VOICE_JA, "rate": "-10%"}, # re - tủ lạnh
    "ja_word_rousoku": {"text": "ろうそく", "voice": VOICE_JA, "rate": "-10%"}, # ro - nến
    "ja_word_wani": {"text": "わに", "voice": VOICE_JA, "rate": "-10%"},     # wa - cá sấu
    
    # ==========================================
    # 4. TỪ VỰNG TIẾNG NHẬT - 46 KATAKANA 
    # ==========================================
    "ja_word_aisu": {"text": "アイス", "voice": VOICE_JA, "rate": "-10%"},       # a - kem
    "ja_word_iruka": {"text": "イルカ", "voice": VOICE_JA, "rate": "-10%"},      # i - cá heo
    "ja_word_uebbu": {"text": "ウェブ", "voice": VOICE_JA, "rate": "-10%"},      # u - web
    "ja_word_erebeetaa": {"text": "エレベーター", "voice": VOICE_JA, "rate": "-10%"}, # e - thang máy
    "ja_word_orenji": {"text": "オレンジ", "voice": VOICE_JA, "rate": "-10%"},    # o - quả cam
    "ja_word_kamera": {"text": "カメラ", "voice": VOICE_JA, "rate": "-10%"},      # ka - máy ảnh
    "ja_word_kiui": {"text": "キウイ", "voice": VOICE_JA, "rate": "-10%"},        # ki - quả kiwi
    "ja_word_kuriimu": {"text": "クリーム", "voice": VOICE_JA, "rate": "-10%"},   # ku - kem
    "ja_word_keeki": {"text": "ケーキ", "voice": VOICE_JA, "rate": "-10%"},       # ke - bánh ngọt
    "ja_word_koohii": {"text": "コーヒー", "voice": VOICE_JA, "rate": "-10%"},    # ko - cà phê
    "ja_word_sakkaa": {"text": "サッカー", "voice": VOICE_JA, "rate": "-10%"},    # sa - bóng đá
    "ja_word_shatsu": {"text": "シャツ", "voice": VOICE_JA, "rate": "-10%"},      # shi - áo sơ mi
    "ja_word_suutsu": {"text": "スーツ", "voice": VOICE_JA, "rate": "-10%"},      # su - vest
    "ja_word_seetaa": {"text": "セーター", "voice": VOICE_JA, "rate": "-10%"},    # se - áo len
    "ja_word_sooseeji": {"text": "ソーセージ", "voice": VOICE_JA, "rate": "-10%"},# so - xúc xích
    "ja_word_taoru": {"text": "タオル", "voice": VOICE_JA, "rate": "-10%"},       # ta - khăn tắm
    "ja_word_chiizu": {"text": "チーズ", "voice": VOICE_JA, "rate": "-10%"},      # chi - phô mai
    "ja_word_tsuaa": {"text": "ツアー", "voice": VOICE_JA, "rate": "-10%"},       # tsu - tour
    "ja_word_terebi": {"text": "テレビ", "voice": VOICE_JA, "rate": "-10%"},      # te - tivi
    "ja_word_tomato": {"text": "トマト", "voice": VOICE_JA, "rate": "-10%"},      # to - cà chua
    "ja_word_naifu": {"text": "ナイフ", "voice": VOICE_JA, "rate": "-10%"},       # na - con dao
    "ja_word_nyuusu": {"text": "ニュース", "voice": VOICE_JA, "rate": "-10%"},    # ni - tin tức
    "ja_word_noodo": {"text": "ノード", "voice": VOICE_JA, "rate": "-10%"},       # no - node
    "ja_word_hamu": {"text": "ハム", "voice": VOICE_JA, "rate": "-10%"},         # ha - thịt nguội
    "ja_word_hiitaa": {"text": "ヒーター", "voice": VOICE_JA, "rate": "-10%"},    # hi - máy sưởi
    "ja_word_fooku": {"text": "フォーク", "voice": VOICE_JA, "rate": "-10%"},     # fu - cái nĩa
    "ja_word_herikoputaa": {"text": "ヘリコプター", "voice": VOICE_JA, "rate": "-10%"}, # he - trực thăng
    "ja_word_hoteru": {"text": "ホテル", "voice": VOICE_JA, "rate": "-10%"},      # ho - khách sạn
    "ja_word_maiku": {"text": "マイク", "voice": VOICE_JA, "rate": "-10%"},       # ma - micro
    "ja_word_miruku": {"text": "ミルク", "voice": VOICE_JA, "rate": "-10%"},      # mi - sữa
    "ja_word_meron": {"text": "メロン", "voice": VOICE_JA, "rate": "-10%"},       # me - dưa lưới
    "ja_word_motaa": {"text": "モーター", "voice": VOICE_JA, "rate": "-10%"},     # mo - mô tơ
    "ja_word_yotto": {"text": "ヨット", "voice": VOICE_JA, "rate": "-10%"},       # yo - du thuyền
    "ja_word_rajio": {"text": "ラジオ", "voice": VOICE_JA, "rate": "-10%"},       # ra - radio
    "ja_word_ribon": {"text": "リボン", "voice": VOICE_JA, "rate": "-10%"},       # ri - ruy băng
    "ja_word_ruubii": {"text": "ルビー", "voice": VOICE_JA, "rate": "-10%"},      # ru - ruby
    "ja_word_remon": {"text": "レモン", "voice": VOICE_JA, "rate": "-10%"},       # re - chanh
    "ja_word_oketto": {"text": "ロケット", "voice": VOICE_JA, "rate": "-10%"},    # ro - tên lửa
    "ja_word_wain": {"text": "ワイン", "voice": VOICE_JA, "rate": "-10%"},        # wa - rượu vang
}

async def generate_single(semaphore, audio_id, config):
    async with semaphore:
        filepath = os.path.join(AUDIO_DIR, f"{audio_id}.mp3")
        for attempt in range(3):
            try:
                tts = edge_tts.Communicate(text=config["text"], voice=config["voice"], rate=config["rate"])
                await tts.save(filepath)
                print(f"-> Đã tạo: {audio_id}.mp3 [{config['text']}]")
                return
            except Exception as e:
                if attempt < 2:
                    await asyncio.sleep(1)
                else:
                    print(f"LỖI: {audio_id} -> {e}")

async def main():
    os.makedirs(AUDIO_DIR, exist_ok=True)
    print(f"BẮT ĐẦU TẠO GÓI SIÊU MỞ RỘNG ({len(CATALOG)} FILE)...")
    semaphore = asyncio.Semaphore(5) # Tải 5 file cùng lúc cho nhanh
    tasks = [generate_single(semaphore, audio_id, config) for audio_id, config in CATALOG.items()]
    await asyncio.gather(*tasks)
    print("HOÀN TẤT GÓI SIÊU MỞ RỘNG!")

if __name__ == "__main__":
    asyncio.run(main())