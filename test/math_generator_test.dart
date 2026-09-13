import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/data/content/math_generator.dart';

void main() {
  group('Math generator', () {
    test('addition under 10 stays within range', () {
      final gen = MathQuestionGenerator(random: Random(1));
      for (var i = 0; i < 50; i++) {
        final q = gen.generateAddition(10, skill: 'addition_under_10');
        final parts = q.question!.split(RegExp(r'[^0-9]+')).where((e) => e.isNotEmpty).toList();
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
  });
}
