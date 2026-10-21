import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/content/game_catalog.dart';
import 'package:mai_an_learning/data/repositories/mastery_repository.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/features/math/presentation/math_screen.dart';
import 'package:mai_an_learning/features/shared/widgets/choice_grid.dart';
import 'package:mai_an_learning/features/shared/widgets/listen_prompt.dart';

Widget _app(String skill, {required int age}) {
  final notifier = CurrentProfileNotifier(ProfileRepository())
    ..state = ChildProfile(id: 't', name: 'Lan', age: age, avatar: 'peach', createdAt: DateTime(2026, 1, 1),
        settings: const {'sound': false, 'bgm': false});
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      masteryRepositoryProvider.overrideWithValue(MasteryRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(AudioService()
        ..soundEnabled = false
        ..sfxEnabled = false),
    ],
    child: MaterialApp(home: MathQuizScreen(skill: skill)),
  );
}

Future<void> _settle(WidgetTester tester, [int ms = 2500]) async {
  for (var t = 0; t < ms; t += 250) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

List<String> _choices(WidgetTester tester) => tester.widget<ChoiceGrid>(find.byType(ChoiceGrid)).choices;

/// Texts inside the question card (instruction + question row).
List<String> _prompt(WidgetTester tester) => [
      for (final t in tester.widgetList<Text>(find.descendant(of: find.byType(ListenPrompt), matching: find.byType(Text))))
        t.data ?? '',
    ];

String _score(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').firstWhere((t) => t.startsWith('Đúng '));

/// Taps choices until the score moves; returns the right one.
Future<String> _solve(WidgetTester tester) async {
  final before = _score(tester);
  for (final c in _choices(tester)) {
    await tester.tap(find.byKey(ValueKey('choice-${_choices(tester).indexOf(c)}-$c')));
    await tester.pump(const Duration(milliseconds: 50));
    if (_score(tester) != before) {
      await _settle(tester);
      return c;
    }
    await _settle(tester, 1500);
  }
  fail('no choice was right: ${_choices(tester)} / ${_prompt(tester)}');
}

void _bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1024, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('comparison: two choices, the bigger one wins, never "bằng nhau"', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(_app('comparison', age: 4));
    await _settle(tester, 500);
    for (var r = 0; r < GameCatalog.roundsForAge(4); r++) {
      final prompt = _prompt(tester);
      final choices = _choices(tester);
      expect(choices.length, 2, reason: '$prompt $choices');
      expect(choices, isNot(contains('bằng nhau')));
      final right = await _solve(tester);
      if (prompt.first == 'Số nào lớn hơn?') {
        final nums = choices.map(int.parse).toList();
        expect(int.parse(right), nums.reduce((a, b) => a > b ? a : b));
        expect(prompt.last.split(RegExp(r'\s+')).toSet(), choices.toSet(), reason: 'choices are the numbers shown');
      } else {
        expect(prompt, ['Nhóm nào nhiều hơn?'], reason: 'groups are the buttons; no second picture row');
        int count(String g) => g.split('\n').join().runes.where((r) => r != 0xFE0F).length;
        expect(count(right), greaterThan(count(choices.firstWhere((c) => c != right))));
      }
    }
    await _settle(tester);
  });

  testWidgets('number recognition: the prompt never shows the numeral to tap', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(_app('number_recognition', age: 3));
    await _settle(tester, 500);
    for (var r = 0; r < 4; r++) {
      final prompt = _prompt(tester).join(' ');
      expect(prompt, startsWith('Số nào là số '));
      expect(RegExp(r'\d').hasMatch(prompt), isFalse, reason: prompt);
      final right = await _solve(tester);
      expect(int.parse(right), inInclusiveRange(1, 10));
    }
    await _settle(tester);
  });

  testWidgets('addition in 5 at age 4: no "+ 0" and no empty picture side', (tester) async {
    _bigScreen(tester);
    await tester.pumpWidget(_app('addition_under_5', age: 4));
    await _settle(tester, 500);
    for (var r = 0; r < 6; r++) {
      final q = _prompt(tester).last;
      expect(q.startsWith(' ') || q.endsWith(' '), isFalse, reason: q);
      expect(q.contains(' 0') || q.startsWith('0'), isFalse, reason: q);
      final right = await _solve(tester);
      expect(int.parse(right), inInclusiveRange(2, 5));
      expect(_choices(tester).isNotEmpty, isTrue);
    }
    await _settle(tester);
  });

  test('skill intros never contradict the question that follows', () {
    // sys_math_shapes is about "hình khối", not picture sums.
    expect(AudioService.introForMathSkill('picture_math'), isNot('sys_math_shapes'));
    // sys_math_order says "từ nhỏ đến lớn"; a pattern can count down.
    expect(AudioService.introForMathSkill('number_pattern'), isNot('sys_math_order'));
    // sys_math_compare says "nhóm nào nhiều hơn"; these ask for a sign.
    expect(AudioService.introForMathSkill('compare_expressions'), isNot('sys_math_compare'));
    // sys_math_calc_add says "phép tính cộng"; the answer may be "−".
    expect(AudioService.introForMathSkill('fill_plus_minus'), isNot('sys_math_calc_add'));
    expect(AudioService.introForMathSkill('comparison'), 'sys_math_compare');
  });
}
