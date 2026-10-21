import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/audio/kid_guide.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/content/content_repository.dart';
import 'package:mai_an_learning/data/repositories/kana_repository_impl.dart';
import 'package:mai_an_learning/data/repositories/mastery_repository.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/features/games/logic/drum_count_round.dart';
import 'package:mai_an_learning/features/games/presentation/drum_count_game.dart';
import 'package:mai_an_learning/features/games/presentation/widgets/game_play_scaffold.dart';

/// Records when (in fake time) Mai speaks and the beats play.
class _TimedAudio extends AudioService {
  int nowMs = 0;
  final events = <(int, String)>[];

  @override
  Future<AudioPlayResult> speak(
    List<String?> lines, {
    String? fallbackId,
    List<String> leadIds = const [],
    List<String> trailIds = const [],
  }) async {
    for (final l in lines.whereType<String>()) {
      events.add((nowMs, l));
    }
    return const AudioPlayResult.unavailable('test');
  }

  @override
  void playCorrectSound() => events.add((nowMs, 'praise'));

  @override
  void playWrongSound() => events.add((nowMs, 'retry'));

  @override
  void sfx(Sfx effect) => events.add((nowMs, 'sfx_${effect.name}'));

  @override
  void bell(int index) => events.add((nowMs, 'bell'));

  @override
  Future<void> stop() async {}

  int firstAt(String what, {int from = 0}) => events.firstWhere((e) => e.$1 >= from && e.$2 == what).$1;
}

Future<void> _run(WidgetTester tester, _TimedAudio audio, int ms) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
    audio.nowMs += 50;
  }
}

Widget _app({required Size size, required int age, AudioService? audio}) {
  final notifier = CurrentProfileNotifier(ProfileRepository())
    ..state = ChildProfile(id: 'test', name: 'Lan', age: age, avatar: 'peach', createdAt: DateTime(2026, 1, 1));
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(audio ?? (AudioService()..soundEnabled = false)),
      kanaRepositoryProvider.overrideWithValue(KanaRepositoryImpl()),
      contentRepositoryProvider.overrideWithValue(ContentRepository()),
      masteryRepositoryProvider.overrideWithValue(MasteryRepository()),
    ],
    child: MaterialApp(
      home: MediaQuery(data: MediaQueryData(size: size), child: const DrumCountGame()),
    ),
  );
}

Future<void> _settle(WidgetTester tester, {int seconds = 12}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

int _answer(WidgetTester tester) {
  final keyed = find.byWidgetPredicate((w) {
    final k = w.key;
    return k is ValueKey<String> && k.value.startsWith('drum-count-answer-');
  });
  expect(keyed, findsOneWidget);
  final key = tester.widget(keyed).key! as ValueKey<String>;
  return int.parse(key.value.substring('drum-count-answer-'.length));
}

void main() {
  group('DrumCountRound', () {
    test('answers stay in each level range and are among the choices', () {
      for (var level = 0; level < DrumCountRound.levels.length; level++) {
        final l = DrumCountRound.levels[level];
        for (var seed = 0; seed < 60; seed++) {
          final r = DrumCountRound.generate(level: level, age: 7, random: Random(seed));
          expect(r.choices, contains(r.answer));
          expect(r.choices.toSet().length, r.choices.length);
          expect(r.choices.length, l.choiceCount);
          expect(r.choices, orderedEquals([...r.choices]..sort()));
          if (!r.mixed) {
            expect(r.answer, inInclusiveRange(l.minCount, l.maxCount));
            expect(l.sounds, contains(r.target));
          } else {
            expect(r.target, DrumSound.bell);
            expect(r.prompt, KidGuide.drumAskMixed);
          }
          expect(KidGuide.all, contains(r.prompt));
        }
      }
    });

    test('easy level is 1 to 3 drum beats with cards 1 2 3', () {
      final r = DrumCountRound.generate(level: 0, age: 3, random: Random(1));
      expect(r.target, DrumSound.drum);
      expect(r.choices, [1, 2, 3]);
      expect(r.prompt, KidGuide.drumAskDrum);
    });

    test('mixed bell rounds only for older kids at the top level', () {
      final top = DrumCountRound.levels.length - 1;
      var mixed = 0;
      for (var seed = 0; seed < 100; seed++) {
        expect(DrumCountRound.generate(level: top, age: 5, random: Random(seed)).mixed, isFalse);
        if (DrumCountRound.generate(level: top, age: 7, random: Random(seed)).mixed) mixed++;
      }
      expect(mixed, greaterThan(0));
      expect(DrumCountRound.maxLevel(3), lessThan(top));
    });

    test('count-along numbers play their bundled math_num clips', () {
      expect(AudioService.mathClips('7'), ['math_num_7']);
      expect(AudioService.normalizeKey('math_num_7'), 'math_num_7');
      expect(AudioService.normalizeKey('math_op_plus'), 'math_op_plus');
    });

    test('does not repeat the previous answer', () {
      for (var seed = 0; seed < 50; seed++) {
        final r = DrumCountRound.generate(level: 1, age: 5, random: Random(seed), avoidAnswer: 3);
        expect(r.answer, isNot(3));
      }
    });
  });

  group('DrumCountGame UI', () {
    for (final size in const [Size(360, 640), Size(1024, 768)]) {
      testWidgets('plays one correct answer at ${size.width.toInt()}', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(_app(size: size, age: 4));
        await tester.pump();
        await _settle(tester);
        expect(tester.takeException(), isNull, reason: 'overflow at $size');

        expect(find.text('Nghe lại'), findsOneWidget);
        final answer = _answer(tester);
        final card = find.byKey(ValueKey('drum-card-$answer'));
        expect(card, findsOneWidget);
        final rect = tester.getRect(card);
        expect(rect.width, greaterThanOrEqualTo(64));
        expect(rect.height, greaterThanOrEqualTo(64));
        expect(rect.right, lessThanOrEqualTo(size.width));

        await tester.tap(card);
        await tester.pump();
        expect(find.text('Giỏi lắm!'), findsOneWidget);
        expect(tester.widget<GameProgressBar>(find.byType(GameProgressBar)).current, 1);

        // Count-along, then the next round starts and its beats play.
        await _settle(tester, seconds: 20);
        expect(tester.takeException(), isNull, reason: 'after answer at $size');
        expect(find.text('Giỏi lắm!'), findsNothing);
        expect(find.text('Nghe lại'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await _settle(tester, seconds: 2);
      });
    }

    testWidgets('a wrong pick shakes and lets the child retry', (tester) async {
      const size = Size(390, 844);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app(size: size, age: 5));
      await tester.pump();
      await _settle(tester);
      final answer = _answer(tester);
      final wrong = find.byWidgetPredicate((w) {
        final k = w.key;
        return k is ValueKey<String> && k.value.startsWith('drum-card-') && k.value != 'drum-card-$answer';
      }).first;
      await tester.tap(wrong);
      await tester.pump();
      expect(find.text('Thử lại nhé!'), findsOneWidget);
      expect(tester.widget<GameProgressBar>(find.byType(GameProgressBar)).current, 0);
      await _settle(tester, seconds: 2);
      await tester.tap(find.byKey(ValueKey('drum-card-$answer')));
      await tester.pump();
      expect(tester.widget<GameProgressBar>(find.byType(GameProgressBar)).current, 1);
      await _settle(tester, seconds: 20);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await _settle(tester, seconds: 2);
    });

    testWidgets('beats wait for Mai, and nothing cuts her lines short', (tester) async {
      const size = Size(390, 844);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final audio = _TimedAudio();
      await tester.pumpWidget(_app(size: size, age: 4, audio: audio));
      await tester.pump();
      await _run(tester, audio, 12000);

      // Intro clip (4.7 s, played to its end) + question (speech ~3.2 s):
      // the first beat must not land on top of the question.
      expect(audio.firstAt(KidGuide.gameDrumCount), 0);
      expect(audio.firstAt('sfx_drum'), greaterThanOrEqualTo(7900));

      // Right answer: the praise line (~2.9 s) plays before Mai counts "1".
      final answer = _answer(tester);
      await tester.tap(find.byKey(ValueKey('drum-card-$answer')));
      final tapAt = audio.nowMs;
      await _run(tester, audio, 6000);
      expect(audio.firstAt('praise', from: tapAt), tapAt);
      expect(audio.firstAt('1', from: tapAt) - tapAt, greaterThanOrEqualTo(2850)); // 50 ms pump steps
      await tester.pumpWidget(const SizedBox());
      await _settle(tester, seconds: 2);
    });

    testWidgets('after two misses Mai counts together once, not again after the answer', (tester) async {
      const size = Size(390, 844);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final audio = _TimedAudio();
      await tester.pumpWidget(_app(size: size, age: 4, audio: audio));
      await tester.pump();
      await _run(tester, audio, 12000);
      final answer = _answer(tester);
      final wrongs = [1, 2, 3].where((n) => n != answer).toList();
      await tester.tap(find.byKey(ValueKey('drum-card-${wrongs[0]}')));
      await _run(tester, audio, 1000);
      await tester.tap(find.byKey(ValueKey('drum-card-${wrongs[1]}')));
      final secondMiss = audio.nowMs;
      await tester.pump();
      // "Mình cùng đếm lại nào!" straight away, no retry line for it to cut.
      expect(audio.events.where((e) => e.$1 >= secondMiss).map((e) => e.$2), isNot(contains('retry')));
      expect(audio.firstAt(KidGuide.drumCountTogether, from: secondMiss), secondMiss);
      await _run(tester, audio, 1900 + answer * 780 + 600);
      expect(audio.events.where((e) => e.$1 >= secondMiss && e.$2 == '$answer'), hasLength(1));

      await tester.tap(find.byKey(ValueKey('drum-card-$answer')));
      final tapAt = audio.nowMs;
      await _run(tester, audio, 3500);
      expect(tester.widget<GameProgressBar>(find.byType(GameProgressBar)).current, 1);
      // No second count-along: the next question comes after the praise.
      expect(audio.events.where((e) => e.$1 >= tapAt && e.$2 == '1'), isEmpty);
      expect(audio.events.where((e) => e.$1 >= tapAt && e.$2.startsWith('Bé nghe thật kỹ')), isNotEmpty);
      await tester.pumpWidget(const SizedBox());
      await _settle(tester, seconds: 2);
    });
  });
}
