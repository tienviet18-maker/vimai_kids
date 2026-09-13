class SkillMastery {
  final String id;
  final String skill;
  final int attempts;
  final int correct;
  final int incorrect;
  final int streak;
  final int mastery;
  final int confidence;
  final DateTime? lastReviewed;
  final DateTime? nextReview;
  final double averageResponseTimeMs;

  const SkillMastery({
    required this.id,
    required this.skill,
    this.attempts = 0,
    this.correct = 0,
    this.incorrect = 0,
    this.streak = 0,
    this.mastery = 0,
    this.confidence = 0,
    this.lastReviewed,
    this.nextReview,
    this.averageResponseTimeMs = 0,
  });

  bool get isMastered => mastery >= 80 && attempts >= 3;
  bool get isLearning => attempts > 0 && !isMastered;
  bool get needsReview {
    if (nextReview == null) return attempts > 0;
    return nextReview!.isBefore(DateTime.now());
  }

  factory SkillMastery.fromJson(Map<String, dynamic> json) {
    return SkillMastery(
      id: json['id'] as String,
      skill: json['skill'] as String,
      attempts: json['attempts'] as int? ?? 0,
      correct: json['correct'] as int? ?? 0,
      incorrect: json['incorrect'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      mastery: json['mastery'] as int? ?? 0,
      confidence: json['confidence'] as int? ?? 0,
      lastReviewed: json['lastReviewed'] != null ? DateTime.parse(json['lastReviewed'] as String) : null,
      nextReview: json['nextReview'] != null ? DateTime.parse(json['nextReview'] as String) : null,
      averageResponseTimeMs: (json['averageResponseTimeMs'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skill': skill,
      'attempts': attempts,
      'correct': correct,
      'incorrect': incorrect,
      'streak': streak,
      'mastery': mastery,
      'confidence': confidence,
      'lastReviewed': lastReviewed?.toIso8601String(),
      'nextReview': nextReview?.toIso8601String(),
      'averageResponseTimeMs': averageResponseTimeMs,
    };
  }
}
