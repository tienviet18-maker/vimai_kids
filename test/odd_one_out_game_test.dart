import 'dart:io';
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
import 'package:mai_an_learning/features/explore/data/explore_catalog.dart';
import 'package:mai_an_learning/features/games/logic/odd_one_out_round.dart';
import 'package:mai_an_learning/features/games/presentation/odd_one_out_game.dart';
import 'package:mai_an_learning/features/games/presentation/widgets/game_play_scaffold.dart';

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

Widget _app({required Size size, required _FakeAudio audio, int age = 5}) {
  final notifier = CurrentProfileNotifier(ProfileRepository())
    ..state = ChildProfile(id: 't', name: 'Lan', age: age, avatar: 'peach', createdAt: DateTime(2026, 1, 1));
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(audio..soundEnabled = false),
      masteryRepositoryProvider.overrideWithValue(MasteryRepository()),
      exploreCatalogProvider.overrideWith((ref) async => _catalog),
    ],
    child: MaterialApp(
      home: MediaQuery(data: MediaQueryData(size: size), child: OddOneOutGame(random: Random(3))),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OddOneOutRound', () {
    test('every category has a question and every level builds valid rounds', () {
      for (final c in _catalog.categories) {
        expect(KidGuide.oddOneOutQuestions[c.id], isNotNull, reason: c.id);
      }
      for (var level = 0; level <= OddOneOutRound.maxLevel; level++) {
        expect(OddOneOutRound.pairsFor(_catalog, level), isNotEmpty);
        for (var seed = 0; seed < 200; seed++) {
          final r = OddOneOutRound.generate(_catalog, level: level, random: Random(seed));
          expect(r.cards.length, OddOneOutRound.cardCount(level));
          expect(r.cards.where(r.isOdd).length, 1);
          expect(r.cards.map((e) => e.id).toSet().length, r.cards.length);
          for (final card in r.cards.where((e) => !r.isOdd(e))) {
            expect(r.majority.items.contains(card), isTrue);
          }
          expect(r.oddCategory.items.contains(r.odd), isTrue);
          expect(r.oddCategory.id, isNot(r.majority.id));
          expect(r.explanation, startsWith(r.odd.name[0].toUpperCase()));
          expect(r.explanation, endsWith('không giống các bạn kia.'));
        }
      }
    });

    test('easy levels never mix close topics', () {
      const animals = {'pets', 'wild', 'sea', 'bugs_birds'};
      for (final (a, b) in OddOneOutRound.pairsFor(_catalog, 0)) {
        expect(animals.contains(a.id) && animals.contains(b.id), isFalse, reason: '${a.id}/${b.id}');
        expect({a.id, b.id}.containsAll({'fruits', 'veggies'}), isFalse);
      }
    });
  });

  group('OddOneOutGame UI', () {
    for (final size in const [Size(360, 640), Size(1024, 768)]) {
      testWidgets('opens, speaks and plays one correct answer at $size', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final audio = _FakeAudio();
        await tester.pumpWidget(_app(size: size, audio: audio));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);

        expect(audio.said, contains(KidGuide.gameOddOneOut));
        final banner = tester.widget<GameTargetBanner>(find.byType(GameTargetBanner));
        expect(KidGuide.oddOneOutQuestions.values, contains(banner.label));
        expect(audio.said, contains(banner.label));

        final cards = find.byType(OddOneOutCard);
        expect(cards, findsNWidgets(3)); // age 5 starts easy
        for (final element in cards.evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          expect(rect.width, greaterThanOrEqualTo(64), reason: '$size');
          expect(rect.height, greaterThanOrEqualTo(64), reason: '$size');
          expect(rect.right, lessThanOrEqualTo(size.width + 0.5));
          expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5));
        }

        final widgets = cards.evaluate().map((e) => e.widget as OddOneOutCard).toList();
        final wrong = widgets.firstWhere((c) => !c.odd);
        final odd = widgets.firstWhere((c) => c.odd);

        // A wrong tap: the card is ruled out and Mai says its name.
        await tester.tap(find.byKey(wrong.key!));
        await tester.pump();
        expect(find.text('Thử lại nhé!'), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
        expect(audio.said.last, wrong.item.name);

        // The right one: Mai explains why it does not belong.
        await tester.tap(find.byKey(odd.key!));
        await tester.pump();
        expect(find.text('Đúng rồi!'), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
        expect(audio.said.last, endsWith('không giống các bạn kia.'));
        expect(audio.said.last, startsWith(odd.item.name[0].toUpperCase()));

        // Next round arrives with a new spoken question.
        await tester.pump(const Duration(seconds: 3));
        expect(tester.takeException(), isNull);
        final next = tester.widget<GameTargetBanner>(find.byType(GameTargetBanner));
        expect(audio.said.last, next.label);
        expect(find.byType(GameProgressBar), findsOneWidget);
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('older children start with four pictures, no overflow 360–1366', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final size in const [Size(360, 640), Size(412, 915), Size(768, 1024), Size(1366, 768)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(_app(size: size, audio: _FakeAudio(), age: 7));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull, reason: '$size');
        expect(find.byType(OddOneOutCard), findsNWidgets(4), reason: '$size');
        for (final element in find.byType(OddOneOutCard).evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          expect(rect.shortestSide, greaterThanOrEqualTo(64), reason: '$size');
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      }
    });
  });
}
