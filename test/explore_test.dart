import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/audio/speech_id.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/features/explore/data/explore_catalog.dart';
import 'package:mai_an_learning/features/explore/explore_guide.dart';
import 'package:mai_an_learning/features/explore/logic/explore_quiz.dart';
import 'package:mai_an_learning/features/explore/presentation/explore_category_screen.dart';
import 'package:mai_an_learning/features/explore/presentation/explore_hub_screen.dart';
import 'package:mai_an_learning/features/explore/presentation/explore_quiz_screen.dart';

/// Records what Mai would say instead of playing audio.
class _FakeAudio extends AudioService {
  final said = <String>[];

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
  Future<void> stop() async {}
}

final _catalog = ExploreCatalog.parse(File(ExploreCatalog.assetPath).readAsStringSync());

Widget _app({required Size size, required Widget home, required _FakeAudio audio}) {
  final notifier = CurrentProfileNotifier(ProfileRepository())
    ..state = ChildProfile(id: 't', name: 'Lan', age: 5, avatar: 'peach', createdAt: DateTime(2026, 1, 1));
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(audio),
      exploreCatalogProvider.overrideWith((ref) async => _catalog),
    ],
    child: MaterialApp(
      home: MediaQuery(data: MediaQueryData(size: size), child: home),
    ),
  );
}

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _sizes = [Size(360, 740), Size(390, 844), Size(412, 915), Size(768, 1024), Size(1024, 768), Size(1366, 900)];

void main() {
  group('explore data', () {
    test('has at least 10 topics with 12+ complete, unique items each', () {
      expect(_catalog.categories.length, greaterThanOrEqualTo(10));
      final categoryIds = <String>{};
      for (final c in _catalog.categories) {
        expect(categoryIds.add(c.id), isTrue, reason: 'duplicate category ${c.id}');
        expect(c.title.trim(), isNotEmpty);
        expect(c.emoji.trim(), isNotEmpty);
        expect(c.items.length, inInclusiveRange(12, 18), reason: c.id);
        final ids = <String>{};
        final names = <String>{};
        final emoji = <String>{};
        for (final item in c.items) {
          expect(ids.add(item.id), isTrue, reason: 'duplicate id ${c.id}.${item.id}');
          expect(names.add(item.name), isTrue, reason: 'duplicate name ${item.name}');
          expect(emoji.add(item.emoji), isTrue, reason: 'duplicate picture ${item.emoji} in ${c.id}');
          expect(item.emoji.trim(), isNotEmpty);
          expect(item.name.trim(), isNotEmpty);
          expect(item.fact.trim(), isNotEmpty);
          expect(item.fact.endsWith('.'), isTrue, reason: item.fact);
          // One short sentence a small child can follow.
          expect(item.fact.split(' ').length, lessThanOrEqualTo(16), reason: item.fact);
          expect(RegExp(r'[.!?]').allMatches(item.fact).length, 1, reason: item.fact);
          expect(SpeechId.spokenText(item.name), isNotNull);
        }
      }
    });

    test('quiz questions are built one way and exported for voicing', () {
      final item = _catalog.categories.first.items.first;
      expect(item.question, exploreQuestion(item.name));
      expect(exploreQuestion('con mèo'), 'Đâu là con mèo?');

      final lines = File('tool/speech/speech_lines.json').readAsStringSync();
      for (final c in _catalog.categories) {
        expect(lines, contains(SpeechId.forText(SpeechId.spokenText(c.title)!)));
        for (final i in c.items) {
          for (final t in [i.name, i.fact, i.question]) {
            expect(lines, contains(SpeechId.forText(SpeechId.spokenText(t)!)), reason: t);
          }
        }
      }
      for (final t in ExploreGuide.all) {
        expect(lines, contains(SpeechId.forText(SpeechId.spokenText(t)!)), reason: t);
      }
    });

    test('quiz rounds have distinct targets and four distinct choices', () {
      for (final c in _catalog.categories) {
        for (var seed = 0; seed < 20; seed++) {
          final round = ExploreQuizRound.generate(c, random: Random(seed));
          expect(round.questions.length, inInclusiveRange(5, 8));
          expect(round.questions.map((q) => q.target.id).toSet().length, round.questions.length);
          for (final q in round.questions) {
            expect(q.choices.length, 4);
            expect(q.choices.map((e) => e.id).toSet().length, 4);
            expect(q.choices.where((e) => e.id == q.target.id).length, 1);
          }
        }
      }
    });
  });

  group('explore screens', () {
    for (final size in _sizes) {
      testWidgets('hub renders without overflow at ${size.width.toInt()}', (tester) async {
        await _setSize(tester, size);
        final audio = _FakeAudio();
        await tester.pumpWidget(_app(size: size, home: const ExploreHubScreen(), audio: audio));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expect(find.text('Khám phá thế giới'), findsOneWidget);
        expect(find.text(_catalog.categories.first.title), findsOneWidget);
        expect(audio.said, contains(ExploreGuide.hub));
      });

      testWidgets('topic, story card and quiz render without overflow at ${size.width.toInt()}', (tester) async {
        await _setSize(tester, size);
        final audio = _FakeAudio();
        final category = _catalog.categories.first;
        await tester.pumpWidget(_app(size: size, home: ExploreCategoryScreen(categoryId: category.id), audio: audio));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expect(find.text(category.title), findsOneWidget);
        expect(audio.said, containsAll([category.title, ExploreGuide.category]));

        // Open the first card: Mai says its name and fact.
        final first = category.items.first;
        await tester.tap(find.text(first.name));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expect(find.text(first.fact), findsOneWidget);
        expect(audio.said, containsAll([first.name, first.fact]));
        await tester.tap(find.bySemanticsLabel('Hình tiếp theo'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(audio.said, contains(category.items[1].name));
        expect(tester.takeException(), isNull);
      });

      testWidgets('quiz plays a round to the reward at ${size.width.toInt()}', (tester) async {
        await _setSize(tester, size);
        final audio = _FakeAudio();
        final category = _catalog.categories[2];
        final round = ExploreQuizRound.generate(category, random: Random(3));
        await tester.pumpWidget(_app(
          size: size,
          home: ExploreQuizScreen(categoryId: category.id, random: Random(3)),
          audio: audio,
        ));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(audio.said, containsAll([ExploreGuide.quizStart, round.questions.first.prompt]));

        for (var i = 0; i < round.questions.length; i++) {
          final q = round.questions[i];
          expect(find.text(q.prompt), findsOneWidget);
          if (i == 0) {
            // A wrong pick: Mai encourages and repeats the question.
            final wrong = q.choices.firstWhere((e) => e.id != q.target.id);
            await tester.tap(find.text(wrong.emoji));
            await tester.pump(const Duration(milliseconds: 600));
            expect(audio.said.where((l) => l == q.prompt).length, greaterThanOrEqualTo(2));
          }
          await tester.tap(find.text(q.target.emoji));
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull);
          await tester.pump(const Duration(seconds: 3));
          await tester.pump(const Duration(seconds: 1));
        }
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Chơi lại'), findsOneWidget);
        expect(audio.said.last, ExploreGuide.quizDone);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
