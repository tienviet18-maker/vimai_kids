class ChildProfile {
  final String id;
  final String name;
  final int age;
  final String avatar;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final Map<String, dynamic> learningStats;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> progress;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> dailyLearningState;

  String get childName => name;
  bool get soundEnabled => settings['sound'] != false;
  bool get bgmEnabled => settings['bgm'] != false;
  bool get aiEnabled => settings['ai_enabled'] != false;
  bool get aiVoiceEnabled => settings['ai_voice_enabled'] != false;
  double get voiceVolume => (settings['voiceVolume'] as num?)?.toDouble() ?? 1.0;
  double get bgmVolume => (settings['bgmVolume'] as num?)?.toDouble() ?? 0.2;
  int get dailyMinutes => (settings['dailyMinutes'] as num?)?.toInt() ?? 15;

  String get lastWorld => settings['lastWorld'] as String? ?? '';

  String get todayDateKey {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int get todaySeconds {
    if (dailyLearningState['date'] != todayDateKey) return 0;
    return (dailyLearningState['seconds'] as num?)?.toInt() ?? 0;
  }

  int get todayMinutes => (todaySeconds / 60).floor();

  int minutesFor(String subject) {
    if (dailyLearningState['date'] != todayDateKey) return 0;
    final by = dailyLearningState['bySubject'] as Map? ?? {};
    return (((by[subject] as num?)?.toInt() ?? 0) / 60).floor();
  }

  bool get metDailyGoal => todayMinutes >= dailyMinutes;

  static int clampAge(int age) {
    if (age < 3) return 3;
    if (age > 7) return 7;
    return age;
  }

  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.avatar,
    required this.createdAt,
    this.lastActiveAt,
    this.learningStats = const {},
    this.settings = const {},
    this.progress = const {},
    this.preferences = const {},
    this.dailyLearningState = const {},
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: ChildProfile.clampAge(json['age'] as int),
      avatar: json['avatar'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: json['lastActiveAt'] != null ? DateTime.parse(json['lastActiveAt'] as String) : null,
      learningStats: json['learningStats'] as Map<String, dynamic>? ?? {},
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      progress: json['progress'] as Map<String, dynamic>? ?? {},
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      dailyLearningState: json['dailyLearningState'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'learningStats': learningStats,
      'settings': settings,
      'progress': progress,
      'preferences': preferences,
      'dailyLearningState': dailyLearningState,
    };
  }

  ChildProfile copyWith({
    String? name,
    int? age,
    String? avatar,
    DateTime? lastActiveAt,
    Map<String, dynamic>? learningStats,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? progress,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? dailyLearningState,
  }) {
    return ChildProfile(
      id: id,
      name: name ?? this.name,
      age: ChildProfile.clampAge(age ?? this.age),
      avatar: avatar ?? this.avatar,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      learningStats: learningStats ?? this.learningStats,
      settings: settings ?? this.settings,
      progress: progress ?? this.progress,
      preferences: preferences ?? this.preferences,
      dailyLearningState: dailyLearningState ?? this.dailyLearningState,
    );
  }
}
