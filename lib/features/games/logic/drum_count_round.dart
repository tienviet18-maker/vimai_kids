import 'dart:math';

import '../../../core/audio/kid_guide.dart';

/// The sounds Bạn gấu can make in "Đếm tiếng trống".
enum DrumSound { drum, bell, coin }

/// One difficulty step of the drum-count game.
class DrumCountLevel {
  const DrumCountLevel({
    required this.minCount,
    required this.maxCount,
    required this.sounds,
    required this.choiceCount,
    required this.tempoMs,
  });

  final int minCount;
  final int maxCount;
  final List<DrumSound> sounds;
  final int choiceCount;

  /// Time between two beats.
  final int tempoMs;
}

/// One round: the beats to play, which sound to count, and the number cards.
class DrumCountRound {
  const DrumCountRound({
    required this.beats,
    required this.target,
    required this.choices,
    required this.prompt,
    required this.tempoMs,
  });

  /// Every sound in play order. Mixed rounds interleave other sounds that
  /// the child must not count.
  final List<DrumSound> beats;
  final DrumSound target;
  final List<int> choices;

  /// Mai's question (a [KidGuide] line).
  final String prompt;
  final int tempoMs;

  int get answer => beats.where((b) => b == target).length;
  bool get mixed => beats.any((b) => b != target);

  /// 1–3 drum beats → 1–5 drum beats → 1–5 drum/bell/coin → 2–10 mixed.
  static const levels = [
    DrumCountLevel(minCount: 1, maxCount: 3, sounds: [DrumSound.drum], choiceCount: 3, tempoMs: 650),
    DrumCountLevel(minCount: 1, maxCount: 5, sounds: [DrumSound.drum], choiceCount: 4, tempoMs: 620),
    DrumCountLevel(
        minCount: 1,
        maxCount: 5,
        sounds: [DrumSound.drum, DrumSound.bell, DrumSound.coin],
        choiceCount: 4,
        tempoMs: 600),
    DrumCountLevel(
        minCount: 2,
        maxCount: 10,
        sounds: [DrumSound.drum, DrumSound.bell, DrumSound.coin],
        choiceCount: 4,
        tempoMs: 560),
  ];

  static int startLevel(int age) => age <= 4 ? 0 : (age == 5 ? 1 : 2);

  /// Three-year-olds stay within five; mixed sounds wait until four.
  static int maxLevel(int age) => age <= 3 ? 1 : (age == 4 ? 2 : levels.length - 1);

  /// Chance of a "count only the bells" round, for ages 6+ at the top level.
  static const mixedChance = 0.3;

  static String promptFor(DrumSound target, {bool mixed = false}) {
    if (mixed) return KidGuide.drumAskMixed;
    return switch (target) {
      DrumSound.drum => KidGuide.drumAskDrum,
      DrumSound.bell => KidGuide.drumAskBell,
      DrumSound.coin => KidGuide.drumAskCoin,
    };
  }

  static DrumCountRound generate({
    required int level,
    required int age,
    required Random random,
    int? avoidAnswer,
  }) {
    final l = levels[level.clamp(0, levels.length - 1)];
    int pick(int lo, int hi) {
      var n = lo + random.nextInt(hi - lo + 1);
      if (n == avoidAnswer && hi > lo) n = n == hi ? lo + random.nextInt(hi - lo) : n + 1;
      return n;
    }

    if (level >= levels.length - 1 && age >= 6 && random.nextDouble() < mixedChance) {
      final bells = pick(2, 5);
      final drums = 1 + random.nextInt(3);
      final beats = [
        ...List.filled(bells, DrumSound.bell),
        ...List.filled(drums, DrumSound.drum),
      ]..shuffle(random);
      return DrumCountRound(
        beats: beats,
        target: DrumSound.bell,
        choices: _choices(bells, 1, 8, l.choiceCount, random),
        prompt: promptFor(DrumSound.bell, mixed: true),
        tempoMs: l.tempoMs + 60,
      );
    }

    final answer = pick(l.minCount, l.maxCount);
    final sound = l.sounds[random.nextInt(l.sounds.length)];
    return DrumCountRound(
      beats: List.filled(answer, sound),
      target: sound,
      choices: _choices(answer, 1, l.maxCount, l.choiceCount, random),
      prompt: promptFor(sound),
      tempoMs: l.tempoMs,
    );
  }

  /// [count] distinct numbers in [lo]..[hi] including [answer], close to it
  /// (so the child really counts), in ascending order.
  static List<int> _choices(int answer, int lo, int hi, int count, Random random) {
    final others = [
      for (var n = lo; n <= hi; n++)
        if (n != answer) n
    ]
      ..shuffle(random)
      ..sort((a, b) => (a - answer).abs().compareTo((b - answer).abs()));
    final near = others.take(min(count - 1, others.length)).toList();
    return [answer, ...near]..sort();
  }
}
