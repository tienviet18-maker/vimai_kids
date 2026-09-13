import '../models/skill_mastery.dart';
import 'spaced_repetition.dart';

class MasteryEngine {
  SkillMastery recordAttempt({
    required SkillMastery current,
    required bool correct,
    double responseTimeMs = 0,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final attempts = current.attempts + 1;
    final correctCount = current.correct + (correct ? 1 : 0);
    final incorrectCount = current.incorrect + (correct ? 0 : 1);
    final streak = correct ? current.streak + 1 : 0;
    final mastery = SpacedRepetition.nextMastery(current: current.mastery, correct: correct);
    final confidence = ((correctCount / attempts) * 100).round();
    final nextReview = SpacedRepetition.nextReview(
      correct: correct,
      streakAfterAnswer: streak,
      now: timestamp,
    );

    final avg = current.attempts == 0
        ? responseTimeMs
        : ((current.averageResponseTimeMs * current.attempts) + responseTimeMs) / attempts;

    return SkillMastery(
      id: current.id,
      skill: current.skill,
      attempts: attempts,
      correct: correctCount,
      incorrect: incorrectCount,
      streak: streak,
      mastery: mastery,
      confidence: confidence,
      lastReviewed: timestamp,
      nextReview: nextReview,
      averageResponseTimeMs: avg,
    );
  }

  List<SkillMastery> prioritize(List<SkillMastery> items) {
    final copy = List<SkillMastery>.from(items);
    copy.sort((a, b) {
      final aWeak = a.incorrect.compareTo(a.correct);
      final bWeak = b.incorrect.compareTo(b.correct);
      if (a.needsReview != b.needsReview) return a.needsReview ? -1 : 1;
      if (a.mastery != b.mastery) return a.mastery.compareTo(b.mastery);
      if (aWeak != bWeak) return bWeak.compareTo(aWeak);
      return b.averageResponseTimeMs.compareTo(a.averageResponseTimeMs);
    });
    return copy;
  }

  int overallPercent(List<SkillMastery> items) {
    if (items.isEmpty) return 0;
    final withAttempts = items.where((e) => e.attempts > 0).toList();
    if (withAttempts.isEmpty) return 0;
    final sum = withAttempts.fold<int>(0, (p, e) => p + e.mastery);
    return (sum / withAttempts.length).round();
  }
}
