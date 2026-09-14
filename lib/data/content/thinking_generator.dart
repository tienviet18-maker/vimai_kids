import 'dart:math';

import '../../domain/content/content_item.dart';
import '../../domain/models/skill_mastery.dart';
import 'learning_repositories.dart';

class ThinkingQuestionEngine {
  final Random _random;
  final List<ContentItem> bank;
  final List<String> _recent = [];
  final LearningRepositories _learning;

  ThinkingQuestionEngine({Random? random, this.bank = const []})
      : _random = random ?? Random(),
        _learning = LearningRepositories(random: random);

  ContentItem next({required int age, List<SkillMastery> mastery = const []}) {
    // Periodically inject shape/color recognition for variety.
    if (_random.nextInt(5) == 0) {
      final injected = _random.nextBool() ? _learning.shapeQuestion() : _learning.colorQuestion();
      if (age >= injected.ageMin && age <= injected.ageMax && !_recent.contains(injected.id)) {
        _recent.add(injected.id);
        if (_recent.length > 8) _recent.removeAt(0);
        return injected;
      }
    }
    final generated = _allForAge(age);
    final combined = [...bank.where((e) => age >= e.ageMin && age <= e.ageMax), ...generated];
    final weakIds = mastery.where((e) => e.skill.startsWith('thinking') && e.needsReview).map((e) => e.id).toSet();
    var pool = combined.where((e) => !_recent.contains(e.id)).toList();
    if (pool.isEmpty) pool = combined;
    final weak = pool.where((e) => weakIds.contains(e.id)).toList();
    final pickFrom = weak.isNotEmpty && _random.nextBool() ? weak : pool;
    final item = pickFrom[_random.nextInt(pickFrom.length)];
    // Fresh shuffle so options aren't sticky across rounds.
    if (item.choices != null) {
      final shuffled = List<String>.from(item.choices!)..shuffle(_random);
      final refreshed = ContentItem(
        id: '${item.id}_${_random.nextInt(9999)}',
        subject: item.subject,
        ageMin: item.ageMin,
        ageMax: item.ageMax,
        level: item.level,
        skill: item.skill,
        difficulty: item.difficulty,
        title: item.title,
        instruction: item.instruction,
        question: item.question,
        answer: item.answer,
        choices: shuffled,
        metadata: item.metadata,
      );
      _recent.add(refreshed.id);
      if (_recent.length > 8) _recent.removeAt(0);
      return refreshed;
    }
    _recent.add(item.id);
    if (_recent.length > 8) _recent.removeAt(0);
    return item;
  }

  List<ContentItem> allForAge(int age) => _allForAge(age);

  List<ContentItem> _allForAge(int age) {
    final base = <ContentItem>[
      ..._odds(),
      ..._patterns(),
      ..._pairs(),
      ..._classes(),
      ..._sizes(),
      ..._sequence(),
      ..._sameDiff(),
      ..._memory(),
      ..._paths(),
      ..._logic(),
    ];
    // Double the bank with remapped ids for more variety.
    final doubled = [
      for (final item in base)
        ContentItem(
          id: '${item.id}_b',
          subject: item.subject,
          ageMin: item.ageMin,
          ageMax: item.ageMax,
          level: item.level,
          skill: item.skill,
          difficulty: item.difficulty,
          title: item.title,
          instruction: item.instruction,
          question: item.question,
          answer: item.answer,
          choices: item.choices == null ? null : (List<String>.from(item.choices!)..shuffle(_random)),
        ),
    ];
    final items = [...base, ...doubled];
    return items.where((e) => age >= e.ageMin && age <= e.ageMax).toList();
  }

  List<ContentItem> _odds() => [
        _odd('o1', ['🍎', '🍎', '🍌', '🍎'], '🍌', 3),
        _odd('o2', ['🐱', '🐱', '🐶', '🐱'], '🐶', 3),
        _odd('o3', ['▲', '▲', '●', '▲'], '●', 3),
        _odd('o4', ['🔴', '🔴', '🔵', '🔴'], '🔵', 3),
        _odd('o5', ['⭐', '⭐', '🌙', '⭐'], '🌙', 3),
        _odd('o6', ['🚗', '🚗', '🚌', '🚗'], '🚌', 4),
        _odd('o7', ['🌸', '🌸', '🌳', '🌸'], '🌳', 4),
        _odd('o8', ['1', '1', '2', '1'], '2', 4),
        _odd('o9', ['☀️', '☀️', '🌧️', '☀️'], '🌧️', 5),
        _odd('o10', ['🔺', '🔺', '🔻', '🔺'], '🔻', 5),
        _odd('o11', ['🍇', '🍇', '🍊', '🍇'], '🍊', 3),
        _odd('o12', ['🐷', '🐷', '🐮', '🐷'], '🐮', 3),
        _odd('o13', ['■', '■', '●', '■'], '●', 3),
        _odd('o14', ['🟡', '🟡', '🟢', '🟡'], '🟢', 3),
        _odd('o15', ['🚲', '🚲', '✈️', '🚲'], '✈️', 4),
        _odd('o16', ['🐟', '🐟', '🐦', '🐟'], '🐦', 4),
        _odd('o17', ['3', '3', '5', '3'], '5', 4),
        _odd('o18', ['❤️', '❤️', '💙', '❤️'], '💙', 3),
        _odd('o19', ['🍪', '🍪', '🥕', '🍪'], '🥕', 4),
        _odd('o20', ['👟', '👟', '🎩', '👟'], '🎩', 4),
        _odd('o21', ['🐘', '🐘', '🐭', '🐘'], '🐭', 5),
        _odd('o22', ['A', 'A', 'B', 'A'], 'B', 5),
        _odd('o23', ['🟦', '🟦', '🟨', '🟦'], '🟨', 5),
        _odd('o24', ['🐸', '🐸', '🐠', '🐸'], '🐠', 5),
        _odd('o25', ['🎾', '🎾', '⚽', '🎾'], '⚽', 5),
        _odd('o26', ['📚', '📚', '✏️', '📚'], '✏️', 6),
        _odd('o27', ['7️⃣', '7️⃣', '9️⃣', '7️⃣'], '9️⃣', 6),
        _odd('o28', ['🏠', '🏠', '🏫', '🏠'], '🏫', 6),
        _odd('o29', ['🎹', '🎹', '🥁', '🎹'], '🥁', 7),
        _odd('o30', ['❄️', '❄️', '🔥', '❄️'], '🔥', 7),
      ];

  List<ContentItem> _patterns() => [
        _item('p1', 'Tìm quy luật', 'Hình tiếp theo: 🔴🔵🔴🔵 ?', '🔴', ['🔴', '🔵', '🟡', '🟢'], 5, 'patterns'),
        _item('p2', 'Tìm quy luật', 'Hình tiếp theo: ⭐⭐🌙⭐⭐🌙 ?', '⭐', ['⭐', '🌙', '☀️', '🌈'], 5, 'patterns'),
        _item('p3', 'Tìm quy luật', 'Số tiếp theo: 1 2 3 ?', '4', ['4', '5', '2', '0'], 5, 'patterns'),
        _item('p4', 'Tìm quy luật', 'Số tiếp theo: 2 4 6 ?', '8', ['7', '8', '9', '5'], 6, 'patterns'),
        _item('p5', 'Tìm quy luật', 'Hình tiếp theo: ▲●▲● ?', '▲', ['▲', '●', '■', '◆'], 5, 'patterns'),
        _item('p6', 'Tìm quy luật', 'Hình tiếp theo: 🐱🐶🐱🐶 ?', '🐱', ['🐱', '🐶', '🐭', '🐰'], 5, 'patterns'),
        _item('p7', 'Tìm quy luật', 'Số tiếp theo: 10 20 30 ?', '40', ['35', '40', '50', '25'], 6, 'patterns'),
        _item('p8', 'Tìm quy luật', 'Hình tiếp theo: 🟥🟥🟦🟥🟥🟦 ?', '🟥', ['🟥', '🟦', '🟩', '🟨'], 6, 'patterns'),
        _item('p9', 'Tìm quy luật', 'Số tiếp theo: 5 4 3 ?', '2', ['1', '2', '3', '0'], 6, 'patterns'),
        _item('p10', 'Tìm quy luật', 'Hình tiếp theo: 🌞🌜🌞🌜 ?', '🌞', ['🌞', '🌜', '⭐', '🌈'], 5, 'patterns'),
        _item('p11', 'Tìm quy luật', 'Hình tiếp theo: 🍎🍌🍎🍌 ?', '🍎', ['🍎', '🍌', '🍇', '🍊'], 3, 'patterns'),
        _item('p12', 'Tìm quy luật', 'Hình tiếp theo: 🟢🟡🟢🟡 ?', '🟢', ['🟢', '🟡', '🔴', '🔵'], 3, 'patterns'),
        _item('p13', 'Tìm quy luật', 'Hình tiếp theo: 🌸🌼🌸🌼 ?', '🌸', ['🌸', '🌼', '🌳', '🍀'], 3, 'patterns'),
        _item('p14', 'Tìm quy luật', 'Hình tiếp theo: ■□■□ ?', '■', ['■', '□', '●', '▲'], 3, 'patterns'),
        _item('p15', 'Tìm quy luật', 'Số tiếp theo: 1 1 2 2 3 ?', '3', ['3', '4', '2', '1'], 4, 'patterns'),
        _item('p16', 'Tìm quy luật', 'Hình tiếp theo: 🐟🐠🐟🐠 ?', '🐟', ['🐟', '🐠', '🐦', '🐸'], 4, 'patterns'),
        _item('p17', 'Tìm quy luật', 'Hình tiếp theo: 🚗🚌🚗🚌 ?', '🚗', ['🚗', '🚌', '🚲', '✈️'], 4, 'patterns'),
        _item('p18', 'Tìm quy luật', 'Số tiếp theo: 3 6 9 ?', '12', ['10', '11', '12', '15'], 6, 'patterns'),
        _item('p19', 'Tìm quy luật', 'Hình tiếp theo: 🔺🔻🔺🔻 ?', '🔺', ['🔺', '🔻', '⬛', '⬜'], 4, 'patterns'),
        _item('p20', 'Tìm quy luật', 'Hình tiếp theo: ⭐🌙☀️⭐🌙☀️ ?', '⭐', ['⭐', '🌙', '☀️', '🌈'], 5, 'patterns'),
        _item('p21', 'Tìm quy luật', 'Số tiếp theo: 1 3 5 ?', '7', ['6', '7', '8', '9'], 6, 'patterns'),
        _item('p22', 'Tìm quy luật', 'Hình tiếp theo: 🟦🟨🟩🟦🟨🟩 ?', '🟦', ['🟦', '🟨', '🟩', '🟥'], 5, 'patterns'),
        _item('p23', 'Tìm quy luật', 'Số tiếp theo: 8 7 6 ?', '5', ['4', '5', '6', '9'], 5, 'patterns'),
        _item('p24', 'Tìm quy luật', 'Hình tiếp theo: 🌱🌿🌳🌱🌿🌳 ?', '🌱', ['🌱', '🌿', '🌳', '🍀'], 5, 'patterns'),
        _item('p25', 'Tìm quy luật', 'Số tiếp theo: 5 10 15 ?', '20', ['18', '20', '25', '16'], 6, 'patterns'),
        _item('p26', 'Tìm quy luật', 'Hình tiếp theo: AA BB AA BB ?', 'A', ['A', 'B', 'C', 'D'], 6, 'patterns'),
        _item('p27', 'Tìm quy luật', 'Số tiếp theo: 2 3 4 5 ?', '6', ['5', '6', '7', '8'], 4, 'patterns'),
        _item('p28', 'Tìm quy luật', 'Hình tiếp theo: 🎹🎸🎹🎸 ?', '🎹', ['🎹', '🎸', '🥁', '🎺'], 7, 'patterns'),
        _item('p29', 'Tìm quy luật', 'Số tiếp theo: 20 18 16 ?', '14', ['12', '14', '15', '18'], 7, 'patterns'),
        _item('p30', 'Tìm quy luật', 'Hình tiếp theo: 🟥🟦🟥🟦🟥 ?', '🟦', ['🟥', '🟦', '🟩', '⬛'], 6, 'patterns'),
      ];

  List<ContentItem> _pairs() => [
        _item('m1', 'Ghép cặp', 'Hình nào giống 🐶?', '🐶', ['🐱', '🐭', '🐶', '🐰'], 3, 'matching'),
        _item('m2', 'Ghép cặp', 'Hình nào giống ⭐?', '⭐', ['🌙', '☀️', '⭐', '🌈'], 3, 'matching'),
        _item('m3', 'Ghép cặp', 'Hình nào giống 🍎?', '🍎', ['🍌', '🍎', '🍇', '🍊'], 3, 'matching'),
        _item('m4', 'Ghép cặp', 'Hình nào giống 🚗?', '🚗', ['🚌', '🚲', '🚗', '✈️'], 3, 'matching'),
        _item('m5', 'Ghép cặp', 'Hình nào giống 🌸?', '🌸', ['🌳', '🌸', '🍀', '🍁'], 3, 'matching'),
        _item('m6', 'Ghép cặp', 'Hình nào giống 🐟?', '🐟', ['🐦', '🐟', '🐸', '🐢'], 4, 'matching'),
        _item('m7', 'Ghép cặp', 'Hình nào giống 🏠?', '🏠', ['🏫', '🏠', '🏥', '🏪'], 4, 'matching'),
        _item('m8', 'Ghép cặp', 'Hình nào giống 🎾?', '🎾', ['⚽', '🏀', '🎾', '🏈'], 4, 'matching'),
        _item('m9', 'Ghép cặp', 'Hình nào giống 📚?', '📚', ['✏️', '📚', '📏', '📎'], 5, 'matching'),
        _item('m10', 'Ghép cặp', 'Hình nào giống 🪁?', '🪁', ['🎈', '🪁', '🎁', '🧸'], 5, 'matching'),
        _item('m11', 'Ghép cặp', 'Hình nào giống 🍌?', '🍌', ['🍎', '🍌', '🍇', '🍓'], 3, 'matching'),
        _item('m12', 'Ghép cặp', 'Hình nào giống 🐱?', '🐱', ['🐶', '🐱', '🐭', '🐹'], 3, 'matching'),
        _item('m13', 'Ghép cặp', 'Hình nào giống ☀️?', '☀️', ['🌙', '⭐', '☀️', '☁️'], 3, 'matching'),
        _item('m14', 'Ghép cặp', 'Hình nào giống 🚌?', '🚌', ['🚗', '🚌', '🚲', '🚂'], 4, 'matching'),
        _item('m15', 'Ghép cặp', 'Hình nào giống 🐸?', '🐸', ['🐟', '🐦', '🐸', '🐢'], 4, 'matching'),
        _item('m16', 'Ghép cặp', 'Hình nào giống 🍓?', '🍓', ['🍒', '🍓', '🍉', '🍑'], 3, 'matching'),
        _item('m17', 'Ghép cặp', 'Hình nào giống 🐘?', '🐘', ['🐭', '🐘', '🦒', '🦓'], 4, 'matching'),
        _item('m18', 'Ghép cặp', 'Hình nào giống 🏀?', '🏀', ['⚽', '🎾', '🏀', '🏐'], 4, 'matching'),
        _item('m19', 'Ghép cặp', 'Hình nào giống 🌙?', '🌙', ['☀️', '⭐', '🌙', '🌈'], 3, 'matching'),
        _item('m20', 'Ghép cặp', 'Hình nào giống 🎹?', '🎹', ['🎸', '🥁', '🎹', '🎺'], 6, 'matching'),
        _item('m21', 'Ghép cặp', 'Hình nào giống 🐧?', '🐧', ['🐦', '🐧', '🐔', '🦆'], 5, 'matching'),
        _item('m22', 'Ghép cặp', 'Hình nào giống ✏️?', '✏️', ['📚', '📏', '✏️', '📎'], 5, 'matching'),
        _item('m23', 'Ghép cặp', 'Hình nào giống 🚂?', '🚂', ['🚌', '🚗', '🚂', '✈️'], 5, 'matching'),
        _item('m24', 'Ghép cặp', 'Hình nào giống 🍉?', '🍉', ['🍎', '🍇', '🍉', '🍌'], 4, 'matching'),
        _item('m25', 'Ghép cặp', 'Hình nào giống 🐢?', '🐢', ['🐸', '🐟', '🐢', '🐦'], 5, 'matching'),
        _item('m26', 'Ghép cặp', 'Hình nào giống 🎁?', '🎁', ['🎈', '🧸', '🎁', '🪁'], 5, 'matching'),
        _item('m27', 'Ghép cặp', 'Hình nào giống 🦒?', '🦒', ['🐘', '🦓', '🦒', '🦛'], 6, 'matching'),
        _item('m28', 'Ghép cặp', 'Hình nào giống 🎺?', '🎺', ['🎹', '🎸', '🥁', '🎺'], 6, 'matching'),
        _item('m29', 'Ghép cặp', 'Hình nào giống 🏫?', '🏫', ['🏠', '🏥', '🏫', '🏪'], 6, 'matching'),
        _item('m30', 'Ghép cặp', 'Hình nào giống 🧭?', '🧭', ['🗺️', '⌚', '🧭', '🔑'], 7, 'matching'),
      ];

  List<ContentItem> _classes() => [
        _item('c1', 'Phân loại', 'Đâu là con vật?', '🐱', ['🚗', '🌸', '🐱', '🍎'], 3, 'classification'),
        _item('c2', 'Phân loại', 'Đâu là đồ ăn?', '🍎', ['🚗', '🌸', '🐱', '🍎'], 3, 'classification'),
        _item('c3', 'Phân loại', 'Đâu là phương tiện?', '🚌', ['🐱', '🚌', '🌸', '🍎'], 3, 'classification'),
        _item('c4', 'Phân loại', 'Đâu là hoa?', '🌸', ['🌳', '🌸', '🍎', '🐱'], 3, 'classification'),
        _item('c5', 'Phân loại', 'Đâu là số?', '7', ['A', '7', '⭐', '🐱'], 4, 'classification'),
        _item('c6', 'Phân loại', 'Đâu là trái cây?', '🍌', ['🥕', '🍌', '🍞', '🥛'], 4, 'classification'),
        _item('c7', 'Phân loại', 'Đâu sống dưới nước?', '🐟', ['🐱', '🐶', '🐟', '🐦'], 5, 'classification'),
        _item('c8', 'Phân loại', 'Đâu dùng để viết?', '✏️', ['🥄', '✏️', '🔑', '👟'], 5, 'classification'),
        _item('c9', 'Phân loại', 'Đâu là quần áo?', '👕', ['🍎', '👕', '🚗', '🌳'], 5, 'classification'),
        _item('c10', 'Phân loại', 'Đâu bay được?', '🐦', ['🐟', '🐸', '🐦', '🐢'], 6, 'classification'),
        _item('c11', 'Phân loại', 'Đâu là đồ uống?', '🥛', ['🍞', '🍎', '🥛', '🥕'], 3, 'classification'),
        _item('c12', 'Phân loại', 'Đâu là rau?', '🥕', ['🍌', '🍎', '🥕', '🍪'], 3, 'classification'),
        _item('c13', 'Phân loại', 'Đâu là đồ chơi?', '🧸', ['🍎', '🧸', '🚌', '🌳'], 3, 'classification'),
        _item('c14', 'Phân loại', 'Đâu là chữ cái?', 'B', ['3', 'B', '⭐', '7'], 4, 'classification'),
        _item('c15', 'Phân loại', 'Đâu là nhạc cụ?', '🎸', ['⚽', '🎸', '📚', '🍎'], 5, 'classification'),
        _item('c16', 'Phân loại', 'Đâu dùng để đọc?', '📚', ['👟', '🔑', '📚', '🍦'], 5, 'classification'),
        _item('c17', 'Phân loại', 'Đâu là thời tiết?', '🌧️', ['🐱', '🌧️', '🏠', '🍌'], 4, 'classification'),
        _item('c18', 'Phân loại', 'Đâu sống trên cạn?', '🐶', ['🐟', '🐳', '🐶', '🐠'], 5, 'classification'),
        _item('c19', 'Phân loại', 'Đâu là hình tròn?', '●', ['▲', '■', '●', '◆'], 3, 'classification'),
        _item('c20', 'Phân loại', 'Đâu là giày?', '👟', ['👕', '🎩', '👟', '🧤'], 4, 'classification'),
        _item('c21', 'Phân loại', 'Đâu dùng để ăn?', '🥄', ['✏️', '🔑', '🥄', '👟'], 5, 'classification'),
        _item('c22', 'Phân loại', 'Đâu là ngôi nhà?', '🏠', ['🚗', '🌸', '🏠', '🐟'], 3, 'classification'),
        _item('c23', 'Phân loại', 'Đâu là môn thể thao?', '⚽', ['📚', '⚽', '🍎', '🎹'], 5, 'classification'),
        _item('c24', 'Phân loại', 'Đâu có bánh xe?', '🚲', ['🐟', '🌳', '🚲', '🐦'], 4, 'classification'),
        _item('c25', 'Phân loại', 'Đâu là đồ ngọt?', '🍦', ['🥕', '🥦', '🍦', '🥬'], 4, 'classification'),
        _item('c26', 'Phân loại', 'Đâu là côn trùng?', '🐝', ['🐱', '🐶', '🐝', '🐟'], 6, 'classification'),
        _item('c27', 'Phân loại', 'Đâu dùng khi mưa?', '☂️', ['🍦', '☂️', '⚽', '🎹'], 5, 'classification'),
        _item('c28', 'Phân loại', 'Đâu là hành tinh?', '🌍', ['⭐', '🌙', '🌍', '☁️'], 7, 'classification'),
        _item('c29', 'Phân loại', 'Đâu là số chẵn?', '8', ['7', '3', '8', '9'], 6, 'classification'),
        _item('c30', 'Phân loại', 'Đâu là dụng cụ nấu ăn?', '🍳', ['📚', '⚽', '🍳', '🎸'], 6, 'classification'),
      ];

  List<ContentItem> _sizes() => [
        _item('s1', 'Lớn / nhỏ', 'Hình nào lớn hơn?', '⬛', ['⬛', '▪', '▫️'], 3, 'size'),
        _item('s2', 'Lớn / nhỏ', 'Hình nào nhỏ hơn?', '▫️', ['⬛', '▪', '▫️'], 3, 'size'),
        _item('s3', 'Lớn / nhỏ', 'Quả nào to hơn?', '🍉', ['🍒', '🍉', '🍇'], 3, 'size'),
        _item('s4', 'Lớn / nhỏ', 'Con nào nhỏ hơn?', '🐭', ['🐘', '🐭', '🐴'], 3, 'size'),
        _item('s5', 'Lớn / nhỏ', 'Số nào lớn hơn?', '9', ['2', '9', '4'], 4, 'size'),
        _item('s6', 'Lớn / nhỏ', 'Số nào nhỏ hơn?', '1', ['1', '8', '5'], 4, 'size'),
        _item('s7', 'Lớn / nhỏ', 'Cây nào cao hơn?', '🌲', ['🌱', '🌲', '🍀'], 4, 'size'),
        _item('s8', 'Lớn / nhỏ', 'Hình nào to nhất?', '⬤', ['•', '●', '⬤'], 5, 'size'),
        _item('s9', 'Lớn / nhỏ', 'Hình nào nhỏ nhất?', '•', ['⬤', '●', '•'], 5, 'size'),
        _item('s10', 'Lớn / nhỏ', 'Nhóm nào nhiều hơn?', '•••••', ['••', '•••••', '•••'], 6, 'size'),
        _item('s11', 'Lớn / nhỏ', 'Con nào to hơn?', '🐘', ['🐭', '🐘', '🐱'], 3, 'size'),
        _item('s12', 'Lớn / nhỏ', 'Quả nào nhỏ hơn?', '🍒', ['🍉', '🍒', '🍍'], 3, 'size'),
        _item('s13', 'Lớn / nhỏ', 'Chữ nào lớn hơn?', 'A', ['a', 'A', '.'], 3, 'size'),
        _item('s14', 'Lớn / nhỏ', 'Số nào lớn hơn?', '5', ['1', '3', '5'], 3, 'size'),
        _item('s15', 'Lớn / nhỏ', 'Số nào nhỏ hơn?', '2', ['2', '6', '9'], 4, 'size'),
        _item('s16', 'Lớn / nhỏ', 'Nhóm nào ít hơn?', '•', ['••••', '•••', '•'], 4, 'size'),
        _item('s17', 'Lớn / nhỏ', 'Xe nào dài hơn?', '🚂', ['🚲', '🚂', '🛴'], 4, 'size'),
        _item('s18', 'Lớn / nhỏ', 'Hình nào cao hơn?', '▮', ['▬', '▮', '▪'], 5, 'size'),
        _item('s19', 'Lớn / nhỏ', 'Số nào lớn nhất?', '10', ['3', '7', '10'], 5, 'size'),
        _item('s20', 'Lớn / nhỏ', 'Số nào nhỏ nhất?', '0', ['0', '4', '8'], 5, 'size'),
        _item('s21', 'Lớn / nhỏ', 'Con nào cao hơn?', '🦒', ['🐶', '🦒', '🐢'], 5, 'size'),
        _item('s22', 'Lớn / nhỏ', 'Nhóm nào nhiều nhất?', '••••••', ['••', '••••', '••••••'], 6, 'size'),
        _item('s23', 'Lớn / nhỏ', 'Hình nào hẹp hơn?', '│', ['━', '│', '■'], 6, 'size'),
        _item('s24', 'Lớn / nhỏ', 'Số nào lớn hơn?', '20', ['12', '20', '8'], 6, 'size'),
        _item('s25', 'Lớn / nhỏ', 'Quả nào nặng hơn?', '🥥', ['🍒', '🥥', '🍓'], 4, 'size'),
        _item('s26', 'Lớn / nhỏ', 'Tòa nào cao hơn?', '🏢', ['🏠', '🏢', '⛺'], 5, 'size'),
        _item('s27', 'Lớn / nhỏ', 'Số nào nhỏ hơn?', '11', ['11', '19', '25'], 6, 'size'),
        _item('s28', 'Lớn / nhỏ', 'Nhóm nào ít nhất?', '•', ['•••••', '•••', '•'], 6, 'size'),
        _item('s29', 'Lớn / nhỏ', 'Số nào lớn nhất?', '100', ['10', '50', '100'], 7, 'size'),
        _item('s30', 'Lớn / nhỏ', 'Khoảng nào dài hơn?', '────', ['─', '──', '────'], 7, 'size'),
      ];

  List<ContentItem> _sequence() => [
        _item('q1', 'Trước / sau', 'Số nào đứng trước 3?', '2', ['1', '2', '4', '5'], 4, 'sequence'),
        _item('q2', 'Trước / sau', 'Số nào đứng sau 4?', '5', ['3', '4', '5', '2'], 4, 'sequence'),
        _item('q3', 'Trước / sau', 'Số nào đứng trước 1?', '0', ['0', '2', '3', '1'], 4, 'sequence'),
        _item('q4', 'Trước / sau', 'Số nào đứng sau 9?', '10', ['8', '9', '10', '7'], 5, 'sequence'),
        _item('q5', 'Trước / sau', 'Ngày nào sau thứ Hai?', 'thứ Ba', ['Chủ nhật', 'thứ Ba', 'thứ Bảy'], 6, 'sequence'),
        _item('q6', 'Trước / sau', 'Buổi nào trước buổi trưa?', 'sáng', ['sáng', 'chiều', 'tối'], 5, 'sequence'),
        _item('q7', 'Trước / sau', 'Số nào đứng trước 10?', '9', ['8', '9', '11', '10'], 5, 'sequence'),
        _item('q8', 'Trước / sau', 'Hình đầu tiên: 1️⃣2️⃣3️⃣ — đâu là đầu?', '1️⃣', ['1️⃣', '2️⃣', '3️⃣'], 3, 'sequence'),
        _item('q9', 'Trước / sau', 'Hình cuối: 🌱🌿🌳 — đâu là cuối?', '🌳', ['🌱', '🌿', '🌳'], 4, 'sequence'),
        _item('q10', 'Trước / sau', 'Số nào đứng sau 19?', '20', ['18', '19', '20', '21'], 7, 'sequence'),
        _item('q11', 'Trước / sau', 'Số nào đứng sau 1?', '2', ['0', '1', '2', '4'], 3, 'sequence'),
        _item('q12', 'Trước / sau', 'Số nào đứng trước 2?', '1', ['0', '1', '3', '4'], 3, 'sequence'),
        _item('q13', 'Trước / sau', 'Hình giữa: 🐱🐶🐭 — đâu là giữa?', '🐶', ['🐱', '🐶', '🐭'], 3, 'sequence'),
        _item('q14', 'Trước / sau', 'Số nào đứng sau 5?', '6', ['4', '5', '6', '8'], 4, 'sequence'),
        _item('q15', 'Trước / sau', 'Số nào đứng trước 8?', '7', ['6', '7', '9', '8'], 4, 'sequence'),
        _item('q16', 'Trước / sau', 'Buổi nào sau buổi chiều?', 'tối', ['sáng', 'trưa', 'tối'], 5, 'sequence'),
        _item('q17', 'Trước / sau', 'Ngày nào trước thứ Tư?', 'thứ Ba', ['thứ Hai', 'thứ Ba', 'thứ Năm'], 6, 'sequence'),
        _item('q18', 'Trước / sau', 'Số nào đứng sau 11?', '12', ['10', '11', '12', '13'], 5, 'sequence'),
        _item('q19', 'Trước / sau', 'Hình đầu: 🥚🐣🐥 — đâu là đầu?', '🥚', ['🥚', '🐣', '🐥'], 4, 'sequence'),
        _item('q20', 'Trước / sau', 'Hình cuối: 🌕🌖🌗 — đâu là cuối?', '🌗', ['🌕', '🌖', '🌗'], 5, 'sequence'),
        _item('q21', 'Trước / sau', 'Số nào đứng trước 15?', '14', ['13', '14', '16', '15'], 6, 'sequence'),
        _item('q22', 'Trước / sau', 'Số nào đứng sau 24?', '25', ['23', '24', '25', '26'], 6, 'sequence'),
        _item('q23', 'Trước / sau', 'Tháng nào sau tháng 1?', 'tháng 2', ['tháng 12', 'tháng 2', 'tháng 3'], 6, 'sequence'),
        _item('q24', 'Trước / sau', 'Chữ nào sau A?', 'B', ['C', 'B', 'Z', 'A'], 4, 'sequence'),
        _item('q25', 'Trước / sau', 'Chữ nào trước C?', 'B', ['A', 'B', 'D', 'C'], 4, 'sequence'),
        _item('q26', 'Trước / sau', 'Số nào đứng trước 20?', '19', ['18', '19', '21', '20'], 6, 'sequence'),
        _item('q27', 'Trước / sau', 'Hình thứ hai: 🚗🚌🚲 — đâu là thứ hai?', '🚌', ['🚗', '🚌', '🚲'], 3, 'sequence'),
        _item('q28', 'Trước / sau', 'Ngày nào sau thứ Sáu?', 'thứ Bảy', ['thứ Năm', 'thứ Bảy', 'thứ Hai'], 7, 'sequence'),
        _item('q29', 'Trước / sau', 'Số nào đứng sau 49?', '50', ['48', '49', '50', '51'], 7, 'sequence'),
        _item('q30', 'Trước / sau', 'Số nào đứng trước 100?', '99', ['90', '98', '99', '101'], 7, 'sequence'),
      ];

  List<ContentItem> _sameDiff() => [
        _item('d1', 'Giống / khác', 'Hai hình này giống hay khác? 🔵 🔵', 'giống', ['giống', 'khác'], 3, 'same_diff'),
        _item('d2', 'Giống / khác', 'Hai hình này giống hay khác? 🔵 🔴', 'khác', ['giống', 'khác'], 3, 'same_diff'),
        _item('d3', 'Giống / khác', 'Hai hình này giống hay khác? ⭐ ⭐', 'giống', ['giống', 'khác'], 3, 'same_diff'),
        _item('d4', 'Giống / khác', 'Hai hình này giống hay khác? 🐱 🐶', 'khác', ['giống', 'khác'], 3, 'same_diff'),
        _item('d5', 'Giống / khác', 'Hai số này giống hay khác? 2 2', 'giống', ['giống', 'khác'], 4, 'same_diff'),
        _item('d6', 'Giống / khác', 'Hai số này giống hay khác? 3 8', 'khác', ['giống', 'khác'], 4, 'same_diff'),
        _item('d7', 'Giống / khác', 'Hai chữ này giống hay khác? A A', 'giống', ['giống', 'khác'], 4, 'same_diff'),
        _item('d8', 'Giống / khác', 'Hai chữ này giống hay khác? A B', 'khác', ['giống', 'khác'], 4, 'same_diff'),
        _item('d9', 'Giống / khác', 'Hai hình này giống hay khác? ▲ △', 'khác', ['giống', 'khác'], 5, 'same_diff'),
        _item('d10', 'Giống / khác', 'Hai hình này giống hay khác? 🟩 🟩', 'giống', ['giống', 'khác'], 5, 'same_diff'),
        _item('d11', 'Giống / khác', 'Hai hình này giống hay khác? 🍎 🍎', 'giống', ['giống', 'khác'], 3, 'same_diff'),
        _item('d12', 'Giống / khác', 'Hai hình này giống hay khác? 🍎 🍌', 'khác', ['giống', 'khác'], 3, 'same_diff'),
        _item('d13', 'Giống / khác', 'Hai hình này giống hay khác? 🚗 🚌', 'khác', ['giống', 'khác'], 3, 'same_diff'),
        _item('d14', 'Giống / khác', 'Hai hình này giống hay khác? 🌸 🌸', 'giống', ['giống', 'khác'], 3, 'same_diff'),
        _item('d15', 'Giống / khác', 'Hai số này giống hay khác? 5 5', 'giống', ['giống', 'khác'], 4, 'same_diff'),
        _item('d16', 'Giống / khác', 'Hai số này giống hay khác? 4 7', 'khác', ['giống', 'khác'], 4, 'same_diff'),
        _item('d17', 'Giống / khác', 'Hai chữ này giống hay khác? C C', 'giống', ['giống', 'khác'], 4, 'same_diff'),
        _item('d18', 'Giống / khác', 'Hai chữ này giống hay khác? M N', 'khác', ['giống', 'khác'], 4, 'same_diff'),
        _item('d19', 'Giống / khác', 'Hai hình này giống hay khác? ■ ■', 'giống', ['giống', 'khác'], 3, 'same_diff'),
        _item('d20', 'Giống / khác', 'Hai hình này giống hay khác? ● ▲', 'khác', ['giống', 'khác'], 3, 'same_diff'),
        _item('d21', 'Giống / khác', 'Hai hình này giống hay khác? 🟥 🟥', 'giống', ['giống', 'khác'], 5, 'same_diff'),
        _item('d22', 'Giống / khác', 'Hai hình này giống hay khác? 🟥 🟦', 'khác', ['giống', 'khác'], 5, 'same_diff'),
        _item('d23', 'Giống / khác', 'Hai số này giống hay khác? 10 10', 'giống', ['giống', 'khác'], 5, 'same_diff'),
        _item('d24', 'Giống / khác', 'Hai số này giống hay khác? 12 21', 'khác', ['giống', 'khác'], 5, 'same_diff'),
        _item('d25', 'Giống / khác', 'Hai chữ này giống hay khác? a A', 'khác', ['giống', 'khác'], 6, 'same_diff'),
        _item('d26', 'Giống / khác', 'Hai hình này giống hay khác? 🌙 ⭐', 'khác', ['giống', 'khác'], 5, 'same_diff'),
        _item('d27', 'Giống / khác', 'Hai hình này giống hay khác? 🐟 🐟', 'giống', ['giống', 'khác'], 4, 'same_diff'),
        _item('d28', 'Giống / khác', 'Hai số này giống hay khác? 0 0', 'giống', ['giống', 'khác'], 4, 'same_diff'),
        _item('d29', 'Giống / khác', 'Hai chữ này giống hay khác? b d', 'khác', ['giống', 'khác'], 6, 'same_diff'),
        _item('d30', 'Giống / khác', 'Hai hình này giống hay khác? ◯ ○', 'giống', ['giống', 'khác'], 7, 'same_diff'),
      ];

  List<ContentItem> _memory() => [
        _item('mem1', 'Nhớ vị trí', 'Hình ở giữa là gì? 🐱 🐶 🐭', '🐶', ['🐱', '🐶', '🐭', '🐰'], 5, 'memory'),
        _item('mem2', 'Nhớ vị trí', 'Hình đầu tiên là gì? 🍎 🍌 🍇', '🍎', ['🍎', '🍌', '🍇', '🍊'], 5, 'memory'),
        _item('mem3', 'Nhớ vị trí', 'Hình cuối là gì? ⭐ 🌙 ☀️', '☀️', ['⭐', '🌙', '☀️', '🌈'], 5, 'memory'),
        _item('mem4', 'Nhớ vị trí', 'Hình ở giữa là gì? 1️⃣ 2️⃣ 3️⃣', '2️⃣', ['1️⃣', '2️⃣', '3️⃣', '4️⃣'], 5, 'memory'),
        _item('mem5', 'Nhớ vị trí', 'Hình thứ hai là gì? 🚗 🚌 🚲', '🚌', ['🚗', '🚌', '🚲', '✈️'], 5, 'memory'),
        _item('mem6', 'Nhớ vị trí', 'Hình đầu là gì? 🌸 🌳 🍀', '🌸', ['🌸', '🌳', '🍀', '🍁'], 4, 'memory'),
        _item('mem7', 'Nhớ vị trí', 'Hình cuối là gì? 🐟 🐦 🐸', '🐸', ['🐟', '🐦', '🐸', '🐢'], 5, 'memory'),
        _item('mem8', 'Nhớ vị trí', 'Hình ở giữa là gì? A B C', 'B', ['A', 'B', 'C', 'D'], 6, 'memory'),
        _item('mem9', 'Nhớ vị trí', 'Hình thứ hai là gì? 🟥 🟦 🟨', '🟦', ['🟥', '🟦', '🟨', '🟩'], 6, 'memory'),
        _item('mem10', 'Nhớ vị trí', 'Hình cuối là gì? 🎹 🎸 🥁', '🥁', ['🎹', '🎸', '🥁', '🎺'], 7, 'memory'),
        _item('mem11', 'Nhớ vị trí', 'Hình đầu tiên là gì? 🐶 🐱 🐭', '🐶', ['🐶', '🐱', '🐭', '🐰'], 3, 'memory'),
        _item('mem12', 'Nhớ vị trí', 'Hình cuối là gì? 🔴 🔵 🟢', '🟢', ['🔴', '🔵', '🟢', '🟡'], 3, 'memory'),
        _item('mem13', 'Nhớ vị trí', 'Hình ở giữa là gì? 🍉 🍓 🍒', '🍓', ['🍉', '🍓', '🍒', '🍇'], 3, 'memory'),
        _item('mem14', 'Nhớ vị trí', 'Hình thứ hai là gì? 🏠 🏫 🏥', '🏫', ['🏠', '🏫', '🏥', '🏪'], 4, 'memory'),
        _item('mem15', 'Nhớ vị trí', 'Hình đầu là gì? ▲ ● ■', '▲', ['▲', '●', '■', '◆'], 3, 'memory'),
        _item('mem16', 'Nhớ vị trí', 'Hình cuối là gì? 🌞 ☁️ 🌧️', '🌧️', ['🌞', '☁️', '🌧️', '❄️'], 4, 'memory'),
        _item('mem17', 'Nhớ vị trí', 'Hình ở giữa là gì? 🎾 ⚽ 🏀', '⚽', ['🎾', '⚽', '🏀', '🏈'], 5, 'memory'),
        _item('mem18', 'Nhớ vị trí', 'Hình thứ hai là gì? 4 5 6', '5', ['4', '5', '6', '7'], 4, 'memory'),
        _item('mem19', 'Nhớ vị trí', 'Hình đầu tiên là gì? 🐘 🦒 🦓', '🐘', ['🐘', '🦒', '🦓', '🦁'], 5, 'memory'),
        _item('mem20', 'Nhớ vị trí', 'Hình cuối là gì? ✏️ 📚 📏', '📏', ['✏️', '📚', '📏', '📎'], 5, 'memory'),
        _item('mem21', 'Nhớ vị trí', 'Hình thứ ba là gì? 🌸 🌼 🌻 🌺', '🌻', ['🌸', '🌼', '🌻', '🌺'], 6, 'memory'),
        _item('mem22', 'Nhớ vị trí', 'Hình ở giữa là gì? 🧁 🍪 🍩', '🍪', ['🧁', '🍪', '🍩', '🍰'], 4, 'memory'),
        _item('mem23', 'Nhớ vị trí', 'Hình đầu là gì? 🪁 🎈 🎁', '🪁', ['🪁', '🎈', '🎁', '🧸'], 4, 'memory'),
        _item('mem24', 'Nhớ vị trí', 'Hình thứ hai là gì? X Y Z', 'Y', ['X', 'Y', 'Z', 'W'], 6, 'memory'),
        _item('mem25', 'Nhớ vị trí', 'Hình cuối là gì? 7 8 9', '9', ['7', '8', '9', '6'], 5, 'memory'),
        _item('mem26', 'Nhớ vị trí', 'Hình thứ ba là gì? 🚗 🚕 🚌 🚎', '🚌', ['🚗', '🚕', '🚌', '🚎'], 6, 'memory'),
        _item('mem27', 'Nhớ vị trí', 'Hình ở giữa là gì? 🌙 ⭐ ☀️', '⭐', ['🌙', '⭐', '☀️', '🌈'], 5, 'memory'),
        _item('mem28', 'Nhớ vị trí', 'Hình đầu tiên là gì? 🐸 🐢 🦎', '🐸', ['🐸', '🐢', '🦎', '🐍'], 5, 'memory'),
        _item('mem29', 'Nhớ vị trí', 'Hình thứ hai trong 🟥🟧🟨🟩 là gì?', '🟧', ['🟥', '🟧', '🟨', '🟩'], 7, 'memory'),
        _item('mem30', 'Nhớ vị trí', 'Hình cuối trong 🎹🎻🎸🎺 là gì?', '🎺', ['🎹', '🎻', '🎸', '🎺'], 7, 'memory'),
      ];

  List<ContentItem> _paths() => [
        _item('path1', 'Tìm đường', 'Đường nào tới nhà? → → ↓', '↓', ['↑', '↓', '←', '→'], 6, 'path'),
        _item('path2', 'Tìm đường', 'Đi lên thì chọn?', '↑', ['↑', '↓', '←', '→'], 5, 'path'),
        _item('path3', 'Tìm đường', 'Đi sang phải thì chọn?', '→', ['↑', '↓', '←', '→'], 5, 'path'),
        _item('path4', 'Tìm đường', 'Đi xuống thì chọn?', '↓', ['↑', '↓', '←', '→'], 5, 'path'),
        _item('path5', 'Tìm đường', 'Đi sang trái thì chọn?', '←', ['↑', '↓', '←', '→'], 5, 'path'),
        _item('path6', 'Tìm đường', 'Mũi tên ngược với ↑ là?', '↓', ['↑', '↓', '←', '→'], 6, 'path'),
        _item('path7', 'Tìm đường', 'Mũi tên ngược với → là?', '←', ['↑', '↓', '←', '→'], 6, 'path'),
        _item('path8', 'Tìm đường', 'Đường vòng về: → ↓ ← ?', '↑', ['↑', '↓', '←', '→'], 7, 'path'),
        _item('path9', 'Tìm đường', 'Để tới 🏠 bên phải, đi?', '→', ['↑', '↓', '←', '→'], 6, 'path'),
        _item('path10', 'Tìm đường', 'Để tới 🌳 phía trên, đi?', '↑', ['↑', '↓', '←', '→'], 6, 'path'),
        _item('path11', 'Tìm đường', 'Mũi tên này chỉ đâu? ↑', 'lên', ['lên', 'xuống', 'trái', 'phải'], 3, 'path'),
        _item('path12', 'Tìm đường', 'Mũi tên này chỉ đâu? ↓', 'xuống', ['lên', 'xuống', 'trái', 'phải'], 3, 'path'),
        _item('path13', 'Tìm đường', 'Mũi tên này chỉ đâu? →', 'phải', ['lên', 'xuống', 'trái', 'phải'], 3, 'path'),
        _item('path14', 'Tìm đường', 'Mũi tên này chỉ đâu? ←', 'trái', ['lên', 'xuống', 'trái', 'phải'], 3, 'path'),
        _item('path15', 'Tìm đường', 'Để tới 🍎 bên trái, đi?', '←', ['↑', '↓', '←', '→'], 4, 'path'),
        _item('path16', 'Tìm đường', 'Để tới ⭐ phía dưới, đi?', '↓', ['↑', '↓', '←', '→'], 4, 'path'),
        _item('path17', 'Tìm đường', 'Bước tiếp: ↑ ↑ ? (đi lên nữa)', '↑', ['↑', '↓', '←', '→'], 4, 'path'),
        _item('path18', 'Tìm đường', 'Mũi tên ngược với ↓ là?', '↑', ['↑', '↓', '←', '→'], 5, 'path'),
        _item('path19', 'Tìm đường', 'Mũi tên ngược với ← là?', '→', ['↑', '↓', '←', '→'], 5, 'path'),
        _item('path20', 'Tìm đường', 'Đường tới trường: → → → bước cuối?', '→', ['↑', '↓', '←', '→'], 5, 'path'),
        _item('path21', 'Tìm đường', 'Rẽ phải sau khi đi lên: ↑ rồi?', '→', ['↑', '↓', '←', '→'], 6, 'path'),
        _item('path22', 'Tìm đường', 'Đường vòng: ↓ ← ↑ ?', '→', ['↑', '↓', '←', '→'], 7, 'path'),
        _item('path23', 'Tìm đường', 'Để về chỗ cũ sau →, đi?', '←', ['↑', '↓', '←', '→'], 6, 'path'),
        _item('path24', 'Tìm đường', 'Hình ở phía trên là? ⭐\n🚗', '⭐', ['⭐', '🚗', '🌙', '🏠'], 4, 'path'),
        _item('path25', 'Tìm đường', 'Hình ở phía dưới là? 🌞\n🌧️', '🌧️', ['🌞', '🌧️', '⭐', '🌙'], 4, 'path'),
        _item('path26', 'Tìm đường', 'Bên phải của 🐱 🐶 là?', '🐶', ['🐱', '🐶', '🐭', '🐰'], 5, 'path'),
        _item('path27', 'Tìm đường', 'Bên trái của 🍎 🍌 là?', '🍎', ['🍎', '🍌', '🍇', '🍊'], 5, 'path'),
        _item('path28', 'Tìm đường', 'Đường chữ U: → ↓ ← ?', '↑', ['↑', '↓', '←', '→'], 7, 'path'),
        _item('path29', 'Tìm đường', 'Đi ngược chiều kim đồng hồ từ → thì?', '↑', ['↑', '↓', '←', '→'], 7, 'path'),
        _item('path30', 'Tìm đường', 'Ba bước tới 🏠: ↑ → ↓ — bước giữa?', '→', ['↑', '↓', '←', '→'], 6, 'path'),
      ];

  List<ContentItem> _logic() => [
        _item('l1', 'Logic đơn giản', 'Nếu có 2 quả táo, thêm 1 quả nữa thì có mấy quả?', '3', ['2', '3', '4', '1'], 6, 'logic'),
        _item('l2', 'Logic đơn giản', 'Có 3 viên kẹo, ăn 1 viên còn mấy viên?', '2', ['1', '2', '3', '4'], 6, 'logic'),
        _item('l3', 'Logic đơn giản', 'Ban ngày trời sáng. Ban đêm trời?', 'tối', ['sáng', 'tối', 'mưa'], 5, 'logic'),
        _item('l4', 'Logic đơn giản', 'Cá sống ở đâu?', 'nước', ['nước', 'trời', 'nhà'], 5, 'logic'),
        _item('l5', 'Logic đơn giản', 'Chim thì biết gì?', 'bay', ['bơi', 'bay', 'đào'], 5, 'logic'),
        _item('l6', 'Logic đơn giản', 'Nếu trời mưa, bé cần gì?', 'ô', ['ô', 'kem', 'bóng'], 6, 'logic'),
        _item('l7', 'Logic đơn giản', 'Có 4 bánh, chia đều 2 bé, mỗi bé mấy bánh?', '2', ['1', '2', '4', '3'], 7, 'logic'),
        _item('l8', 'Logic đơn giản', 'Mẹ có 5 bông hoa, tặng 2 bông, còn mấy bông?', '3', ['2', '3', '5', '7'], 7, 'logic'),
        _item('l9', 'Logic đơn giản', 'Giày đi với gì?', 'chân', ['tay', 'chân', 'đầu'], 6, 'logic'),
        _item('l10', 'Logic đơn giản', 'Muốn đọc sách thì cần gì?', 'sách', ['sách', 'bóng', 'kẹo'], 6, 'logic'),
        _item('l11', 'Logic đơn giản', 'Chó kêu như thế nào?', 'gâu', ['gâu', 'meo', 'quạc'], 3, 'logic'),
        _item('l12', 'Logic đơn giản', 'Mèo kêu như thế nào?', 'meo', ['gâu', 'meo', 'ọ'], 3, 'logic'),
        _item('l13', 'Logic đơn giản', 'Trời nắng thì bé thấy gì?', 'nắng', ['nắng', 'tuyết', 'đêm'], 3, 'logic'),
        _item('l14', 'Logic đơn giản', 'Muốn vẽ thì cần gì?', 'bút', ['bút', 'kẹo', 'giày'], 4, 'logic'),
        _item('l15', 'Logic đơn giản', 'Khát nước thì bé làm gì?', 'uống', ['ngủ', 'uống', 'chạy'], 4, 'logic'),
        _item('l16', 'Logic đơn giản', 'Buồn ngủ thì bé nên?', 'ngủ', ['ăn kẹo', 'ngủ', 'nhảy'], 4, 'logic'),
        _item('l17', 'Logic đơn giản', 'Có 1 quả, thêm 1 quả nữa thì có mấy quả?', '2', ['1', '2', '3', '0'], 3, 'logic'),
        _item('l18', 'Logic đơn giản', 'Tay dùng để làm gì?', 'cầm', ['đi', 'cầm', 'ngửi'], 5, 'logic'),
        _item('l19', 'Logic đơn giản', 'Mắt dùng để làm gì?', 'nhìn', ['nghe', 'nhìn', 'nếm'], 5, 'logic'),
        _item('l20', 'Logic đơn giản', 'Tai dùng để làm gì?', 'nghe', ['nhìn', 'nghe', 'chạy'], 5, 'logic'),
        _item('l21', 'Logic đơn giản', 'Nếu cửa khóa, bé cần gì để mở?', 'chìa', ['chìa', 'bánh', 'bóng'], 6, 'logic'),
        _item('l22', 'Logic đơn giản', 'Có 6 viên bi, mất 2 viên còn mấy viên?', '4', ['2', '4', '6', '8'], 6, 'logic'),
        _item('l23', 'Logic đơn giản', 'Lửa thì?', 'nóng', ['lạnh', 'nóng', 'ướt'], 5, 'logic'),
        _item('l24', 'Logic đơn giản', 'Nước đá thì?', 'lạnh', ['nóng', 'lạnh', 'bay'], 5, 'logic'),
        _item('l25', 'Logic đơn giản', 'Muốn rửa tay thì cần gì?', 'nước', ['cát', 'nước', 'kẹo'], 4, 'logic'),
        _item('l26', 'Logic đơn giản', 'Ban đêm bé nhìn thấy gì trên trời?', 'sao', ['nắng', 'sao', 'cầu vồng'], 4, 'logic'),
        _item('l27', 'Logic đơn giản', 'Có 8 cái kẹo, chia đều 2 hộp, mỗi hộp mấy cái?', '4', ['2', '4', '6', '8'], 7, 'logic'),
        _item('l28', 'Logic đơn giản', 'Nếu hôm qua là thứ Hai, hôm nay là?', 'thứ Ba', ['Chủ nhật', 'thứ Ba', 'thứ Sáu'], 7, 'logic'),
        _item('l29', 'Logic đơn giản', 'Xe chạy trên gì?', 'đường', ['nước', 'đường', 'mây'], 6, 'logic'),
        _item('l30', 'Logic đơn giản', 'Cây cần gì để lớn?', 'nước', ['kẹo', 'nước', 'bóng'], 6, 'logic'),
      ];

  ContentItem _odd(String id, List<String> choices, String answer, int ageMin) {
    return _item(id, 'Tìm hình khác', 'Hình nào khác với các hình còn lại?', answer, choices, ageMin, 'odd_one_out');
  }

  ContentItem _item(
    String id,
    String title,
    String instruction,
    String answer,
    List<String> choices,
    int ageMin,
    String skill,
  ) {
    return ContentItem(
      id: 'think_$id',
      subject: ContentSubject.thinking,
      ageMin: ageMin,
      ageMax: 7,
      level: ageMin <= 4 ? 1 : (ageMin <= 5 ? 2 : 3),
      skill: skill,
      difficulty: ageMin <= 4 ? 1 : 2,
      title: title,
      instruction: instruction,
      question: instruction,
      answer: answer,
      choices: List<String>.from(choices)..shuffle(_random),
    );
  }
}
