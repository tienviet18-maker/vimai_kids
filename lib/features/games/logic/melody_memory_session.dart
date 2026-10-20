import 'dart:math';

import '../../../data/content/game_catalog.dart';

/// What happened after a wrong note.
enum MelodyMiss {
  /// First slip: Mai plays the same melody again.
  replay,

  /// Second slip on the same melody: it gets one note shorter (and may lose
  /// a bell) before Mai plays it again.
  shortened,
}

/// Rules for "Giai điệu bí ẩn" (a Simon-style bell game), kept free of
/// Flutter so they can be tested directly.
///
/// Notes are bell indices 0..5 (C D E G A C). The set of bells in play grows
/// as the child succeeds and shrinks after repeated slips; bells are always
/// added in the same order, so a melody stays valid when a bell is added.
class MelodyMemorySession {
  MelodyMemorySession({required this.age, Random? random}) : _random = random ?? Random() {
    restart();
  }

  final int age;
  final Random _random;

  /// Bells in play for each bar count; each set contains the previous one,
  /// spread over the scale so neighbouring bars sound clearly different.
  static const bellSets = <int, List<int>>{
    3: [0, 2, 4],
    4: [0, 2, 4, 5],
    5: [0, 1, 2, 4, 5],
    6: [0, 1, 2, 3, 4, 5],
  };

  int get startBars => age <= 4 ? 3 : 4;
  int get maxBars => age <= 3 ? 4 : (age <= 4 ? 5 : 6);
  int get startLength => age >= 7 ? 3 : 2;
  int get maxLength => age <= 3 ? 5 : (age <= 5 ? 7 : 9);

  /// Melodies to finish: half the usual game rounds, because each melody is
  /// several taps and grows by a note every time.
  int get goal => (GameCatalog.roundsForAge(age) / 2).round();

  /// Time between two notes when Mai plays (slower for the youngest).
  Duration get noteGap => Duration(milliseconds: age <= 4 ? 720 : 580);

  /// Successes in a row before another bell joins.
  static const streakForNewBell = 2;

  late int barCount;
  List<int> sequence = const [];

  /// Notes the child has tapped right in the current attempt.
  int position = 0;
  int solved = 0;
  int mistakes = 0;
  int streak = 0;
  int missesOnMelody = 0;

  /// The longest melody the child has played back correctly.
  List<int> longest = const [];

  List<int> get bells => bellSets[barCount]!;
  bool get finished => solved >= goal;
  int? get expected => position < sequence.length ? sequence[position] : null;

  void restart() {
    barCount = startBars;
    position = 0;
    solved = 0;
    mistakes = 0;
    streak = 0;
    missesOnMelody = 0;
    longest = const [];
    sequence = const [];
    while (sequence.length < startLength) {
      sequence = [...sequence, _nextNote(sequence)];
    }
  }

  /// Starts a fresh attempt at the current melody (after a replay).
  void resetAttempt() => position = 0;

  /// The child tapped [bell]. Returns true when it was the expected note.
  bool tap(int bell) {
    if (bell != expected) return false;
    position++;
    return true;
  }

  bool get attemptComplete => sequence.isNotEmpty && position >= sequence.length;

  /// Call after the whole melody was repeated. Returns true when a new bell
  /// joined the set.
  bool completeMelody() {
    solved++;
    streak++;
    missesOnMelody = 0;
    if (sequence.length > longest.length) longest = List.of(sequence);
    var addedBell = false;
    if (streak % streakForNewBell == 0 && barCount < maxBars) {
      barCount++;
      addedBell = true;
    }
    if (sequence.length < maxLength) {
      sequence = [...sequence, _nextNote(sequence)];
    } else {
      // At the longest length, keep it fresh with a new melody.
      sequence = _fresh(sequence.length);
    }
    position = 0;
    return addedBell;
  }

  MelodyMiss miss() {
    mistakes++;
    streak = 0;
    missesOnMelody++;
    position = 0;
    if (missesOnMelody < 2) return MelodyMiss.replay;
    missesOnMelody = 0;
    if (barCount > startBars) barCount--;
    final shorter = sequence.length > 2 ? sequence.sublist(0, sequence.length - 1) : List.of(sequence);
    // Swap out notes of a bell that just left.
    final allowed = bells.toSet();
    final fixed = <int>[];
    for (final n in shorter) {
      fixed.add(allowed.contains(n) ? n : _nextNote(fixed));
    }
    sequence = fixed;
    return MelodyMiss.shortened;
  }

  List<int> _fresh(int length) {
    final out = <int>[];
    while (out.length < length) {
      out.add(_nextNote(out));
    }
    return out;
  }

  /// A random bell, never the same as the note just before it, so every
  /// note is a visible move to a different bar.
  int _nextNote(List<int> before) {
    final options = bells.where((b) => before.isEmpty || b != before.last).toList();
    return options[_random.nextInt(options.length)];
  }
}
