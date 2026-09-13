import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/branding/config.dart';
import 'package:mai_an_learning/core/contact/feedback_mail.dart';
import 'package:mai_an_learning/data/content/creativity_catalog.dart';
import 'package:mai_an_learning/data/content/game_catalog.dart';
import 'package:mai_an_learning/data/content/math_generator.dart';
import 'package:mai_an_learning/data/content/thinking_generator.dart';
import 'package:mai_an_learning/data/kana/hiragana_data.dart';
import 'package:mai_an_learning/data/kana/katakana_data.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/domain/models/kana_item.dart';

void main() {
  test('Vietnamese alphabet is 29 letters and excludes F', () {
    final list = jsonDecode(File('assets/content/vietnamese/alphabet.json').readAsStringSync()) as List;
    expect(list.length, 29);
    final letters = list.map((e) => (e as Map)['question']).toSet();
    expect(letters.contains('F'), isFalse);
    expect(letters.contains('A'), isTrue);
  });

  test('Japanese character sets', () {
    expect(hiraganaData.where((e) => e.kanaType == KanaType.basic).length, 46);
    expect(katakanaData.where((e) => e.kanaType == KanaType.basic).length, 46);
    expect(hiraganaData.where((e) => e.kanaType == KanaType.dakuten).length, 20);
    expect(katakanaData.where((e) => e.kanaType == KanaType.dakuten).length, 20);
    expect(hiraganaData.where((e) => e.kanaType == KanaType.handakuten).length, 5);
    expect(katakanaData.where((e) => e.kanaType == KanaType.handakuten).length, 5);
    expect(hiraganaData.where((e) => e.kanaType == KanaType.yoon).length, 33);
    expect(katakanaData.where((e) => e.kanaType == KanaType.yoon).length, 33);
    expect(hiraganaData.where((e) => e.kanaType == KanaType.small).length, greaterThanOrEqualTo(8));
    expect(katakanaData.where((e) => e.kanaType == KanaType.extended), isNotEmpty);
  });

  test('math age gating, no negative subtraction, max 100', () {
    for (final age in [3, 4, 5, 6, 7]) {
      final gen = MathQuestionGenerator(random: Random(age * 17));
      for (var i = 0; i < 40; i++) {
        final add = gen.generateBySkill(MathQuestionGenerator.skillForAge(age, addition: true), age: age);
        final sub = gen.generateBySkill(MathQuestionGenerator.skillForAge(age, addition: false), age: age);
        expect(int.parse(add.answer!), lessThanOrEqualTo(100));
        expect(int.parse(sub.answer!), greaterThanOrEqualTo(0));
        expect(int.parse(sub.answer!), lessThanOrEqualTo(100));
        if (age <= 3) {
          expect(int.parse(add.answer!), lessThanOrEqualTo(10));
        }
      }
    }
  });

  test('thinking and creativity counts and age gating', () {
    final thinking = ThinkingQuestionEngine(random: Random(1));
    expect(thinking.allForAge(3).length, greaterThanOrEqualTo(30));
    expect(thinking.allForAge(7).length, greaterThanOrEqualTo(thinking.allForAge(3).length));
    expect(CreativityCatalog.coloringPages().length, greaterThanOrEqualTo(30));
    expect(CreativityCatalog.dotPuzzles().length, greaterThanOrEqualTo(30));
    expect(CreativityCatalog.matchPuzzles().length, greaterThanOrEqualTo(30));
    expect(CreativityCatalog.patternPuzzles().length, greaterThanOrEqualTo(30));
    expect(CreativityCatalog.drawingChallenges().length, greaterThanOrEqualTo(30));
    expect(CreativityCatalog.coloringForAge(3).every((e) => e.ageMin <= 3), isTrue);
  });

  test('games have 30+ variants or equivalent generator', () {
    expect(GameCatalog.similarSymbols.length, greaterThanOrEqualTo(30));
    final gen = MathQuestionGenerator(random: Random(9));
    final ids = {for (var i = 0; i < 40; i++) gen.generateAddition(10).id};
    expect(ids.length, greaterThan(1));
    expect(GameCatalog.roundsForAge(3), 8);
    expect(GameCatalog.roundsForAge(7), 16);
  });

  test('ChildProfile age clamp and no hardcoded Mai An in profile', () {
    final profile = ChildProfile(id: 'x', name: 'Lan', age: 9, avatar: '🐱', createdAt: DateTime(2026));
    expect(ChildProfile.clampAge(9), 7);
    expect(ChildProfile.clampAge(2), 3);
    expect(profile.childName, isNot('Mai An'));
  });

  test('branding and support mailto', () {
    expect(AppBrand.productDisplayName, 'ViMai Kids');
    expect(AppBrand.productBrand, 'ViMai');
    expect(AppBrand.supportEmail, 'vimai.support@gmail.com');
    expect(AppBrand.supportEmail.contains('tienviet18'), isFalse);
    final uri = FeedbackMail.mailto(childName: 'Lan', age: 5);
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'vimai.support@gmail.com');
  });

  test('source tree has no hardcoded Mai An in features', () {
    final dir = Directory('lib');
    for (final file in dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      expect(source.contains('Mai An'), isFalse, reason: file.path);
      expect(source.contains('tienviet18@gmail.com'), isFalse, reason: file.path);
      expect(source.contains('Phạm Tiến Việt'), isFalse, reason: file.path);
      expect(source.contains('Bài học hôm nay'), isFalse, reason: file.path);
    }
  });

  test('home screen does not contain daily lesson copy', () {
    final source = File('lib/features/home/presentation/home_screen.dart').readAsStringSync();
    expect(source.contains('Bài học hôm nay'), isFalse);
    expect(source.contains('DiscoveryNest'), isTrue);
    expect(source.contains('CanopyPathTrail'), isTrue);
    expect(source.contains('continueLearningProvider'), isTrue);
    expect(source.contains('VimaiSpace.maxHome'), isTrue);
    expect(source.contains('startHomeBgm'), isTrue);
    expect(source.contains('KidsValleyScene'), isFalse);
    expect(source.contains('WorldIsland'), isFalse);
    expect(source.contains('ActivityGarden'), isFalse);
    expect(source.contains('KidsRoomScene'), isFalse);
  });

  test('rich Vietnamese catalogs', () {
    expect((jsonDecode(File('assets/content/vietnamese/phonics.json').readAsStringSync()) as List).length, greaterThanOrEqualTo(40));
    expect((jsonDecode(File('assets/content/vietnamese/rimes.json').readAsStringSync()) as List).length, greaterThanOrEqualTo(40));
    expect((jsonDecode(File('assets/content/vietnamese/words.json').readAsStringSync()) as List).length, greaterThanOrEqualTo(120));
    expect((jsonDecode(File('assets/content/vietnamese/sentences.json').readAsStringSync()) as List).length, greaterThanOrEqualTo(30));
  });
}
