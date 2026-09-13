import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/content/content_repository.dart';
import 'package:mai_an_learning/data/kana/hiragana_data.dart';
import 'package:mai_an_learning/data/repositories/kana_repository_impl.dart';
import 'package:mai_an_learning/data/repositories/mastery_repository.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/features/games/logic/catch_kana_round.dart';
import 'package:mai_an_learning/features/games/logic/falling_layout.dart';
import 'package:mai_an_learning/features/games/logic/game_board_metrics.dart';
import 'package:mai_an_learning/features/games/presentation/games_screen.dart';
import 'package:mai_an_learning/features/games/presentation/widgets/game_play_scaffold.dart';

Widget _app({required Size size, required Widget home, required ChildProfile profile}) {
  final notifier = CurrentProfileNotifier(ProfileRepository())..state = profile;
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(AudioService()..soundEnabled = false),
      kanaRepositoryProvider.overrideWithValue(KanaRepositoryImpl()),
      contentRepositoryProvider.overrideWithValue(ContentRepository()),
      masteryRepositoryProvider.overrideWithValue(MasteryRepository()),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: home,
      ),
    ),
  );
}

ChildProfile _profile({int age = 5}) {
  return ChildProfile(id: 'test', name: 'Lan', age: age, avatar: 'peach', createdAt: DateTime(2026, 1, 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CatchKanaRound', () {
    test('target is unique among items and checking works', () {
      final random = Random(7);
      for (var i = 0; i < 80; i++) {
        final round = CatchKanaRound.generate(pool: hiraganaData, random: random);
        expect(round.includesTarget, isTrue);
        expect(round.hasUniqueItems, isTrue);
        expect(round.items.length, 4);
        expect(round.isCorrect(round.target), isTrue);
        final distractor = round.items.firstWhere((e) => e.id != round.target.id);
        expect(round.isCorrect(distractor), isFalse);
      }
    });

    test('never duplicates character in a round', () {
      final seen = <String>{};
      for (var i = 0; i < 40; i++) {
        final round = CatchKanaRound.generate(pool: hiraganaData, random: Random(i));
        final chars = round.items.map((e) => e.character).toList();
        expect(chars.toSet().length, chars.length);
        seen.add(round.target.id);
      }
      expect(seen.length, greaterThan(1));
    });
  });

  group('FallingLayout', () {
    test('tokens stay inside board and do not overlap', () {
      const sizes = [
        Size(280, 320),
        Size(328, 400),
        Size(390, 500),
        Size(440, 580),
      ];
      for (final size in sizes) {
        final boxes = FallingLayout.placeLanes(
          width: size.width,
          height: size.height,
          count: 4,
          random: Random(3),
        );
        expect(boxes.length, 4, reason: '$size');
        expect(FallingLayout.allInside(boxes, size.width, size.height), isTrue, reason: '$size');
        expect(FallingLayout.noneOverlap(boxes), isTrue, reason: '$size');
        expect(boxes.every((b) => b.size >= 40), isTrue);
      }
    });

    test('advanceY wraps inside the board', () {
      const height = 400.0;
      const size = 56.0;
      var y = 300.0;
      for (var i = 0; i < 80; i++) {
        y = FallingLayout.advanceY(top: y, size: size, boardHeight: height, pixels: 12);
        expect(y >= 0, isTrue);
        expect(y + size <= height + 0.75, isTrue);
      }
    });

    test('desktop available space fits a compact board', () {
      final fitted = GameBoardMetrics.fit(1366, 768);
      expect(fitted.width, lessThanOrEqualTo(GameBoardMetrics.maxWidth));
      expect(fitted.height, lessThanOrEqualTo(GameBoardMetrics.maxHeight));
      expect(fitted.width, lessThan(600));
    });
  });

  group('Catch kana UI', () {
    Future<void> pumpCatch(WidgetTester tester, Size size) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_app(size: size, home: const CatchKanaGame(), profile: _profile()));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
    }

    testWidgets('shows target, progress and letters inside the playfield', (tester) async {
      await pumpCatch(tester, const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      expect(find.text('Tìm chữ'), findsOneWidget);
      expect(find.textContaining('/'), findsWidgets);
      expect(find.byType(GameLetterToken), findsNWidgets(4));
      expect(find.byType(GameProgressBar), findsOneWidget);
      expect(tester.takeException(), isNull);

      final board = tester.getRect(find.byKey(const ValueKey('game-playfield')));
      expect(board.width, lessThanOrEqualTo(GameBoardMetrics.maxWidth + 1));
      expect(board.height, lessThanOrEqualTo(GameBoardMetrics.maxHeight + 1));
      for (final element in find.byType(GameLetterToken).evaluate()) {
        final rect = tester.getRect(find.byWidget(element.widget));
        expect(rect.left, greaterThanOrEqualTo(board.left - 1), reason: 'left $rect vs $board');
        expect(rect.top, greaterThanOrEqualTo(board.top - 1), reason: 'top $rect vs $board');
        expect(rect.right, lessThanOrEqualTo(board.right + 1), reason: 'right $rect vs $board');
        expect(rect.bottom, lessThanOrEqualTo(board.bottom + 1), reason: 'bottom $rect vs $board');
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('wrong tap shows retry feedback and does not finish', (tester) async {
      await pumpCatch(tester, const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final tokens = find.byType(GameLetterToken);
      GameLetterToken? distractor;
      for (final element in tokens.evaluate()) {
        final widget = element.widget as GameLetterToken;
        if (widget.character != (find.byType(GameTargetBanner).evaluate().first.widget as GameTargetBanner).glyph) {
          distractor = widget;
          break;
        }
      }
      expect(distractor, isNotNull);
      await tester.tap(find.byWidget(distractor!));
      await tester.pump();
      expect(find.text('Thử lại nhé!'), findsOneWidget);
      expect(find.text('Giỏi lắm!'), findsNothing);
      expect(find.text('Chơi lại'), findsNothing);
      await tester.pump(const Duration(milliseconds: 420));
    });

    testWidgets('does not overflow across phone tablet and desktop sizes', (tester) async {
      const sizes = [
        Size(360, 640),
        Size(390, 844),
        Size(412, 915),
        Size(600, 960),
        Size(768, 1024),
        Size(1366, 768),
      ];
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final size in sizes) {
        await pumpCatch(tester, size);
        expect(tester.takeException(), isNull, reason: 'overflow at $size');
        expect(find.text('Tìm chữ'), findsOneWidget, reason: '$size');
        final board = tester.getRect(find.byKey(const ValueKey('game-playfield')));
        expect(board.width, lessThanOrEqualTo(GameBoardMetrics.maxWidth + 1), reason: '$size');
        expect(find.byType(GameLetterToken), findsNWidgets(4), reason: '$size');
      }
    });
  });

  group('Other games layout', () {
    testWidgets('hub and sibling games fit small and desktop sizes', (tester) async {
      const sizes = [Size(360, 640), Size(1366, 768)];
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final size in sizes) {
        for (final home in const <Widget>[
          GamesScreen(),
          MatchKanaGame(),
          MathRocketGame(),
          NumberTrainGame(),
          FindSimilarGame(),
        ]) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(_app(size: size, home: home, profile: _profile()));
          await tester.pump();
          await tester.pump();
          expect(tester.takeException(), isNull, reason: '${home.runtimeType} at $size');
        }
      }
    });
  });
}
