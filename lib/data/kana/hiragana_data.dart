import '../../domain/models/kana_item.dart';

final List<KanaItem> hiraganaData = [
  // Basic
  const KanaItem(id: 'h_a', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'あ', romaji: 'a', pronunciation: 'a', strokeCount: 3, exampleWord: 'あり', exampleMeaningVietnamese: 'kiến', exampleWordAudioId: 'ja_word_ari'),
  const KanaItem(id: 'h_i', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'い', romaji: 'i', pronunciation: 'i', strokeCount: 2, exampleWord: 'いぬ', exampleMeaningVietnamese: 'con chó', exampleWordAudioId: 'ja_word_inu'),
  const KanaItem(id: 'h_u', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'う', romaji: 'u', pronunciation: 'u', strokeCount: 2, exampleWord: 'うし', exampleMeaningVietnamese: 'con bò', exampleWordAudioId: 'ja_word_ushi'),
  const KanaItem(id: 'h_e', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'え', romaji: 'e', pronunciation: 'e', strokeCount: 2, exampleWord: 'えき', exampleMeaningVietnamese: 'nhà ga', exampleWordAudioId: 'ja_word_eki'),
  const KanaItem(id: 'h_o', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'お', romaji: 'o', pronunciation: 'o', strokeCount: 3, exampleWord: 'おに', exampleMeaningVietnamese: 'yêu tinh', exampleWordAudioId: 'ja_word_oni'),
  
  const KanaItem(id: 'h_ka', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'か', romaji: 'ka', pronunciation: 'ka', strokeCount: 3, exampleWord: 'かさ', exampleMeaningVietnamese: 'cái ô', exampleWordAudioId: 'ja_word_kasa'),
  const KanaItem(id: 'h_ki', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'き', romaji: 'ki', pronunciation: 'ki', strokeCount: 4, confusionGroup: ['さ'], exampleWord: 'きく', exampleMeaningVietnamese: 'hoa cúc', exampleWordAudioId: 'ja_word_kiku'),
  const KanaItem(id: 'h_ku', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'く', romaji: 'ku', pronunciation: 'ku', strokeCount: 1, exampleWord: 'くま', exampleMeaningVietnamese: 'con gấu', exampleWordAudioId: 'ja_word_kuma'),
  const KanaItem(id: 'h_ke', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'け', romaji: 'ke', pronunciation: 'ke', strokeCount: 3, exampleWord: 'けいと', exampleMeaningVietnamese: 'cuộn len', exampleWordAudioId: 'ja_word_keito'),
  const KanaItem(id: 'h_ko', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'こ', romaji: 'ko', pronunciation: 'ko', strokeCount: 2, exampleWord: 'こま', exampleMeaningVietnamese: 'con quay', exampleWordAudioId: 'ja_word_koma'),

  const KanaItem(id: 'h_sa', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'さ', romaji: 'sa', pronunciation: 'sa', strokeCount: 3, confusionGroup: ['き'], exampleWord: 'さくら', exampleMeaningVietnamese: 'hoa anh đào', exampleWordAudioId: 'ja_word_sakura'),
  const KanaItem(id: 'h_shi', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'し', romaji: 'shi', pronunciation: 'shi', strokeCount: 1, exampleWord: 'しか', exampleMeaningVietnamese: 'con nai', exampleWordAudioId: 'ja_word_shika'),
  const KanaItem(id: 'h_su', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'す', romaji: 'su', pronunciation: 'su', strokeCount: 2, exampleWord: 'すいか', exampleMeaningVietnamese: 'dưa hấu', exampleWordAudioId: 'ja_word_suika'),
  const KanaItem(id: 'h_se', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'せ', romaji: 'se', pronunciation: 'se', strokeCount: 3, exampleWord: 'せみ', exampleMeaningVietnamese: 'con ve', exampleWordAudioId: 'ja_word_semi'),
  const KanaItem(id: 'h_so', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'そ', romaji: 'so', pronunciation: 'so', strokeCount: 1, exampleWord: 'そら', exampleMeaningVietnamese: 'bầu trời', exampleWordAudioId: 'ja_word_sora'),

  const KanaItem(id: 'h_ta', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'た', romaji: 'ta', pronunciation: 'ta', strokeCount: 4, exampleWord: 'たこ', exampleMeaningVietnamese: 'bạch tuộc', exampleWordAudioId: 'ja_word_tako'),
  const KanaItem(id: 'h_chi', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'ち', romaji: 'chi', pronunciation: 'chi', strokeCount: 2, exampleWord: 'ちず', exampleMeaningVietnamese: 'bản đồ', exampleWordAudioId: 'ja_word_chizu'),
  const KanaItem(id: 'h_tsu', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'つ', romaji: 'tsu', pronunciation: 'tsu', strokeCount: 1, exampleWord: 'つき', exampleMeaningVietnamese: 'mặt trăng', exampleWordAudioId: 'ja_word_tsuki'),
  const KanaItem(id: 'h_te', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'て', romaji: 'te', pronunciation: 'te', strokeCount: 1, exampleWord: 'て', exampleMeaningVietnamese: 'bàn tay', exampleWordAudioId: 'ja_word_te'),
  const KanaItem(id: 'h_to', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'と', romaji: 'to', pronunciation: 'to', strokeCount: 2, exampleWord: 'とけい', exampleMeaningVietnamese: 'đồng hồ', exampleWordAudioId: 'ja_word_tokei'),

  const KanaItem(id: 'h_na', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'な', romaji: 'na', pronunciation: 'na', strokeCount: 4, exampleWord: 'なつ', exampleMeaningVietnamese: 'mùa hè', exampleWordAudioId: 'ja_word_natsu'),
  const KanaItem(id: 'h_ni', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'に', romaji: 'ni', pronunciation: 'ni', strokeCount: 3, exampleWord: 'にじ', exampleMeaningVietnamese: 'cầu vồng', exampleWordAudioId: 'ja_word_niji'),
  const KanaItem(id: 'h_nu', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'ぬ', romaji: 'nu', pronunciation: 'nu', strokeCount: 2, confusionGroup: ['め'], exampleWord: 'ぬの', exampleMeaningVietnamese: 'vải', exampleWordAudioId: 'ja_word_nuno'),
  const KanaItem(id: 'h_ne', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'ね', romaji: 'ne', pronunciation: 'ne', strokeCount: 2, confusionGroup: ['れ', 'わ'], exampleWord: 'ねこ', exampleMeaningVietnamese: 'con mèo', exampleWordAudioId: 'ja_word_neko'),
  const KanaItem(id: 'h_no', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'の', romaji: 'no', pronunciation: 'no', strokeCount: 1, exampleWord: 'のり', exampleMeaningVietnamese: 'rong biển', exampleWordAudioId: 'ja_word_nori'),

  const KanaItem(id: 'h_ha', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'は', romaji: 'ha', pronunciation: 'ha', strokeCount: 3, exampleWord: 'はな', exampleMeaningVietnamese: 'bông hoa', exampleWordAudioId: 'ja_word_hana'),
  const KanaItem(id: 'h_hi', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'ひ', romaji: 'hi', pronunciation: 'hi', strokeCount: 1, exampleWord: 'ひこうき', exampleMeaningVietnamese: 'máy bay', exampleWordAudioId: 'ja_word_hikouki'),
  const KanaItem(id: 'h_fu', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'ふ', romaji: 'fu', pronunciation: 'fu', strokeCount: 4, exampleWord: 'ふね', exampleMeaningVietnamese: 'con tàu', exampleWordAudioId: 'ja_word_fune'),
  const KanaItem(id: 'h_he', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'へ', romaji: 'he', pronunciation: 'he', strokeCount: 1, exampleWord: 'へび', exampleMeaningVietnamese: 'con rắn', exampleWordAudioId: 'ja_word_hebi'),
  const KanaItem(id: 'h_ho', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'ほ', romaji: 'ho', pronunciation: 'ho', strokeCount: 4, exampleWord: 'ほし', exampleMeaningVietnamese: 'ngôi sao', exampleWordAudioId: 'ja_word_hoshi'),

  const KanaItem(id: 'h_ma', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'ま', romaji: 'ma', pronunciation: 'ma', strokeCount: 3, exampleWord: 'まど', exampleMeaningVietnamese: 'cửa sổ', exampleWordAudioId: 'ja_word_mado'),
  const KanaItem(id: 'h_mi', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'み', romaji: 'mi', pronunciation: 'mi', strokeCount: 2, exampleWord: 'みかん', exampleMeaningVietnamese: 'quả quýt', exampleWordAudioId: 'ja_word_mikan'),
  const KanaItem(id: 'h_mu', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'む', romaji: 'mu', pronunciation: 'mu', strokeCount: 3, exampleWord: 'むし', exampleMeaningVietnamese: 'côn trùng', exampleWordAudioId: 'ja_word_mushi'),
  const KanaItem(id: 'h_me', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'め', romaji: 'me', pronunciation: 'me', strokeCount: 2, confusionGroup: ['ぬ'], exampleWord: 'めがね', exampleMeaningVietnamese: 'mắt kính', exampleWordAudioId: 'ja_word_megane'),
  const KanaItem(id: 'h_mo', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'も', romaji: 'mo', pronunciation: 'mo', strokeCount: 3, exampleWord: 'もも', exampleMeaningVietnamese: 'quả đào', exampleWordAudioId: 'ja_word_momo'),

  const KanaItem(id: 'h_ya', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'や', romaji: 'ya', pronunciation: 'ya', strokeCount: 3, exampleWord: 'やま', exampleMeaningVietnamese: 'ngọn núi', exampleWordAudioId: 'ja_word_yama'),
  const KanaItem(id: 'h_yu', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'ゆ', romaji: 'yu', pronunciation: 'yu', strokeCount: 2, exampleWord: 'ゆき', exampleMeaningVietnamese: 'tuyết', exampleWordAudioId: 'ja_word_yuki'),
  const KanaItem(id: 'h_yo', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'よ', romaji: 'yo', pronunciation: 'yo', strokeCount: 2, exampleWord: 'よる', exampleMeaningVietnamese: 'buổi tối', exampleWordAudioId: 'ja_word_yoru'),

  const KanaItem(id: 'h_ra', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'ら', romaji: 'ra', pronunciation: 'ra', strokeCount: 2, exampleWord: 'らいおん', exampleMeaningVietnamese: 'sư tử', exampleWordAudioId: 'ja_word_raion'),
  const KanaItem(id: 'h_ri', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'り', romaji: 'ri', pronunciation: 'ri', strokeCount: 2, exampleWord: 'りんご', exampleMeaningVietnamese: 'quả táo', exampleWordAudioId: 'ja_word_ringo'),
  const KanaItem(id: 'h_ru', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'る', romaji: 'ru', pronunciation: 'ru', strokeCount: 1, confusionGroup: ['ろ'], exampleWord: 'るす', exampleMeaningVietnamese: 'vắng nhà', exampleWordAudioId: 'ja_word_rusu'),
  const KanaItem(id: 'h_re', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'れ', romaji: 're', pronunciation: 're', strokeCount: 2, confusionGroup: ['ね', 'わ'], exampleWord: 'れいぞうこ', exampleMeaningVietnamese: 'tủ lạnh', exampleWordAudioId: 'ja_word_reizouko'),
  const KanaItem(id: 'h_ro', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'ろ', romaji: 'ro', pronunciation: 'ro', strokeCount: 1, confusionGroup: ['る'], exampleWord: 'ろうそく', exampleMeaningVietnamese: 'nến', exampleWordAudioId: 'ja_word_rousoku'),

  const KanaItem(id: 'h_wa', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'わ', romaji: 'wa', pronunciation: 'wa', strokeCount: 2, confusionGroup: ['ね', 'れ'], exampleWord: 'わに', exampleMeaningVietnamese: 'cá sấu', exampleWordAudioId: 'ja_word_wani'),
  const KanaItem(id: 'h_wo', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'を', romaji: 'wo', pronunciation: 'o', strokeCount: 3),
  const KanaItem(id: 'h_n', script: KanaScript.hiragana, kanaType: KanaType.basic, character: 'ん', romaji: 'n', pronunciation: 'n', strokeCount: 1),

  // Dakuten
  const KanaItem(id: 'h_ga', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'が', romaji: 'ga', pronunciation: 'ga'),
  const KanaItem(id: 'h_gi', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'ぎ', romaji: 'gi', pronunciation: 'gi'),
  const KanaItem(id: 'h_gu', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'ぐ', romaji: 'gu', pronunciation: 'gu'),
  const KanaItem(id: 'h_ge', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'げ', romaji: 'ge', pronunciation: 'ge'),
  const KanaItem(id: 'h_go', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'ご', romaji: 'go', pronunciation: 'go'),

  const KanaItem(id: 'h_za', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'ざ', romaji: 'za', pronunciation: 'za'),
  const KanaItem(id: 'h_ji', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'じ', romaji: 'ji', pronunciation: 'ji'),
  const KanaItem(id: 'h_zu', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'ず', romaji: 'zu', pronunciation: 'zu'),
  const KanaItem(id: 'h_ze', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'ぜ', romaji: 'ze', pronunciation: 'ze'),
  const KanaItem(id: 'h_zo', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'ぞ', romaji: 'zo', pronunciation: 'zo'),

  const KanaItem(id: 'h_da', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'だ', romaji: 'da', pronunciation: 'da'),
  const KanaItem(id: 'h_dji', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'ぢ', romaji: 'ji', pronunciation: 'ji'),
  const KanaItem(id: 'h_dzu', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'づ', romaji: 'zu', pronunciation: 'zu'),
  const KanaItem(id: 'h_de', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'で', romaji: 'de', pronunciation: 'de'),
  const KanaItem(id: 'h_do', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'ど', romaji: 'do', pronunciation: 'do'),

  const KanaItem(id: 'h_ba', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'ば', romaji: 'ba', pronunciation: 'ba'),
  const KanaItem(id: 'h_bi', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'び', romaji: 'bi', pronunciation: 'bi'),
  const KanaItem(id: 'h_bu', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'ぶ', romaji: 'bu', pronunciation: 'bu'),
  const KanaItem(id: 'h_be', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'べ', romaji: 'be', pronunciation: 'be'),
  const KanaItem(id: 'h_bo', script: KanaScript.hiragana, kanaType: KanaType.dakuten, character: 'ぼ', romaji: 'bo', pronunciation: 'bo'),

  // Handakuten
  const KanaItem(id: 'h_pa', script: KanaScript.hiragana, kanaType: KanaType.handakuten, character: 'ぱ', romaji: 'pa', pronunciation: 'pa'),
  const KanaItem(id: 'h_pi', script: KanaScript.hiragana, kanaType: KanaType.handakuten, character: 'ぴ', romaji: 'pi', pronunciation: 'pi'),
  const KanaItem(id: 'h_pu', script: KanaScript.hiragana, kanaType: KanaType.handakuten, character: 'ぷ', romaji: 'pu', pronunciation: 'pu'),
  const KanaItem(id: 'h_pe', script: KanaScript.hiragana, kanaType: KanaType.handakuten, character: 'ぺ', romaji: 'pe', pronunciation: 'pe'),
  const KanaItem(id: 'h_po', script: KanaScript.hiragana, kanaType: KanaType.handakuten, character: 'ぽ', romaji: 'po', pronunciation: 'po'),

  // Yoon (Contracted)
  const KanaItem(id: 'h_kya', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'きゃ', romaji: 'kya', pronunciation: 'kya'),
  const KanaItem(id: 'h_kyu', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'きゅ', romaji: 'kyu', pronunciation: 'kyu'),
  const KanaItem(id: 'h_kyo', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'きょ', romaji: 'kyo', pronunciation: 'kyo'),
  
  const KanaItem(id: 'h_sha', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'しゃ', romaji: 'sha', pronunciation: 'sha'),
  const KanaItem(id: 'h_shu', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'しゅ', romaji: 'shu', pronunciation: 'shu'),
  const KanaItem(id: 'h_sho', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'しょ', romaji: 'sho', pronunciation: 'sho'),

  const KanaItem(id: 'h_cha', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'ちゃ', romaji: 'cha', pronunciation: 'cha'),
  const KanaItem(id: 'h_chu', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'ちゅ', romaji: 'chu', pronunciation: 'chu'),
  const KanaItem(id: 'h_cho', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'ちょ', romaji: 'cho', pronunciation: 'cho'),

  const KanaItem(id: 'h_nya', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'にゃ', romaji: 'nya', pronunciation: 'nya'),
  const KanaItem(id: 'h_nyu', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'にゅ', romaji: 'nyu', pronunciation: 'nyu'),
  const KanaItem(id: 'h_nyo', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'にょ', romaji: 'nyo', pronunciation: 'nyo'),

  const KanaItem(id: 'h_hya', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'ひゃ', romaji: 'hya', pronunciation: 'hya'),
  const KanaItem(id: 'h_hyu', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'ひゅ', romaji: 'hyu', pronunciation: 'hyu'),
  const KanaItem(id: 'h_hyo', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'ひょ', romaji: 'hyo', pronunciation: 'hyo'),

  const KanaItem(id: 'h_mya', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'みゃ', romaji: 'mya', pronunciation: 'mya'),
  const KanaItem(id: 'h_myu', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'みゅ', romaji: 'myu', pronunciation: 'myu'),
  const KanaItem(id: 'h_myo', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'みょ', romaji: 'myo', pronunciation: 'myo'),

  const KanaItem(id: 'h_rya', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'りゃ', romaji: 'rya', pronunciation: 'rya'),
  const KanaItem(id: 'h_ryu', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'りゅ', romaji: 'ryu', pronunciation: 'ryu'),
  const KanaItem(id: 'h_ryo', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'りょ', romaji: 'ryo', pronunciation: 'ryo'),

  const KanaItem(id: 'h_gya', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'ぎゃ', romaji: 'gya', pronunciation: 'gya'),
  const KanaItem(id: 'h_gyu', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'ぎゅ', romaji: 'gyu', pronunciation: 'gyu'),
  const KanaItem(id: 'h_gyo', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'ぎょ', romaji: 'gyo', pronunciation: 'gyo'),

  const KanaItem(id: 'h_ja', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'じゃ', romaji: 'ja', pronunciation: 'ja'),
  const KanaItem(id: 'h_ju', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'じゅ', romaji: 'ju', pronunciation: 'ju'),
  const KanaItem(id: 'h_jo', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'じょ', romaji: 'jo', pronunciation: 'jo'),

  const KanaItem(id: 'h_bya', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'びゃ', romaji: 'bya', pronunciation: 'bya'),
  const KanaItem(id: 'h_byu', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'びゅ', romaji: 'byu', pronunciation: 'byu'),
  const KanaItem(id: 'h_byo', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'びょ', romaji: 'byo', pronunciation: 'byo'),

  const KanaItem(id: 'h_pya', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'ぴゃ', romaji: 'pya', pronunciation: 'pya'),
  const KanaItem(id: 'h_pyu', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'ぴゅ', romaji: 'pyu', pronunciation: 'pyu'),
  const KanaItem(id: 'h_pyo', script: KanaScript.hiragana, kanaType: KanaType.yoon, character: 'ぴょ', romaji: 'pyo', pronunciation: 'pyo'),

  // Small Kana
  const KanaItem(id: 'h_small_a', script: KanaScript.hiragana, kanaType: KanaType.small, character: 'ぁ', romaji: 'a', pronunciation: 'a'),
  const KanaItem(id: 'h_small_i', script: KanaScript.hiragana, kanaType: KanaType.small, character: 'ぃ', romaji: 'i', pronunciation: 'i'),
  const KanaItem(id: 'h_small_u', script: KanaScript.hiragana, kanaType: KanaType.small, character: 'ぅ', romaji: 'u', pronunciation: 'u'),
  const KanaItem(id: 'h_small_e', script: KanaScript.hiragana, kanaType: KanaType.small, character: 'ぇ', romaji: 'e', pronunciation: 'e'),
  const KanaItem(id: 'h_small_o', script: KanaScript.hiragana, kanaType: KanaType.small, character: 'ぉ', romaji: 'o', pronunciation: 'o'),
  const KanaItem(id: 'h_small_ya', script: KanaScript.hiragana, kanaType: KanaType.small, character: 'ゃ', romaji: 'ya', pronunciation: 'ya'),
  const KanaItem(id: 'h_small_yu', script: KanaScript.hiragana, kanaType: KanaType.small, character: 'ゅ', romaji: 'yu', pronunciation: 'yu'),
  const KanaItem(id: 'h_small_yo', script: KanaScript.hiragana, kanaType: KanaType.small, character: 'ょ', romaji: 'yo', pronunciation: 'yo'),

  // Sokuon
  const KanaItem(id: 'h_sokuon', script: KanaScript.hiragana, kanaType: KanaType.sokuon, character: 'っ', romaji: '(tsu)', pronunciation: ''),
  const KanaItem(id: 'h_choon', script: KanaScript.hiragana, kanaType: KanaType.choon, character: 'ー', romaji: '-', pronunciation: ''),
];
