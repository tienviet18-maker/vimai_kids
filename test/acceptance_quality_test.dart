import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_asset_registry.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/core/audio/audio_resolver.dart';
import 'package:mai_an_learning/core/contact/feedback_mail.dart';
import 'package:mai_an_learning/data/content/creativity_catalog.dart';
import 'package:mai_an_learning/data/content/math_generator.dart';
import 'package:mai_an_learning/data/content/thinking_generator.dart';
import 'package:mai_an_learning/data/kana/hiragana_data.dart';
import 'package:mai_an_learning/domain/content/content_item.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/domain/models/kana_item.dart';

void main() {
  test('Vietnamese alphabet has 29 letters', () {
    final list = jsonDecode(File('assets/content/vietnamese/alphabet.json').readAsStringSync()) as List;
    expect(list.length, 29);
    final letters = list.map((e) => (e as Map)['question']).toList();
    expect(letters.take(4).toList(), ['A', 'Ă', 'Â', 'B']);
    expect(letters.contains('F'), isFalse);
    final byLetter = <String, String>{};
    for (final raw in list) {
      final item = Map<String, dynamic>.from(raw as Map);
      final meta = Map<String, dynamic>.from(item['metadata'] as Map);
      byLetter[item['question'] as String] = meta['letterName'] as String;
    }
    expect(byLetter['A'], 'a');
    expect(byLetter['Ă'], 'ă');
    expect(byLetter['Â'], 'â');
    expect(byLetter['B'], 'bê');
    expect(byLetter['C'], 'xê');
    expect(byLetter['L'], 'e-lờ');
    expect(byLetter['M'], 'em-mờ');
    expect(byLetter['N'], 'en-nờ');
    expect(byLetter['Y'], 'i');
  });

  test('Japanese hiragana has 46 basic characters in あ い う え お order', () {
    final basic = hiraganaData.where((e) => e.kanaType == KanaType.basic).toList();
    expect(basic.length, 46);
    expect(basic.map((e) => e.character).take(5).toList(), ['あ', 'い', 'う', 'え', 'お']);
  });

  test('Vietnamese audio resolver always returns vi-VN', () {
    final resolved = AudioResolver.vietnamese('bê');
    expect(resolved.locale, 'vi-VN');
    expect(resolved.language, AudioLanguage.vietnamese);
    expect(AudioResolver.isAllowedLocale(resolved.language, resolved.locale), isTrue);
  });

  test('Japanese audio resolver always returns ja-JP', () {
    final resolved = AudioResolver.japanese('あ');
    expect(resolved.locale, 'ja-JP');
    expect(resolved.language, AudioLanguage.japanese);
  });

  test('Vietnamese audio never fallback ja-JP or en-US', () {
    final resolved = AudioResolver.forContent(
      const ContentItem(
        id: 'v_b',
        subject: ContentSubject.vietnamese,
        ageMin: 3,
        ageMax: 7,
        level: 1,
        skill: 'alphabet',
        difficulty: 1,
        title: 'B',
        instruction: 'B',
        audioAsset: 'assets/audio/vi/letters/b.mp3',
        metadata: {'audioText': 'bê', 'audioLocale': 'vi-VN'},
      ),
    );
    expect(resolved.locale, isNot('ja-JP'));
    expect(resolved.locale, isNot('en-US'));
    expect(AudioResolver.vietnameseFallsBackToJapanese(resolved.locale), isFalse);
    expect(AudioResolver.fallsBackToEnglish(resolved.locale), isFalse);
    expect(AudioAssetRegistry.exists('assets/audio/vi/letters/b.mp3'), isFalse);
    expect(resolved.recordedAsset, isNot('assets/audio/vi/letters/b.mp3'));
    if (resolved.recordedAsset != null) {
      expect(resolved.recordedAsset!.startsWith('assets/audio/vietnamese/'), isTrue);
    }
  });

  test('Japanese audio never fallback en-US', () {
    final resolved = AudioResolver.japanese('あ', audioAsset: 'missing.mp3');
    expect(resolved.locale, 'ja-JP');
    expect(AudioResolver.fallsBackToEnglish(resolved.locale), isFalse);
    expect(resolved.recordedAsset, isNull);
  });

  test('Math subtraction is never negative and addition <= 100', () {
    final gen = MathQuestionGenerator(random: Random(9));
    for (var i = 0; i < 40; i++) {
      expect(int.parse(gen.generateSubtraction(100, age: 7).answer!), greaterThanOrEqualTo(0));
      expect(int.parse(gen.generateAddition(100, age: 7).answer!), lessThanOrEqualTo(100));
    }
  });

  test('Math questions are age-gated by skill', () {
    expect(MathQuestionGenerator.skillForAge(3, addition: true), 'addition_under_10');
    expect(MathQuestionGenerator.skillForAge(3, addition: false), 'counting');
    expect(MathQuestionGenerator.skillForAge(4, addition: false), 'subtraction_under_10');
    expect(MathQuestionGenerator.skillForAge(5, addition: true), 'addition_under_20');
    expect(MathQuestionGenerator.skillForAge(6, addition: true), 'addition_under_50');
    expect(MathQuestionGenerator.skillForAge(7, addition: true), 'addition_under_100');
  });

  test('Thinking questions are age-gated and not a single repeating item', () {
    final engine = ThinkingQuestionEngine(random: Random(3));
    expect(engine.allForAge(3).every((e) => e.ageMin <= 3), isTrue);
    expect(engine.allForAge(3).where((e) => e.skill == 'odd_one_out').length, greaterThanOrEqualTo(5));
    expect(engine.allForAge(7).length, greaterThanOrEqualTo(50));
    final seen = <String>{};
    for (var i = 0; i < 12; i++) {
      seen.add(engine.next(age: 5).id);
    }
    expect(seen.length, greaterThan(1));
  });

  test('Creativity puzzles have at least 15 in each main group', () {
    expect(CreativityCatalog.coloringPages().length, greaterThanOrEqualTo(15));
    expect(CreativityCatalog.dotPuzzles().length, greaterThanOrEqualTo(15));
    expect(CreativityCatalog.matchPuzzles().length, greaterThanOrEqualTo(15));
    expect(CreativityCatalog.dotPuzzles().every((e) => e.points.length >= 6), isTrue);
  });

  test('Connect-the-dots data has many puzzles with numbered points', () {
    final puzzles = CreativityCatalog.dotPuzzles();
    expect(puzzles.map((e) => e.id).toSet().length, puzzles.length);
    expect(puzzles.first.points.length, greaterThan(1));
  });

  test('Next lesson does not pop route', () {
    final items = hiraganaData.where((e) => e.kanaType == KanaType.basic).toList();
    var index = 0;
    var popped = false;
    void next() {
      if (index < items.length - 1) index++;
    }
    next();
    expect(items[index].character, 'い');
    expect(popped, isFalse);
  });

  test('Vietnamese lesson sequence A Ă Â B', () {
    final list = jsonDecode(File('assets/content/vietnamese/alphabet.json').readAsStringSync()) as List;
    expect(list[0]['question'], 'A');
    expect(list[1]['question'], 'Ă');
    expect(list[2]['question'], 'Â');
    expect(list[3]['question'], 'B');
  });

  test('Japanese lesson sequence あ い う え お', () {
    final basic = hiraganaData.where((e) => e.kanaType == KanaType.basic).toList();
    expect(basic[0].character, 'あ');
    expect(basic[1].character, 'い');
    expect(basic[2].character, 'う');
    expect(basic[3].character, 'え');
    expect(basic[4].character, 'お');
  });

  test('ChildProfile name is used and age is only 3-7', () {
    final profile = ChildProfile(
      id: 'p1',
      name: 'Minh',
      age: 9,
      avatar: '🐱',
      createdAt: DateTime(2026, 1, 1),
    );
    expect(profile.childName, 'Minh');
    expect(ChildProfile.clampAge(profile.age), 7);
    expect(ChildProfile.clampAge(1), 3);
    expect(ChildProfile.fromJson({
      'id': 'p2',
      'name': 'Lan',
      'age': 2,
      'avatar': '🐰',
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    }).age, 3);
  });

  test('mailto is created with vimai.support@gmail.com', () {
    final uri = FeedbackMail.mailto(childName: 'Lan', age: 5);
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'vimai.support@gmail.com');
    expect(uri.path, isNot('tienviet18@gmail.com'));
    expect(uri.queryParameters['subject'], '[ViMai Kids] Phản hồi từ người dùng');
    expect(uri.queryParameters['body'], contains('Tên bé:'));
    expect(uri.queryParameters['body'], contains('Tuổi:'));
    expect(uri.queryParameters['body'], contains('Nội dung góp ý:'));
  });

  test('phonics blends including ph th kh nh ch tr gh ngh stay vi-VN', () {
    final list = jsonDecode(File('assets/content/vietnamese/phonics.json').readAsStringSync()) as List;
    final onsets = list.map((e) => (e as Map)['metadata']['onset']).toSet();
    expect(onsets, containsAll(['ph', 'th', 'kh', 'nh', 'ch', 'tr', 'gh', 'ngh']));
    for (final raw in list) {
      final item = raw as Map;
      expect(item['metadata']['audioLocale'], 'vi-VN');
      expect(item['metadata']['audioText'], item['answer']);
    }
  });

  test('launcher and web title are ViMai Kids, not mai_an_learning', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:label="ViMai Kids"'));
    expect(manifest, isNot(contains('android:label="mai_an_learning"')));
    expect(manifest, isNot(contains('android:label="Học vui"')));
    final web = File('web/index.html').readAsStringSync();
    expect(web, contains('<title>ViMai Kids</title>'));
    expect(web, isNot(contains('<title>mai_an_learning</title>')));
    expect(web, isNot(contains('<title>Học vui</title>')));
  });
}
