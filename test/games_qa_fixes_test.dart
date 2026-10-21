import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/kid_guide.dart';
import 'package:mai_an_learning/data/content/game_catalog.dart';
import 'package:mai_an_learning/data/kana/hiragana_data.dart';
import 'package:mai_an_learning/data/kana/katakana_data.dart';
import 'package:mai_an_learning/features/explore/data/explore_catalog.dart';
import 'package:mai_an_learning/features/games/logic/catch_kana_round.dart';
import 'package:mai_an_learning/features/games/logic/melody_memory_session.dart';
import 'package:mai_an_learning/features/games/logic/odd_one_out_round.dart';
import 'package:mai_an_learning/features/games/presentation/widgets/game_play_scaffold.dart';

final _explore = ExploreCatalog.parse(File(ExploreCatalog.assetPath).readAsStringSync());

void main() {
  group('Bắt chữ / Nghe và bắt chữ: choices follow the child\'s age', () {
    final pools = {
      'vi': (int age, bool lower) => CatchKanaRound.vietnamesePool(age: age, lowercase: lower),
      'hiragana': (int age, bool lower) => hiraganaData,
      'katakana': (int age, bool lower) => katakanaData,
    };

    for (final age in [3, 4]) {
      test('age $age: every letter on screen is clearly different', () {
        for (final MapEntry(key: name, value: pool) in pools.entries) {
          for (var seed = 0; seed < 400; seed++) {
            final r = CatchKanaRound.generate(pool: pool(age, false), random: Random(seed), age: age);
            expect(r.items, hasLength(4));
            expect(r.hasUniqueItems && r.includesTarget, isTrue);
            for (final a in r.items) {
              for (final b in r.items) {
                if (a.id == b.id) continue;
                expect(CatchKanaRound.confusable(a, b), isFalse,
                    reason: '$name age $age: ${a.character}/${b.character} in ${r.items.map((e) => e.character)}');
              }
            }
          }
        }
      });
    }

    test('ages 3–4 get only Vietnamese letters without marks', () {
      final young = CatchKanaRound.vietnamesePool(age: 3).map((e) => e.character).join();
      for (final marked in 'ĂÂĐÊÔƠƯ'.split('')) {
        expect(young, isNot(contains(marked)));
      }
      expect(young, contains('A'));
      expect(CatchKanaRound.vietnamesePool(age: 6).map((e) => e.character).join(), contains('Ă'));
      expect(CatchKanaRound.vietnamesePool(age: 6, lowercase: true).map((e) => e.character).join(), contains('ơ'));
    });

    test('the known pairs count as confusable', () {
      final vi = {for (final k in CatchKanaRound.vietnamesePool(age: 7)) k.character: k};
      final h = {for (final k in hiraganaData) k.character: k};
      expect(CatchKanaRound.confusable(vi['A']!, vi['Ă']!), isTrue);
      expect(CatchKanaRound.confusable(vi['O']!, vi['Ơ']!), isTrue);
      expect(CatchKanaRound.confusable(vi['C']!, vi['K']!), isTrue);
      expect(CatchKanaRound.confusable(h['よ']!, h['ゆ']!), isTrue);
      expect(CatchKanaRound.confusable(h['ぬ']!, h['め']!), isTrue);
      expect(CatchKanaRound.confusable(vi['A']!, vi['M']!), isFalse);
      expect(CatchKanaRound.confusable(h['あ']!, h['く']!), isFalse);
    });

    test('age 5: nothing can be taken for the target', () {
      for (var seed = 0; seed < 400; seed++) {
        final r = CatchKanaRound.generate(pool: hiraganaData, random: Random(seed), age: 5);
        for (final o in r.items.where((e) => e.id != r.target.id)) {
          expect(CatchKanaRound.confusable(o, r.target), isFalse);
        }
      }
    });

    test('age 6+: a look-alike of the target is on screen when one exists', () {
      var withTwin = 0;
      for (var seed = 0; seed < 300; seed++) {
        final pool = CatchKanaRound.vietnamesePool(age: 6);
        final r = CatchKanaRound.generate(pool: pool, random: Random(seed), age: 6);
        final hasTwin = pool.any((o) => o.id != r.target.id && CatchKanaRound.looksAlike(o, r.target));
        final shown = r.items.any((o) => o.id != r.target.id && CatchKanaRound.looksAlike(o, r.target));
        expect(shown, hasTwin, reason: r.target.character);
        if (shown) withTwin++;
      }
      expect(withTwin, greaterThan(100));
    });
  });

  group('Cái nào khác nhóm?', () {
    test('never asks "neither insect nor bird"; insect and bird rounds stay apart', () {
      expect(KidGuide.all.where((l) => l.contains('cũng không phải')), isEmpty);
      const birds = {'bird', 'parrot', 'owl', 'eagle', 'penguin', 'peacock', 'flamingo', 'dove', 'swan'};
      final asked = <String>{};
      for (var level = 0; level <= OddOneOutRound.maxLevel; level++) {
        for (var seed = 0; seed < 1500; seed++) {
          final r = OddOneOutRound.generate(_explore, level: level, random: Random(seed));
          expect(r.question.split('không').length - 1, 1, reason: r.question);
          if (r.majority.id != 'bugs_birds') continue;
          asked.add(r.question);
          final same = r.cards.where((c) => !r.isOdd(c)).map((c) => birds.contains(c.id)).toSet();
          expect(same, hasLength(1));
          expect(r.question, same.first ? KidGuide.oddOutBirds : KidGuide.oddOutBugs);
          expect(r.majorityEmoji, same.first ? '🐦' : '🦋');
        }
      }
      expect(asked, {KidGuide.oddOutBirds, KidGuide.oddOutBugs});
    });
  });

  group('GameCardGrid', () {
    test('three cards on a phone sit in one row, not 2 + 1', () {
      // 390×844 play area after header/progress: ~366×560.
      expect(GameCardGrid.layout(itemCount: 3, maxW: 342, maxH: 520, aspect: 0.86).cols, 3);
      expect(GameCardGrid.layout(itemCount: 4, maxW: 342, maxH: 520, aspect: 0.86).cols, isNot(3));
      expect(GameCardGrid.layout(itemCount: 8, maxW: 342, maxH: 520, aspect: 0.8).cols, isNot(3));
    });

    testWidgets('three cards render side by side at 390 wide', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GameCardGrid(
            itemCount: 3,
            aspect: 0.86,
            builder: (context, i) => Container(key: ValueKey('c$i'), color: Colors.blue),
          ),
        ),
      ));
      final tops = [for (var i = 0; i < 3; i++) tester.getRect(find.byKey(ValueKey('c$i'))).top];
      expect(tops.toSet(), hasLength(1));
      expect(tester.getRect(find.byKey(const ValueKey('c0'))).width, greaterThanOrEqualTo(90));
    });

    testWidgets('a short last row is centred', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GameCardGrid(
            itemCount: 5,
            builder: (context, i) => Container(key: ValueKey('c$i'), color: Colors.blue),
          ),
        ),
      ));
      final last = tester.getRect(find.byKey(const ValueKey('c4')));
      final first = tester.getRect(find.byKey(const ValueKey('c0')));
      expect(last.top, greaterThan(first.top), reason: 'five cards on a phone take two or more rows');
      expect((last.center.dx - 195).abs(), lessThan(2), reason: 'the lone last card is centred');
    });
  });

  test('game sessions are short: 4–10 rounds, fewer for age 3', () {
    for (final game in GameKind.values) {
      final young = GameCatalog.sessionRounds(game, 3);
      final old = GameCatalog.sessionRounds(game, 7);
      expect(young, inInclusiveRange(4, 6), reason: '$game');
      expect(old, inInclusiveRange(6, 10), reason: '$game');
      expect(young, lessThan(old));
      expect(GameCatalog.sessionRounds(game, 4), GameCatalog.sessionRounds(game, 5));
    }
    expect(MelodyMemorySession(age: 3).goal, 4);
    expect(MelodyMemorySession(age: 7).goal, 6);
  });
}
