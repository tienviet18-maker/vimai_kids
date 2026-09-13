import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/data/content/math_generator.dart';
import 'package:mai_an_learning/data/content/thinking_generator.dart';
import 'package:mai_an_learning/data/kana/hiragana_data.dart';
import 'package:mai_an_learning/data/kana/katakana_data.dart';
import 'package:mai_an_learning/domain/models/kana_item.dart';

void main() {
  const requiredHiraganaBasic = [
    'あ','い','う','え','お','か','き','く','け','こ','さ','し','す','せ','そ',
    'た','ち','つ','て','と','な','に','ぬ','ね','の','は','ひ','ふ','へ','ほ',
    'ま','み','む','め','も','や','ゆ','よ','ら','り','る','れ','ろ','わ','を','ん',
  ];
  const requiredKatakanaBasic = [
    'ア','イ','ウ','エ','オ','カ','キ','ク','ケ','コ','サ','シ','ス','セ','ソ',
    'タ','チ','ツ','テ','ト','ナ','ニ','ヌ','ネ','ノ','ハ','ヒ','フ','ヘ','ホ',
    'マ','ミ','ム','メ','モ','ヤ','ユ','ヨ','ラ','リ','ル','レ','ロ','ワ','ヲ','ン',
  ];

  test('hiragana dataset contains every required basic character exactly once', () {
    final basic = hiraganaData.where((e) => e.kanaType == KanaType.basic).map((e) => e.character).toList();
    expect(basic.toSet().length, basic.length);
    for (final ch in requiredHiraganaBasic) {
      expect(basic, contains(ch));
    }
    expect(basic.length, 46);
  });

  test('katakana dataset contains every required basic character exactly once', () {
    final basic = katakanaData.where((e) => e.kanaType == KanaType.basic).map((e) => e.character).toList();
    expect(basic.toSet().length, basic.length);
    for (final ch in requiredKatakanaBasic) {
      expect(basic, contains(ch));
    }
    expect(basic.length, 46);
  });

  test('ids are unique and romaji is present', () {
    final ids = <String>{};
    for (final kana in [...hiraganaData, ...katakanaData]) {
      expect(kana.romaji, isNotEmpty);
      expect(kana.languageCode, 'ja-JP');
      expect(ids.add(kana.id), isTrue);
    }
  });

  test('dakuten handakuten yoon small sokuon choon yoon counts', () {
    expect(hiraganaData.where((e) => e.kanaType == KanaType.dakuten).length, 20);
    expect(hiraganaData.where((e) => e.kanaType == KanaType.handakuten).length, 5);
    expect(hiraganaData.where((e) => e.kanaType == KanaType.yoon).length, 33);
    expect(katakanaData.where((e) => e.kanaType == KanaType.dakuten).length, 20);
    expect(katakanaData.where((e) => e.kanaType == KanaType.yoon).length, 33);
    expect(hiraganaData.where((e) => e.kanaType == KanaType.choon), isNotEmpty);
    expect(katakanaData.where((e) => e.kanaType == KanaType.extended), isNotEmpty);
  });

  test('vietnamese alphabet has 29 unique letters and letter names', () {
    final file = File('assets/content/vietnamese/alphabet.json');
    final list = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    expect(list.length, 29);
    final letters = <String>{};
    for (final raw in list) {
      final item = raw as Map<String, dynamic>;
      expect(item['metadata']['letterName'], isNotEmpty);
      expect(letters.add(item['question'] as String), isTrue);
    }
    expect(letters, containsAll(['A', 'Ă', 'Â', 'B']));
    expect(letters.contains('F'), isFalse);
    for (final raw in list) {
      final item = raw as Map<String, dynamic>;
      final meta = item['metadata'] as Map<String, dynamic>;
      expect(meta['audioLocale'], 'vi-VN');
      expect(meta['audioText'], isNotEmpty);
      expect(meta['letterName'], isNot('ay'));
      expect(meta['letterName'], isNot('bee'));
    }
    final b = list.cast<Map<String, dynamic>>().firstWhere((e) => e['question'] == 'B');
    expect(b['metadata']['letterName'], 'bê');
    expect(b['metadata']['phoneme'], 'bờ');
    expect(b['metadata']['phoneme'], isNot('b'));
  });

  test('vietnamese phonics and rimes have valid answers in choices', () {
    for (final path in ['assets/content/vietnamese/phonics.json', 'assets/content/vietnamese/rimes.json', 'assets/content/vietnamese/words.json']) {
      final list = jsonDecode(File(path).readAsStringSync()) as List<dynamic>;
      expect(list, isNotEmpty);
      for (final raw in list) {
        final item = raw as Map<String, dynamic>;
        final choices = (item['choices'] as List).cast<String>();
        expect(choices.toSet().length, choices.length, reason: 'duplicate choices in ${item['id']}');
        expect(choices, contains(item['answer']));
        if (path.contains('phonics')) {
          expect(item['metadata']['audioLocale'], 'vi-VN');
          expect(item['metadata']['audioText'], item['answer']);
          expect(item['metadata']['audioText'], isNot(contains('+')));
        }
      }
    }
  });

  test('math generator never uses English locale and stays under 100', () {
    expect(AudioLocalePolicy.requiredLocale(EducationalLanguage.japanese), 'ja-JP');
    expect(AudioLocalePolicy.localeFor(AudioLanguage.japanese), 'ja-JP');
    expect(AudioLocalePolicy.localeFor(AudioLanguage.vietnamese), 'vi-VN');
    final gen = MathQuestionGenerator();
    for (var i = 0; i < 30; i++) {
      final q = gen.generateBySkill('addition_under_100', age: 7);
      expect(int.parse(q.answer!), lessThanOrEqualTo(100));
      expect(q.choices, contains(q.answer));
      final sub = gen.generateBySkill('subtraction_under_100', age: 7);
      expect(int.parse(sub.answer!), greaterThanOrEqualTo(0));
    }
  });

  test('thinking engine returns age-appropriate unique questions', () {
    final engine = ThinkingQuestionEngine();
    final seen = <String>{};
    for (var i = 0; i < 12; i++) {
      final q = engine.next(age: 5);
      expect(q.choices, isNotEmpty);
      expect(q.choices, contains(q.answer));
      seen.add(q.id);
    }
    expect(seen.length, greaterThan(1));
    final young = engine.next(age: 3);
    expect(young.ageMin, lessThanOrEqualTo(3));
  });
}
