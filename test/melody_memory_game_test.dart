import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/audio/kid_guide.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/repositories/mastery_repository.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/features/games/logic/melody_memory_session.dart';
import 'package:mai_an_learning/features/games/presentation/melody_memory_game.dart';
import 'package:mai_an_learning/features/games/presentation/widgets/game_play_scaffold.dart';

/// Records what the game asks for instead of playing audio.
class _FakeAudio extends AudioService {
  final said = <String>[];
  final bells = <int>[];
  int correct = 0;
  int wrong = 0;
  final effects = <Sfx>[];

  @override
  Future<AudioPlayResult> speak(
    List<String?> lines, {
    String? fallbackId,
    List<String> leadIds = const [],
    List<String> trailIds = const [],
  }) async {
    said.addAll(lines.whereType<String>());
    return const AudioPlayResult.unavailable('test');
  }

  @override
  void bell(int index) => bells.add(index);

  @override
  void sfx(Sfx effect) => effects.add(effect);

  @override
  void playCorrectSound() => correct++;

  @override
  void playWrongSound() => wrong++;

  @override
  Future<void> startGameBgm() async {}

  @override
  Future<void> stopGameBgm() async {}

  @override
  Future<void> stop() async {}
}

Widget _app({required Size size, required _FakeAudio audio, int age = 5}) {
  final notifier = CurrentProfileNotifier(ProfileRepository())
    ..state = ChildProfile(id: 't', name: 'Lan', age: age, avatar: 'peach', createdAt: DateTime(2026, 1, 1));
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(audio),
      masteryRepositoryProvider.overrideWithValue(MasteryRepository()),
    ],
    child: MaterialApp(
      home: MediaQuery(data: MediaQueryData(size: size), child: const MelodyMemoryGame()),
    ),
  );
}

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

bool _yourTurn(WidgetTester tester) =>
    tester.widget<GameTargetBanner>(find.byType(GameTargetBanner)).label == 'Đến lượt bé!';

/// Pumps until Mai hands the child turn number [turn]; returns the melody
/// she rang meanwhile.
Future<List<int>> _waitForTurn(WidgetTester tester, _FakeAudio audio, int turn) async {
  for (var i = 0; i < 120 && !_yourTurn(tester); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(_yourTurn(tester), isTrue, reason: 'Mai should hand over turn $turn');
  final melody = List.of(audio.bells);
  audio.bells.clear();
  return melody;
}

Future<void> _tapMelody(WidgetTester tester, _FakeAudio audio, List<int> melody) async {
  for (final bell in melody) {
    await tester.tap(find.text(melodyBars[bell].animal));
    await tester.pump(const Duration(milliseconds: 120));
  }
  audio.bells.clear();
}

void main() {
  group('MelodyMemorySession', () {
    test('starts easy by age and grows a note per success', () {
      final young = MelodyMemorySession(age: 3, random: Random(1));
      expect(young.bells.length, 3);
      expect(young.sequence.length, 2);
      final older = MelodyMemorySession(age: 6, random: Random(1));
      expect(older.bells.length, 4);

      final s = MelodyMemorySession(age: 5, random: Random(2));
      final first = List.of(s.sequence);
      for (final n in first) {
        expect(s.tap(n), isTrue);
      }
      expect(s.attemptComplete, isTrue);
      s.completeMelody();
      expect(s.sequence.length, 3);
      expect(s.sequence.sublist(0, 2), first, reason: 'Simon style: melody keeps its start');
      expect(s.longest, first);
    });

    test('adds a bell after two successes in a row, never repeats a note twice in a row', () {
      final s = MelodyMemorySession(age: 5, random: Random(3));
      final bars = s.barCount;
      s.completeMelody();
      s.completeMelody();
      expect(s.barCount, bars + 1);
      for (var i = 1; i < s.sequence.length; i++) {
        expect(s.sequence[i], isNot(s.sequence[i - 1]));
      }
      for (final n in s.sequence) {
        expect(s.bells, contains(n));
      }
    });

    test('first slip replays, second shortens and drops a bell', () {
      final s = MelodyMemorySession(age: 5, random: Random(4));
      for (var i = 0; i < 4; i++) {
        s.completeMelody();
      }
      final len = s.sequence.length;
      final bars = s.barCount;
      expect(s.miss(), MelodyMiss.replay);
      expect(s.sequence.length, len);
      expect(s.miss(), MelodyMiss.shortened);
      expect(s.sequence.length, len - 1);
      expect(s.barCount, bars - 1);
      for (final n in s.sequence) {
        expect(s.bells, contains(n));
      }
      expect(s.mistakes, 2);
    });

    test('a shortened melody never rings the same bar twice in a row', () {
      for (var seed = 0; seed < 400; seed++) {
        // Long enough that the melody is a fresh one over all six bells,
        // so the bell that leaves can sit in the middle of it.
        final s = MelodyMemorySession(age: 7, random: Random(seed));
        for (var i = 0; i < 12; i++) {
          s.completeMelody();
        }
        s.miss();
        s.miss();
        for (var i = 1; i < s.sequence.length; i++) {
          expect(s.sequence[i], isNot(s.sequence[i - 1]), reason: 'seed $seed ${s.sequence}');
        }
      }
    });

    test('goal follows the age-based round count', () {
      expect(MelodyMemorySession(age: 3).goal, 4);
      expect(MelodyMemorySession(age: 5).goal, 6);
      expect(MelodyMemorySession(age: 7).goal, 8);
    });
  });

  for (final size in const [Size(360, 640), Size(1024, 768)]) {
    testWidgets('plays one melody back correctly at ${size.width.toInt()}', (tester) async {
      await _setSize(tester, size);
      final audio = _FakeAudio();
      await tester.pumpWidget(_app(size: size, audio: audio));
      await tester.pump();
      expect(audio.said.first, KidGuide.gameMelodyIntro);

      final melody = await _waitForTurn(tester, audio, 1);
      expect(melody.length, 2);
      expect(tester.takeException(), isNull);

      // Every bar is a big target.
      for (final bar in MelodyMemorySession.bellSets[4]!.map((b) => melodyBars[b])) {
        final rect = tester.getRect(find.ancestor(of: find.text(bar.animal), matching: find.byType(GestureDetector)).first);
        expect(rect.width, greaterThanOrEqualTo(64), reason: '${bar.name} $rect');
        expect(rect.height, greaterThanOrEqualTo(64), reason: '${bar.name} $rect');
      }

      await _tapMelody(tester, audio, melody);
      expect(audio.correct, 1, reason: 'one correct sound per full melody');
      expect(audio.wrong, 0);
      expect(find.text('1 / 6'), findsOneWidget);

      // Next round: Mai rings a longer melody.
      final next = await _waitForTurn(tester, audio, 2);
      expect(next.length, 3);
      expect(next.sublist(0, 2), melody);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a wrong note gets gentle feedback and a replay', (tester) async {
    const size = Size(390, 844);
    await _setSize(tester, size);
    final audio = _FakeAudio();
    await tester.pumpWidget(_app(size: size, audio: audio, age: 3));
    await tester.pump();
    final melody = await _waitForTurn(tester, audio, 1);
    final wrongBell = MelodyMemorySession.bellSets[3]!.firstWhere((b) => b != melody.first);
    await tester.tap(find.text(melodyBars[wrongBell].animal));
    await tester.pump(const Duration(milliseconds: 100));
    // A soft boop and "Bé nghe Mai gõ nhé!" at once; the melody waits for her.
    expect(audio.effects, contains(Sfx.wrong));
    expect(audio.said.last, KidGuide.gameMelodyListen);
    expect(audio.correct, 0);
    audio.bells.clear();
    await tester.pump(const Duration(milliseconds: 1800));
    expect(audio.bells, isEmpty, reason: 'no bell over Mai\'s line');
    final replayed = await _waitForTurn(tester, audio, 2);
    expect(replayed, melody, reason: 'first slip replays the same melody');
    expect(tester.takeException(), isNull);
  });

  testWidgets('praise is not cut off, and "your turn" is said once', (tester) async {
    const size = Size(390, 844);
    await _setSize(tester, size);
    final audio = _FakeAudio();
    await tester.pumpWidget(_app(size: size, audio: audio, age: 5));
    await tester.pump();
    var melody = await _waitForTurn(tester, audio, 1);
    await _tapMelody(tester, audio, melody);
    expect(audio.correct, 1);
    final saidAtPraise = audio.said.length;
    await tester.pump(const Duration(milliseconds: 2800));
    expect(audio.said.length, saidAtPraise, reason: 'nothing said over the praise line');
    expect(audio.bells, isEmpty, reason: 'no bell over the praise line');
    melody = await _waitForTurn(tester, audio, 2);
    await _tapMelody(tester, audio, melody);
    await _waitForTurn(tester, audio, 3);
    expect(audio.said.where((l) => l == KidGuide.gameMelodyYourTurn), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('finishing plays the concert, then the win panel', (tester) async {
    const size = Size(1024, 768);
    await _setSize(tester, size);
    final audio = _FakeAudio();
    await tester.pumpWidget(_app(size: size, audio: audio, age: 3));
    await tester.pump();
    final goal = MelodyMemorySession(age: 3).goal;
    List<int> longest = const [];
    for (var round = 1; round <= goal; round++) {
      final melody = await _waitForTurn(tester, audio, round);
      longest = melody;
      await _tapMelody(tester, audio, melody);
    }
    expect(audio.correct, goal);
    for (var i = 0; i < 40 && !audio.said.contains(KidGuide.gameMelodyConcert); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(audio.said, contains(KidGuide.gameMelodyConcert));
    for (var i = 0; i < 80 && find.byType(GameCompletePanel).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(audio.bells, longest, reason: 'the concert replays the longest melody');
    expect(find.byType(GameCompletePanel), findsOneWidget);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });
}
