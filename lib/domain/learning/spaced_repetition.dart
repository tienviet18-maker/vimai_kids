class SpacedRepetition {
  static const intervalsInDays = [1, 2, 4, 7, 14, 30];

  static DateTime nextReview({
    required bool correct,
    required int streakAfterAnswer,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    if (!correct) {
      return current.add(const Duration(minutes: 5));
    }
    final index = (streakAfterAnswer - 1).clamp(0, intervalsInDays.length - 1);
    return current.add(Duration(days: intervalsInDays[index]));
  }

  static int nextMastery({required int current, required bool correct}) {
    if (correct) {
      return (current + 12).clamp(0, 100);
    }
    return (current - 18).clamp(0, 100);
  }
}
