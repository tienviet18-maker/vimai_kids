import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/audio/speech_id.dart';

void main() {
  test('speech ids match the Python generator (FNV-1a over normalised UTF-8)', () {
    expect(SpeechId.forText('Đọc từ này.'), 'vi_say_c56aee1d');
    expect(SpeechId.forText('  Bé giỏi   quá! '), 'vi_say_5d0982cb');
    expect(SpeechId.forText('Đọc từ này'), SpeechId.forText('đọc từ này!'));
  });

  // Regression: the plain `hash * prime` overflowed 2^53 on the web (ints are
  // doubles there), so no vi_say_* clip was ever found in the browser.
  // Run with `flutter test --platform chrome test/speech_id_test.dart` too.
  test('speech ids stay exact where ints are doubles (web)', () {
    expect(SpeechId.forText('Đúng rồi! Bé giỏi quá!'), 'vi_say_4658469d');
    expect(SpeechId.forText('Bé nghe từng âm, rồi ghép lại thành tiếng nhé.'), 'vi_say_1ba4c730');
    expect(SpeechId.forText('Đúng rồi! Bé nhanh ghê!'), 'vi_say_68c26936');
  });

  // Regression: normalizeKey mapped every vi_* id to v_*, so playAudio looked
  // for assets/audio/v_say_<hash>.mp3, which does not exist.
  test('line clip ids reach playAudio unchanged', () {
    expect(AudioService.normalizeKey('vi_say_4658469d'), 'vi_say_4658469d');
    expect(AudioService.normalizeKey('assets/audio/vi_say_1ba4c730.mp3'), 'vi_say_1ba4c730');
    expect(AudioService.normalizeKey('vi_word_aasm'), 'v_word_aasm');
  });

  test('only lines with letters are speakable', () {
    expect(SpeechId.isSpeakable('🍎 🍌'), isFalse);
    expect(SpeechId.isSpeakable('3 + 4'), isFalse);
    expect(SpeechId.isSpeakable('quả táo'), isTrue);
  });

  test('spoken text names emoji and math signs', () {
    expect(SpeechId.spokenText('Bên phải của 🐱 🐶 là?'), 'Bên phải của con mèo con chó là?');
    expect(SpeechId.spokenText('Hai hình này giống hay khác? ▲ △'), 'Hai hình này giống hay khác? tam giác tam giác');
    expect(SpeechId.spokenText('Hình cuối: 🌱🌿🌳 — đâu là cuối?'), 'Hình cuối: mầm cây cành lá cái cây, đâu là cuối?');
    expect(SpeechId.spokenText('3 + 4 = ?'), '3 cộng 4 bằng mấy');
    expect(SpeechId.spokenText('B'), isNull);
    expect(SpeechId.spokenText('⬜ Vuông'), 'Vuông');
    expect(SpeechId.spokenText('Chữ nào bắt đầu từ: 🫖 ấm?'), 'Chữ nào bắt đầu từ: ấm?');
    expect(SpeechId.spokenText('🍎'), 'quả táo');
  });
}
