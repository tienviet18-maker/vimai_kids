import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/data/kana/hiragana_data.dart';
import 'package:mai_an_learning/data/kana/katakana_data.dart';
import 'package:mai_an_learning/domain/models/kana_item.dart';

void main() {
  group('Kana content', () {
    test('Hiragana basic contains exactly 46 characters', () {
      expect(hiraganaData.where((e) => e.kanaType == KanaType.basic).length, 46);
    });

    test('Katakana basic contains exactly 46 characters', () {
      expect(katakanaData.where((e) => e.kanaType == KanaType.basic).length, 46);
    });

    test('dakuten, handakuten, yoon, small, sokuon, choon exist', () {
      expect(hiraganaData.where((e) => e.kanaType == KanaType.dakuten), isNotEmpty);
      expect(katakanaData.where((e) => e.kanaType == KanaType.dakuten), isNotEmpty);
      expect(hiraganaData.where((e) => e.kanaType == KanaType.handakuten), isNotEmpty);
      expect(katakanaData.where((e) => e.kanaType == KanaType.handakuten), isNotEmpty);
      expect(hiraganaData.where((e) => e.kanaType == KanaType.yoon), isNotEmpty);
      expect(katakanaData.where((e) => e.kanaType == KanaType.yoon), isNotEmpty);
      expect(hiraganaData.where((e) => e.kanaType == KanaType.small), isNotEmpty);
      expect(katakanaData.where((e) => e.kanaType == KanaType.small), isNotEmpty);
      expect(hiraganaData.where((e) => e.kanaType == KanaType.sokuon), isNotEmpty);
      expect(katakanaData.where((e) => e.kanaType == KanaType.sokuon), isNotEmpty);
      expect(katakanaData.where((e) => e.kanaType == KanaType.choon), isNotEmpty);
    });

    test('every kana has romaji and unique id', () {
      final ids = <String>{};
      for (final kana in [...hiraganaData, ...katakanaData]) {
        expect(kana.romaji, isNotEmpty);
        expect(ids.add(kana.id), isTrue);
      }
    });

    test('confusion groups are data-driven', () {
      final nu = hiraganaData.firstWhere((e) => e.character == 'ぬ');
      final shi = katakanaData.firstWhere((e) => e.character == 'シ');
      expect(nu.confusionGroup, contains('め'));
      expect(shi.confusionGroup, contains('ツ'));
    });
  });
}
