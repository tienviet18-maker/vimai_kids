import '../../domain/models/kana_item.dart';

final List<KanaItem> katakanaData = [
  // Basic
  const KanaItem(id: 'k_a', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ア', romaji: 'a', pronunciation: 'a', strokeCount: 2, exampleWord: 'アイス', exampleMeaningVietnamese: 'kem', exampleWordAudioId: 'ja_word_aisu'),
  const KanaItem(id: 'k_i', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'イ', romaji: 'i', pronunciation: 'i', strokeCount: 2, exampleWord: 'イルカ', exampleMeaningVietnamese: 'cá heo', exampleWordAudioId: 'ja_word_iruka'),
  const KanaItem(id: 'k_u', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ウ', romaji: 'u', pronunciation: 'u', strokeCount: 3, exampleWord: 'ウェブ', exampleMeaningVietnamese: 'web', exampleWordAudioId: 'ja_word_uebbu'),
  const KanaItem(id: 'k_e', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'エ', romaji: 'e', pronunciation: 'e', strokeCount: 3, exampleWord: 'エレベーター', exampleMeaningVietnamese: 'thang máy', exampleWordAudioId: 'ja_word_erebeetaa'),
  const KanaItem(id: 'k_o', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'オ', romaji: 'o', pronunciation: 'o', strokeCount: 3, exampleWord: 'オレンジ', exampleMeaningVietnamese: 'quả cam', exampleWordAudioId: 'ja_word_orenji'),
  
  const KanaItem(id: 'k_ka', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'カ', romaji: 'ka', pronunciation: 'ka', strokeCount: 2, exampleWord: 'カメラ', exampleMeaningVietnamese: 'máy ảnh', exampleWordAudioId: 'ja_word_kamera'),
  const KanaItem(id: 'k_ki', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'キ', romaji: 'ki', pronunciation: 'ki', strokeCount: 3, exampleWord: 'キウイ', exampleMeaningVietnamese: 'quả kiwi', exampleWordAudioId: 'ja_word_kiui'),
  const KanaItem(id: 'k_ku', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ク', romaji: 'ku', pronunciation: 'ku', strokeCount: 2, exampleWord: 'クリーム', exampleMeaningVietnamese: 'kem', exampleWordAudioId: 'ja_word_kuriimu'),
  const KanaItem(id: 'k_ke', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ケ', romaji: 'ke', pronunciation: 'ke', strokeCount: 3, exampleWord: 'ケーキ', exampleMeaningVietnamese: 'bánh ngọt', exampleWordAudioId: 'ja_word_keeki'),
  const KanaItem(id: 'k_ko', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'コ', romaji: 'ko', pronunciation: 'ko', strokeCount: 2, exampleWord: 'コーヒー', exampleMeaningVietnamese: 'cà phê', exampleWordAudioId: 'ja_word_koohii'),

  const KanaItem(id: 'k_sa', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'サ', romaji: 'sa', pronunciation: 'sa', strokeCount: 3, exampleWord: 'サッカー', exampleMeaningVietnamese: 'bóng đá', exampleWordAudioId: 'ja_word_sakkaa'),
  const KanaItem(id: 'k_shi', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'シ', romaji: 'shi', pronunciation: 'shi', strokeCount: 3, confusionGroup: ['ツ'], exampleWord: 'シャツ', exampleMeaningVietnamese: 'áo sơ mi', exampleWordAudioId: 'ja_word_shatsu'),
  const KanaItem(id: 'k_su', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ス', romaji: 'su', pronunciation: 'su', strokeCount: 2, exampleWord: 'スーツ', exampleMeaningVietnamese: 'vest', exampleWordAudioId: 'ja_word_suutsu'),
  const KanaItem(id: 'k_se', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'セ', romaji: 'se', pronunciation: 'se', strokeCount: 2, exampleWord: 'セーター', exampleMeaningVietnamese: 'áo len', exampleWordAudioId: 'ja_word_seetaa'),
  const KanaItem(id: 'k_so', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ソ', romaji: 'so', pronunciation: 'so', strokeCount: 2, confusionGroup: ['ン'], exampleWord: 'ソーセージ', exampleMeaningVietnamese: 'xúc xích', exampleWordAudioId: 'ja_word_sooseeji'),

  const KanaItem(id: 'k_ta', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'タ', romaji: 'ta', pronunciation: 'ta', strokeCount: 3, exampleWord: 'タオル', exampleMeaningVietnamese: 'khăn tắm', exampleWordAudioId: 'ja_word_taoru'),
  const KanaItem(id: 'k_chi', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'チ', romaji: 'chi', pronunciation: 'chi', strokeCount: 3, exampleWord: 'チーズ', exampleMeaningVietnamese: 'phô mai', exampleWordAudioId: 'ja_word_chiizu'),
  const KanaItem(id: 'k_tsu', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ツ', romaji: 'tsu', pronunciation: 'tsu', strokeCount: 3, confusionGroup: ['シ'], exampleWord: 'ツアー', exampleMeaningVietnamese: 'tour', exampleWordAudioId: 'ja_word_tsuaa'),
  const KanaItem(id: 'k_te', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'テ', romaji: 'te', pronunciation: 'te', strokeCount: 3, exampleWord: 'テレビ', exampleMeaningVietnamese: 'tivi', exampleWordAudioId: 'ja_word_terebi'),
  const KanaItem(id: 'k_to', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ト', romaji: 'to', pronunciation: 'to', strokeCount: 2, exampleWord: 'トマト', exampleMeaningVietnamese: 'cà chua', exampleWordAudioId: 'ja_word_tomato'),

  const KanaItem(id: 'k_na', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ナ', romaji: 'na', pronunciation: 'na', strokeCount: 2, exampleWord: 'ナイフ', exampleMeaningVietnamese: 'con dao', exampleWordAudioId: 'ja_word_naifu'),
  const KanaItem(id: 'k_ni', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ニ', romaji: 'ni', pronunciation: 'ni', strokeCount: 2, exampleWord: 'ニュース', exampleMeaningVietnamese: 'tin tức', exampleWordAudioId: 'ja_word_nyuusu'),
  const KanaItem(id: 'k_nu', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ヌ', romaji: 'nu', pronunciation: 'nu', strokeCount: 2),
  const KanaItem(id: 'k_ne', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ネ', romaji: 'ne', pronunciation: 'ne', strokeCount: 4),
  const KanaItem(id: 'k_no', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ノ', romaji: 'no', pronunciation: 'no', strokeCount: 1, exampleWord: 'ノード', exampleMeaningVietnamese: 'node', exampleWordAudioId: 'ja_word_noodo'),

  const KanaItem(id: 'k_ha', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ハ', romaji: 'ha', pronunciation: 'ha', strokeCount: 2, exampleWord: 'ハム', exampleMeaningVietnamese: 'thịt nguội', exampleWordAudioId: 'ja_word_hamu'),
  const KanaItem(id: 'k_hi', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ヒ', romaji: 'hi', pronunciation: 'hi', strokeCount: 2, exampleWord: 'ヒーター', exampleMeaningVietnamese: 'máy sưởi', exampleWordAudioId: 'ja_word_hiitaa'),
  const KanaItem(id: 'k_fu', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'フ', romaji: 'fu', pronunciation: 'fu', strokeCount: 1, exampleWord: 'フォーク', exampleMeaningVietnamese: 'cái nĩa', exampleWordAudioId: 'ja_word_fooku'),
  const KanaItem(id: 'k_he', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ヘ', romaji: 'he', pronunciation: 'he', strokeCount: 1, exampleWord: 'ヘリコプター', exampleMeaningVietnamese: 'trực thăng', exampleWordAudioId: 'ja_word_herikoputaa'),
  const KanaItem(id: 'k_ho', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ホ', romaji: 'ho', pronunciation: 'ho', strokeCount: 4, exampleWord: 'ホテル', exampleMeaningVietnamese: 'khách sạn', exampleWordAudioId: 'ja_word_hoteru'),

  const KanaItem(id: 'k_ma', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'マ', romaji: 'ma', pronunciation: 'ma', strokeCount: 2, exampleWord: 'マイク', exampleMeaningVietnamese: 'micro', exampleWordAudioId: 'ja_word_maiku'),
  const KanaItem(id: 'k_mi', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ミ', romaji: 'mi', pronunciation: 'mi', strokeCount: 3, exampleWord: 'ミルク', exampleMeaningVietnamese: 'sữa', exampleWordAudioId: 'ja_word_miruku'),
  const KanaItem(id: 'k_mu', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ム', romaji: 'mu', pronunciation: 'mu', strokeCount: 2),
  const KanaItem(id: 'k_me', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'メ', romaji: 'me', pronunciation: 'me', strokeCount: 2, exampleWord: 'メロン', exampleMeaningVietnamese: 'dưa lưới', exampleWordAudioId: 'ja_word_meron'),
  const KanaItem(id: 'k_mo', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'モ', romaji: 'mo', pronunciation: 'mo', strokeCount: 3, exampleWord: 'モーター', exampleMeaningVietnamese: 'mô tơ', exampleWordAudioId: 'ja_word_motaa'),

  const KanaItem(id: 'k_ya', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ヤ', romaji: 'ya', pronunciation: 'ya', strokeCount: 2),
  const KanaItem(id: 'k_yu', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ユ', romaji: 'yu', pronunciation: 'yu', strokeCount: 2),
  const KanaItem(id: 'k_yo', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ヨ', romaji: 'yo', pronunciation: 'yo', strokeCount: 3, exampleWord: 'ヨット', exampleMeaningVietnamese: 'du thuyền', exampleWordAudioId: 'ja_word_yotto'),

  const KanaItem(id: 'k_ra', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ラ', romaji: 'ra', pronunciation: 'ra', strokeCount: 2, exampleWord: 'ラジオ', exampleMeaningVietnamese: 'radio', exampleWordAudioId: 'ja_word_rajio'),
  const KanaItem(id: 'k_ri', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'リ', romaji: 'ri', pronunciation: 'ri', strokeCount: 2, exampleWord: 'リボン', exampleMeaningVietnamese: 'ruy băng', exampleWordAudioId: 'ja_word_ribon'),
  const KanaItem(id: 'k_ru', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ル', romaji: 'ru', pronunciation: 'ru', strokeCount: 2, exampleWord: 'ルビー', exampleMeaningVietnamese: 'ruby', exampleWordAudioId: 'ja_word_ruubii'),
  const KanaItem(id: 'k_re', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'レ', romaji: 're', pronunciation: 're', strokeCount: 1, exampleWord: 'レモン', exampleMeaningVietnamese: 'chanh', exampleWordAudioId: 'ja_word_remon'),
  const KanaItem(id: 'k_ro', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ロ', romaji: 'ro', pronunciation: 'ro', strokeCount: 3, exampleWord: 'ロケット', exampleMeaningVietnamese: 'tên lửa', exampleWordAudioId: 'ja_word_oketto'),

  const KanaItem(id: 'k_wa', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ワ', romaji: 'wa', pronunciation: 'wa', strokeCount: 2, exampleWord: 'ワイン', exampleMeaningVietnamese: 'rượu vang', exampleWordAudioId: 'ja_word_wain'),
  const KanaItem(id: 'k_wo', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ヲ', romaji: 'wo', pronunciation: 'o', strokeCount: 3),
  const KanaItem(id: 'k_n', script: KanaScript.katakana, kanaType: KanaType.basic, character: 'ン', romaji: 'n', pronunciation: 'n', strokeCount: 2, confusionGroup: ['ソ']),

  // Dakuten
  const KanaItem(id: 'k_ga', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ガ', romaji: 'ga', pronunciation: 'ga'),
  const KanaItem(id: 'k_gi', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ギ', romaji: 'gi', pronunciation: 'gi'),
  const KanaItem(id: 'k_gu', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'グ', romaji: 'gu', pronunciation: 'gu'),
  const KanaItem(id: 'k_ge', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ゲ', romaji: 'ge', pronunciation: 'ge'),
  const KanaItem(id: 'k_go', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ゴ', romaji: 'go', pronunciation: 'go'),

  const KanaItem(id: 'k_za', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ザ', romaji: 'za', pronunciation: 'za'),
  const KanaItem(id: 'k_ji', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ジ', romaji: 'ji', pronunciation: 'ji'),
  const KanaItem(id: 'k_zu', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ズ', romaji: 'zu', pronunciation: 'zu'),
  const KanaItem(id: 'k_ze', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ゼ', romaji: 'ze', pronunciation: 'ze'),
  const KanaItem(id: 'k_zo', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ゾ', romaji: 'zo', pronunciation: 'zo'),

  const KanaItem(id: 'k_da', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ダ', romaji: 'da', pronunciation: 'da'),
  const KanaItem(id: 'k_dji', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ヂ', romaji: 'ji', pronunciation: 'ji'),
  const KanaItem(id: 'k_dzu', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ヅ', romaji: 'zu', pronunciation: 'zu'),
  const KanaItem(id: 'k_de', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'デ', romaji: 'de', pronunciation: 'de'),
  const KanaItem(id: 'k_do', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ド', romaji: 'do', pronunciation: 'do'),

  const KanaItem(id: 'k_ba', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'バ', romaji: 'ba', pronunciation: 'ba'),
  const KanaItem(id: 'k_bi', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ビ', romaji: 'bi', pronunciation: 'bi'),
  const KanaItem(id: 'k_bu', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ブ', romaji: 'bu', pronunciation: 'bu'),
  const KanaItem(id: 'k_be', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ベ', romaji: 'be', pronunciation: 'be'),
  const KanaItem(id: 'k_bo', script: KanaScript.katakana, kanaType: KanaType.dakuten, character: 'ボ', romaji: 'bo', pronunciation: 'bo'),

  // Handakuten
  const KanaItem(id: 'k_pa', script: KanaScript.katakana, kanaType: KanaType.handakuten, character: 'パ', romaji: 'pa', pronunciation: 'pa'),
  const KanaItem(id: 'k_pi', script: KanaScript.katakana, kanaType: KanaType.handakuten, character: 'ピ', romaji: 'pi', pronunciation: 'pi'),
  const KanaItem(id: 'k_pu', script: KanaScript.katakana, kanaType: KanaType.handakuten, character: 'プ', romaji: 'pu', pronunciation: 'pu'),
  const KanaItem(id: 'k_pe', script: KanaScript.katakana, kanaType: KanaType.handakuten, character: 'ペ', romaji: 'pe', pronunciation: 'pe'),
  const KanaItem(id: 'k_po', script: KanaScript.katakana, kanaType: KanaType.handakuten, character: 'ポ', romaji: 'po', pronunciation: 'po'),

  // Yoon (Contracted)
  const KanaItem(id: 'k_kya', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'キャ', romaji: 'kya', pronunciation: 'kya'),
  const KanaItem(id: 'k_kyu', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'キュ', romaji: 'kyu', pronunciation: 'kyu'),
  const KanaItem(id: 'k_kyo', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'キョ', romaji: 'kyo', pronunciation: 'kyo'),
  
  const KanaItem(id: 'k_sha', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'シャ', romaji: 'sha', pronunciation: 'sha'),
  const KanaItem(id: 'k_shu', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'シュ', romaji: 'shu', pronunciation: 'shu'),
  const KanaItem(id: 'k_sho', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ショ', romaji: 'sho', pronunciation: 'sho'),

  const KanaItem(id: 'k_cha', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'チャ', romaji: 'cha', pronunciation: 'cha'),
  const KanaItem(id: 'k_chu', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'チュ', romaji: 'chu', pronunciation: 'chu'),
  const KanaItem(id: 'k_cho', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'チョ', romaji: 'cho', pronunciation: 'cho'),

  const KanaItem(id: 'k_nya', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ニャ', romaji: 'nya', pronunciation: 'nya'),
  const KanaItem(id: 'k_nyu', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ニュ', romaji: 'nyu', pronunciation: 'nyu'),
  const KanaItem(id: 'k_nyo', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ニョ', romaji: 'nyo', pronunciation: 'nyo'),

  const KanaItem(id: 'k_hya', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ヒャ', romaji: 'hya', pronunciation: 'hya'),
  const KanaItem(id: 'k_hyu', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ヒュ', romaji: 'hyu', pronunciation: 'hyu'),
  const KanaItem(id: 'k_hyo', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ヒョ', romaji: 'hyo', pronunciation: 'hyo'),

  const KanaItem(id: 'k_mya', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ミャ', romaji: 'mya', pronunciation: 'mya'),
  const KanaItem(id: 'k_myu', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ミュ', romaji: 'myu', pronunciation: 'myu'),
  const KanaItem(id: 'k_myo', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ミョ', romaji: 'myo', pronunciation: 'myo'),

  const KanaItem(id: 'k_rya', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'リャ', romaji: 'rya', pronunciation: 'rya'),
  const KanaItem(id: 'k_ryu', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'リュ', romaji: 'ryu', pronunciation: 'ryu'),
  const KanaItem(id: 'k_ryo', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'リョ', romaji: 'ryo', pronunciation: 'ryo'),

  const KanaItem(id: 'k_gya', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ギャ', romaji: 'gya', pronunciation: 'gya'),
  const KanaItem(id: 'k_gyu', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ギュ', romaji: 'gyu', pronunciation: 'gyu'),
  const KanaItem(id: 'k_gyo', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ギョ', romaji: 'gyo', pronunciation: 'gyo'),

  const KanaItem(id: 'k_ja', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ジャ', romaji: 'ja', pronunciation: 'ja'),
  const KanaItem(id: 'k_ju', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ジュ', romaji: 'ju', pronunciation: 'ju'),
  const KanaItem(id: 'k_jo', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ジョ', romaji: 'jo', pronunciation: 'jo'),

  const KanaItem(id: 'k_bya', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ビャ', romaji: 'bya', pronunciation: 'bya'),
  const KanaItem(id: 'k_byu', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ビュ', romaji: 'byu', pronunciation: 'byu'),
  const KanaItem(id: 'k_byo', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ビョ', romaji: 'byo', pronunciation: 'byo'),

  const KanaItem(id: 'k_pya', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ピャ', romaji: 'pya', pronunciation: 'pya'),
  const KanaItem(id: 'k_pyu', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ピュ', romaji: 'pyu', pronunciation: 'pyu'),
  const KanaItem(id: 'k_pyo', script: KanaScript.katakana, kanaType: KanaType.yoon, character: 'ピョ', romaji: 'pyo', pronunciation: 'pyo'),

  // Small Kana
  const KanaItem(id: 'k_small_a', script: KanaScript.katakana, kanaType: KanaType.small, character: 'ァ', romaji: 'a', pronunciation: 'a'),
  const KanaItem(id: 'k_small_i', script: KanaScript.katakana, kanaType: KanaType.small, character: 'ィ', romaji: 'i', pronunciation: 'i'),
  const KanaItem(id: 'k_small_u', script: KanaScript.katakana, kanaType: KanaType.small, character: 'ゥ', romaji: 'u', pronunciation: 'u'),
  const KanaItem(id: 'k_small_e', script: KanaScript.katakana, kanaType: KanaType.small, character: 'ェ', romaji: 'e', pronunciation: 'e'),
  const KanaItem(id: 'k_small_o', script: KanaScript.katakana, kanaType: KanaType.small, character: 'ォ', romaji: 'o', pronunciation: 'o'),
  const KanaItem(id: 'k_small_ya', script: KanaScript.katakana, kanaType: KanaType.small, character: 'ャ', romaji: 'ya', pronunciation: 'ya'),
  const KanaItem(id: 'k_small_yu', script: KanaScript.katakana, kanaType: KanaType.small, character: 'ュ', romaji: 'yu', pronunciation: 'yu'),
  const KanaItem(id: 'k_small_yo', script: KanaScript.katakana, kanaType: KanaType.small, character: 'ョ', romaji: 'yo', pronunciation: 'yo'),

  // Sokuon & Choonpu
  const KanaItem(id: 'k_sokuon', script: KanaScript.katakana, kanaType: KanaType.sokuon, character: 'ッ', romaji: '(tsu)', pronunciation: ''),
  const KanaItem(id: 'k_choonpu', script: KanaScript.katakana, kanaType: KanaType.choon, character: 'ー', romaji: '-', pronunciation: ''),

  // Extended (Common Foreign)
  const KanaItem(id: 'k_fa', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'ファ', romaji: 'fa', pronunciation: 'fa'),
  const KanaItem(id: 'k_fi', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'フィ', romaji: 'fi', pronunciation: 'fi'),
  const KanaItem(id: 'k_fe', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'フェ', romaji: 'fe', pronunciation: 'fe'),
  const KanaItem(id: 'k_fo', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'フォ', romaji: 'fo', pronunciation: 'fo'),
  const KanaItem(id: 'k_ti', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'ティ', romaji: 'ti', pronunciation: 'ti'),
  const KanaItem(id: 'k_di', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'ディ', romaji: 'di', pronunciation: 'di'),
  const KanaItem(id: 'k_che', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'チェ', romaji: 'che', pronunciation: 'che'),
  const KanaItem(id: 'k_je', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'ジェ', romaji: 'je', pronunciation: 'je'),
  const KanaItem(id: 'k_wi', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'ウィ', romaji: 'wi', pronunciation: 'wi', ageMin: 6, difficulty: 3),
  const KanaItem(id: 'k_we', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'ウェ', romaji: 'we', pronunciation: 'we', ageMin: 6, difficulty: 3),
  const KanaItem(id: 'k_wo_ex', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'ウォ', romaji: 'wo', pronunciation: 'wo', ageMin: 6, difficulty: 3),
  const KanaItem(id: 'k_she', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'シェ', romaji: 'she', pronunciation: 'she', ageMin: 6, difficulty: 3),
  const KanaItem(id: 'k_tsa', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'ツァ', romaji: 'tsa', pronunciation: 'tsa', ageMin: 6, difficulty: 3),
  const KanaItem(id: 'k_tsi', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'ツィ', romaji: 'tsi', pronunciation: 'tsi', ageMin: 6, difficulty: 3),
  const KanaItem(id: 'k_tse', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'ツェ', romaji: 'tse', pronunciation: 'tse', ageMin: 6, difficulty: 3),
  const KanaItem(id: 'k_tso', script: KanaScript.katakana, kanaType: KanaType.extended, character: 'ツォ', romaji: 'tso', pronunciation: 'tso', ageMin: 6, difficulty: 3),
];
