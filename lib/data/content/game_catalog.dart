import 'dart:math';

/// Age-scaled game banks. Generators plus static variants keep rounds from repeating.
class GameCatalog {
  static const similarSymbols = [
    '⭐', '🌙', '☀️', '🌈', '🍎', '🐱', '🚗', '🌸',
    '🐶', '🐸', '🍌', '🍇', '🧸', '🎈', '⚽', '🏀',
    '🐟', '🐦', '🌻', '🍀', '🍓', '🍊', '🦋', '🐝',
    '🐰', '🐼', '🐨', '🐧', '🍉', '🍪', '🧁', '🎁',
    '🪁', '🪀', '🥁', '🎹',
  ];

  static int catchSpeed(int age) => age <= 3 ? 3 : (age <= 5 ? 4 : 6);

  static int roundsForAge(int age) {
    if (age <= 3) return 8;
    if (age <= 5) return 12;
    return 16;
  }

  static int pairCount(int age) => age <= 4 ? 4 : (age <= 6 ? 6 : 8);

  static List<int> numberTrain(int age, Random random) {
    final max = age <= 3 ? 5 : (age == 4 ? 8 : (age == 5 ? 10 : (age == 6 ? 12 : 15)));
    final start = 1 + random.nextInt(max - 4);
    return List<int>.generate(5, (i) => start + i)..shuffle(random);
  }

  static List<String> similarDeal(int age, Random random) {
    final count = pairCount(age);
    final pool = List<String>.from(similarSymbols)..shuffle(random);
    final selected = pool.take(count).toList();
    return [...selected, ...selected]..shuffle(random);
  }

  static int countingMax(int age) {
    if (age <= 3) return 5;
    if (age <= 5) return 10;
    if (age == 6) return 20;
    return 30;
  }
}
