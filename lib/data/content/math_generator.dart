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
      '${item.skill}|${item.question}|${item.answer}|${item.instruction}';

  ContentItem generateAddition(int maxSum, {int age = 5, String skill = 'addition_under_10'}) {
    final cap = maxSum < 1 ? 1 : maxSum;
    final a = _random.nextInt(cap + 1);
    final b = _random.nextInt(cap - a + 1);
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
    );
  }

  ContentItem generateSubtraction(int maxNum, {int age = 5, String skill = 'subtraction_under_10'}) {
    final cap = maxNum < 1 ? 1 : maxNum;
    final a = _random.nextInt(cap) + 1;
    final b = _random.nextInt(a + 1);
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
      choices: _distinctChoices(n, cap),
      metadata: {'icon': icon, 'quantity': n},
    );
  }

  ContentItem generateComparison(int maxNum) {
    final useItems = _random.nextBool() && maxNum <= 10;
    if (useItems) {
      final a = _random.nextInt(maxNum) + 1;
      final b = _random.nextInt(maxNum) + 1;
      final iconA = countingIcons[_random.nextInt(countingIcons.length)];
      var iconB = countingIcons[_random.nextInt(countingIcons.length)];
      if (iconB == iconA) {
        iconB = countingIcons[(countingIcons.indexOf(iconA) + 1) % countingIcons.length];
      }
      String answer;
      if (a > b) {
        answer = 'trái';
      } else if (b > a) {
        answer = 'phải';
      } else {
        answer = 'bằng nhau';
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
        instruction: 'Bên nào nhiều hơn?',
        question: '${List.filled(a, iconA).join()}   ?   ${List.filled(b, iconB).join()}',
        answer: answer,
        choices: _shuffled(['trái', 'phải', 'bằng nhau']),
      );
    }

    final a = _random.nextInt(maxNum) + 1;
    final b = _random.nextInt(maxNum) + 1;
    String answer;
    if (a > b) {
      answer = '$a';
    } else if (b > a) {
      answer = '$b';
    } else {
      answer = 'bằng nhau';
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
      question: '$a  ?  $b',
      answer: answer,
      choices: _shuffled(a == b ? [answer, '$a', '${a + 1}'] : ['$a', '$b', 'bằng nhau']),
    );
  }

  ContentItem generateNumberRecognition(int maxNum) {
    final cap = maxNum.clamp(1, 20);
    // Prefer 1..cap (kids rarely need zero in recognition drills).
    final n = _random.nextInt(cap) + 1;
    return _choiceItem(
      idPrefix: 'gen_num',
      skill: 'number_recognition',
      age: 3,
      title: 'Nhận biết số',
      instruction: 'Đây là số mấy?',
      question: '$n',
      answer: n,
      maxValue: cap,
    );
  }

  ContentItem generateMissingNumber(int maxNum) {
    final start = _random.nextInt(maxNum - 3) + 1;
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
      choices: _distinctChoices(missing, maxNum),
    );
  }

  ContentItem generateWordProblem(int age) {
    final a = _random.nextInt(age >= 7 ? 20 : 8) + 1;
    final b = _random.nextInt(age >= 7 ? 10 : 5) + 1;
    final item = ['kẹo', 'bóng', 'hoa', 'sao', 'bánh'][_random.nextInt(5)];
    return ContentItem(
      id: 'gen_word_${_random.nextInt(999999)}',
      subject: ContentSubject.math,
      ageMin: 6,
      ageMax: 7,
      level: 3,
      skill: 'word_problem',
      difficulty: 3,
      title: 'Toán lời văn',
      instruction: 'Bé có $a cái $item, thêm $b cái nữa. Bé có bao nhiêu cái?',
      question: '$a + $b = ?',
      answer: (a + b).toString(),
      choices: _distinctChoices(a + b, a + b + 5),
    );
  }

  ContentItem generateBeforeAfter(int maxNum) {
    final n = _random.nextInt(maxNum - 2) + 2;
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
      choices: _distinctChoices(answer, maxNum),
    );
  }

  ContentItem generateNumberMatch(int maxNum) {
    final n = _random.nextInt(maxNum) + 1;
    final showPicture = _random.nextBool();
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
      instruction: showPicture ? 'Có bao nhiêu?' : 'Chọn nhóm đúng với số $n',
      question: showPicture ? List.filled(n, icon).join() : '$n',
      answer: showPicture ? n.toString() : List.filled(n, icon).join(),
      choices: showPicture ? _distinctChoices(n, maxNum) : _iconGroupChoices(n, maxNum, icon),
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

  ContentItem generatePictureMath(int cap) {
    final icon = countingIcons[_random.nextInt(countingIcons.length)];
    final add = _random.nextBool();
    if (add) {
      final a = _random.nextInt(cap + 1);
      final b = _random.nextInt(cap - a + 1);
      final answer = a + b;
      return _choiceItem(
        idPrefix: 'gen_pic',
        skill: 'picture_math',
        age: 3,
        title: 'Toán hình',
        instruction: 'Đếm rồi tính',
        question: '${icon * a} + ${icon * b}',
        answer: answer,
        maxValue: cap,
      );
    }
    final a = _random.nextInt(cap) + 1;
    final b = _random.nextInt(a + 1);
    final answer = a - b;
    return _choiceItem(
      idPrefix: 'gen_pic',
      skill: 'picture_math',
      age: 3,
      title: 'Toán hình',
      instruction: 'Còn lại bao nhiêu?',
      question: '${icon * a} − ${icon * b}',
      answer: answer,
      maxValue: cap,
    );
  }

  ContentItem generateNumberLine(int maxNum) {
    final start = _random.nextInt(maxNum - 4) + 1;
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
      choices: _distinctChoices(answer, maxNum),
    );
  }

  ContentItem generateCompareExpressions(int cap) {
    final a = _random.nextInt(cap ~/ 2 + 1);
    final b = _random.nextInt(cap - a + 1);
    final c = _random.nextInt(cap ~/ 2 + 1);
    final d = _random.nextInt(cap - c + 1);
    final left = a + b;
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
    );
  }

  ContentItem generateFindCorrectOp(int cap) {
    final plus = _random.nextBool();
    late int a;
    late int b;
    late int result;
    late String op;
    if (plus) {
      a = _random.nextInt(cap);
      b = _random.nextInt(cap - a) + 1;
      result = a + b;
      op = '+';
    } else {
      a = _random.nextInt(cap) + 1;
      b = a == 1 ? 1 : _random.nextInt(a) + 1;
      result = a - b;
      op = '−';
    }
    final wrongOp = plus ? '−' : '+';
    final distractor = plus ? '$a + $b = ${result + 1}' : '$a − $b = ${result + 1}';
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
      question: '$a  □  $b  =  $result',
      answer: '$a $op $b = $result',
      choices: _shuffled([
        '$a $op $b = $result',
        '$a $wrongOp $b = $result',
        distractor,
        '$b $op $a = ${result + 2}',
      ]),
    );
  }

  ContentItem generateFillPlusMinus(int cap) {
    final plus = _random.nextBool();
    late int a;
    late int b;
    late int result;
    late String answer;
    if (plus) {
      a = _random.nextInt(cap);
      b = _random.nextInt(cap - a) + 1;
      result = a + b;
      answer = '+';
    } else {
      a = _random.nextInt(cap) + 1;
      b = a == 1 ? 1 : _random.nextInt(a) + 1;
      result = a - b;
      answer = '−';
    }
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
      question: '$a  □  $b  =  $result',
      answer: answer,
      choices: _shuffled(const ['+', '−', '×']),
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
    final kind = _random.nextInt(3);
    late List<int> seq;
    late int answer;
    if (kind == 0) {
      final start = _random.nextInt(maxNum - 4) + 1;
      seq = [start, start + 1, start + 2];
      answer = start + 3;
    } else if (kind == 1) {
      const step = 2;
      final start = _random.nextInt((maxNum ~/ 2).clamp(1, 8)) + 1;
      seq = [start, start + step, start + step * 2];
      answer = start + step * 3;
      if (answer > maxNum) {
        seq = [2, 4, 6];
        answer = 8;
      }
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
      choices: _distinctChoices(answer, maxNum),
    );
  }

  ContentItem generateClassifyNumbers(int maxNum) {
    final even = _random.nextBool();
    final evens = [for (var i = 2; i <= maxNum; i += 2) i]..shuffle(_random);
    final odds = [for (var i = 1; i <= maxNum; i += 2) i]..shuffle(_random);
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
      choices: _distinctChoices(answer, maxValue),
    );
  }

  /// Correct answer + up to 3 distinct distractors, always shuffled.
  List<String> _distinctChoices(int answer, int maxValue) {
    final cap = maxValue < 1 ? 1 : maxValue;
    final choices = <String>{answer.toString()};
    var guard = 0;
    while (choices.length < 4 && guard < 80) {
      guard++;
      final delta = _random.nextInt(5) + 1;
      final wrong = _random.nextBool() ? answer + delta : answer - delta;
      if (wrong < 0 || wrong > cap + 2) continue;
      if (wrong == answer) continue;
      choices.add(wrong.toString());
    }
    // Fallback fill if range is tiny.
    var fill = 0;
    while (choices.length < 4 && fill <= cap + 3) {
      choices.add('$fill');
      fill++;
    }
    final list = choices.toList()..shuffle(_random);
    return list;
  }

  List<String> _iconGroupChoices(int answer, int maxNum, String icon) {
    final choices = <String>{List.filled(answer, icon).join()};
    var guard = 0;
    while (choices.length < 4 && guard < 40) {
      guard++;
      final n = _random.nextInt(maxNum) + 1;
      if (n == answer) continue;
      choices.add(List.filled(n, icon).join());
    }
    return choices.toList()..shuffle(_random);
  }

  List<String> _shuffled(List<String> values) => List<String>.from(values)..shuffle(_random);

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
