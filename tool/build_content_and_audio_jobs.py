"""Build Vietnamese JSON catalogs and the unified audio job list."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

LETTERS = [
    ("A", "a", "a", "a", "áo", "vowel"),
    ("Ă", "ă", "ă", "ă", "ăn", "vowel"),
    ("Â", "â", "â", "â", "ấm", "vowel"),
    ("B", "b", "bê", "bờ", "bố", "consonant"),
    ("C", "c", "xê", "cờ", "cá", "consonant"),
    ("D", "d", "dê", "dờ", "da", "consonant"),
    ("Đ", "đ", "đê", "đờ", "đá", "consonant"),
    ("E", "e", "e", "e", "em", "vowel"),
    ("Ê", "ê", "ê", "ê", "ếch", "vowel"),
    ("G", "g", "giê", "gờ", "gà", "consonant"),
    ("H", "h", "hát", "hờ", "hoa", "consonant"),
    ("I", "i", "i", "i", "im", "vowel"),
    ("K", "k", "ca", "cờ", "kem", "consonant"),
    ("L", "l", "e-lờ", "lờ", "lá", "consonant"),
    ("M", "m", "em-mờ", "mờ", "mẹ", "consonant"),
    ("N", "n", "en-nờ", "nờ", "nón", "consonant"),
    ("O", "o", "o", "o", "ong", "vowel"),
    ("Ô", "ô", "ô", "ô", "ô", "vowel"),
    ("Ơ", "ơ", "ơ", "ơ", "ớt", "vowel"),
    ("P", "p", "pê", "pờ", "pin", "consonant"),
    ("Q", "q", "quy", "quờ", "quả", "consonant"),
    ("R", "r", "e-rờ", "rờ", "rùa", "consonant"),
    ("S", "s", "ét", "sờ", "sữa", "consonant"),
    ("T", "t", "tê", "tờ", "táo", "consonant"),
    ("U", "u", "u", "u", "ung", "vowel"),
    ("Ư", "ư", "ư", "ư", "ưa", "vowel"),
    ("V", "v", "vê", "vờ", "voi", "consonant"),
    ("X", "x", "ích", "xờ", "xe", "consonant"),
    ("Y", "y", "i", "i", "yêu", "vowel"),
]

PHONICS = [
    ("b", "a", "ba"), ("b", "e", "be"), ("b", "i", "bi"), ("b", "o", "bo"), ("b", "u", "bu"),
    ("c", "a", "ca"), ("c", "o", "co"), ("c", "u", "cu"),
    ("d", "a", "da"), ("d", "e", "de"), ("d", "i", "di"), ("d", "o", "do"), ("d", "u", "du"),
    ("đ", "a", "đa"), ("đ", "e", "đe"), ("đ", "i", "đi"), ("đ", "o", "đo"), ("đ", "u", "đu"),
    ("g", "a", "ga"), ("g", "o", "go"), ("g", "u", "gu"),
    ("h", "a", "ha"), ("h", "e", "he"), ("h", "i", "hi"), ("h", "o", "ho"), ("h", "u", "hu"),
    ("k", "e", "ke"), ("k", "i", "ki"),
    ("l", "a", "la"), ("l", "e", "le"), ("l", "i", "li"), ("l", "o", "lo"), ("l", "u", "lu"),
    ("m", "a", "ma"), ("m", "e", "me"), ("m", "i", "mi"), ("m", "o", "mo"), ("m", "u", "mu"),
    ("n", "a", "na"), ("n", "e", "ne"), ("n", "i", "ni"), ("n", "o", "no"), ("n", "u", "nu"),
    ("p", "a", "pa"), ("p", "i", "pi"), ("p", "o", "po"),
    ("q", "ua", "qua"),
    ("r", "a", "ra"), ("r", "e", "re"), ("r", "i", "ri"), ("r", "o", "ro"), ("r", "u", "ru"),
    ("s", "a", "sa"), ("s", "o", "so"), ("s", "u", "su"),
    ("t", "a", "ta"), ("t", "e", "te"), ("t", "i", "ti"), ("t", "o", "to"), ("t", "u", "tu"),
    ("v", "a", "va"), ("v", "e", "ve"), ("v", "i", "vi"), ("v", "o", "vo"), ("v", "u", "vu"),
    ("x", "a", "xa"), ("x", "e", "xe"), ("x", "i", "xi"), ("x", "o", "xo"), ("x", "u", "xu"),
    ("ph", "a", "pha"), ("ph", "o", "pho"), ("ph", "u", "phu"),
    ("th", "a", "tha"), ("th", "e", "the"), ("th", "i", "thi"), ("th", "o", "tho"), ("th", "u", "thu"),
    ("kh", "a", "kha"), ("kh", "e", "khe"), ("kh", "o", "kho"), ("kh", "u", "khu"),
    ("nh", "a", "nha"), ("nh", "e", "nhe"), ("nh", "i", "nhi"), ("nh", "o", "nho"), ("nh", "u", "nhu"),
    ("ch", "a", "cha"), ("ch", "e", "che"), ("ch", "i", "chi"), ("ch", "o", "cho"), ("ch", "u", "chu"),
    ("tr", "a", "tra"), ("tr", "e", "tre"), ("tr", "i", "tri"), ("tr", "o", "tro"), ("tr", "u", "tru"),
    ("gh", "e", "ghe"), ("gh", "i", "ghi"),
    ("ng", "a", "nga"), ("ng", "o", "ngo"), ("ng", "u", "ngu"),
    ("ngh", "e", "nghe"), ("ngh", "i", "nghi"),
]

RIMES = [
    "an", "ang", "anh", "ao", "au", "ay", "am", "ap", "at", "ac",
    "ăn", "ăng", "ân", "âng", "âu", "ây",
    "em", "en", "eng", "êt", "êch", "êu", "ên",
    "im", "in", "inh", "ich", "ip", "it",
    "ong", "oc", "ot", "om", "op", "oi",
    "ông", "ôc", "ôt", "ôm",
    "ung", "uc", "ut", "um", "ui",
    "ưng", "ưt", "ưu",
    "ươn", "ương", "ươm", "ướt", "ước",
    "iên", "iêng", "iêt", "iêu",
    "uyên", "uyết",
]

WORDS = [
    ("ba", "cha", "👨", 3), ("mẹ", "mẹ", "👩", 3), ("bé", "em bé", "👶", 3), ("bà", "bà", "👵", 3),
    ("bố", "bố", "👨", 3), ("ông", "ông", "👴", 3), ("anh", "anh", "👦", 3), ("chị", "chị", "👧", 3),
    ("cá", "con cá", "🐟", 3), ("gà", "con gà", "🐔", 3), ("bò", "con bò", "🐮", 3), ("mèo", "con mèo", "🐱", 4),
    ("chó", "con chó", "🐶", 4), ("heo", "con heo", "🐷", 4), ("vịt", "con vịt", "🦆", 4), ("ngựa", "con ngựa", "🐴", 5),
    ("voi", "con voi", "🐘", 4), ("thỏ", "con thỏ", "🐰", 3), ("chim", "con chim", "🐦", 4), ("tôm", "con tôm", "🦐", 5),
    ("hoa", "bông hoa", "🌸", 4), ("cây", "cây", "🌳", 5), ("lá", "lá cây", "🍃", 5), ("quả", "quả", "🍎", 4),
    ("nhà", "ngôi nhà", "🏠", 4), ("xe", "xe", "🚗", 4), ("áo", "cái áo", "👕", 4), ("mũ", "cái mũ", "🧢", 4),
    ("cơm", "cơm", "🍚", 3), ("sữa", "sữa", "🥛", 3), ("bánh", "bánh", "🍞", 3), ("kẹo", "kẹo", "🍬", 3),
    ("nước", "nước", "💧", 3), ("trà", "trà", "🍵", 5), ("cá", "con cá", "🐟", 3),
    ("ăn", "ăn", "🍚", 3), ("uống", "uống", "🥤", 4), ("ngủ", "ngủ", "😴", 3), ("chơi", "chơi", "🎲", 3),
    ("đi", "đi", "🚶", 5), ("chạy", "chạy", "🏃", 5), ("nhảy", "nhảy", "🤸", 5), ("hát", "hát", "🎤", 4),
    ("đỏ", "màu đỏ", "🔴", 3), ("xanh", "màu xanh", "🟢", 4), ("vàng", "màu vàng", "🟡", 4), ("tím", "màu tím", "🟣", 5),
    ("một", "số một", "1", 3), ("hai", "số hai", "2", 3), ("ba", "số ba", "3", 3), ("bốn", "số bốn", "4", 4),
    ("năm", "số năm", "5", 4), ("tay", "bàn tay", "✋", 3), ("chân", "bàn chân", "🦶", 3), ("mắt", "mắt", "👁️", 3),
    ("mũi", "mũi", "👃", 3), ("miệng", "miệng", "👄", 4), ("tóc", "tóc", "💇", 4), ("tai", "tai", "👂", 3),
    ("bút", "bút", "✏️", 4), ("sách", "sách", "📖", 5), ("bảng", "bảng", "🟩", 5), ("cặp", "cặp sách", "🎒", 5),
    ("trường", "trường học", "🏫", 5), ("cô", "cô giáo", "👩‍🏫", 4), ("bạn", "bạn", "🧒", 4),
    ("mưa", "mưa", "🌧️", 4), ("nắng", "nắng", "☀️", 4), ("gió", "gió", "💨", 5), ("mây", "mây", "☁️", 4),
    ("sao", "ngôi sao", "⭐", 4), ("trăng", "mặt trăng", "🌙", 4), ("trời", "bầu trời", "🌌", 5),
    ("bàn", "cái bàn", "🪵", 4), ("ghế", "cái ghế", "🪑", 4), ("cửa", "cánh cửa", "🚪", 4), ("đèn", "cái đèn", "💡", 4),
    ("chén", "cái chén", "🥣", 4), ("đũa", "đôi đũa", "🥢", 5), ("thìa", "cái thìa", "🥄", 4), ("nồi", "cái nồi", "🍲", 5),
    ("bóng", "quả bóng", "⚽", 3), ("gấu", "gấu bông", "🧸", 3), ("búp", "búp bê", "🪆", 4), ("xe", "xe đồ chơi", "🚗", 3),
    ("táo", "quả táo", "🍎", 3), ("chuối", "quả chuối", "🍌", 3), ("cam", "quả cam", "🍊", 4), ("nho", "quả nho", "🍇", 4),
    ("dưa", "dưa hấu", "🍉", 4), ("xoài", "quả xoài", "🥭", 5), ("dâu", "quả dâu", "🍓", 4),
    ("cơm", "cơm", "🍚", 3), ("phở", "phở", "🍜", 5), ("cháo", "cháo", "🥣", 4), ("bánh mì", "bánh mì", "🥖", 4),
    ("sữa chua", "sữa chua", "🥛", 5), ("kem", "kem", "🍦", 4),
    ("yêu", "yêu", "❤️", 3), ("vui", "vui", "😊", 3), ("buồn", "buồn", "😢", 5), ("khỏe", "khỏe", "💪", 5),
    ("to", "to", "⬜", 3), ("nhỏ", "nhỏ", "◽", 3), ("cao", "cao", "📏", 5), ("thấp", "thấp", "📐", 5),
    ("ngày", "ban ngày", "🌞", 4), ("đêm", "ban đêm", "🌃", 4), ("sáng", "buổi sáng", "🌅", 5), ("tối", "buổi tối", "🌙", 5),
    ("mẹ", "mẹ", "👩", 3), ("em", "em", "👶", 3), ("cục", "cục tẩy", "🧽", 6), ("thước", "thước kẻ", "📏", 6),
    ("màu", "màu vẽ", "🎨", 5), ("giấy", "tờ giấy", "📄", 5), ("kéo", "cây kéo", "✂️", 5),
    ("sông", "sông", "🏞️", 6), ("núi", "núi", "⛰️", 6), ("biển", "biển", "🌊", 6), ("rừng", "rừng", "🌲", 6),
    ("máy bay", "máy bay", "✈️", 5), ("tàu", "tàu hỏa", "🚆", 5), ("thuyền", "thuyền", "⛵", 5),
    ("bác sĩ", "bác sĩ", "👨‍⚕️", 6), ("công an", "công an", "👮", 6), ("nông", "nông dân", "👨‍🌾", 6),
    ("chợ", "chợ", "🛒", 5), ("công viên", "công viên", "🛝", 5), ("bệnh viện", "bệnh viện", "🏥", 6),
    ("răng", "răng", "🦷", 4), ("tim", "trái tim", "❤️", 5), ("bụng", "bụng", "🫄", 4),
    ("cười", "cười", "😄", 4), ("khóc", "khóc", "😭", 4), ("ôm", "ôm", "🤗", 3),
    ("xin", "xin chào", "👋", 4), ("cảm ơn", "cảm ơn", "🙏", 4), ("xin lỗi", "xin lỗi", "🙇", 5),
    ("sạch", "sạch", "✨", 5), ("bẩn", "bẩn", "🫧", 5), ("nóng", "nóng", "🔥", 5), ("lạnh", "lạnh", "❄️", 5),
    ("nhanh", "nhanh", "⚡", 6), ("chậm", "chậm", "🐢", 6),
    ("sách vở", "sách vở", "📚", 6), ("bài tập", "bài tập", "📝", 7), ("đi học", "đi học", "🎒", 5),
    ("về nhà", "về nhà", "🏠", 4), ("ngủ ngon", "ngủ ngon", "😴", 3),
]

SENTENCES = [
    "Mẹ yêu bé.", "Ba yêu con.", "Con mèo ngủ.", "Bé ăn cơm.", "Bé uống sữa.",
    "Gà kêu ó o.", "Cá bơi dưới nước.", "Hoa rất đẹp.", "Trời đang nắng.",
    "Bé đi học.", "Cô giáo vui.", "Bạn chơi bóng.", "Nhà có cửa.",
    "Xe chạy nhanh.", "Chim bay trên trời.", "Thỏ ăn cà rốt.", "Bé rửa tay.",
    "Mẹ nấu cơm.", "Ba đọc sách.", "Em bé khóc.", "Chị hát hay.",
    "Ông kể chuyện.", "Bà nấu canh.", "Bé đánh răng.", "Trăng tròn đêm.",
    "Mưa rơi nhẹ.", "Lá xanh trên cây.", "Quả táo đỏ.", "Bé chào cô.",
    "Con yêu mẹ.", "Bé ngồi ghế.", "Sách ở trên bàn.", "Đèn sáng rồi.",
    "Chó chạy ngoài sân.", "Mèo ngồi im.", "Bé mặc áo.", "Mẹ đi chợ.",
    "Ba về nhà.", "Bé ngủ ngon.", "Hôm nay vui.", "Con cảm ơn mẹ.",
]

EXTRA_WORDS = [
    ("bánh bao", "bánh bao", "🥟", 5), ("xôi", "xôi", "🍚", 5), ("chè", "chè", "🍮", 5),
    ("canh", "canh", "🍲", 5), ("rau", "rau", "🥬", 4), ("thịt", "thịt", "🍖", 5),
    ("trứng", "trứng", "🥚", 4), ("muối", "muối", "🧂", 6), ("đường", "đường", "🍬", 5),
    ("gạo", "gạo", "🌾", 6), ("cháo gà", "cháo gà", "🥣", 5), ("súp", "súp", "🍲", 5),
    ("bánh chưng", "bánh chưng", "🟩", 6), ("tết", "tết", "🧧", 5), ("lì xì", "lì xì", "🧧", 5),
    ("bút chì", "bút chì", "✏️", 4), ("tẩy", "cục tẩy", "🧽", 5), ("hộp", "cái hộp", "📦", 4),
    ("túi", "túi", "👜", 4), ("khăn", "khăn", "🧻", 4), ("xà phòng", "xà phòng", "🧼", 5),
    ("bàn chải", "bàn chải", "🪥", 4), ("gối", "cái gối", "🛏️", 4), ("chăn", "cái chăn", "🛏️", 4),
    ("tủ", "cái tủ", "🗄️", 5), ("quạt", "cái quạt", "🪭", 5), ("máy", "máy móc", "⚙️", 6),
    ("chuông", "chuông", "🔔", 5), ("còi", "còi", "📯", 6), ("trống", "cái trống", "🥁", 5),
    ("sáo", "cây sáo", "🪈", 6), ("đàn", "cây đàn", "🎸", 6), ("nhạc", "âm nhạc", "🎵", 5),
    ("vẽ", "vẽ", "🎨", 4), ("tô", "tô màu", "🖍️", 4), ("đọc", "đọc", "📖", 5),
    ("viết", "viết", "✍️", 5), ("học", "học", "📚", 4), ("chữ", "chữ", "🔤", 4),
    ("số", "số", "🔢", 4), ("hình", "hình", "🔷", 4), ("màu sắc", "màu sắc", "🌈", 4),
    ("vàng anh", "màu vàng", "🟡", 6), ("hồng", "màu hồng", "🩷", 4), ("nâu", "màu nâu", "🟤", 5),
    ("xám", "màu xám", "⚪", 6), ("đen", "màu đen", "⚫", 4), ("trắng", "màu trắng", "⬜", 4),
    ("bốn chân", "bốn chân", "🐾", 6), ("cánh", "cánh", "🪽", 5), ("đuôi", "đuôi", "🐕", 5),
    ("sừng", "sừng", "🦌", 6), ("lông", "lông", "🪶", 5), ("vảy", "vảy", "🐟", 6),
    ("tổ", "tổ chim", "🪺", 5), ("hồ", "hồ nước", "🏞️", 5), ("suối", "suối", "💦", 6),
    ("đá", "hòn đá", "🪨", 4), ("cát", "cát", "🏖️", 5), ("sóng", "sóng", "🌊", 5),
    ("thuyền buồm", "thuyền buồm", "⛵", 6), ("cầu", "cây cầu", "🌉", 5), ("đường đi", "đường", "🛣️", 5),
    ("đèn đỏ", "đèn đỏ", "🚦", 5), ("biển báo", "biển báo", "🛑", 6), ("mũ bảo hiểm", "mũ bảo hiểm", "⛑️", 6),
    ("bác", "bác", "👨", 4), ("cậu", "cậu", "👨", 5), ("dì", "dì", "👩", 5),
    ("cô chú", "cô chú", "👨‍👩‍👧", 5), ("em bé", "em bé", "👶", 3), ("bạn thân", "bạn thân", "🤝", 5),
    ("lớp", "lớp học", "🏫", 5), ("cô hiệu", "cô hiệu trưởng", "👩‍💼", 7),
    ("sân chơi", "sân chơi", "🛝", 4), ("xích đu", "xích đu", "🎠", 4), ("cầu trượt", "cầu trượt", "🛝", 4),
    ("bóng rổ", "bóng rổ", "🏀", 6), ("bơi", "bơi", "🏊", 5), ("đá bóng", "đá bóng", "⚽", 5),
    ("nhảy dây", "nhảy dây", "🪢", 5), ("cướp cờ", "cướp cờ", "🚩", 6),
    ("chúc ngủ", "chúc ngủ ngon", "🌙", 3), ("chào buổi", "chào buổi sáng", "🌅", 5),
    ("xin chào", "xin chào", "👋", 3), ("tạm biệt", "tạm biệt", "👋", 4),
    ("làm ơn", "làm ơn", "🙏", 5), ("vâng", "vâng", "🙆", 3), ("dạ", "dạ", "🙇", 3),
]

ONSET_SOUNDS = [
    ("vi_ph", "phờ"),
    ("vi_th", "thờ"),
    ("vi_kh", "khờ"),
    ("vi_nh", "nhờ"),
    ("vi_ch", "chờ"),
    ("vi_tr", "trờ"),
    ("vi_gh", "gờ"),
    ("vi_ng", "ngờ"),
    ("vi_ngh", "nghờ"),
]

PHRASES = [("vi_phrase_gioi_lam", "Giỏi lắm", "assets/audio/vi/phrases/gioi_lam.wav")]


def slug(text: str) -> str:
    table = {
        "ă": "aw", "â": "aa", "đ": "dd", "ê": "ee", "ô": "oo", "ơ": "ow", "ư": "uw",
        "á": "as", "à": "af", "ả": "ar", "ã": "ax", "ạ": "aj",
        "ắ": "aws", "ằ": "awf", "ẳ": "awr", "ẵ": "awx", "ặ": "awj",
        "ấ": "aas", "ầ": "aaf", "ẩ": "aar", "ẫ": "aax", "ậ": "aaj",
        "é": "es", "è": "ef", "ẻ": "er", "ẽ": "ex", "ẹ": "ej",
        "ế": "ees", "ề": "eef", "ể": "eer", "ễ": "eex", "ệ": "eej",
        "í": "is", "ì": "if", "ỉ": "ir", "ĩ": "ix", "ị": "ij",
        "ó": "os", "ò": "of", "ỏ": "or", "õ": "ox", "ọ": "oj",
        "ố": "oos", "ồ": "oof", "ổ": "oor", "ỗ": "oox", "ộ": "ooj",
        "ớ": "ows", "ờ": "owf", "ở": "owr", "ỡ": "owx", "ợ": "owj",
        "ú": "us", "ù": "uf", "ủ": "ur", "ũ": "ux", "ụ": "uj",
        "ứ": "uws", "ừ": "uwf", "ử": "uwr", "ữ": "uwx", "ự": "uwj",
        "ý": "ys", "ỳ": "yf", "ỷ": "yr", "ỹ": "yx", "ỵ": "yj",
        " ": "_", "-": "_",
    }
    out = []
    for ch in text.lower():
        out.append(table.get(ch, ch if ch.isalnum() else "_"))
    value = "".join(out).strip("_")
    while "__" in value:
        value = value.replace("__", "_")
    return value or "clip"


def vi_entry(audio_id: str, text: str, asset: str) -> dict:
    return {
        "id": audio_id,
        "language": "vi",
        "text": text,
        "asset": asset,
        "source": "Piper vi_VN-vais1000-medium",
        "license": "CC BY 4.0",
        "attribution": "Voice vais1000 (Piper). Audio generated by ViMai Kids build pipeline.",
    }


def ja_entry(audio_id: str, text: str, asset: str) -> dict:
    return {
        "id": audio_id,
        "language": "ja",
        "text": text,
        "asset": asset,
        "source": "Piper Plus Tsukuyomi-chan",
        "license": "See AUDIO_LICENSES.md / tyc.rei-yumesaki.net corpus terms",
        "attribution": "Tsukuyomi-chan (夢前黎). Audio generated by ViMai Kids build pipeline.",
    }


def build_alphabet() -> list[dict]:
    items = []
    for i, (up, low, name, sound, example, group) in enumerate(LETTERS, start=1):
        slug_id = slug(low)
        items.append({
            "id": f"v_{slug_id}",
            "subject": "vietnamese",
            "ageMin": 3,
            "ageMax": 7,
            "level": 1,
            "skill": "alphabet",
            "difficulty": 1 if group == "vowel" else 2,
            "title": f"Chữ {up}",
            "instruction": f"Chữ {up}",
            "question": up,
            "answer": up,
            "metadata": {
                "uppercase": up,
                "lowercase": low,
                "letterName": name,
                "phoneme": sound,
                "audioText": name,
                "audioLocale": "vi-VN",
                "exampleWord": example,
                "group": group,
                "order": i,
                "audioNameId": f"vi_letter_{slug_id}_name",
                "audioSoundId": f"vi_letter_{slug_id}_sound",
                "audioId": f"vi_letter_{slug_id}_name",
            },
        })
    return items


def build_phonics() -> list[dict]:
    items = []
    for onset, rime, syllable in PHONICS:
        distractors = [s for _, _, s in PHONICS if s != syllable][:3]
        while len(distractors) < 3:
            distractors.append(syllable + "a")
        choices = [syllable, *distractors[:3]]
        items.append({
            "id": f"ph_{slug(syllable)}",
            "subject": "vietnamese",
            "ageMin": 3 if len(onset) == 1 else 5,
            "ageMax": 7,
            "level": 5,
            "skill": "blending",
            "difficulty": 1 if len(onset) == 1 else 2,
            "title": "Ghép âm",
            "instruction": f"{onset} + {rime} = ?",
            "question": f"{onset} + {rime}",
            "answer": syllable,
            "choices": choices,
            "metadata": {
                "onset": onset,
                "rime": rime,
                "syllable": syllable,
                "audioText": syllable,
                "audioLocale": "vi-VN",
                "audioId": f"vi_phonics_{slug(syllable)}",
            },
        })
    return items


def build_rimes() -> list[dict]:
    items = []
    onsets = ["b", "c", "m", "n", "t", "h", "l"]
    for i, rime in enumerate(RIMES):
        onset = onsets[i % len(onsets)]
        answer = f"{onset}{rime}"
        others = [f"{onsets[(i + k) % len(onsets)]}{rime}" for k in range(1, 4)]
        items.append({
            "id": f"r_{slug(rime)}",
            "subject": "vietnamese",
            "ageMin": 5 if i < 40 else 6,
            "ageMax": 7,
            "level": 6,
            "skill": "rime",
            "difficulty": 2 if i < 40 else 3,
            "title": "Ghép vần",
            "instruction": f"Vần nào đúng: {onset} + {rime}",
            "question": f"{onset} + {rime}",
            "answer": answer,
            "choices": [answer, *others],
            "metadata": {
                "audioText": answer,
                "audioLocale": "vi-VN",
                "rime": rime,
                "audioId": f"vi_rime_{slug(rime)}",
            },
        })
    return items


def build_words() -> list[dict]:
    seen = set()
    items = []
    for text, meaning, image, age in [*WORDS, *EXTRA_WORDS]:
        key = text
        if key in seen:
            continue
        seen.add(key)
        distractors = [w[0] for w in WORDS if w[0] != text][:3]
        items.append({
            "id": f"w_{slug(text)}",
            "subject": "vietnamese",
            "ageMin": age,
            "ageMax": 7,
            "level": 6,
            "skill": "words",
            "difficulty": 1 if age <= 4 else 2,
            "title": "Từ đơn",
            "instruction": "Đọc từ này",
            "question": text,
            "answer": text,
            "choices": [text, *distractors],
            "tags": ["vietnamese", "word"],
            "metadata": {
                "meaning": meaning,
                "image": image,
                "audioText": text,
                "audioLocale": "vi-VN",
                "audioId": f"vi_word_{slug(text)}",
            },
        })
    return items


def build_sentences() -> list[dict]:
    items = []
    for i, text in enumerate(SENTENCES, start=1):
        items.append({
            "id": f"s_{i:03d}",
            "subject": "vietnamese",
            "ageMin": 4 if i < 25 else 6,
            "ageMax": 7,
            "level": 7,
            "skill": "sentence",
            "difficulty": 2,
            "title": "Câu ngắn",
            "instruction": "Đọc câu này",
            "question": text,
            "answer": text,
            "metadata": {
                "audioText": text,
                "audioLocale": "vi-VN",
                "audioId": f"vi_sentence_{i:03d}",
            },
        })
    return items


def japanese_jobs() -> list[dict]:
    jobs = []
    kana_dir = ROOT / "assets" / "content" / "japanese" / "kana"
    for path in sorted(kana_dir.glob("*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        rows = data if isinstance(data, list) else data.get("items") or data.get("kana") or []
        for item in rows:
            if not isinstance(item, dict):
                continue
            kid = item.get("id")
            ch = item.get("character")
            if not kid or not ch:
                continue
            audio_id = f"ja_{kid}"
            jobs.append(ja_entry(audio_id, ch, f"assets/audio/ja/kana/{kid}.wav"))
            example = (item.get("exampleWord") or "").strip()
            if example and example != ch:
                jobs.append(ja_entry(f"ja_{kid}_example", example, f"assets/audio/ja/examples/{kid}.wav"))
    return jobs


def all_jobs() -> list[dict]:
    jobs = []
    for up, low, name, sound, _ex, _g in LETTERS:
        s = slug(low)
        jobs.append(vi_entry(f"vi_letter_{s}_name", name, f"assets/audio/vi/letters/{s}_name.wav"))
        jobs.append(vi_entry(f"vi_letter_{s}_sound", sound, f"assets/audio/vi/letters/{s}_sound.wav"))
    for _o, _r, syllable in PHONICS:
        jobs.append(vi_entry(f"vi_phonics_{slug(syllable)}", syllable, f"assets/audio/vi/phonics/{slug(syllable)}.wav"))
    for rime in RIMES:
        onset = "b"
        jobs.append(vi_entry(f"vi_rime_{slug(rime)}", f"{onset}{rime}", f"assets/audio/vi/rimes/{slug(rime)}.wav"))
    seen = set()
    for text, *_rest in [*WORDS, *EXTRA_WORDS]:
        if text in seen:
            continue
        seen.add(text)
        jobs.append(vi_entry(f"vi_word_{slug(text)}", text, f"assets/audio/vi/words/{slug(text)}.wav"))
    for i, text in enumerate(SENTENCES, start=1):
        jobs.append(vi_entry(f"vi_sentence_{i:03d}", text, f"assets/audio/vi/sentences/s_{i:03d}.wav"))
    for audio_id, text, asset in PHRASES:
        jobs.append(vi_entry(audio_id, text, asset))
    for audio_id, spoken in ONSET_SOUNDS:
        jobs.append(vi_entry(audio_id, spoken, f"assets/audio/vi/phonics/{audio_id}.wav"))
    jobs.extend(japanese_jobs())
    unique: dict[str, dict] = {}
    for job in jobs:
        if job["id"] in unique:
            continue
        unique[job["id"]] = job
    return list(unique.values())


def write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    vn = ROOT / "assets" / "content" / "vietnamese"
    write_json(vn / "alphabet.json", build_alphabet())
    write_json(vn / "phonics.json", build_phonics())
    write_json(vn / "rimes.json", build_rimes())
    write_json(vn / "words.json", build_words())
    write_json(vn / "vocabulary.json", build_words()[:40])
    write_json(vn / "sentences.json", build_sentences())
    jobs = all_jobs()
    write_json(ROOT / "assets" / "audio" / "audio_jobs.json", jobs)
    print("letters", len(build_alphabet()))
    print("phonics", len(build_phonics()))
    print("rimes", len(build_rimes()))
    print("words", len(build_words()))
    print("sentences", len(build_sentences()))
    print("audio_jobs", len(jobs))


if __name__ == "__main__":
    main()
