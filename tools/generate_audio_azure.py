import os
import json
import asyncio
import edge_tts

AUDIO_DIR = os.path.join("assets", "audio")
MANIFEST_PATH = os.path.join(AUDIO_DIR, "audio_manifest.json")

VOICE_VI = "vi-VN-HoaiMyNeural"
VOICE_JA = "ja-JP-NanamiNeural"

CATALOG = {
    # =========================================================================
    # 1. BẢNG CHỮ CÁI TIẾNG VIỆT (29 CHỮ CHUẨN NGỮ ÂM ĐÁNH VẦN TIỂU HỌC)
    # =========================================================================
    "v_a": {"text": "a.", "voice": VOICE_VI, "rate": "-10%"},
    "v_aw": {"text": "á.", "voice": VOICE_VI, "rate": "-20%"},        # ă
    "v_aa": {"text": "ớ!", "voice": VOICE_VI, "rate": "-20%"},        # â
    "v_b": {"text": "bờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_c": {"text": "cờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_d": {"text": "dờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_dd": {"text": "đờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_e": {"text": "e.", "voice": VOICE_VI, "rate": "-10%"},
    "v_ee": {"text": "ê.", "voice": VOICE_VI, "rate": "-10%"},
    "v_g": {"text": "gờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_h": {"text": "hờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_i": {"text": "i.", "voice": VOICE_VI, "rate": "-10%"},
    "v_k": {"text": "cờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_l": {"text": "lờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_m": {"text": "mờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_n": {"text": "nờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_o": {"text": "o.", "voice": VOICE_VI, "rate": "-10%"},
    "v_oo": {"text": "ô.", "voice": VOICE_VI, "rate": "-10%"},
    "v_ow": {"text": "ơ.", "voice": VOICE_VI, "rate": "-10%"},
    "v_p": {"text": "pờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_q": {"text": "cu.", "voice": VOICE_VI, "rate": "-15%"},
    "v_r": {"text": "rờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_s": {"text": "sờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_t": {"text": "tờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_u": {"text": "u.", "voice": VOICE_VI, "rate": "-10%"},
    "v_uw": {"text": "ư.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v": {"text": "vờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_x": {"text": "xờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_y": {"text": "i.", "voice": VOICE_VI, "rate": "-10%"},

    # 5 Dấu thanh Tiếng Việt
    "v_tone_sac": {"text": "Dấu sắc.", "voice": VOICE_VI, "rate": "-10%"},
    "v_tone_huyen": {"text": "Dấu huyền.", "voice": VOICE_VI, "rate": "-10%"},
    "v_tone_hoi": {"text": "Dấu hỏi.", "voice": VOICE_VI, "rate": "-10%"},
    "v_tone_nga": {"text": "Dấu ngã.", "voice": VOICE_VI, "rate": "-10%"},
    "v_tone_nang": {"text": "Dấu nặng.", "voice": VOICE_VI, "rate": "-10%"},
    "v_tone_ngang": {"text": "Thanh ngang.", "voice": VOICE_VI, "rate": "-10%"},

    # 11 Phụ âm ghép tiếng Việt
    "v_c_ch": {"text": "chờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_c_gh": {"text": "gờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_c_gi": {"text": "giờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_c_kh": {"text": "khờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_c_nh": {"text": "nhờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_c_ng": {"text": "ngờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_c_ngh": {"text": "ngờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_c_ph": {"text": "phờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_c_qu": {"text": "quờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_c_th": {"text": "thờ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_c_tr": {"text": "trờ.", "voice": VOICE_VI, "rate": "-15%"},

    # Các vần cơ bản thông dụng
    "v_v_ai": {"text": "ai.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v_ao": {"text": "ao.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v_au": {"text": "au.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v_ay": {"text": "ay.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v_an": {"text": "an.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v_am": {"text": "am.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v_ap": {"text": "ap.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v_at": {"text": "at.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v_en": {"text": "en.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v_et": {"text": "et.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v_in": {"text": "in.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v_on": {"text": "on.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v_ong": {"text": "ong.", "voice": VOICE_VI, "rate": "-10%"},
    "v_v_ung": {"text": "ung.", "voice": VOICE_VI, "rate": "-10%"},

    # Ghép vần hoàn chỉnh (Phonics Blending)
    "v_blend_ba": {"text": "bờ - a - ba.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_ba_sac": {"text": "bờ - a - ba - sắc - bá.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_ba_huyen": {"text": "bờ - a - ba - huyền - bà.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_ba_hoi": {"text": "bờ - a - ba - hỏi - bả.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_ba_nga": {"text": "bờ - a - ba - ngã - bã.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_ba_nang": {"text": "bờ - a - ba - nặng - bạ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_ca": {"text": "cờ - a - ca.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_ca_sac": {"text": "cờ - a - ca - sắc - cá.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_da": {"text": "dờ - a - da.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_me": {"text": "mờ - e - me.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_me_nang": {"text": "mờ - e - me - nặng - mẹ.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_bo": {"text": "bờ - o - bo.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_bo_sac": {"text": "bờ - o - bo - sắc - bó.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_ga": {"text": "gờ - a - ga.", "voice": VOICE_VI, "rate": "-15%"},
    "v_blend_ga_huyen": {"text": "gờ - a - ga - huyền - gà.", "voice": VOICE_VI, "rate": "-15%"},

    # Từ vựng Tiếng Việt phong phú (Động vật, Đồ vật, Gia đình)
    "v_word_a": {"text": "Quả na.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_aw": {"text": "Mặt trăng.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_aa": {"text": "Cái nấm.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_aasm": {"text": "Cái ấm.", "voice": VOICE_VI, "rate": "-10%"},
    "vi_word_aasm": {"text": "Cái ấm.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_b": {"text": "Con bò.", "voice": VOICE_VI, "rate": "-10%"},
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
    "v_word_q": {"text": "Cái quạt.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_r": {"text": "Con rùa.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_s": {"text": "Ngôi sao.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_t": {"text": "Quả táo.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_u": {"text": "Cái mũ.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_uw": {"text": "Bức thư.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_v": {"text": "Con voi.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_x": {"text": "Xe buýt.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_y": {"text": "Y tá.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_dog": {"text": "Con chó.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_duck": {"text": "Con vịt.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_bird": {"text": "Con chim.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_car": {"text": "Xe ô tô.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_bike": {"text": "Xe đạp.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_plane": {"text": "Máy bay.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_ship": {"text": "Tàu thủy.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_sun": {"text": "Ông mặt trời.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_rain": {"text": "Cơn mưa.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_cloud": {"text": "Đám mây.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_tree": {"text": "Cây xanh.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_house": {"text": "Ngôi nhà.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_dad": {"text": "Bố yêu.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_mom": {"text": "Mẹ yêu.", "voice": VOICE_VI, "rate": "-10%"},
    "v_word_baby": {"text": "Em bé ngoan.", "voice": VOICE_VI, "rate": "-10%"},

    # =========================================================================
    # 2. TOÁN HỌC MAI AI - SỐ ĐẾM (0-100), PHÉP TÍNH & HÌNH KHỐI
    # =========================================================================
    # Lời dẫn MAI AI từng module Toán cụ thể
    "sys_math_intro": {"text": "Chào mừng bé đến với xưởng số vui nhộn!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_math_count": {"text": "Bé hãy đếm xem có tất cả bao nhiêu bạn nhé?", "voice": VOICE_VI, "rate": "-5%"},
    "sys_math_identify": {"text": "Bé hãy chạm vào chữ số chính xác theo yêu cầu nào!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_math_compare": {"text": "Bé hãy so sánh xem nhóm nào có số lượng nhiều hơn nhé!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_math_match": {"text": "Bé hãy ghép nối các số có cùng số lượng với nhau nào!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_math_calc_add": {"text": "Bé hãy cùng thực hiện phép tính cộng nhé!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_math_calc_sub": {"text": "Bé hãy cùng thực hiện phép tính trừ nhé!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_math_shapes": {"text": "Bé hãy cùng tìm hiểu các hình khối vui nhộn nào!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_math_order": {"text": "Bé hãy sắp xếp các con số theo thứ tự từ nhỏ đến lớn nhé!", "voice": VOICE_VI, "rate": "-5%"},

    # Số đếm từ 0 đến 30 và tròn chục
    "math_num_0": {"text": "Số không.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_1": {"text": "Số một.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_2": {"text": "Số hai.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_3": {"text": "Số ba.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_4": {"text": "Số bốn.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_5": {"text": "Số năm.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_6": {"text": "Số sáu.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_7": {"text": "Số bảy.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_8": {"text": "Số tám.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_9": {"text": "Số chín.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_10": {"text": "Số mười.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_11": {"text": "Số mười một.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_12": {"text": "Số mười hai.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_13": {"text": "Số mười ba.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_14": {"text": "Số mười bốn.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_15": {"text": "Số mười lăm.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_16": {"text": "Số mười sáu.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_17": {"text": "Số mười bảy.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_18": {"text": "Số mười tám.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_19": {"text": "Số mười chín.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_20": {"text": "Số hai mươi.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_30": {"text": "Số ba mươi.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_40": {"text": "Số bốn mươi.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_50": {"text": "Số năm mươi.", "voice": VOICE_VI, "rate": "-10%"},
    "math_num_100": {"text": "Một trăm.", "voice": VOICE_VI, "rate": "-10%"},

    # Thuật ngữ phép toán & Câu hỏi
    "math_op_plus": {"text": "Cộng.", "voice": VOICE_VI, "rate": "-10%"},
    "math_op_minus": {"text": "Trừ.", "voice": VOICE_VI, "rate": "-10%"},
    "math_op_equal": {"text": "Bằng.", "voice": VOICE_VI, "rate": "-10%"},
    "math_cmp_greater": {"text": "Lớn hơn.", "voice": VOICE_VI, "rate": "-10%"},
    "math_cmp_less": {"text": "Bé hơn.", "voice": VOICE_VI, "rate": "-10%"},
    "math_cmp_equal": {"text": "Bằng nhau.", "voice": VOICE_VI, "rate": "-10%"},
    "math_q_how_many": {"text": "Có bao nhiêu tất cả hả bé?", "voice": VOICE_VI, "rate": "-5%"},
    "math_q_find_bigger": {"text": "Số nào lớn hơn hả bé?", "voice": VOICE_VI, "rate": "-5%"},
    "math_q_find_smaller": {"text": "Số nào bé hơn hả bé?", "voice": VOICE_VI, "rate": "-5%"},

    # Hình khối & Kích thước
    "shape_circle": {"text": "Hình tròn.", "voice": VOICE_VI, "rate": "-10%"},
    "shape_square": {"text": "Hình vuông.", "voice": VOICE_VI, "rate": "-10%"},
    "shape_triangle": {"text": "Hình tam giác.", "voice": VOICE_VI, "rate": "-10%"},
    "shape_rectangle": {"text": "Hình chữ nhật.", "voice": VOICE_VI, "rate": "-10%"},
    "shape_star": {"text": "Hình ngôi sao.", "voice": VOICE_VI, "rate": "-10%"},
    "shape_heart": {"text": "Hình trái tim.", "voice": VOICE_VI, "rate": "-10%"},
    "shape_oval": {"text": "Hình bầu dục.", "voice": VOICE_VI, "rate": "-10%"},
    "shape_diamond": {"text": "Hình thoi.", "voice": VOICE_VI, "rate": "-10%"},
    "size_big": {"text": "To lớn.", "voice": VOICE_VI, "rate": "-10%"},
    "size_small": {"text": "Nhỏ bé.", "voice": VOICE_VI, "rate": "-10%"},

    # =========================================================================
    # 3. TRÒ CHƠI TƯ DUY & SÁNG TẠO (LOGIC, MÀU SẮC, KHÁM PHÁ)
    # =========================================================================
    "sys_thinking_intro": {"text": "Cùng bạn Mai rèn luyện tư duy nhanh trí nào!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_thinking_find": {"text": "Bé hãy quan sát thật kỹ và tìm hình còn thiếu nhé!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_thinking_match": {"text": "Bé hãy nối các đồ vật có liên quan với nhau nào!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_thinking_shadow": {"text": "Bé hãy tìm xem đâu là chiếc bóng chính xác nhé!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_thinking_memory": {"text": "Bé hãy lật mở và tìm các cặp hình giống hệt nhau nhé!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_thinking_maze": {"text": "Bé hãy tìm đường đi đúng để đưa bạn về nhà nào!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_thinking_diff": {"text": "Bé hãy tìm điểm khác biệt giữa hai bức tranh nào!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_creativity_intro": {"text": "Bé hãy thỏa sức sáng tạo và vẽ tranh nào!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_color_pick": {"text": "Bé muốn tô bức tranh bằng màu sắc nào?", "voice": VOICE_VI, "rate": "-5%"},
    "sys_clear_canvas": {"text": "Chúng mình cùng xóa bảng để vẽ bức tranh mới nhé!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_brush_size": {"text": "Bé chọn nét cọ to hay nét cọ nhỏ nào?", "voice": VOICE_VI, "rate": "-5%"},

    # Bảng màu sắc chi tiết
    "color_red": {"text": "Màu đỏ.", "voice": VOICE_VI, "rate": "-10%"},
    "color_blue": {"text": "Màu xanh dương.", "voice": VOICE_VI, "rate": "-10%"},
    "color_green": {"text": "Màu xanh lá cây.", "voice": VOICE_VI, "rate": "-10%"},
    "color_yellow": {"text": "Màu vàng.", "voice": VOICE_VI, "rate": "-10%"},
    "color_orange": {"text": "Màu cam.", "voice": VOICE_VI, "rate": "-10%"},
    "color_pink": {"text": "Màu hồng.", "voice": VOICE_VI, "rate": "-10%"},
    "color_purple": {"text": "Màu tím.", "voice": VOICE_VI, "rate": "-10%"},
    "color_brown": {"text": "Màu nâu.", "voice": VOICE_VI, "rate": "-10%"},
    "color_black": {"text": "Màu đen.", "voice": VOICE_VI, "rate": "-10%"},
    "color_white": {"text": "Màu trắng.", "voice": VOICE_VI, "rate": "-10%"},
    "color_grey": {"text": "Màu xám.", "voice": VOICE_VI, "rate": "-10%"},

    # =========================================================================
    # 4. HỆ THỐNG PHẢN HỒI THÔNG MINH (INTERACTIVE FEEDBACK ENGINE)
    # =========================================================================
    "sys_praise_1": {"text": "Bé giỏi quá! Tuyệt vời!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_praise_2": {"text": "Chính xác rồi! Hoan hô bé!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_praise_3": {"text": "Bé thật là thông minh và xuất sắc!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_praise_4": {"text": "Đúng rồi! Bạn làm rất đỉnh!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_praise": {"text": "Bé giỏi quá! Tuyệt vời!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_correct": {"text": "Đúng rồi! Bạn làm rất tốt!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_try_again_1": {"text": "Chưa chính xác rồi, bé thử lại lần nữa nhé!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_try_again_2": {"text": "Gần đúng rồi, bé hãy quan sát kỹ hơn nào!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_try_again": {"text": "Chưa chính xác rồi, bé thử lại nhé!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_encourage": {"text": "Cố gắng lên nào, bé sắp hoàn thành rồi!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_level_up": {"text": "Chúc mừng bé đã vượt qua thử thách xuất sắc!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_game_over": {"text": "Hết giờ rồi, cùng chơi lại một ván mới nhé!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_welcome_back": {"text": "Chào mừng bé quay trở lại cùng học với bạn Mai!", "voice": VOICE_VI, "rate": "-5%"},
    "sys_goodbye": {"text": "Tạm biệt bé, hẹn gặp lại ở bài học sau nhé!", "voice": VOICE_VI, "rate": "-5%"},

    # =========================================================================
    # 5. TIẾNG NHẬT - HIRAGANA ĐẦY ĐỦ (CƠ BẢN, BIẾN ÂM & ÂM GHÉP YOON)
    # =========================================================================
    # 46 Âm Hiragana cơ bản
    "ja_h_a": {"text": "あ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_i": {"text": "い.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_u": {"text": "う.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_e": {"text": "え.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_o": {"text": "お.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ka": {"text": "か.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ki": {"text": "き.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ku": {"text": "く.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ke": {"text": "け.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ko": {"text": "こ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_sa": {"text": "さ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_shi": {"text": "し.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_su": {"text": "す.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_se": {"text": "せ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_so": {"text": "そ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ta": {"text": "た.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_chi": {"text": "ち.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_tsu": {"text": "つ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_te": {"text": "て.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_to": {"text": "と.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_na": {"text": "な.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ni": {"text": "に.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_nu": {"text": "ぬ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ne": {"text": "ね.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_no": {"text": "の.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ha": {"text": "は.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_hi": {"text": "ひ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_fu": {"text": "ふ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_he": {"text": "へ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ho": {"text": "ほ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ma": {"text": "ま.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_mi": {"text": "み.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_mu": {"text": "む.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_me": {"text": "め.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_mo": {"text": "も.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ya": {"text": "や.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_yu": {"text": "ゆ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_yo": {"text": "よ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ra": {"text": "ら.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ri": {"text": "り.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ru": {"text": "る.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_re": {"text": "れ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ro": {"text": "ろ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_wa": {"text": "わ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_wo": {"text": "を.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_n": {"text": "ん.", "voice": VOICE_JA, "rate": "-10%"},

    # 25 Âm đục & bán đục Hiragana
    "ja_h_ga": {"text": "が.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_gi": {"text": "ぎ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_gu": {"text": "ぐ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ge": {"text": "げ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_go": {"text": "ご.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_za": {"text": "ざ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ji": {"text": "じ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_zu": {"text": "ず.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ze": {"text": "ぜ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_zo": {"text": "ぞ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_da": {"text": "だ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ji_d": {"text": "ぢ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_zu_d": {"text": "づ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_de": {"text": "で.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_do": {"text": "ど.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ba": {"text": "ば.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_bi": {"text": "び.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_bu": {"text": "ぶ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_be": {"text": "べ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_bo": {"text": "ぼ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_pa": {"text": "ぱ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_pi": {"text": "ぴ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_pu": {"text": "ぷ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_pe": {"text": "ぺ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_po": {"text": "ぽ.", "voice": VOICE_JA, "rate": "-10%"},

    # Âm ghép Hiragana Yoon
    "ja_h_kya": {"text": "きゃ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_kyu": {"text": "きゅ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_kyo": {"text": "きょ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_sha": {"text": "しゃ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_shu": {"text": "しゅ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_sho": {"text": "しょ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_cha": {"text": "ちゃ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_chu": {"text": "ちゅ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_cho": {"text": "ちょ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_nya": {"text": "にゃ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_nyu": {"text": "にゅ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_nyo": {"text": "にょ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_hya": {"text": "ひゃ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_hyu": {"text": "ひゅ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_hyo": {"text": "ひょ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_mya": {"text": "みゃ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_myu": {"text": "みゅ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_myo": {"text": "みょ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_rya": {"text": "りゃ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ryu": {"text": "りゅ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_h_ryo": {"text": "りょ.", "voice": VOICE_JA, "rate": "-10%"},

    # =========================================================================
    # 6. TIẾNG NHẬT - KATAKANA ĐẦY ĐỦ (CƠ BẢN, BIẾN ÂM & ÂM GHÉP)
    # =========================================================================
    # 46 Âm Katakana cơ bản
    "ja_k_a": {"text": "ア.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_i": {"text": "イ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_u": {"text": "ウ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_e": {"text": "エ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_o": {"text": "オ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ka": {"text": "カ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ki": {"text": "キ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ku": {"text": "ク.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ke": {"text": "ケ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ko": {"text": "コ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_sa": {"text": "サ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_shi": {"text": "シ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_su": {"text": "ス.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_se": {"text": "セ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_so": {"text": "ソ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ta": {"text": "タ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_chi": {"text": "チ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_tsu": {"text": "ツ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_te": {"text": "テ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_to": {"text": "ト.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_na": {"text": "ナ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ni": {"text": "ニ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_nu": {"text": "ヌ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ne": {"text": "ネ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_no": {"text": "ノ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ha": {"text": "ハ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_hi": {"text": "ヒ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_fu": {"text": "フ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_he": {"text": "ヘ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ho": {"text": "ホ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ma": {"text": "マ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_mi": {"text": "ミ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_mu": {"text": "ム.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_me": {"text": "メ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_mo": {"text": "モ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ya": {"text": "ヤ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_yu": {"text": "ユ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_yo": {"text": "ヨ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ra": {"text": "ラ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ri": {"text": "リ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ru": {"text": "ル.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_re": {"text": "レ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ro": {"text": "ロ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_wa": {"text": "ワ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_wo": {"text": "ヲ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_n": {"text": "ン.", "voice": VOICE_JA, "rate": "-10%"},

    # 25 Âm đục & bán đục Katakana
    "ja_k_ga": {"text": "ガ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_gi": {"text": "ギ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_gu": {"text": "グ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ge": {"text": "ゲ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_go": {"text": "ゴ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_za": {"text": "ザ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ji": {"text": "ジ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_zu": {"text": "ズ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ze": {"text": "ゼ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_zo": {"text": "ゾ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_da": {"text": "ダ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ji_d": {"text": "ヂ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_zu_d": {"text": "ヅ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_de": {"text": "デ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_do": {"text": "ド.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_ba": {"text": "バ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_bi": {"text": "ビ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_bu": {"text": "ブ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_be": {"text": "ベ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_bo": {"text": "ボ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_pa": {"text": "パ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_pi": {"text": "ピ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_pu": {"text": "プ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_pe": {"text": "ペ.", "voice": VOICE_JA, "rate": "-10%"},
    "ja_k_po": {"text": "ポ.", "voice": VOICE_JA, "rate": "-10%"},

    # Câu chỉ dẫn tiếng Nhật Nanami
    "sys_ja_intro": {"text": "日本語を楽しく学びましょう！", "voice": VOICE_JA, "rate": "-5%"},
    "sys_ja_hiragana": {"text": "ひらがなの練習です。よく聞いてね！", "voice": VOICE_JA, "rate": "-5%"},
    "sys_ja_katakana": {"text": "カタカナの練習です。声に出してみよう！", "voice": VOICE_JA, "rate": "-5%"},
    "sys_ja_praise": {"text": "すごい！よくできました！", "voice": VOICE_JA, "rate": "-5%"},
    "sys_ja_try_again": {"text": "もう一回やってみよう！", "voice": VOICE_JA, "rate": "-5%"},
}

async def generate_single(semaphore, audio_id, config):
    async with semaphore:
        filename = f"{audio_id}.mp3"
        filepath = os.path.join(AUDIO_DIR, filename)
        for attempt in range(3):
            try:
                tts = edge_tts.Communicate(text=config["text"], voice=config["voice"], rate=config["rate"])
                await tts.save(filepath)
                print(f"-> Tạo thành công: {filename} [{config['text']}]")
                return audio_id, filename
            except Exception as e:
                if attempt < 2:
                    await asyncio.sleep(1)
                else:
                    print(f"LỖI: {filename} -> {e}")
                    return audio_id, None

async def main():
    os.makedirs(AUDIO_DIR, exist_ok=True)
    manifest = {}
    print(f"BẮT ĐẦU TẠO KHO {len(CATALOG)} FILE ÂM THANH THƯƠNG MẠI TOÀN HỆ THỐNG...")
    
    # Sử dụng Semaphore giới hạn 5 luồng tải đồng thời để tối ưu tốc độ và không bị chặn IP
    semaphore = asyncio.Semaphore(5)
    tasks = [generate_single(semaphore, audio_id, config) for audio_id, config in CATALOG.items()]
    results = await asyncio.gather(*tasks)

    for audio_id, filename in results:
        if filename:
            manifest[audio_id] = filename

    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    print(f"\nHOÀN TẤT TOÀN BỘ DỰ ÁN: Đã xuất bản {len(manifest)} file audio thương mại!")

if __name__ == "__main__":
    asyncio.run(main())