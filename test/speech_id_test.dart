import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/speech_id.dart';

void main() {
  test('speech ids match the Python generator (FNV-1a over normalised UTF-8)', () {
    expect(SpeechId.forText('Đọc từ này.'), 'vi_say_c56aee1d');
    expect(SpeechId.forText('  Bé giỏi   quá! '), 'vi_say_5d0982cb');
    expect(SpeechId.forText('Đọc từ này'), SpeechId.forText('đọc từ này!'));
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
