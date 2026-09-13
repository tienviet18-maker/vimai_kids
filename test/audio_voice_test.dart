import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/core/audio/audio_playback_policy.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/audio/vietnamese_speech_catalog.dart';

void main() {
  test('getAudioIdForLetter hard-maps glyphs to telex Hoài My MP3 ids', () {
    expect(VietnameseSpeechCatalog.getAudioIdForLetter('ă'), 'v_aw');
    expect(VietnameseSpeechCatalog.getAudioIdForLetter('Ă'), 'v_aw');
    expect(VietnameseSpeechCatalog.getAudioIdForLetter('â'), 'v_aa');
    expect(VietnameseSpeechCatalog.getAudioIdForLetter('b'), 'v_b');
    expect(VietnameseSpeechCatalog.getAudioIdForLetter('c'), 'v_c');
    expect(VietnameseSpeechCatalog.getAudioIdForLetter('đ'), 'v_dd');
    expect(VietnameseSpeechCatalog.getAudioIdForLetter('ơ'), 'v_ow');
    expect(VietnameseSpeechCatalog.getAudioIdForLetter('ư'), 'v_uw');
    expect(AudioService.getAudioIdForLetter('ă'), 'v_aw');
  });

  test('getAudioIdForWord maps example words to v_word_* schema ids', () {
    expect(VietnameseSpeechCatalog.getAudioIdForWord('ấm'), 'v_word_aasm');
    expect(VietnameseSpeechCatalog.getAudioIdForWord('áo'), 'v_word_ao');
    expect(VietnameseSpeechCatalog.getAudioIdForWord('ăn'), 'v_word_an');
    expect(VietnameseSpeechCatalog.getAudioIdForWord('bố'), 'v_word_bo');
    expect(VietnameseSpeechCatalog.getAudioIdForWord('cá'), 'v_word_ca');
  });

  test('normalizeKey prefers telex never unicode for letters', () {
    expect(AudioService.normalizeKey('v_aw'), 'v_aw');
    expect(AudioService.normalizeKey('v_ă'), 'v_aw');
    expect(AudioService.normalizeKey('vi_letter_aw_sound'), 'v_aw');
    expect(AudioService.normalizeKey('vi_letter_aa_sound'), 'v_aa');
    expect(AudioService.normalizeKey('vi_word_aasm'), 'v_word_aasm');
  });

  test('explicit methods map to required locales', () {
    expect(AudioLocalePolicy.localeFor(AudioLanguage.japanese), 'ja-JP');
    expect(AudioLocalePolicy.localeFor(AudioLanguage.vietnamese), 'vi-VN');
    expect(AudioLocalePolicy.localeFor(AudioLanguage.english), 'en-US');
  });

  test('native TTS fallback is permanently disabled', () {
    expect(AudioPlaybackPolicy.allowSameLanguageTtsFallback, isFalse);
  });
}
