import 'dart:math';

/// Games whose session length comes from [GameCatalog.sessionRounds].
enum GameKind { catchLetters, listenKana, mathRocket, feedAnimal, firstSound, oddOneOut, drumCount, numberTrain, melodyMemory }

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

  /// Questions in a math lesson quiz (MathScreen). Games use [sessionRounds].
  static int roundsForAge(int age) {
    if (age <= 3) return 8;
    if (age <= 5) return 12;
    return 16;
  }

  /// Rounds to win one game, by game and age. A session should end while a
  /// 3–7 year old is still enjoying it (about 3–5 minutes): quick one-tap
  /// games get up to 10 rounds, games whose rounds take longer (loading a
  /// whole train, listening to drum beats, a growing melody) get fewer.
  static int sessionRounds(GameKind game, int age) {
    final band = age <= 3 ? 0 : (age <= 5 ? 1 : 2);
    const table = <GameKind, List<int>>{
      GameKind.catchLetters: [6, 8, 10],
      GameKind.listenKana: [6, 8, 10],
      GameKind.mathRocket: [6, 8, 10],
      GameKind.feedAnimal: [6, 8, 10],
      GameKind.firstSound: [5, 6, 8],
      GameKind.oddOneOut: [5, 6, 8],
      GameKind.drumCount: [5, 6, 8],
      // Five boxes to load per train.
      GameKind.numberTrain: [4, 5, 6],
      // Each melody is a note longer than the last one.
      GameKind.melodyMemory: [4, 5, 6],
    };
    return table[game]![band];
  }

  static int pairCount(int age) => age <= 4 ? 4 : (age <= 6 ? 6 : 8);

  static List<int> numberTrain(int age, Random random) {
    final max = age <= 3 ? 5 : (age == 4 ? 8 : (age == 5 ? 10 : (age == 6 ? 12 : 15)));
    final start = 1 + random.nextInt(max - 4);
    final numbers = List<int>.generate(5, (i) => start + i);
    // Never hand out a train that is already in order (nothing to do).
    do {
      numbers.shuffle(random);
    } while (numbers.join(',') == List<int>.generate(5, (i) => start + i).join(','));
    return numbers;
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
