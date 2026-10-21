import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/content/content_repository.dart';
import 'package:mai_an_learning/data/content/thinking_generator.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/features/explore/data/explore_catalog.dart';
import 'package:mai_an_learning/features/explore/logic/explore_quiz.dart';
import 'package:mai_an_learning/features/vietnamese/presentation/vietnamese_activities.dart';
import 'package:mai_an_learning/features/vietnamese/presentation/vietnamese_letter_lesson_screen.dart';

Widget _app(Widget home, ContentRepository content) {
  final notifier = CurrentProfileNotifier(ProfileRepository())
    ..state = ChildProfile(id: 't', name: 'Lan', age: 5, avatar: 'peach', createdAt: DateTime(2026, 1, 1));
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(AudioService()..soundEnabled = false),
      contentRepositoryProvider.overrideWithValue(content),
    ],
    child: MaterialApp(home: home),
  );
}

Future<ContentRepository> _content(WidgetTester tester) async {
  final repo = ContentRepository();
  await tester.runAsync(repo.loadAllContent);
  return repo;
}

Future<void> _settle(WidgetTester tester, [int steps = 12]) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

double _page(WidgetTester tester) => tester.widget<PageView>(find.byType(PageView)).controller!.page!;

void main() {
  testWidgets('Ghép âm does not show the joined syllable (the answer) before the child picks', (tester) async {
    await _phone(tester);
    final content = await _content(tester);
    await tester.pumpWidget(_app(
      VietnameseQuizListScreen(
        title: 'Ghép âm',
        skill: 'vietnamese.blend',
        loader: (ref) => ref.read(contentRepositoryProvider).getVietnamesePhonics(),
      ),
      content,
    ));
    await _settle(tester, 4);
    // First item is b + a = ba: "ba" may only be one of the four choices.
    expect(find.text('b + a'), findsOneWidget);
    expect(find.text('ba'), findsOneWidget);

    await tester.tap(find.text('ba'));
    await tester.pump(const Duration(milliseconds: 100));
    // Once found, the syllable chip appears next to b and a.
    expect(find.text('ba'), findsNWidgets(2));
    await _settle(tester);
  });

  testWidgets('letter lesson: "Ôn lại" after the last letter goes back to the first one', (tester) async {
    await _phone(tester);
    final content = await _content(tester);
    await tester.pumpWidget(_app(const VietnameseLetterLessonScreen(startId: 'v_y'), content));
    await _settle(tester, 4);
    await tester.tap(find.text('Tiếp tục!'));
    await _settle(tester, 4);
    expect(find.text('Ôn lại'), findsOneWidget);

    await tester.tap(find.text('Ôn lại'));
    await _settle(tester, 4);
    // Before the fix the button did nothing: the PageView controller had no clients.
    expect(find.text('Ôn lại'), findsNothing);
    expect(find.text('Học âm chữ: A'), findsOneWidget);
  });

  testWidgets('letter lesson: tapping "Tiếp tục" right after a correct answer moves one letter, not two', (tester) async {
    await _phone(tester);
    final content = await _content(tester);
    await tester.pumpWidget(_app(const VietnameseLetterLessonScreen(startId: 'v_a', startMode: 'recognize'), content));
    await _settle(tester, 4);
    expect(_page(tester), 0);
    // The letter to find is never printed in recognize mode.
    expect(find.text('Học âm chữ: A'), findsNothing);

    await tester.tap(find.text('A'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Tiếp tục!'));
    await _settle(tester);
    expect(_page(tester), 1);
  });

  test('"Chọn chữ" letter-in-word: distractor words never contain the letter', () {
    expect(vietnameseWordHasLetter('cá', 'a'), isTrue);
    expect(vietnameseWordHasLetter('táo', 'o'), isTrue);
    expect(vietnameseWordHasLetter('cờ', 'ơ'), isTrue);
    expect(vietnameseWordHasLetter('ăn', 'a'), isFalse);
    expect(vietnameseWordHasLetter('ấm', 'â'), isTrue);
    expect(vietnameseWordHasLetter('đu đủ', 'd'), isFalse);
    expect(vietnameseWordHasLetter('dù', 'D'), isTrue);
  });

  test('thinking puzzles do not come back within eight questions', () {
    String root(String id) => id.replaceFirst(RegExp(r'_\d+$'), '').replaceFirst(RegExp(r'_b$'), '');
    final engine = ThinkingQuestionEngine(random: Random(7));
    final seen = <String>[];
    for (var i = 0; i < 60; i++) {
      final item = engine.next(age: 5);
      if (item.id.startsWith('shape_') || item.id.startsWith('color_')) continue;
      final id = root(item.id);
      final window = seen.length > 6 ? seen.sublist(seen.length - 6) : seen;
      expect(window, isNot(contains(id)), reason: 'repeated $id after ${seen.length} questions');
      seen.add(id);
    }
  });

  test('explore quiz never offers a second picture that also fits the question', () {
    expect(namesOverlap('con cá', 'con cá heo'), isTrue);
    expect(namesOverlap('máy bay', 'máy bay trực thăng'), isTrue);
    expect(namesOverlap('quả đào', 'quả anh đào'), isTrue);
    expect(namesOverlap('cái chân', 'bàn chân'), isTrue);
    expect(namesOverlap('con gà trống', 'con gà mái'), isFalse);
    expect(namesOverlap('bàn tay', 'ngón tay'), isFalse);

    final catalog = ExploreCatalog.parse(File(ExploreCatalog.assetPath).readAsStringSync());
    for (final category in catalog.categories) {
      for (var seed = 0; seed < 40; seed++) {
        final round = ExploreQuizRound.generate(category, random: Random(seed));
        for (final q in round.questions) {
          expect(q.choices.where((c) => c.id == q.target.id), hasLength(1));
          for (final c in q.choices) {
            if (c.id == q.target.id) continue;
            expect(namesOverlap(c.name, q.target.name), isFalse, reason: '${q.prompt} with ${c.name}');
          }
        }
      }
    }
  });
}
