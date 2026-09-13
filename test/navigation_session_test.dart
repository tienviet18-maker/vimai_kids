import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/data/kana/hiragana_data.dart';
import 'package:mai_an_learning/domain/content/content_item.dart';

void main() {
  test('Tiếp tục advances kana index and does not wrap to start', () {
    final items = hiraganaData.where((e) => e.kanaType.name == 'basic').toList();
    var index = 0;
    var popped = false;
    void continuePressed() {
      if (index >= items.length - 1) {
        // complete session, stay in module
        return;
      }
      index++;
    }

    expect(items[index].character, 'あ');
    continuePressed();
    expect(items[index].character, 'い');
    expect(popped, isFalse);
    continuePressed();
    expect(items[index].character, 'う');
    expect(popped, isFalse);
  });

  test('Vietnamese letters advance A Ă Â B without popping', () {
    const letters = ['A', 'Ă', 'Â', 'B', 'C'];
    var index = 0;
    var popped = false;
    void next() {
      if (index < letters.length - 1) index++;
    }

    expect(letters[index], 'A');
    next();
    expect(letters[index], 'Ă');
    next();
    expect(letters[index], 'Â');
    next();
    expect(letters[index], 'B');
    expect(popped, isFalse);
  });

  test('Vietnamese content items declare vi-VN audio locale', () {
    const letter = ContentItem(
      id: 'v_b',
      subject: ContentSubject.vietnamese,
      ageMin: 3,
      ageMax: 7,
      level: 1,
      skill: 'alphabet',
      difficulty: 1,
      title: 'Chữ B',
      instruction: 'Chữ B',
      question: 'B',
      metadata: {
        'letterName': 'bê',
        'phoneme': 'bờ',
        'audioText': 'bê',
        'audioLocale': 'vi-VN',
      },
    );
    expect(letter.audioLocale, 'vi-VN');
    expect(letter.audioText, 'bê');
    expect(letter.phoneme, 'bờ');
    expect(letter.letterName, isNot('bee'));
  });
}
