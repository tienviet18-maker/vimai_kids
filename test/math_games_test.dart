import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/content/game_catalog.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/features/games/presentation/feed_animal_game.dart';
import 'package:mai_an_learning/features/games/presentation/math_rocket_game.dart';
import 'package:mai_an_learning/features/games/presentation/number_train_game.dart';
import 'package:mai_an_learning/features/games/presentation/widgets/game_play_scaffold.dart';
import 'package:mai_an_learning/features/shared/widgets/choice_grid.dart';

Widget _app(Widget game, {int age = 5}) {
  final notifier = CurrentProfileNotifier(ProfileRepository())
    ..state = ChildProfile(id: 't', name: 'Lan', age: age, avatar: 'peach', createdAt: DateTime(2026, 1, 1),
        // The games copy these onto AudioService; silent keeps tests free of audio timers.
        settings: const {'sound': false, 'bgm': false});
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(AudioService()
        ..soundEnabled = false
        ..sfxEnabled = false),
    ],
    child: MaterialApp(home: game),
  );
}

Future<void> _settle(WidgetTester tester, [int ms = 2500]) async {
  for (var t = 0; t < ms; t += 250) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1024, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

List<String> _choices(WidgetTester tester) => tester.widget<ChoiceGrid>(find.byType(ChoiceGrid)).choices;

Future<void> _tapChoice(WidgetTester tester, String c) async {
  await tester.tap(find.descendant(of: find.byType(ChoiceGrid), matching: find.text(c)));
  await tester.pump(const Duration(milliseconds: 50));
}

/// The sum on the rocket's panel: "3 + 4 = ?" or a picture sum "🍎🍎 + 🍎".
String _sum(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').firstWhere((t) => t.contains(' + '));

String _answerOf(String q) {
  final sides = q.replaceAll(' = ?', '').split(' + ');
  int value(String side) => int.tryParse(side.trim()) ?? side.runes.where((r) => r != 0xFE0F && r != 0x20).length;
  return '${value(sides[0]) + value(sides[1])}';
}

int _progress(WidgetTester tester) => tester.widget<GameProgressBar>(find.byType(GameProgressBar)).current;

/// Taps choices in order until one is right (progress moves), then waits for
/// the next round. Returns how many wrong taps it took.
Future<int> _solveRound(WidgetTester tester) async {
  final before = _progress(tester);
  var wrong = 0;
  for (final c in _choices(tester)) {
    await _tapChoice(tester, c);
    if (_progress(tester) > before) break;
    wrong++;
  }
  expect(_progress(tester), before + 1, reason: 'one of the choices must be the answer');
  await _settle(tester);
  return wrong;
}

void main() {
  testWidgets('math rocket: picture sums never show an empty side; replayed wrong taps count once', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(_app(const MathRocketGame(), age: 3));
    await _settle(tester, 500);
    final goal = GameCatalog.sessionRounds(GameKind.mathRocket, 3);
    for (var r = 0; r < goal; r++) {
      final q = _sum(tester);
      expect(q.startsWith(' ') || q.endsWith(' '), isFalse, reason: 'empty side in "$q"');
      final answer = _answerOf(q);
      expect(_choices(tester), contains(answer));
      if (r == 0) {
        // Hammer the same wrong answer: it costs one mark, not three.
        final bad = _choices(tester).firstWhere((c) => c != answer);
        for (var i = 0; i < 3; i++) {
          await _tapChoice(tester, bad);
        }
      }
      await _tapChoice(tester, answer);
      expect(_progress(tester), r + 1);
      await _settle(tester);
    }
    expect(tester.widget<GameCompletePanel>(find.byType(GameCompletePanel)).wrong, 1);
    await _settle(tester);
  });

  testWidgets('math rocket: praise is not cut off, the next sum waits for it', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(_app(const MathRocketGame()));
    await _settle(tester, 500);
    final first = _choices(tester);
    final before = _progress(tester);
    for (final c in first) {
      await _tapChoice(tester, c);
      if (_progress(tester) > before) break;
    }
    // Still on the solved sum while Mai praises.
    await tester.pump(const Duration(milliseconds: 1000));
    expect(tester.widget<ChoiceGrid>(find.byType(ChoiceGrid)).lastCorrect, isTrue);
    await _settle(tester);
    expect(tester.widget<ChoiceGrid>(find.byType(ChoiceGrid)).lastCorrect, isNull);
    await _settle(tester);
  });

  testWidgets('feed animal: the panda is only ever fed food', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(_app(const FeedAnimalGame(), age: 4));
    await _settle(tester, 500);
    const food = {'🍎', '🍌', '🍓', '🍇', '🍊', '🧁'};
    for (var r = 0; r < GameCatalog.sessionRounds(GameKind.feedAnimal, 4); r++) {
      final glyph = tester.widget<GameTargetBanner>(find.byType(GameTargetBanner)).glyph;
      expect(food, contains(glyph));
      await _solveRound(tester);
    }
    expect(find.byType(GameCompletePanel), findsOneWidget);
    await _settle(tester);
  });

  group('number train', () {
    List<int> cargo(WidgetTester tester) => tester
        .widgetList(find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('cargo-')))
        .map((w) => int.parse((w.key as ValueKey<String>).value.substring(6)))
        .toList();

    Future<void> tapBox(WidgetTester tester, int n) async {
      await tester.tap(find.byKey(ValueKey('cargo-$n')));
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('a wrong box bounces back but keeps the wagons already loaded', (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(_app(const NumberTrainGame()));
      await _settle(tester, 500);
      final nums = cargo(tester)..sort();
      expect(nums, hasLength(5));

      await tapBox(tester, nums[0]);
      await tapBox(tester, nums[1]);
      // Wrong: skip ahead. Twice on the same train counts one mark.
      await tapBox(tester, nums[4]);
      await tapBox(tester, nums[3]);
      // The right ones are still on board; finish the train.
      for (final n in nums.skip(2)) {
        await tapBox(tester, n);
      }
      expect(_progress(tester), 1);

      // "Làm lại" during the drive-off starts a fresh train that the old
      // timer must not wipe once the child has started loading it.
      await tester.tap(find.text('Làm lại'));
      await tester.pump(const Duration(milliseconds: 50));
      final next = cargo(tester)..sort();
      await tapBox(tester, next[0]);
      await _settle(tester);
      final wagons = find.byWidgetPredicate((w) => w is Text && w.data == '${next[0]}');
      expect(wagons, findsNWidgets(2), reason: 'loaded wagon + its used cargo box');
      expect(_progress(tester), 1);
    });

    testWidgets('a whole session counts one mark per train with a slip', (tester) async {
      _bigScreen(tester);
      await tester.pumpWidget(_app(const NumberTrainGame(), age: 3));
      await _settle(tester, 500);
      final goal = GameCatalog.sessionRounds(GameKind.numberTrain, 3);
      for (var r = 0; r < goal; r++) {
        final nums = cargo(tester)..sort();
        if (r.isEven) {
          await tapBox(tester, nums[2]);
          await tapBox(tester, nums[3]);
        }
        for (final n in nums) {
          await tapBox(tester, n);
        }
        await _settle(tester);
      }
      final done = tester.widget<GameCompletePanel>(find.byType(GameCompletePanel));
      expect(done.score, goal);
      expect(done.wrong, (goal + 1) ~/ 2);
      await _settle(tester);
    });
  });

  test('number train never deals a train that is already in order', () {
    for (var seed = 0; seed < 300; seed++) {
      final t = GameCatalog.numberTrain(3, Random(seed));
      expect(t, isNot(orderedEquals([...t]..sort())));
    }
  });
}
