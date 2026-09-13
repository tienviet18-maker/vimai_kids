import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_asset_registry.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/core/audio/audio_playback_plan.dart';
import 'package:mai_an_learning/core/audio/audio_resolver.dart';
import 'package:mai_an_learning/core/audio/vietnamese_speech_catalog.dart';

void main() {
  test('catalog maps B to bê / bờ and all 29 letters have names', () {
    expect(VietnameseSpeechCatalog.letters.length, 29);
    expect(VietnameseSpeechCatalog.nameSpoken('B'), 'bê');
    expect(VietnameseSpeechCatalog.soundSpoken('B'), 'bờ');
    expect(VietnameseSpeechCatalog.nameSpoken('L'), 'e-lờ');
    expect(VietnameseSpeechCatalog.nameSpoken('Y'), 'i');
    expect(VietnameseSpeechCatalog.letters.containsKey('F'), isFalse);
  });

  test('playVietnameseLetterName(B) speaks bê on vi-VN, never ja-JP or en-US', () {
    final spoken = VietnameseSpeechCatalog.nameSpoken('B');
    expect(spoken, 'bê');
    final plan = AudioPlaybackPlan.vietnamese(spoken, audioAsset: VietnameseSpeechCatalog.nameAsset('B'));
    expect(plan.locale, 'vi-VN');
    expect(plan.language, AudioLanguage.vietnamese);
    expect(plan.usesJapaneseLocale, isFalse);
    expect(plan.usesEnglishLocale, isFalse);
    expect(plan.text, 'bê');
  });

  test('playVietnameseLetterSound(B) speaks bờ on vi-VN, never ja-JP or en-US', () {
    expect(VietnameseSpeechCatalog.soundSpoken('B'), 'bờ');
    final plan = AudioPlaybackPlan.vietnamese(
      VietnameseSpeechCatalog.soundSpoken('B'),
      audioAsset: VietnameseSpeechCatalog.soundAsset('B'),
    );
    expect(plan.locale, 'vi-VN');
    expect(plan.usesJapaneseLocale, isFalse);
    expect(plan.usesEnglishLocale, isFalse);
  });

  test('Vietnamese phonics and words stay vi-VN', () {
    expect(AudioPlaybackPlan.vietnamese('ba').locale, 'vi-VN');
    expect(AudioPlaybackPlan.vietnamese('bố').locale, 'vi-VN');
    expect(AudioPlaybackPlan.vietnamese('ba').usesJapaneseLocale, isFalse);
    expect(AudioPlaybackPlan.vietnamese('bố').usesEnglishLocale, isFalse);
  });

  test('Vietnamese never calls ja-JP or en-US', () {
    for (final text in ['bê', 'bờ', 'ba', 'bố', 'Giỏi lắm']) {
      final plan = AudioPlaybackPlan.vietnamese(text);
      expect(plan.locale, isNot('ja-JP'), reason: text);
      expect(plan.locale, isNot('en-US'), reason: text);
      expect(plan.usesJapaneseLocale, isFalse, reason: text);
      expect(plan.usesEnglishLocale, isFalse, reason: text);
      expect(plan.usesVietnameseLocale, isTrue, reason: text);
    }
  });

  test('Japanese never calls vi-VN or en-US', () {
    final plan = AudioPlaybackPlan.japanese('あ');
    expect(plan.locale, 'ja-JP');
    expect(plan.usesVietnameseLocale, isFalse);
    expect(plan.usesEnglishLocale, isFalse);
    expect(AudioResolver.fallsBackToEnglish(plan.locale), isFalse);
  });

  test('English locale is only used when English is requested explicitly', () {
    expect(AudioPlaybackPlan.english('hello').locale, 'en-US');
    expect(AudioPlaybackPlan.english('hello').language, AudioLanguage.english);
    expect(AudioPlaybackPlan.vietnamese('hello').locale, 'vi-VN');
    expect(AudioPlaybackPlan.japanese('hello').locale, 'ja-JP');
    expect(AudioLocalePolicy.localeFor(AudioLanguage.english), 'en-US');
  });

  test('missing recorded path is not treated as playable', () {
    expect(AudioAssetRegistry.exists('assets/audio/vi/letters/missing.wav'), isFalse);
    expect(AudioAssetRegistry.exists('assets/audio/vietnamese/missing.mp3'), isFalse);
  });

  test('registry only lists files that exist on disk', () {
    if (!File('assets/audio/audio_manifest.json').existsSync()) {
      return;
    }
    AudioAssetRegistry.loadFromDiskSync();
    for (final path in AudioAssetRegistry.recordedVietnamese) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(path.contains('/ja/'), isFalse, reason: path);
      expect(path.endsWith('.wav') || path.endsWith('.mp3'), isTrue, reason: path);
    }
    for (final path in AudioAssetRegistry.recordedJapanese) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(path.contains('/vi/'), isFalse, reason: path);
      expect(path.endsWith('.wav') || path.endsWith('.mp3'), isTrue, reason: path);
    }
  });

  test('Vietnamese feature files never call playJapanese or playEnglish', () {
    final dir = Directory('lib/features/vietnamese');
    expect(dir.existsSync(), isTrue);
    final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    for (final file in files) {
      final source = file.readAsStringSync();
      expect(source.contains('playJapanese('), isFalse, reason: file.path);
      expect(source.contains('playEnglish('), isFalse, reason: file.path);
      expect(source.contains('AudioLanguage.japanese'), isFalse, reason: file.path);
      expect(source.contains('ja-JP'), isFalse, reason: file.path);
      expect(source.contains('en-US'), isFalse, reason: file.path);
    }
  });

  test('no feature screen calls playEnglish', () {
    final dir = Directory('lib/features');
    for (final file in dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      expect(file.readAsStringSync().contains('playEnglish('), isFalse, reason: file.path);
    }
  });
}
