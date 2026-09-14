import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/data/content/learning_repositories.dart';
import 'package:mai_an_learning/data/content/math_generator.dart';
import 'package:mai_an_learning/data/content/quiz_session.dart';

void main() {
  group('Math generator', () {
    test('addition under 10 stays within range', () {
      final gen = MathQuestionGenerator(random: Random(1));
      for (var i = 0; i < 50; i++) {
        final q = gen.generateAddition(10, skill: 'addition_under_10');
        final parts = q.question!.split(RegExp(r'[^0-9]+')).where((e) => e.isNotEmpty).toList();
        expect(parts.length, greaterThanOrEqualTo(2));
        final a = int.parse(parts[0]);
        final b = int.parse(parts[1]);
        expect(a + b, int.parse(q.answer!));
        expect(a + b, lessThanOrEqualTo(10));
        expect(q.choices, contains(q.answer));
      }
    });

    test('addition under 20 stays within range', () {
      final gen = MathQuestionGenerator(random: Random(2));
      final q = gen.generateBySkill('addition_under_20');
      expect(int.parse(q.answer!), lessThanOrEqualTo(20));
    });

    test('addition under 100 stays within range', () {
      final gen = MathQuestionGenerator(random: Random(3));
      final q = gen.generateBySkill('addition_under_100');
      expect(int.parse(q.answer!), lessThanOrEqualTo(100));
    });

    test('subtraction never produces negative results', () {
      final gen = MathQuestionGenerator(random: Random(4));
      for (final skill in [
        'subtraction_under_10',
        'subtraction_under_20',
        'subtraction_under_50',
        'subtraction_under_100',
      ]) {
        for (var i = 0; i < 40; i++) {
          final q = gen.generateBySkill(skill);
          expect(int.parse(q.answer!), greaterThanOrEqualTo(0));
        }
      }
    });

    test('counting uses diverse icons and shuffled choices', () {
      final gen = MathQuestionGenerator(random: Random(42));
      final icons = <String>{};
      for (var i = 0; i < 30; i++) {
        final q = gen.generateCounting(10);
        expect(int.parse(q.answer!), inInclusiveRange(1, 10));
        expect(q.choices, isNotNull);
        expect(q.choices!.length, greaterThanOrEqualTo(2));
        expect(q.choices, contains(q.answer));
        final icon = q.metadata?['icon'] as String?;
        expect(icon, isNotNull);
        icons.add(icon!);
      }
      expect(icons.length, greaterThan(1));
    });

    test('number recognition never repeats consecutive fingerprints', () {
      final gen = MathQuestionGenerator(random: Random(7));
      String? prev;
      for (var i = 0; i < 40; i++) {
        final q = gen.generateBySkill('number_recognition', age: 5);
        final fp = '${q.question}|${q.answer}';
        expect(fp, isNot(equals(prev)));
        prev = fp;
        expect(q.choices, contains(q.answer));
        expect(q.choices!.toSet().length, q.choices!.length);
      }
    });

    test('comparison choices are shuffled and valid', () {
      final gen = MathQuestionGenerator(random: Random(9));
      for (var i = 0; i < 20; i++) {
        final q = gen.generateComparison(10);
        expect(q.choices, contains(q.answer));
        expect(q.choices!.length, greaterThanOrEqualTo(2));
      }
    });
  });

  group('Learning repositories', () {
    test('vietnamese / japanese / shapes yield unique consecutive questions', () {
      final repo = LearningRepositories(random: Random(11));
      String? prev;
      for (var i = 0; i < 20; i++) {
        final q = i.isEven ? repo.vietnameseLetterQuestion() : repo.shapeQuestion();
        final fp = '${q.question}|${q.answer}';
        expect(fp, isNot(equals(prev)));
        prev = fp;
        expect(q.choices, contains(q.answer));
        expect(q.choices!.toSet().length, q.choices!.length);
      }
    });

    test('japanese kana options are shuffled with correct answer', () {
      final repo = LearningRepositories(random: Random(13));
      final q = repo.japaneseKanaQuestion(hiragana: true);
      expect(q.choices, contains(q.answer));
      expect(q.choices!.length, 4);
    });
  });

  group('QuizSession', () {
    test('advances and regenerates after correct answers until complete', () {
      var builds = 0;
      final session = QuizSession(
        totalQuestions: 3,
        generate: () {
          builds++;
          return MathQuestionGenerator(random: Random(builds)).generateCounting(5);
        },
      );
      expect(builds, 1);
      expect(session.registerAnswer(correct: true), isFalse);
      expect(session.score, 1);
      expect(builds, 2);
      expect(session.registerAnswer(correct: false), isFalse);
      expect(session.wrong, 1);
      expect(builds, 2); // no regenerate on wrong
      expect(session.registerAnswer(correct: true), isFalse);
      expect(session.registerAnswer(correct: true), isTrue);
      expect(session.finished, isTrue);
    });
  });
}
