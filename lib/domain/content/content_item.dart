enum ContentSubject {
  japanese,
  vietnamese,
  math,
  thinking,
  creativity,
  game
}

class ContentItem {
  final String id;
  final ContentSubject subject;
  final int ageMin;
  final int ageMax;
  final int level;
  final String skill;
  final int difficulty;
  final String title;
  final String instruction;
  final String? question;
  final String? answer;
  final List<String>? choices;
  final String? imageAsset;
  final String? audioAsset;
  final Map<String, dynamic>? metadata;
  final List<String>? tags;

  const ContentItem({
    required this.id,
    required this.subject,
    required this.ageMin,
    required this.ageMax,
    required this.level,
    required this.skill,
    required this.difficulty,
    required this.title,
    required this.instruction,
    this.question,
    this.answer,
    this.choices,
    this.imageAsset,
    this.audioAsset,
    this.metadata,
    this.tags,
  });

  String get audioId => metadata?['audioId'] as String? ?? '';
  String get audioNameId => metadata?['audioNameId'] as String? ?? '';
  String get audioSoundId => metadata?['audioSoundId'] as String? ?? '';
  /// Example-word clip for alphabet cards (`v_word_a`, `v_word_aw`, …).
  String get wordAudioId {
    final fromMeta = metadata?['wordAudioId'] as String? ??
        metadata?['exampleWordAudioId'] as String? ??
        metadata?['exampleAudioId'] as String? ??
        '';
    if (fromMeta.isNotEmpty) return fromMeta;
    if (id.startsWith('v_') && skill.contains('alphabet')) {
      return 'v_word_${id.substring(2)}';
    }
    return '';
  }

  /// Alias used by Words/Phonics speaker buttons.
  String get exampleWordAudioId {
    final fromMeta = metadata?['exampleWordAudioId'] as String? ?? '';
    if (fromMeta.isNotEmpty) return fromMeta;
    return wordAudioId.isNotEmpty ? wordAudioId : blendAudioId;
  }

  /// Blend / ghép âm clip (`v_blend_ba`, …).
  String get blendAudioId {
    final fromMeta = metadata?['blendAudioId'] as String? ?? '';
    if (fromMeta.isNotEmpty) return fromMeta;
    if (audioId.startsWith('v_blend_')) return audioId;
    final syl = syllable.trim().toLowerCase();
    if (syl.isNotEmpty && RegExp(r'^[a-z0-9_]+$').hasMatch(syl)) {
      return 'v_blend_$syl';
    }
    return audioId;
  }

  String get letterName => metadata?['letterName'] as String? ?? title;
  String get phoneme => metadata?['phoneme'] as String? ?? (question ?? '');
  String get lowercase => metadata?['lowercase'] as String? ?? (question?.toLowerCase() ?? '');
  String get exampleWord => metadata?['exampleWord'] as String? ?? '';
  String get audioText =>
      metadata?['audioText'] as String? ?? letterName;
  String get audioLocale => metadata?['audioLocale'] as String? ?? defaultAudioLocale;
  bool suitableForAge(int age) => age >= ageMin && age <= ageMax;
  String get defaultAudioLocale => subject == ContentSubject.japanese ? 'ja-JP' : 'vi-VN';
  String get syllable => metadata?['syllable'] as String? ?? (answer ?? '');
  String get onset => metadata?['onset'] as String? ?? '';
  String get rime => metadata?['rime'] as String? ?? '';

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] as String,
      subject: ContentSubject.values.firstWhere((e) => e.name == json['subject']),
      ageMin: json['ageMin'] as int,
      ageMax: json['ageMax'] as int,
      level: json['level'] as int,
      skill: json['skill'] as String,
      difficulty: json['difficulty'] as int,
      title: json['title'] as String,
      instruction: json['instruction'] as String,
      question: json['question'] as String?,
      answer: json['answer'] as String?,
      choices: (json['choices'] as List<dynamic>?)?.map((e) => e as String).toList(),
      imageAsset: json['imageAsset'] as String?,
      audioAsset: json['audioAsset'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject.name,
      'ageMin': ageMin,
      'ageMax': ageMax,
      'level': level,
      'skill': skill,
      'difficulty': difficulty,
      'title': title,
      'instruction': instruction,
      'question': question,
      'answer': answer,
      'choices': choices,
      'imageAsset': imageAsset,
      'audioAsset': audioAsset,
      'metadata': metadata,
      'tags': tags,
    };
  }
}
