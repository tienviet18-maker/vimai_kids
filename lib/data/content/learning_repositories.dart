import 'dart:math';

import '../../domain/content/content_item.dart';
import '../../domain/models/kana_item.dart';
import '../kana/hiragana_data.dart';
import '../kana/katakana_data.dart';

/// Shared knowledge banks for language / shapes / colors quizzes.
class LearningRepositories {
  LearningRepositories({Random? random}) : _random = random ?? Random();

  final Random _random;
  String? _lastFingerprint;

  static const vietnameseAlphabet = [
    'a', 'ă', 'â', 'b', 'c', 'd', 'đ', 'e', 'ê', 'g',
    'h', 'i', 'k', 'l', 'm', 'n', 'o', 'ô', 'ơ', 'p',
    'q', 'r', 's', 't', 'u', 'ư', 'v', 'x', 'y',
  ];

  static const vietnameseWordBank = <String, String>{
    'a': '🍎 áo',
    'ă': '🍚 ăn',
    'â': '🫖 ấm',
    'b': '👨 bố',
    'c': '🐟 cá',
    'd': '☂️ dù',
    'đ': '🍈 đu đủ',
    'e': '👶 em',
    'ê': '🐸 ếch',
    'g': '🐔 gà',
    'h': '🌸 hoa',
    'i': '🔵 bi',
    'k': '✂️ kéo',
    'l': '🍐 lê',
    'm': '🐱 mèo',
    'n': '🎀 nơ',
    'o': '🐝 ong',
    'ô': '⛱️ ô',
    'ơ': '🚩 cờ',
    'p': '🔦 pin',
    'q': '🍊 quýt',
    'r': '🐢 rùa',
    's': '⭐ sao',
    't': '🍎 táo',
    'u': '🧢 mũ',
    'ư': '✉️ thư',
    'v': '🐘 voi',
    'x': '🚲 xe',
    'y': '👩‍⚕️ y tá',
  };

  static const tones = ['ngang', 'huyền', 'sắc', 'hỏi', 'ngã', 'nặng'];

  static const shapes = <String, String>{
    'circle': '⭕ Tròn',
    'square': '⬜ Vuông',
    'triangle': '🔺 Tam giác',
    'rectangle': '▬ Chữ nhật',
    'star': '⭐ Ngôi sao',
    'heart': '❤️ Trái tim',
    'oval': '⬭ Bầu dục',
  };

  static const colors = <String, String>{
    'red': '🔴 Đỏ',
    'blue': '🔵 Xanh dương',
    'yellow': '🟡 Vàng',
    'green': '🟢 Xanh lá',
    'orange': '🟠 Cam',
    'purple': '🟣 Tím',
    'pink': '🩷 Hồng',
    'brown': '🟤 Nâu',
  };

  static const japaneseVocab = <({String word, String meaning, String romaji, String script})>[
    (word: 'いぬ', meaning: 'con chó', romaji: 'inu', script: 'hiragana'),
    (word: 'ねこ', meaning: 'con mèo', romaji: 'neko', script: 'hiragana'),
    (word: 'さくら', meaning: 'hoa anh đào', romaji: 'sakura', script: 'hiragana'),
    (word: 'りんご', meaning: 'quả táo', romaji: 'ringo', script: 'hiragana'),
    (word: 'こんにちは', meaning: 'xin chào', romaji: 'konnichiwa', script: 'hiragana'),
    (word: 'ありがとう', meaning: 'cảm ơn', romaji: 'arigatou', script: 'hiragana'),
    (word: 'バナナ', meaning: 'chuối', romaji: 'banana', script: 'katakana'),
    (word: 'アイス', meaning: 'kem', romaji: 'aisu', script: 'katakana'),
    (word: 'カメラ', meaning: 'máy ảnh', romaji: 'kamera', script: 'katakana'),
    (word: 'オレンジ', meaning: 'cam', romaji: 'orenji', script: 'katakana'),
  ];

  ContentItem vietnameseLetterQuestion() {
    return _unique(() {
      final answer = vietnameseAlphabet[_random.nextInt(vietnameseAlphabet.length)];
      final distractors = <String>{};
      while (distractors.length < 3) {
        final d = vietnameseAlphabet[_random.nextInt(vietnameseAlphabet.length)];
        if (d != answer) distractors.add(d);
      }
      final word = vietnameseWordBank[answer] ?? answer;
      return ContentItem(
        id: 'vi_letter_${_random.nextInt(999999)}',
        subject: ContentSubject.vietnamese,
        ageMin: 3,
        ageMax: 7,
        level: 1,
        skill: 'alphabet',
        difficulty: 1,
        title: 'Chữ cái',
        instruction: 'Chữ nào bắt đầu từ: $word?',
        question: word,
        answer: answer,
        choices: _shuffled([answer, ...distractors]),
      );
    });
  }

  ContentItem japaneseKanaQuestion({required bool hiragana}) {
    return _unique(() {
      final pool = (hiragana ? hiraganaData : katakanaData)
          .where((e) => e.kanaType == KanaType.basic)
          .toList();
      final answer = pool[_random.nextInt(pool.length)];
      final distractors = <String>{};
      while (distractors.length < 3) {
        final d = pool[_random.nextInt(pool.length)];
        if (d.character != answer.character) distractors.add(d.character);
      }
      return ContentItem(
        id: 'ja_kana_${_random.nextInt(999999)}',
        subject: ContentSubject.japanese,
        ageMin: 3,
        ageMax: 7,
        level: 1,
        skill: hiragana ? 'hiragana' : 'katakana',
        difficulty: 1,
        title: hiragana ? 'Hiragana' : 'Katakana',
        instruction: 'Chữ nào đọc là "${answer.romaji}"?',
        question: answer.romaji,
        answer: answer.character,
        choices: _shuffled([answer.character, ...distractors]),
        metadata: {'romaji': answer.romaji, 'furigana': answer.romaji},
      );
    });
  }

  ContentItem japaneseVocabQuestion() {
    return _unique(() {
      final answer = japaneseVocab[_random.nextInt(japaneseVocab.length)];
      final distractors = <String>{};
      while (distractors.length < 3) {
        final d = japaneseVocab[_random.nextInt(japaneseVocab.length)];
        if (d.word != answer.word) distractors.add(d.word);
      }
      return ContentItem(
        id: 'ja_vocab_${_random.nextInt(999999)}',
        subject: ContentSubject.japanese,
        ageMin: 4,
        ageMax: 7,
        level: 2,
        skill: 'vocab',
        difficulty: 2,
        title: 'Từ vựng Nhật',
        instruction: 'Từ nào nghĩa là "${answer.meaning}"? (${answer.romaji})',
        question: answer.meaning,
        answer: answer.word,
        choices: _shuffled([answer.word, ...distractors]),
        metadata: {'romaji': answer.romaji, 'script': answer.script},
      );
    });
  }

  ContentItem shapeQuestion() {
    return _unique(() {
      final keys = shapes.keys.toList();
      final answerKey = keys[_random.nextInt(keys.length)];
      final answer = shapes[answerKey]!;
      final distractors = <String>{};
      while (distractors.length < 3) {
        final d = shapes[keys[_random.nextInt(keys.length)]]!;
        if (d != answer) distractors.add(d);
      }
      return ContentItem(
        id: 'shape_${_random.nextInt(999999)}',
        subject: ContentSubject.thinking,
        ageMin: 3,
        ageMax: 7,
        level: 1,
        skill: 'shapes',
        difficulty: 1,
        title: 'Hình khối',
        instruction: 'Đâu là hình đúng?',
        question: answer.split(' ').first,
        answer: answer,
        choices: _shuffled([answer, ...distractors]),
      );
    });
  }

  ContentItem colorQuestion() {
    return _unique(() {
      final keys = colors.keys.toList();
      final answerKey = keys[_random.nextInt(keys.length)];
      final answer = colors[answerKey]!;
      final distractors = <String>{};
      while (distractors.length < 3) {
        final d = colors[keys[_random.nextInt(keys.length)]]!;
        if (d != answer) distractors.add(d);
      }
      return ContentItem(
        id: 'color_${_random.nextInt(999999)}',
        subject: ContentSubject.thinking,
        ageMin: 3,
        ageMax: 7,
        level: 1,
        skill: 'colors',
        difficulty: 1,
        title: 'Màu sắc',
        instruction: 'Đây là màu gì?',
        question: answer.split(' ').first,
        answer: answer,
        choices: _shuffled([answer, ...distractors]),
      );
    });
  }

  ContentItem _unique(ContentItem Function() build) {
    ContentItem item;
    var guard = 0;
    do {
      item = build();
      guard++;
    } while (guard < 10 && _lastFingerprint == _fp(item));
    _lastFingerprint = _fp(item);
    return item;
  }

  String _fp(ContentItem item) => '${item.skill}|${item.question}|${item.answer}';

  List<String> _shuffled(List<String> values) => List<String>.from(values)..shuffle(_random);
}
