import 'dart:math';

import '../../domain/content/content_item.dart';

/// Rich, randomized math question factory for quizzes and mini-games.
/// Guarantees shuffled options and never repeats the exact previous question.
class MathQuestionGenerator {
  final Random _random;
  String? _lastFingerprint;

  static const countingIcons = [
    '🍎', '🍌', '🚗', '⭐️', '🐱', '🌸', '🎈', '🍓', '🐟', '🐶',
    '🍇', '🍊', '🐸', '🦋', '⚽', '🧁', '🧸', '🌈',
  ];

  MathQuestionGenerator({Random? random}) : _random = random ?? Random();

  static String skillForAge(int age, {required bool addition}) {
    if (age <= 3) return addition ? 'addition_under_10' : 'counting';
    if (age == 4) return addition ? 'addition_under_10' : 'subtraction_under_10';
    if (age == 5) return addition ? 'addition_under_20' : 'subtraction_under_20';
    if (age == 6) return addition ? 'addition_under_50' : 'subtraction_under_50';
    return addition ? 'addition_under_100' : 'subtraction_under_100';
  }

  static int maxForSkill(String skill) {
    if (skill.endsWith('_5')) return 5;
    if (skill.endsWith('_10')) return 10;
    if (skill.endsWith('_20')) return 20;
    if (skill.endsWith('_50')) return 50;
    if (skill.endsWith('_100')) return 100;
    return 10;
  }

  ContentItem generateBySkill(String skill, {int age = 5}) {
    ContentItem item;
    var guard = 0;
    do {
      item = _generateOnce(skill, age: age);
      guard++;
    } while (guard < 12 && _isRepeat(item));
    _remember(item);
    return item;
  }

  ContentItem _generateOnce(String skill, {required int age}) {
    if (skill.startsWith('addition')) {
      return generateAddition(maxForSkill(skill), age: age, skill: skill);
    }
    if (skill.startsWith('subtraction')) {
      return generateSubtraction(maxForSkill(skill), age: age, skill: skill);
    }
    switch (skill) {
      case 'comparison':
        return generateComparison(age <= 4 ? 5 : (age == 5 ? 10 : 20));
      case 'counting':
        return generateCounting(age <= 3 ? 5 : 10);
      case 'missing_number':
        return generateMissingNumber(age <= 5 ? 10 : 20);
      case 'word_problem':
        return generateWordProblem(age);
      case 'before_after':
        return generateBeforeAfter(age <= 5 ? 10 : (age == 6 ? 20 : 50));
      case 'number_match':
        return generateNumberMatch(age <= 3 ? 5 : (age <= 5 ? 10 : 20));
      case 'sort_numbers':
        return generateSortNumbers(age <= 6 ? 20 : 50);
      case 'picture_math':
        return generatePictureMath(age <= 4 ? 5 : 10);
      case 'number_line':
        return generateNumberLine(age <= 5 ? 10 : 20);
      case 'compare_expressions':
        return generateCompareExpressions(age >= 7 ? 20 : 10);
      case 'find_correct_op':
        return generateFindCorrectOp(age >= 7 ? 20 : 10);
      case 'fill_plus_minus':
        return generateFillPlusMinus(age >= 7 ? 20 : 10);
      case 'odd_even':
        return generateOddEven(age >= 7 ? 50 : 20);
      case 'number_pattern':
        return generateNumberPattern(age <= 4 ? 10 : (age <= 5 ? 20 : 50));
      case 'classify_numbers':
        return generateClassifyNumbers(age <= 5 ? 10 : 20);
      case 'number_recognition':
      default:
        // Recognition pool: 1–20 (age 3 stays gentle at 1–10).
        return generateNumberRecognition(age <= 3 ? 10 : 20);
    }
  }

  bool _isRepeat(ContentItem item) {
    final fp = _fingerprint(item);
    return _lastFingerprint != null && _lastFingerprint == fp;
  }

  void _remember(ContentItem item) {
    _lastFingerprint = _fingerprint(item);
  }

  String _fingerprint(ContentItem item) =>
      '${item.skill}|${item.question}|${item.answer}|${item.instruction}|${item.choices?.join(',')}';

  ContentItem generateAddition(int maxSum, {int age = 5, String skill = 'addition_under_10'}) {
    // Both addends are at least 1: "5 + 0" teaches nothing and a picture sum
    // with an empty side (" + 🍎🍎") shows nothing to count.
    // The sum is drawn first so every total is equally likely (drawing the
    // addends first made "= 5" the answer to over half of the sums in 5).
    final cap = maxSum < 2 ? 2 : maxSum;
    final (a, b) = _addends(cap);
    final answer = a + b;
    final visual = age <= 4 && cap <= 10 && a <= 8 && b <= 8;
    final icon = countingIcons[_random.nextInt(countingIcons.length)];
    return _choiceItem(
      idPrefix: 'gen_add',
      skill: skill,
      age: age,
      title: cap <= 5 ? 'Phép cộng trong 5' : 'Phép cộng',
      instruction: visual ? 'Đếm rồi cộng' : 'Tính tổng',
      question: visual ? '${icon * a} + ${icon * b}' : '$a + $b = ?',
      answer: answer,
      maxValue: cap,
      minValue: 1,
    );
  }

  ContentItem generateSubtraction(int maxNum, {int age = 5, String skill = 'subtraction_under_10'}) {
    // Take away at least 1 (never "7 - 0"). Ages 3–5 always keep something
    // left; from 6 the child may also meet "5 - 5 = 0".
    final cap = maxNum < 2 ? 2 : maxNum;
    final allowZero = age >= 6;
    final a = _random.nextInt(cap - 1) + 2;
    final b = _random.nextInt(allowZero ? a : a - 1) + 1;
    final answer = a - b;
    if (answer < 0) {
      throw StateError('Invalid negative subtraction: $a - $b');
    }
    final visual = age <= 4 && cap <= 10 && a <= 8;
    final icon = countingIcons[_random.nextInt(countingIcons.length)];
    return _choiceItem(
      idPrefix: 'gen_sub',
      skill: skill,
      age: age,
      title: cap <= 5 ? 'Phép trừ trong 5' : 'Phép trừ',
      instruction: visual ? 'Còn lại bao nhiêu?' : 'Tính hiệu',
      question: visual ? '${icon * a} − ${icon * b}' : '$a - $b = ?',
      answer: answer,
      maxValue: cap,
      minValue: allowZero ? 0 : 1,
    );
  }

  ContentItem generateCounting(int maxCount) {
    final cap = maxCount.clamp(1, 10);
    final n = _random.nextInt(cap) + 1;
    final icon = countingIcons[_random.nextInt(countingIcons.length)];
    final label = _labelForIcon(icon);
    return ContentItem(
      id: 'gen_count_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 3,
      ageMax: 7,
      level: 1,
      skill: 'counting',
      difficulty: 1,
      title: 'Đếm số',
      instruction: 'Có bao nhiêu $label?',
      question: List.filled(n, icon).join(),
      answer: n.toString(),
      choices: _distinctChoices(n, cap, minValue: 1),
      metadata: {'icon': icon, 'quantity': n},
    );
  }


  /// "Which is bigger?" with two different amounts, so there is always
  /// exactly one right answer and the choices are exactly the two things shown.
  /// Up to 10: half the time two picture groups ("Nhóm nào nhiều hơn?"), the
  /// child taps the bigger group; otherwise two numbers ("Số nào lớn hơn?").
  /// Equal amounts and the >, <, = signs live in [generateCompareExpressions].
  ContentItem generateComparison(int maxNum) {
    final cap = maxNum < 2 ? 2 : maxNum;
    final a = _random.nextInt(cap) + 1;
    var b = _random.nextInt(cap - 1) + 1;
    if (b >= a) b++;
    final usePictures = cap <= 10 && _random.nextBool();
    if (usePictures) {
      final iconA = countingIcons[_random.nextInt(countingIcons.length)];
      var iconB = countingIcons[_random.nextInt(countingIcons.length)];
      if (iconB == iconA) {
        iconB = countingIcons[(countingIcons.indexOf(iconA) + 1) % countingIcons.length];
      }
      final groupA = _group(a, iconA);
      final groupB = _group(b, iconB);
      return ContentItem(
        id: 'gen_cmp_${_random.nextInt(999999)}',
        subject: ContentSubject.math,
        ageMin: 3,
        ageMax: 7,
        level: 1,
        skill: 'comparison',
        difficulty: 1,
        title: 'So sánh',
        instruction: 'Nhóm nào nhiều hơn?',
        // No question row: the two groups are the buttons the child taps.
        question: null,
        answer: a > b ? groupA : groupB,
        choices: [groupA, groupB],
        metadata: {'mode': 'pictures', 'left': a, 'right': b},
      );
    }
    return ContentItem(
      id: 'gen_cmp_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 3,
      ageMax: 7,
      level: 1,
      skill: 'comparison',
      difficulty: 1,
      title: 'So sánh',
      instruction: 'Số nào lớn hơn?',
      question: '$a     $b',
      answer: '${a > b ? a : b}',
      choices: _shuffled(['$a', '$b']),
      metadata: {'mode': 'numbers', 'left': a, 'right': b},
    );
  }

  /// Mai names a number ("Số nào là số bảy?") and the child taps its numeral.
  /// The numeral is not shown in the prompt (it would be the answer itself)
  /// and the name is written in words, so the child recognises the digit.
  ContentItem generateNumberRecognition(int maxNum) {
    final cap = maxNum.clamp(4, 20);
    final n = _random.nextInt(cap) + 1;
    return ContentItem(
      id: 'gen_num_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 3,
      ageMax: 7,
      level: 1,
      skill: 'number_recognition',
      difficulty: 1,
      title: 'Nhận biết số',
      instruction: 'Số nào là số ${numberWord(n)}?',
      question: '?',
      answer: '$n',
      choices: _distinctChoices(n, cap, minValue: 1),
      metadata: {'quantity': n},
    );
  }

  ContentItem generateMissingNumber(int maxNum) {
    final cap = maxNum < 4 ? 4 : maxNum;
    final start = _random.nextInt(cap - 3) + 1;
    final missing = start + 1;
    return ContentItem(
      id: 'gen_miss_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 5,
      ageMax: 7,
      level: 2,
      skill: 'missing_number',
      difficulty: 2,
      title: 'Số còn thiếu',
      instruction: 'Điền số còn thiếu',
      question: '$start  ?  ${start + 2}',
      answer: missing.toString(),
      choices: _distinctChoices(missing, cap, minValue: 1),
    );
  }

  /// Things a child can hold, each with its own Vietnamese classifier
  /// ("cái bóng" would be a shadow, "cái hoa" is not said).
  static const _wordProblemThings = ['cái kẹo', 'quả bóng', 'bông hoa', 'ngôi sao', 'cái bánh'];

  ContentItem generateWordProblem(int age) {
    final maxA = age >= 7 ? 20 : 8;
    final maxB = age >= 7 ? 10 : 5;
    final a = _random.nextInt(maxA) + 1;
    final b = _random.nextInt(maxB) + 1;
    final thing = _wordProblemThings[_random.nextInt(_wordProblemThings.length)];
    return ContentItem(
      id: 'gen_word_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 6,
      ageMax: 7,
      level: 3,
      skill: 'word_problem',
      difficulty: 3,
      title: 'Toán lời văn',
      instruction: 'Bé có $a $thing, thêm $b $thing nữa. Bé có tất cả bao nhiêu $thing?',
      question: '$a + $b = ?',
      answer: (a + b).toString(),
      choices: _distinctChoices(a + b, maxA + maxB, minValue: 2),
    );
  }

  ContentItem generateBeforeAfter(int maxNum) {
    final cap = maxNum < 3 ? 3 : maxNum;
    final n = _random.nextInt(cap - 2) + 2;
    final askBefore = _random.nextBool();
    final answer = askBefore ? n - 1 : n + 1;
    return ContentItem(
      id: 'gen_ba_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 5,
      ageMax: 7,
      level: 2,
      skill: 'before_after',
      difficulty: 2,
      title: 'Trước / sau',
      instruction: askBefore ? 'Số nào đứng trước $n?' : 'Số nào đứng sau $n?',
      question: askBefore ? '?  $n' : '$n  ?',
      answer: answer.toString(),
      choices: _distinctChoices(answer, cap, minValue: 1),
    );
  }

  /// Either a picture group → pick its number, or a number → pick the group.
  /// Groups to choose from stay at 10 or fewer pictures so each button can
  /// still be counted (rows of five).
  ContentItem generateNumberMatch(int maxNum) {
    final showPicture = _random.nextBool();
    final cap = showPicture ? maxNum.clamp(4, 20) : maxNum.clamp(4, 10);
    final n = _random.nextInt(cap) + 1;
    final icon = countingIcons[_random.nextInt(countingIcons.length)];
    return ContentItem(
      id: 'gen_nmatch_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 3,
      ageMax: 7,
      level: 1,
      skill: 'number_match',
      difficulty: 1,
      title: 'Ghép số',
      instruction: showPicture ? 'Có bao nhiêu ${_labelForIcon(icon)}?' : 'Chọn nhóm đúng với số $n',
      question: showPicture ? icon * n : '$n',
      answer: showPicture ? n.toString() : _group(n, icon),
      choices: showPicture ? _distinctChoices(n, cap, minValue: 1) : _iconGroupChoices(n, cap, icon),
      metadata: {'icon': icon, 'quantity': n},
    );
  }

  ContentItem generateSortNumbers(int maxNum) {
    final set = <int>{};
    while (set.length < 3) {
      set.add(_random.nextInt(maxNum) + 1);
    }
    final nums = set.toList()..shuffle(_random);
    final sorted = [...nums]..sort();
    final answer = sorted.join(' ');
    final x = nums[0];
    final y = nums[1];
    final z = nums[2];
    final perms = <String>{
      answer,
      [x, y, z].join(' '),
      [x, z, y].join(' '),
      [y, x, z].join(' '),
      [y, z, x].join(' '),
      [z, x, y].join(' '),
      [z, y, x].join(' '),
    };
    final others = perms.where((e) => e != answer).toList()..shuffle(_random);
    final choices = [answer, ...others.take(3)]..shuffle(_random);
    return ContentItem(
      id: 'gen_sort_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 6,
      ageMax: 7,
      level: 3,
      skill: 'sort_numbers',
      difficulty: 2,
      title: 'Sắp xếp số',
      instruction: 'Sắp xếp từ nhỏ đến lớn',
      question: nums.join('  '),
      answer: answer,
      choices: choices.take(4).toList(),
    );
  }

  /// Picture sums for the youngest: both sides always have pictures and
  /// something is always left after taking away.
  ContentItem generatePictureMath(int cap) {
    final top = cap < 3 ? 3 : cap;
    final icon = countingIcons[_random.nextInt(countingIcons.length)];
    final add = _random.nextBool();
    if (add) {
      final (a, b) = _addends(top);
      final answer = a + b;
      return _choiceItem(
        idPrefix: 'gen_pic',
        skill: 'picture_math',
        age: 3,
        title: 'Toán hình',
        instruction: 'Đếm rồi tính',
        question: '${icon * a} + ${icon * b}',
        answer: answer,
        maxValue: top,
        minValue: 1,
      );
    }
    final a = _random.nextInt(top - 1) + 2;
    final b = _random.nextInt(a - 1) + 1;
    final answer = a - b;
    return _choiceItem(
      idPrefix: 'gen_pic',
      skill: 'picture_math',
      age: 3,
      title: 'Toán hình',
      instruction: 'Còn lại bao nhiêu?',
      question: '${icon * a} − ${icon * b}',
      answer: answer,
      maxValue: top,
      minValue: 1,
    );
  }

  ContentItem generateNumberLine(int maxNum) {
    final cap = maxNum < 5 ? 5 : maxNum;
    final start = _random.nextInt(cap - 4) + 1;
    final missingIndex = _random.nextInt(3) + 1;
    final values = [start, start + 1, start + 2, start + 3];
    final answer = values[missingIndex];
    final shown = [
      for (var i = 0; i < values.length; i++) i == missingIndex ? '?' : '${values[i]}',
    ];
    return ContentItem(
      id: 'gen_nline_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 4,
      ageMax: 7,
      level: 2,
      skill: 'number_line',
      difficulty: 2,
      title: 'Tia số',
      instruction: 'Số nào đứng ở dấu hỏi?',
      question: shown.join(' — '),
      answer: answer.toString(),
      choices: _distinctChoices(answer, cap, minValue: 1),
    );
  }

  /// "a + b ? c + d" with >, < or =. About a third of the items are equal,
  /// so "=" is a real answer and not a give-away.
  ContentItem generateCompareExpressions(int cap) {
    final top = cap < 4 ? 4 : cap;
    final a = _random.nextInt(top ~/ 2) + 1;
    final b = _random.nextInt(top - a) + 1;
    final left = a + b;
    late int c;
    late int d;
    if (_random.nextInt(3) == 0) {
      // The same total written another way (never the very same sum).
      c = _random.nextInt(left - 1) + 1;
      d = left - c;
      if (c == a || c == b) {
        c = c == 1 ? 2 : c - 1;
        d = left - c;
      }
      if (c == a || c == b || d < 1) {
        // left = a + b with a, b ≥ 1; fall back to any other split.
        c = [for (var i = 1; i < left; i++) i].firstWhere((i) => i != a && i != b, orElse: () => a);
        d = left - c;
      }
    } else {
      c = _random.nextInt(top ~/ 2) + 1;
      d = _random.nextInt(top - c) + 1;
    }
    final right = c + d;
    final answer = left > right ? '>' : (left < right ? '<' : '=');
    return ContentItem(
      id: 'gen_cmpex_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 7,
      ageMax: 7,
      level: 3,
      skill: 'compare_expressions',
      difficulty: 3,
      title: 'So sánh phép tính',
      instruction: 'Chọn dấu đúng',
      question: '$a + $b  ?  $c + $d',
      answer: answer,
      choices: _shuffled(const ['>', '<', '=']),
      metadata: {'left': left, 'right': right},
    );
  }

  ContentItem generateFindCorrectOp(int cap) {
    final top = cap < 3 ? 3 : cap;
    final plus = _random.nextBool();
    late int a;
    late int b;
    late int result;
    late String op;
    if (plus) {
      (a, b) = _addends(top);
      result = a + b;
      op = '+';
    } else {
      a = _random.nextInt(top - 1) + 2;
      b = _random.nextInt(a - 1) + 1;
      result = a - b;
      op = '−';
    }
    final wrongOp = plus ? '−' : '+';
    final correct = '$a $op $b = $result';
    // Every distractor is a false sentence (b ≥ 1, so a + b ≠ a − b).
    final wrongs = <String>{
      '$a $wrongOp $b = $result',
      '$a $op $b = ${result + 1}',
      if (result >= 2) '$a $op $b = ${result - 1}' else '$a $op $b = ${result + 2}',
    }..remove(correct);
    return ContentItem(
      id: 'gen_op_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 6,
      ageMax: 7,
      level: 3,
      skill: 'find_correct_op',
      difficulty: 3,
      title: 'Tìm phép tính',
      instruction: 'Phép tính nào đúng?',
      question: '$a  ?  $b  =  $result',
      answer: correct,
      choices: _shuffled([correct, ...wrongs]),
    );
  }

  ContentItem generateFillPlusMinus(int cap) {
    final top = cap < 3 ? 3 : cap;
    final plus = _random.nextBool();
    late int a;
    late int b;
    late int result;
    late String answer;
    if (plus) {
      (a, b) = _addends(top);
      result = a + b;
      answer = '+';
    } else {
      a = _random.nextInt(top - 1) + 2;
      b = _random.nextInt(a - 1) + 1;
      result = a - b;
      answer = '−';
    }
    // Only + and −: "2 ? 2 = 4" would also be right with ×.
    return ContentItem(
      id: 'gen_fill_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 7,
      ageMax: 7,
      level: 3,
      skill: 'fill_plus_minus',
      difficulty: 3,
      title: 'Điền + hoặc −',
      instruction: 'Điền dấu đúng vào ô trống',
      question: '$a  ?  $b  =  $result',
      answer: answer,
      choices: _shuffled(const ['+', '−']),
    );
  }

  ContentItem generateOddEven(int maxNum) {
    final n = _random.nextInt(maxNum) + 1;
    final answer = n.isEven ? 'chẵn' : 'lẻ';
    return ContentItem(
      id: 'gen_oe_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 7,
      ageMax: 7,
      level: 3,
      skill: 'odd_even',
      difficulty: 2,
      title: 'Chẵn / lẻ',
      instruction: 'Số $n là số chẵn hay số lẻ?',
      question: '$n',
      answer: answer,
      choices: _shuffled(const ['chẵn', 'lẻ']),
    );
  }

  ContentItem generateNumberPattern(int maxNum) {
    final cap = maxNum < 10 ? 10 : maxNum;
    final kind = _random.nextInt(3);
    late List<int> seq;
    late int answer;
    if (kind == 0) {
      final start = _random.nextInt(cap - 4) + 1;
      seq = [start, start + 1, start + 2];
      answer = start + 3;
    } else if (kind == 1) {
      const step = 2;
      final start = _random.nextInt((cap - 6).clamp(1, 8)) + 1;
      seq = [start, start + step, start + step * 2];
      answer = start + step * 3;
    } else {
      final start = _random.nextInt(4) + 4;
      seq = [start, start - 1, start - 2];
      answer = start - 3;
    }
    return ContentItem(
      id: 'gen_npat_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 4,
      ageMax: 7,
      level: 2,
      skill: 'number_pattern',
      difficulty: 2,
      title: 'Quy luật số',
      instruction: 'Số tiếp theo là gì?',
      question: '${seq.join('  ')}  ?',
      answer: answer.toString(),
      choices: _distinctChoices(answer, cap, minValue: 1),
    );
  }

  ContentItem generateClassifyNumbers(int maxNum) {
    final cap = maxNum < 8 ? 8 : maxNum;
    final even = _random.nextBool();
    final evens = [for (var i = 2; i <= cap; i += 2) i]..shuffle(_random);
    final odds = [for (var i = 1; i <= cap; i += 2) i]..shuffle(_random);
    final target = even ? evens.first : odds.first;
    final others = even ? odds.take(3) : evens.take(3);
    final choices = [...others.map((e) => e.toString()), target.toString()]..shuffle(_random);
    return ContentItem(
      id: 'gen_cls_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 5,
      ageMax: 7,
      level: 2,
      skill: 'classify_numbers',
      difficulty: 2,
      title: 'Phân loại số',
      instruction: even ? 'Số nào là số chẵn?' : 'Số nào là số lẻ?',
      question: even ? 'Tìm số chẵn' : 'Tìm số lẻ',
      answer: target.toString(),
      choices: choices,
    );
  }

  ContentItem _choiceItem({
    required String idPrefix,
    required String skill,
    required int age,
    required String title,
    required String instruction,
    required String question,
    required int answer,
    required int maxValue,
    int minValue = 0,
  }) {
    return ContentItem(
      id: '${idPrefix}_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(999)}',
      subject: ContentSubject.math,
      ageMin: age <= 4 ? 3 : 5,
      ageMax: 7,
      level: 2,
      skill: skill,
      difficulty: maxValue <= 10 ? 1 : (maxValue <= 20 ? 2 : 3),
      title: title,
      instruction: instruction,
      question: question,
      answer: answer.toString(),
      choices: _distinctChoices(answer, maxValue, minValue: minValue),
    );
  }

  /// Two addends, both at least 1, whose sum is uniform over 2..[maxSum].
  (int, int) _addends(int maxSum) {
    final sum = _random.nextInt(maxSum - 1) + 2;
    final a = _random.nextInt(sum - 1) + 1;
    return (a, sum - a);
  }

  /// Correct answer + up to 3 distinct distractors near it, always shuffled.
  /// Every choice stays inside [minValue]..[maxValue] (the skill's range:
  /// no 12 when counting to 10, no 0 when counting things).
  List<String> _distinctChoices(int answer, int maxValue, {int minValue = 0}) {
    final lo = min(minValue, answer);
    final hi = max(maxValue, answer);
    final choices = <String>{answer.toString()};
    var guard = 0;
    while (choices.length < 4 && guard < 80) {
      guard++;
      final delta = _random.nextInt(5) + 1;
      final wrong = _random.nextBool() ? answer + delta : answer - delta;
      if (wrong < lo || wrong > hi) continue;
      choices.add(wrong.toString());
    }
    // Tiny range: fill with the nearest numbers still inside it.
    for (var d = 1; choices.length < 4 && d <= hi - lo; d++) {
      for (final wrong in [answer - d, answer + d]) {
        if (choices.length < 4 && wrong >= lo && wrong <= hi) choices.add('$wrong');
      }
    }
    return choices.toList()..shuffle(_random);
  }

  /// [n] pictures in short rows (2, 3 or 5 a row, like dice), so a group
  /// drawn inside a button stays big enough to count.
  static String _group(int n, String icon) {
    final perRow = n <= 4 ? 2 : (n <= 9 ? 3 : 5);
    return [
      for (var i = 0; i < n; i += perRow) icon * (n - i < perRow ? n - i : perRow),
    ].join('\n');
  }

  List<String> _iconGroupChoices(int answer, int maxNum, String icon) => [
        for (final n in _distinctChoices(answer, maxNum, minValue: 1)) _group(int.parse(n), icon),
      ];

  List<String> _shuffled(List<String> values) => List<String>.from(values)..shuffle(_random);

  /// Vietnamese name of 0–100 as Mai says it ("bảy", "mười lăm", "hai mươi mốt").
  static String numberWord(int n) {
    const units = ['không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'];
    if (n < 0 || n > 100) return '$n';
    if (n < 10) return units[n];
    if (n == 100) return 'một trăm';
    final tens = n ~/ 10;
    final unit = n % 10;
    final head = tens == 1 ? 'mười' : '${units[tens]} mươi';
    if (unit == 0) return head;
    if (unit == 5) return '$head lăm';
    if (unit == 1 && tens > 1) return '$head mốt';
    if (unit == 4 && tens > 1) return '$head tư';
    return '$head ${units[unit]}';
  }

  String _labelForIcon(String icon) {
    const map = {
      '🍎': 'quả táo',
      '🍌': 'quả chuối',
      '🚗': 'xe ô tô',
      '⭐️': 'ngôi sao',
      '🐱': 'con mèo',
      '🌸': 'bông hoa',
      '🎈': 'bóng bay',
      '🍓': 'quả dâu',
      '🐟': 'con cá',
      '🐶': 'con chó',
      '🍇': 'chùm nho',
      '🍊': 'quả cam',
      '🐸': 'con ếch',
      '🦋': 'con bướm',
      '⚽': 'quả bóng',
      '🧁': 'bánh cupcake',
      '🧸': 'gấu bông',
      '🌈': 'cầu vồng',
    };
    return map[icon] ?? 'hình';
  }
}
