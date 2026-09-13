import 'audio_asset_registry.dart';

class VietnameseLetterSpeech {
  final String glyph;
  final String name;
  final String sound;
  final String slug;
  final String teachingSound;

  const VietnameseLetterSpeech({
    required this.glyph,
    required this.name,
    required this.sound,
    required this.slug,
    this.teachingSound = '',
  });

  String get phonicsSpoken => teachingSound.isEmpty ? sound : teachingSound;

  String get nameAssetPath => 'assets/audio/vi/letters/${slug}_name.wav';
  String get soundAssetPath => 'assets/audio/vi/letters/${slug}_sound.wav';
  String get nameAudioId => 'vi_letter_${slug}_name';
  String get soundAudioId => 'vi_letter_${slug}_sound';

  /// Hard-wired Hoài My MP3 key (telex): ă→v_aw, â→v_aa, c→v_c.
  String get modernAudioId => 'v_$slug';
}

/// Spoken forms and on-disk paths for Vietnamese learning audio.
/// Paths are only returned when [AudioAssetRegistry] lists a real file.
class VietnameseSpeechCatalog {
  static const letters = <String, VietnameseLetterSpeech>{
    'A': VietnameseLetterSpeech(glyph: 'A', name: 'a', sound: 'a', slug: 'a'),
    'Ă': VietnameseLetterSpeech(glyph: 'Ă', name: 'ă', sound: 'ă', slug: 'aw', teachingSound: 'á'),
    'Â': VietnameseLetterSpeech(glyph: 'Â', name: 'â', sound: 'â', slug: 'aa', teachingSound: 'ớ'),
    'B': VietnameseLetterSpeech(glyph: 'B', name: 'bê', sound: 'bờ', slug: 'b'),
    'C': VietnameseLetterSpeech(glyph: 'C', name: 'xê', sound: 'cờ', slug: 'c'),
    'D': VietnameseLetterSpeech(glyph: 'D', name: 'dê', sound: 'dờ', slug: 'd'),
    'Đ': VietnameseLetterSpeech(glyph: 'Đ', name: 'đê', sound: 'đờ', slug: 'dd'),
    'E': VietnameseLetterSpeech(glyph: 'E', name: 'e', sound: 'e', slug: 'e'),
    'Ê': VietnameseLetterSpeech(glyph: 'Ê', name: 'ê', sound: 'ê', slug: 'ee'),
    'G': VietnameseLetterSpeech(glyph: 'G', name: 'giê', sound: 'gờ', slug: 'g'),
    'H': VietnameseLetterSpeech(glyph: 'H', name: 'hát', sound: 'hờ', slug: 'h'),
    'I': VietnameseLetterSpeech(glyph: 'I', name: 'i', sound: 'i', slug: 'i'),
    'K': VietnameseLetterSpeech(glyph: 'K', name: 'ca', sound: 'cờ', slug: 'k'),
    'L': VietnameseLetterSpeech(glyph: 'L', name: 'e-lờ', sound: 'lờ', slug: 'l'),
    'M': VietnameseLetterSpeech(glyph: 'M', name: 'em-mờ', sound: 'mờ', slug: 'm'),
    'N': VietnameseLetterSpeech(glyph: 'N', name: 'en-nờ', sound: 'nờ', slug: 'n'),
    'O': VietnameseLetterSpeech(glyph: 'O', name: 'o', sound: 'o', slug: 'o'),
    'Ô': VietnameseLetterSpeech(glyph: 'Ô', name: 'ô', sound: 'ô', slug: 'oo'),
    'Ơ': VietnameseLetterSpeech(glyph: 'Ơ', name: 'ơ', sound: 'ơ', slug: 'ow'),
    'P': VietnameseLetterSpeech(glyph: 'P', name: 'pê', sound: 'pờ', slug: 'p'),
    'Q': VietnameseLetterSpeech(glyph: 'Q', name: 'quy', sound: 'cu', slug: 'q'),
    'R': VietnameseLetterSpeech(glyph: 'R', name: 'e-rờ', sound: 'rờ', slug: 'r'),
    'S': VietnameseLetterSpeech(glyph: 'S', name: 'ét', sound: 'sờ', slug: 's'),
    'T': VietnameseLetterSpeech(glyph: 'T', name: 'tê', sound: 'tờ', slug: 't'),
    'U': VietnameseLetterSpeech(glyph: 'U', name: 'u', sound: 'u', slug: 'u'),
    'Ư': VietnameseLetterSpeech(glyph: 'Ư', name: 'ư', sound: 'ư', slug: 'uw'),
    'V': VietnameseLetterSpeech(glyph: 'V', name: 'vê', sound: 'vờ', slug: 'v'),
    'X': VietnameseLetterSpeech(glyph: 'X', name: 'ích', sound: 'xờ', slug: 'x'),
    'Y': VietnameseLetterSpeech(glyph: 'Y', name: 'i', sound: 'i', slug: 'y', teachingSound: 'i dài'),
  };

  static const phraseAssets = <String, String>{
    'Giỏi lắm': 'assets/audio/vi/phrases/gioi_lam.wav',
    'giỏi lắm': 'assets/audio/vi/phrases/gioi_lam.wav',
  };

  static const phraseAudioIds = <String, String>{
    'Giỏi lắm': 'vi_phrase_gioi_lam',
    'giỏi lắm': 'vi_phrase_gioi_lam',
  };

  static const _telex = {
    'ă': 'aw',
    'â': 'aa',
    'đ': 'dd',
    'ê': 'ee',
    'ô': 'oo',
    'ơ': 'ow',
    'ư': 'uw',
    'á': 'as',
    'à': 'af',
    'ả': 'ar',
    'ã': 'ax',
    'ạ': 'aj',
    'ắ': 'aws',
    'ằ': 'awf',
    'ẳ': 'awr',
    'ẵ': 'awx',
    'ặ': 'awj',
    'ấ': 'aas',
    'ầ': 'aaf',
    'ẩ': 'aar',
    'ẫ': 'aax',
    'ậ': 'aaj',
    'é': 'es',
    'è': 'ef',
    'ẻ': 'er',
    'ẽ': 'ex',
    'ẹ': 'ej',
    'ế': 'ees',
    'ề': 'eef',
    'ể': 'eer',
    'ễ': 'eex',
    'ệ': 'eej',
    'í': 'is',
    'ì': 'if',
    'ỉ': 'ir',
    'ĩ': 'ix',
    'ị': 'ij',
    'ó': 'os',
    'ò': 'of',
    'ỏ': 'or',
    'õ': 'ox',
    'ọ': 'oj',
    'ố': 'oos',
    'ồ': 'oof',
    'ổ': 'oor',
    'ỗ': 'oox',
    'ộ': 'ooj',
    'ớ': 'ows',
    'ờ': 'owf',
    'ở': 'owr',
    'ỡ': 'owx',
    'ợ': 'owj',
    'ú': 'us',
    'ù': 'uf',
    'ủ': 'ur',
    'ũ': 'ux',
    'ụ': 'uj',
    'ứ': 'uws',
    'ừ': 'uwf',
    'ử': 'uwr',
    'ữ': 'uwx',
    'ự': 'uwj',
    'ý': 'ys',
    'ỳ': 'yf',
    'ỷ': 'yr',
    'ỹ': 'yx',
    'ỵ': 'yj',
  };

  static VietnameseLetterSpeech? letterOf(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final upper = trimmed.toUpperCase();
    final direct = letters[upper];
    if (direct != null) return direct;
    for (final letter in letters.values) {
      if (letter.name == trimmed || letter.sound == trimmed) return letter;
    }
    return null;
  }

  /// Hard map letter glyph/name → Hoài My MP3 id.
  /// Examples: 'ă'/'Ă' → 'v_aw', 'â' → 'v_aa', 'b' → 'v_b', 'c' → 'v_c'.
  static String getAudioIdForLetter(String letter) {
    final item = letterOf(letter);
    if (item != null) return item.modernAudioId;
    final trimmed = letter.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    const charToSlug = {
      'ă': 'aw',
      'â': 'aa',
      'đ': 'dd',
      'ê': 'ee',
      'ô': 'oo',
      'ơ': 'ow',
      'ư': 'uw',
    };
    if (charToSlug.containsKey(trimmed)) return 'v_${charToSlug[trimmed]}';
    if (RegExp(r'^[a-z]$').hasMatch(trimmed)) return 'v_$trimmed';
    return '';
  }

  /// Explicit short aliases declared in tools/audio_schema.json.
  static const Map<String, String> _wordIdAliases = {
    'ấm': 'v_word_aasm',
    'áo': 'v_word_ao',
    'ăn': 'v_word_an',
    'bố': 'v_word_bo',
    'cá': 'v_word_ca',
  };

  /// Example word → Hoài My word MP3 id (e.g. 'ấm' → 'v_word_aasm').
  static String getAudioIdForWord(String word) {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return '';
    final lower = trimmed.toLowerCase();
    return _wordIdAliases[lower] ?? _wordIdAliases[trimmed] ?? wordAudioId(trimmed) ?? '';
  }

  static String nameSpoken(String letter) => letterOf(letter)?.name ?? letter.trim();

  static String soundSpoken(String letter) => letterOf(letter)?.sound ?? letter.trim();

  static String phonicsSpoken(String letter) => letterOf(letter)?.phonicsSpoken ?? letter.trim();

  static String? nameAudioId(String letter) => letterOf(letter)?.nameAudioId;

  static String? soundAudioId(String letter) => letterOf(letter)?.soundAudioId;

  static String? nameAsset(String letter) {
    final item = letterOf(letter);
    if (item == null) return null;
    return AudioAssetRegistry.existingOrNull(item.nameAssetPath);
  }

  static String? soundAsset(String letter) {
    final item = letterOf(letter);
    if (item == null) return null;
    return AudioAssetRegistry.existingOrNull(item.soundAssetPath);
  }

  static String slug(String text) {
    final chars = <String>[];
    for (final ch in text.trim().toLowerCase().split('')) {
      if (_telex.containsKey(ch)) {
        chars.add(_telex[ch]!);
      } else if (RegExp(r'[a-z0-9]').hasMatch(ch)) {
        chars.add(ch);
      } else if (ch == '-' || ch == ' ') {
        chars.add('_');
      }
    }
    final value = chars.join().replaceAll(RegExp(r'^_+|_+$'), '');
    return value.isEmpty ? 'clip' : value;
  }

  static String? clipIn(String folder, String text) {
    return AudioAssetRegistry.existingOrNull(
      'assets/audio/vi/$folder/${slug(text)}.wav',
    );
  }

  static String? phonicsAudioId(String text) => 'vi_phonics_${slug(text)}';

  static String? rimeAudioId(String text) => 'vi_rime_${slug(text)}';

  static String? wordAudioId(String text) => 'v_word_${slug(text)}';

  static String? phonicsAsset(String text) => clipIn('phonics', text);

  static String? rimeAsset(String text) => clipIn('rimes', text);

  static String? wordAsset(String text) => clipIn('words', text);

  static String? audioIdForSpoken(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final phrase = phraseAudioIds[trimmed];
    if (phrase != null) return phrase;
    for (final letter in letters.values) {
      if (letter.name == trimmed) return letter.nameAudioId;
    }
    for (final letter in letters.values) {
      if (letter.sound == trimmed && letter.sound != letter.name) return letter.soundAudioId;
    }
    if (AudioAssetRegistry.hasId('v_word_${slug(trimmed)}')) return 'v_word_${slug(trimmed)}';
    if (AudioAssetRegistry.hasId('vi_word_${slug(trimmed)}')) return 'v_word_${slug(trimmed)}';
    if (AudioAssetRegistry.hasId('vi_phonics_${slug(trimmed)}')) return 'vi_phonics_${slug(trimmed)}';
    if (AudioAssetRegistry.hasId('vi_rime_${slug(trimmed)}')) return 'vi_rime_${slug(trimmed)}';
    return AudioAssetRegistry.idForText(language: 'vi', text: trimmed);
  }

  static String? phraseAsset(String text) {
    return AudioAssetRegistry.existingOrNull(phraseAssets[text.trim()]);
  }

  /// Best recorded clip for already-spoken Vietnamese text (not a letter glyph).
  static String? assetForSpokenText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final phrase = phraseAsset(trimmed);
    if (phrase != null) return phrase;

    for (final letter in letters.values) {
      if (letter.name == trimmed) {
        final asset = AudioAssetRegistry.existingOrNull(letter.nameAssetPath);
        if (asset != null) return asset;
      }
    }
    for (final letter in letters.values) {
      if (letter.sound == trimmed && letter.sound != letter.name) {
        final asset = AudioAssetRegistry.existingOrNull(letter.soundAssetPath);
        if (asset != null) return asset;
      }
    }

    return phonicsAsset(trimmed) ?? rimeAsset(trimmed) ?? wordAsset(trimmed) ?? clipIn('phrases', trimmed);
  }
}
