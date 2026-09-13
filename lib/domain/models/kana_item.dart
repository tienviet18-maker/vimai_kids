enum KanaScript { hiragana, katakana }

enum KanaType {
  basic,
  dakuten,
  handakuten,
  yoon,
  small,
  sokuon,
  choon,
  extended,
}

class KanaItem {
  final String id;
  final KanaScript script;
  final KanaType kanaType;
  final String character;
  final String romaji;
  final String pronunciation;
  final String? baseCharacter;
  final int strokeCount;
  final String? strokeOrderAsset;
  final String? audioAsset;
  final List<String>? confusionGroup;
  final int ageMin;
  final int ageMax;
  final int difficulty;
  final String? exampleWord;
  final String? exampleMeaningVietnamese;
  /// Bundled vocab clip id without `.mp3` (`ja_word_ari`, `ja_word_aisu`, …).
  final String? exampleWordAudioId;
  final String? row;

  const KanaItem({
    required this.id,
    required this.script,
    required this.kanaType,
    required this.character,
    required this.romaji,
    required this.pronunciation,
    this.baseCharacter,
    this.strokeCount = 1,
    this.strokeOrderAsset,
    this.audioAsset,
    this.confusionGroup,
    this.ageMin = 3,
    this.ageMax = 7,
    this.difficulty = 1,
    this.exampleWord,
    this.exampleMeaningVietnamese,
    this.exampleWordAudioId,
    this.row,
  });

  String get audioId => 'ja_$id'; // ja_h_a / ja_k_ga — matches assets/audio/ja_*.mp3
  /// Production vocab clip (`ja_word_*`); falls back to legacy `*_example` then kana audio.
  String get wordAudioId {
    final id = exampleWordAudioId?.trim();
    if (id != null && id.isNotEmpty) return id;
    return '${audioId}_example';
  }
  String get displayText => character;
  String get type => kanaType.name;
  String get category => kanaType.name;
  String get languageCode => 'ja-JP';
  String get resolvedRow => row ?? _rowFromRomaji(romaji);
  String get resolvedExampleWord => exampleWord ?? '';
  String get resolvedExampleMeaning => exampleMeaningVietnamese ?? '';

  static String _rowFromRomaji(String romaji) {
    if (romaji.isEmpty) return 'other';
    if (romaji == 'n' || romaji == '(tsu)' || romaji == '-') return romaji;
    final last = romaji[romaji.length - 1];
    if ('aiueo'.contains(last)) return '$last-row';
    return 'other';
  }

  factory KanaItem.fromJson(Map<String, dynamic> json) {
    return KanaItem(
      id: json['id'] as String,
      script: KanaScript.values.firstWhere((e) => e.name == json['script']),
      kanaType: KanaType.values.firstWhere((e) => e.name == (json['kanaType'] ?? json['category'])), // Fallback for old data
      character: json['character'] as String,
      romaji: json['romaji'] as String,
      pronunciation: json['pronunciation'] as String,
      baseCharacter: json['baseCharacter'] as String?,
      strokeCount: json['strokeCount'] as int? ?? 1,
      strokeOrderAsset: json['strokeOrderAsset'] as String?,
      audioAsset: json['audioAsset'] as String?,
      confusionGroup: (json['confusionGroup'] as List<dynamic>?)?.map((e) => e as String).toList(),
      ageMin: json['ageMin'] as int? ?? 3,
      ageMax: json['ageMax'] as int? ?? 7,
      difficulty: json['difficulty'] as int? ?? 1,
      exampleWord: json['exampleWord'] as String?,
      exampleMeaningVietnamese: json['exampleMeaningVietnamese'] as String?,
      exampleWordAudioId: json['exampleWordAudioId'] as String?,
      row: json['row'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'script': script.name,
      'kanaType': kanaType.name,
      'character': character,
      'romaji': romaji,
      'pronunciation': pronunciation,
      'baseCharacter': baseCharacter,
      'strokeCount': strokeCount,
      'strokeOrderAsset': strokeOrderAsset,
      'audioAsset': audioAsset,
      'confusionGroup': confusionGroup,
      'ageMin': ageMin,
      'ageMax': ageMax,
      'difficulty': difficulty,
      'exampleWord': exampleWord,
      'exampleMeaningVietnamese': exampleMeaningVietnamese,
      'exampleWordAudioId': exampleWordAudioId,
      'row': row,
      'displayText': character,
      'type': kanaType.name,
      'category': kanaType.name,
    };
  }
}
