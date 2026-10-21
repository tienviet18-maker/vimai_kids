// Sweeps every skill MathQuestionGenerator supports, at every age, and checks
// each item the way a child meets it: one right answer that is among the
// choices, no repeated choices, no empty picture, choices inside the skill's
// range, and a prompt that asks what the answer actually is.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/audio/speech_id.dart';
import 'package:mai_an_learning/data/content/math_generator.dart';
import 'package:mai_an_learning/domain/content/content_item.dart';

const _skills = [
  'counting', 'number_recognition', 'comparison', 'number_match', 'picture_math',
  'addition_under_5', 'subtraction_under_5', 'addition_under_10', 'subtraction_under_10',
  'number_pattern', 'number_line', 'addition_under_20', 'subtraction_under_20', 'missing_number',
  'before_after', 'classify_numbers', 'addition_under_50', 'subtraction_under_50', 'word_problem',
  'sort_numbers', 'find_correct_op', 'addition_under_100', 'subtraction_under_100',
  'compare_expressions', 'fill_plus_minus', 'odd_even',
];

/// How many pictures of [icon] are in [text].
int _count(String text, String icon) => icon.allMatches(text).length;

/// The single counting icon used in [text], or null when it has none.
String? _iconIn(String text) {
  for (final icon in MathQuestionGenerator.countingIcons) {
    if (text.contains(icon)) return icon;
  }
  return null;
}

List<int> _ints(String text) => [for (final m in RegExp(r'\d+').allMatches(text)) int.parse(m[0]!)];

/// Every picture-or-number side of a "+"/"−" question has something on it.
void _expectNoEmptySide(String q, String why) {
  for (final op in [' + ', ' − ', ' - ']) {
    if (!q.contains(op)) continue;
    for (final side in q.split(op)) {
      expect(side.trim(), isNotEmpty, reason: 'empty side in "$q" ($why)');
    }
  }
}

void _expectNumbersIn(List<String> choices, int lo, int hi, String why) {
  for (final c in choices) {
    final n = int.tryParse(c);
    expect(n, isNotNull, reason: 'choice "$c" is not a number ($why)');
    expect(n, inInclusiveRange(lo, hi), reason: 'choice $c outside $lo..$hi ($why)');
  }
}

int _range(String skill, int age) => switch (skill) {
      'counting' => age <= 3 ? 5 : 10,
      'comparison' => age <= 4 ? 5 : (age == 5 ? 10 : 20),
      'number_recognition' => age <= 3 ? 10 : 20,
      'picture_math' => age <= 4 ? 5 : 10,
      'missing_number' || 'number_line' => age <= 5 ? 10 : 20,
      'before_after' => age <= 5 ? 10 : (age == 6 ? 20 : 50),
      'number_pattern' => age <= 4 ? 10 : (age <= 5 ? 20 : 50),
      'compare_expressions' || 'find_correct_op' || 'fill_plus_minus' => age >= 7 ? 20 : 10,
      _ => MathQuestionGenerator.maxForSkill(skill),
    };

void _check(ContentItem q, String skill, int age) {
  final why = '$skill age $age: ${q.instruction} | ${q.question} | ${q.answer} | ${q.choices}';
  final choices = q.choices!;
  final answer = q.answer!;
  // Only "Nhóm nào nhiều hơn?" has no question row (its groups are the buttons).
  final question = q.question ?? '';
  if (question.isEmpty) expect(q.metadata?['mode'], 'pictures', reason: why);
  expect(choices.length, greaterThanOrEqualTo(2), reason: why);
  expect(choices.toSet().length, choices.length, reason: 'repeated choice: $why');
  expect(choices.where((c) => c == answer).length, 1, reason: 'answer not in choices: $why');
  for (final c in choices) {
    expect(c.trim(), isNotEmpty, reason: why);
  }
  if (q.question != null) expect(question.trim(), isNotEmpty, reason: why);
  expect(question, isNot(contains('bằng nhau')), reason: why);
  expect(SpeechId.spokenText(q.instruction), isNotNull, reason: 'instruction cannot be said: $why');
  _expectNoEmptySide(question, why);
  final max = _range(skill, age);

  if (skill.startsWith('addition') || skill.startsWith('subtraction') || skill == 'picture_math') {
    final icon = _iconIn(question);
    late int a;
    late int b;
    final plus = question.contains('+');
    if (icon != null) {
      final sides = question.split(plus ? ' + ' : ' − ');
      expect(sides.length, 2, reason: why);
      a = _count(sides[0], icon);
      b = _count(sides[1], icon);
      expect(q.instruction, plus ? anyOf('Đếm rồi cộng', 'Đếm rồi tính') : 'Còn lại bao nhiêu?', reason: why);
    } else {
      final n = _ints(question);
      expect(n.length, 2, reason: why);
      a = n[0];
      b = n[1];
      expect(AudioService.mathClips(question), isNotNull, reason: 'question not read out: $why');
      expect(q.instruction, plus ? 'Tính tổng' : 'Tính hiệu', reason: why);
    }
    if (skill.startsWith('addition')) expect(plus, isTrue, reason: why);
    if (skill.startsWith('subtraction')) expect(plus, isFalse, reason: why);
    expect(a, greaterThanOrEqualTo(1), reason: 'zero operand: $why');
    expect(b, greaterThanOrEqualTo(1), reason: 'zero operand: $why');
    final result = plus ? a + b : a - b;
    expect(int.parse(answer), result, reason: why);
    expect(result, lessThanOrEqualTo(max), reason: why);
    final young = age <= 5 || icon != null;
    expect(result, greaterThanOrEqualTo(young || plus ? 1 : 0), reason: why);
    _expectNumbersIn(choices, young || plus ? 1 : 0, max, why);
    return;
  }

  switch (skill) {
    case 'counting':
      final icon = q.metadata!['icon'] as String;
      final n = _count(question, icon);
      expect(n, int.parse(answer), reason: why);
      expect(n, inInclusiveRange(1, max), reason: why);
      expect(q.instruction, startsWith('Có bao nhiêu '), reason: why);
      _expectNumbersIn(choices, 1, max, why);
      expect(choices.length, 4, reason: why);
    case 'comparison':
      expect(q.instruction, isNot(contains('bằng nhau')), reason: why);
      expect(choices.length, 2, reason: why);
      final left = q.metadata!['left'] as int;
      final right = q.metadata!['right'] as int;
      expect(left, isNot(right), reason: 'equal amounts asked as "bigger": $why');
      expect([left, right].every((n) => n >= 1 && n <= max), isTrue, reason: why);
      if (q.metadata!['mode'] == 'numbers') {
        expect(q.instruction, 'Số nào lớn hơn?', reason: why);
        expect(_ints(question), [left, right], reason: why);
        expect(choices.toSet(), {'$left', '$right'}, reason: 'choices must be the two numbers: $why');
        expect(answer, '${left > right ? left : right}', reason: why);
        expect(AudioService.mathClips(question), isNotNull, reason: why);
      } else {
        expect(q.instruction, 'Nhóm nào nhiều hơn?', reason: why);
        final counts = [for (final c in choices) _count(c, _iconIn(c)!)];
        expect(counts.toSet(), {left, right}, reason: 'groups must be the two shown: $why');
        expect(_count(answer, _iconIn(answer)!), left > right ? left : right, reason: why);
        expect(_iconIn(choices[0]), isNot(_iconIn(choices[1])), reason: why);
        for (final c in choices) {
          expect(c.split('\n').every((row) => _count(row, _iconIn(c)!) <= 5), isTrue, reason: why);
        }
      }
    case 'number_recognition':
      final n = int.parse(answer);
      expect(n, inInclusiveRange(1, max), reason: why);
      expect(q.instruction, 'Số nào là số ${MathQuestionGenerator.numberWord(n)}?', reason: why);
      expect(_ints('${q.instruction} $question'), isEmpty, reason: 'prompt shows the answer: $why');
      _expectNumbersIn(choices, 1, max, why);
    case 'number_match':
      final n = q.metadata!['quantity'] as int;
      final icon = q.metadata!['icon'] as String;
      if (int.tryParse(answer) != null) {
        expect(_count(question, icon), n, reason: why);
        expect(answer, '$n', reason: why);
        _expectNumbersIn(choices, 1, 20, why);
      } else {
        expect(question, '$n', reason: why);
        expect(q.instruction, 'Chọn nhóm đúng với số $n', reason: why);
        expect(_count(answer, icon), n, reason: why);
        final counts = [for (final c in choices) _count(c, icon)];
        expect(counts.toSet().length, counts.length, reason: why);
        expect(counts.every((c) => c >= 1 && c <= 10), isTrue, reason: why);
      }
    case 'missing_number':
      final n = _ints(question);
      expect(n.length, 2, reason: why);
      expect(int.parse(answer), n[0] + 1, reason: why);
      expect(n[1], n[0] + 2, reason: why);
      _expectNumbersIn(choices, 1, max, why);
    case 'before_after':
      final n = _ints(question).single;
      final before = q.instruction.contains('trước');
      expect(q.instruction, contains('$n'), reason: why);
      expect(int.parse(answer), before ? n - 1 : n + 1, reason: why);
      _expectNumbersIn(choices, 1, max, why);
    case 'number_line':
      final parts = question.split(' — ');
      expect(parts.length, 4, reason: why);
      final i = parts.indexOf('?');
      final start = int.parse(parts[i == 0 ? 1 : 0]) - (i == 0 ? 1 : 0);
      expect(int.parse(answer), start + i, reason: why);
      _expectNumbersIn(choices, 1, max, why);
    case 'number_pattern':
      final n = _ints(question);
      expect(n.length, 3, reason: why);
      final step = n[1] - n[0];
      expect(n[2] - n[1], step, reason: why);
      expect(int.parse(answer), n[2] + step, reason: why);
      _expectNumbersIn(choices, 1, max, why);
    case 'classify_numbers':
      final even = q.instruction.contains('chẵn');
      expect(choices.where((c) => int.parse(c).isEven == even).toList(), [answer], reason: why);
    case 'odd_even':
      final n = int.parse(question);
      expect(answer, n.isEven ? 'chẵn' : 'lẻ', reason: why);
      expect(choices.toSet(), {'chẵn', 'lẻ'}, reason: why);
      expect(q.instruction, contains('chẵn hay số lẻ'), reason: 'choices are said in the prompt: $why');
    case 'word_problem':
      final story = _ints(q.instruction);
      expect(story, _ints(question), reason: why);
      expect(int.parse(answer), story[0] + story[1], reason: why);
      expect(q.instruction, isNot(contains('cái bóng')), reason: why);
      expect(q.instruction, isNot(contains('cái hoa')), reason: why);
      expect(q.instruction, isNot(contains('cái sao')), reason: why);
      _expectNumbersIn(choices, 1, 30, why);
    case 'sort_numbers':
      bool sorted(String s) {
        final n = _ints(s);
        for (var i = 1; i < n.length; i++) {
          if (n[i] < n[i - 1]) return false;
        }
        return true;
      }
      expect(choices.where(sorted).toList(), [answer], reason: why);
      expect(_ints(answer).toSet(), _ints(question).toSet(), reason: why);
    case 'compare_expressions':
      final n = _ints(question);
      expect(n.length, 4, reason: why);
      expect(n.every((e) => e >= 1), isTrue, reason: why);
      final l = n[0] + n[1];
      final r = n[2] + n[3];
      expect(answer, l > r ? '>' : (l < r ? '<' : '='), reason: why);
      expect(l <= max && r <= max, isTrue, reason: why);
      expect(choices.toSet(), {'>', '<', '='}, reason: why);
      expect(AudioService.mathClips(question), isNotNull, reason: why);
    case 'fill_plus_minus':
      final n = _ints(question);
      final works = [
        if (n[0] + n[1] == n[2]) '+',
        if (n[0] - n[1] == n[2]) '−',
      ];
      expect(works, [answer], reason: 'exactly one sign must work: $why');
      expect(choices.toSet(), {'+', '−'}, reason: why);
      expect(AudioService.mathClips(question), isNotNull, reason: why);
    case 'find_correct_op':
      bool isTrue(String eq) {
        final n = _ints(eq);
        return eq.contains('+') ? n[0] + n[1] == n[2] : n[0] - n[1] == n[2];
      }
      expect(choices.where(isTrue).toList(), [answer], reason: 'exactly one true sentence: $why');
      final shown = _ints(question);
      expect(_ints(answer), shown, reason: why);
      expect(AudioService.mathClips(question), isNotNull, reason: why);
    default:
      fail('skill $skill not checked');
  }
}

void main() {
  test('every skill at every age gives clean, answerable questions', () {
    for (final skill in _skills) {
      for (var age = 3; age <= 7; age++) {
        final gen = MathQuestionGenerator(random: Random(skill.hashCode ^ age));
        for (var i = 0; i < 2000; i++) {
          _check(gen.generateBySkill(skill, age: age), skill, age);
        }
      }
    }
  });

  test('regression: picture sums never have an empty side or a zero', () {
    final gen = MathQuestionGenerator(random: Random(5));
    for (var i = 0; i < 3000; i++) {
      for (final skill in ['addition_under_5', 'subtraction_under_5', 'picture_math']) {
        final q = gen.generateBySkill(skill, age: 3 + i % 3);
        expect(q.question, isNot(matches(RegExp(r'^\s|\s$'))), reason: q.question);
        expect(q.question, isNot(contains('+ 0')), reason: q.question);
        expect(q.question, isNot(contains('- 0')), reason: q.question);
      }
    }
  });

  test('regression: comparison never asks "bigger" about two equal numbers', () {
    final gen = MathQuestionGenerator(random: Random(4));
    for (var i = 0; i < 3000; i++) {
      final q = gen.generateComparison(i.isEven ? 5 : 20);
      expect(q.answer, isNot('bằng nhau'));
      expect(q.choices, isNot(contains('bằng nhau')));
      if (q.metadata!['mode'] == 'numbers') {
        expect(q.choices!.toSet(), _ints(q.question!).map((e) => '$e').toSet());
      }
    }
  });

  test('regression: sums are not nearly always the biggest total', () {
    // Drawing the first addend, then the second, made "= 5" the answer to
    // over half of the sums in 5; a child could win by always tapping 5.
    for (final skill in ['addition_under_5', 'picture_math', 'addition_under_10']) {
      final gen = MathQuestionGenerator(random: Random(8));
      final seen = <String, int>{};
      const n = 4000;
      for (var i = 0; i < n; i++) {
        final q = gen.generateBySkill(skill, age: 4);
        seen[q.answer!] = (seen[q.answer!] ?? 0) + 1;
      }
      final top = seen.values.reduce(max);
      expect(top / n, lessThan(0.4), reason: '$skill answers: $seen');
    }
  });

  test('regression: counting choices stay within 1..max', () {
    final gen = MathQuestionGenerator(random: Random(6));
    for (var i = 0; i < 3000; i++) {
      final q = gen.generateCounting(10);
      _expectNumbersIn(q.choices!, 1, 10, '${q.choices}');
    }
  });

  test('numberWord says Vietnamese numbers', () {
    expect(MathQuestionGenerator.numberWord(7), 'bảy');
    expect(MathQuestionGenerator.numberWord(10), 'mười');
    expect(MathQuestionGenerator.numberWord(15), 'mười lăm');
    expect(MathQuestionGenerator.numberWord(14), 'mười bốn');
    expect(MathQuestionGenerator.numberWord(20), 'hai mươi');
    expect(MathQuestionGenerator.numberWord(21), 'hai mươi mốt');
    expect(MathQuestionGenerator.numberWord(24), 'hai mươi tư');
  });
}
