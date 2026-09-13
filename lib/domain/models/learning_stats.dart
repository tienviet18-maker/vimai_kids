class LearningStats {
  final String itemId;
  final int visualRecognition;
  final int audioRecognition;
  final int reading;
  final int recognitionQuiz;
  final int writing;
  final int correctCount;
  final int wrongCount;
  final int streak;
  final DateTime? lastReviewed;
  final DateTime? nextReview;
  final double averageResponseTimeMs;

  const LearningStats({
    required this.itemId,
    this.visualRecognition = 0,
    this.audioRecognition = 0,
    this.reading = 0,
    this.recognitionQuiz = 0,
    this.writing = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.streak = 0,
    this.lastReviewed,
    this.nextReview,
    this.averageResponseTimeMs = 0.0,
  });

  int get overallMastery {
    return ((visualRecognition + audioRecognition + reading + recognitionQuiz + writing) / 5).round();
  }

  LearningStats copyWith({
    int? visualRecognition,
    int? audioRecognition,
    int? reading,
    int? recognitionQuiz,
    int? writing,
    int? correctCount,
    int? wrongCount,
    int? streak,
    DateTime? lastReviewed,
    DateTime? nextReview,
    double? averageResponseTimeMs,
  }) {
    return LearningStats(
      itemId: itemId,
      visualRecognition: visualRecognition ?? this.visualRecognition,
      audioRecognition: audioRecognition ?? this.audioRecognition,
      reading: reading ?? this.reading,
      recognitionQuiz: recognitionQuiz ?? this.recognitionQuiz,
      writing: writing ?? this.writing,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      streak: streak ?? this.streak,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      averageResponseTimeMs: averageResponseTimeMs ?? this.averageResponseTimeMs,
    );
  }

  factory LearningStats.fromJson(Map<String, dynamic> json) {
    return LearningStats(
      itemId: json['itemId'] as String,
      visualRecognition: json['visualRecognition'] as int? ?? 0,
      audioRecognition: json['audioRecognition'] as int? ?? 0,
      reading: json['reading'] as int? ?? 0,
      recognitionQuiz: json['recognitionQuiz'] as int? ?? 0,
      writing: json['writing'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      wrongCount: json['wrongCount'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      lastReviewed: json['lastReviewed'] != null ? DateTime.parse(json['lastReviewed'] as String) : null,
      nextReview: json['nextReview'] != null ? DateTime.parse(json['nextReview'] as String) : null,
      averageResponseTimeMs: (json['averageResponseTimeMs'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'visualRecognition': visualRecognition,
      'audioRecognition': audioRecognition,
      'reading': reading,
      'recognitionQuiz': recognitionQuiz,
      'writing': writing,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'streak': streak,
      'lastReviewed': lastReviewed?.toIso8601String(),
      'nextReview': nextReview?.toIso8601String(),
      'averageResponseTimeMs': averageResponseTimeMs,
    };
  }
}
