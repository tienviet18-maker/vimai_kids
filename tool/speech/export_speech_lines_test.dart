// Run: flutter test tool/speech/export_speech_lines_test.dart
// Writes tool/speech/speech_lines.json — every Vietnamese line a child can see.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/kid_guide.dart';
import 'package:mai_an_learning/core/audio/speech_id.dart';
import 'package:mai_an_learning/data/content/creativity_catalog.dart';
import 'package:mai_an_learning/data/content/learning_repositories.dart';
import 'package:mai_an_learning/data/content/math_generator.dart';
import 'package:mai_an_learning/data/content/thinking_generator.dart';
import 'package:mai_an_learning/domain/content/content_item.dart';
import 'package:mai_an_learning/features/explore/data/explore_catalog.dart';
import 'package:mai_an_learning/features/explore/explore_guide.dart';

void main() {
  test('export speech lines', () {
    final lines = <String, Set<String>>{};
    void add(String group, String? text) {
      if (text == null) return;
      // Phonics formulas ("b + a") are voiced sound-first by their own
      // v_blend_*/v_rime_* clips; a narrator would read letter names.
      if ((group == 'vi_phonics' || group == 'vi_rimes') && text.contains('+')) return;
      final spoken = SpeechId.spokenText(text);
      if (spoken == null) return;
      lines.putIfAbsent(group, () => <String>{}).add(spoken);
    }

    void addItem(String group, ContentItem item, {bool choices = true}) {
      add(group, item.title);
      add(group, item.instruction);
      add(group, item.question);
      add(group, item.answer);
      if (choices) {
        for (final c in item.choices ?? const <String>[]) {
          add(group, c);
        }
      }
    }

    // Vietnamese JSON content.
    for (final f in ['phonics', 'rimes', 'words', 'vocabulary', 'sentences', 'alphabet', 'lessons']) {
      final file = File('assets/data/vietnamese/$f.json');
      if (!file.existsSync()) continue;
      final data = jsonDecode(file.readAsStringSync());
      if (data is! List) continue;
      for (final raw in data.whereType<Map<String, dynamic>>()) {
        add('vi_$f', raw['title'] as String?);
        add('vi_$f', raw['instruction'] as String?);
        add('vi_$f', raw['question'] as String?);
        add('vi_$f', raw['answer'] as String?);
        for (final c in (raw['choices'] as List? ?? const [])) {
          add('vi_$f', c.toString());
        }
        final meta = raw['metadata'];
        if (meta is Map) add('vi_$f', meta['meaning'] as String?);
      }
    }

    // Engines, sampled widely with fixed seeds.
    for (var seed = 0; seed < 40; seed++) {
      final rnd = Random(seed);
      final math = MathQuestionGenerator(random: rnd);
      for (final skill in _mathSkills) {
        for (var age = 3; age <= 7; age++) {
          final item = math.generateBySkill(skill, age: age);
          add('math', item.title);
          add('math', item.instruction);
          if (skill == 'word_problem') add('math_word_problem', item.question);
        }
      }
      final thinking = ThinkingQuestionEngine(random: rnd);
      for (var age = 3; age <= 7; age++) {
        for (var i = 0; i < 30; i++) {
          addItem('thinking', thinking.next(age: age));
        }
      }
      final repo = LearningRepositories(random: rnd);
      for (var i = 0; i < 10; i++) {
        addItem('learning', repo.shapeQuestion());
        addItem('learning', repo.colorQuestion());
        addItem('learning', repo.vietnameseLetterQuestion(), choices: false);
      }
    }
    final thinkingBank = jsonDecode(File('assets/data/thinking/patterns.json').readAsStringSync());
    if (thinkingBank is List) {
      for (final raw in thinkingBank.whereType<Map<String, dynamic>>()) {
        add('thinking', raw['title'] as String?);
        add('thinking', raw['instruction'] as String?);
        add('thinking', raw['question'] as String?);
      }
    }

    for (final item in CreativityCatalog.asContentItems()) {
      addItem('creativity', item);
    }

    for (final line in KidGuide.all) {
      add('guide', line);
    }

    // Khám phá thế giới: topic titles, every picture's name, fact and quiz question.
    final explore = ExploreCatalog.parse(File(ExploreCatalog.assetPath).readAsStringSync());
    for (final category in explore.categories) {
      add('explore', category.title);
      for (final item in category.items) {
        add('explore', item.name);
        add('explore', item.fact);
        add('explore', item.question);
      }
    }
    for (final line in ExploreGuide.all) {
      add('explore', line);
    }

    final out = {
      for (final e in lines.entries)
        e.key: [
          for (final t in (e.value.toList()..sort())) {'id': SpeechId.forText(t), 'text': t},
        ],
    };
    File('tool/speech/speech_lines.json').writeAsStringSync(const JsonEncoder.withIndent(' ').convert(out));
    for (final e in out.entries) {
      // ignore: avoid_print
      print('${e.key}: ${e.value.length}');
    }
  });
}

const _mathSkills = [
  'counting', 'number_recognition', 'comparison', 'number_match', 'picture_math',
  'addition_under_5', 'subtraction_under_5', 'addition_under_10', 'subtraction_under_10',
  'number_pattern', 'number_line', 'addition_under_20', 'subtraction_under_20', 'missing_number',
  'before_after', 'classify_numbers', 'addition_under_50', 'subtraction_under_50', 'word_problem',
  'sort_numbers', 'find_correct_op', 'addition_under_100', 'subtraction_under_100',
  'compare_expressions', 'fill_plus_minus', 'odd_even',
];
