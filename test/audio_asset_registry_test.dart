import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_asset_registry.dart';
import 'package:mai_an_learning/core/audio/vietnamese_speech_catalog.dart';
import 'package:mai_an_learning/data/kana/hiragana_data.dart';
import 'package:mai_an_learning/data/kana/katakana_data.dart';

void main() {
  late Map<String, Map<String, dynamic>> byId;

  setUpAll(() {
    AudioAssetRegistry.loadFromDiskSync();
    final raw = jsonDecode(File('assets/audio/audio_manifest.json').readAsStringSync()) as List;
    byId = {
      for (final item in raw.cast<Map<String, dynamic>>()) item['id'] as String: item,
    };
  });

  bool wavOk(String asset) {
    final file = File(asset);
    if (!file.existsSync() || file.lengthSync() < 64) return false;
    final bytes = file.readAsBytesSync();
    return bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WAVE';
  }

  test('all audioIds in Vietnamese content have vi assets', () {
    final files = [
      'assets/content/vietnamese/alphabet.json',
      'assets/content/vietnamese/phonics.json',
      'assets/content/vietnamese/rimes.json',
      'assets/content/vietnamese/words.json',
      'assets/content/vietnamese/sentences.json',
    ];
    final ids = <String>{'vi_phrase_gioi_lam'};
    for (final path in files) {
      for (final raw in jsonDecode(File(path).readAsStringSync()) as List) {
        final meta = Map<String, dynamic>.from((raw as Map)['metadata'] as Map);
        for (final key in ['audioId', 'audioNameId', 'audioSoundId']) {
          final id = meta[key] as String?;
          if (id != null && id.isNotEmpty) ids.add(id);
        }
      }
    }
    expect(ids, isNotEmpty);
    for (final id in ids) {
      expect(byId.containsKey(id), isTrue, reason: 'missing $id');
      expect(byId[id]!['language'], 'vi', reason: id);
      final asset = byId[id]!['asset'] as String;
      expect(asset.contains('/vi/'), isTrue, reason: id);
      expect(asset.contains('/ja/'), isFalse, reason: id);
      expect(wavOk(asset), isTrue, reason: asset);
    }
  });

  test('all Japanese kana audioIds map only to ja assets', () {
    final kanaIds = [...hiraganaData, ...katakanaData].map((e) => e.audioId);
    for (final id in kanaIds) {
      expect(byId.containsKey(id), isTrue, reason: 'missing $id');
      expect(byId[id]!['language'], 'ja', reason: id);
      final asset = byId[id]!['asset'] as String;
      expect(asset.contains('/ja/'), isTrue, reason: id);
      expect(asset.contains('/vi/'), isFalse, reason: id);
      expect(asset.contains('/en/'), isFalse, reason: id);
      expect(wavOk(asset), isTrue, reason: asset);
    }
  });

  test('no duplicate audioId and no English fallback in educational catalog', () {
    final ids = byId.keys.toList();
    expect(ids.toSet().length, ids.length);
    for (final rec in byId.values) {
      expect(rec['language'], isNot('en'));
      expect((rec['asset'] as String).contains('/en/'), isFalse);
    }
  });

  test('every manifest asset exists on disk with duration > 0', () {
    var missing = 0;
    for (final rec in byId.values) {
      final asset = rec['asset'] as String;
      if (!wavOk(asset)) missing++;
    }
    expect(missing, 0);
  });

  test('registry language isolation helpers', () {
    expect(AudioAssetRegistry.requireVietnamese('vi_letter_b_name').isVietnamese, isTrue);
    expect(AudioAssetRegistry.requireJapanese(hiraganaData.first.audioId).isJapanese, isTrue);
    expect(
      () => AudioAssetRegistry.requireVietnamese(hiraganaData.first.audioId),
      throwsA(isA<StateError>()),
    );
  });

  test('Vietnamese 29 letters have name and sound ids, no F', () {
    expect(VietnameseSpeechCatalog.letters.length, 29);
    expect(VietnameseSpeechCatalog.letters.containsKey('F'), isFalse);
    for (final letter in VietnameseSpeechCatalog.letters.values) {
      expect(byId.containsKey(letter.nameAudioId), isTrue, reason: letter.glyph);
      expect(byId.containsKey(letter.soundAudioId), isTrue, reason: letter.glyph);
      expect(byId[letter.nameAudioId]!['language'], 'vi');
    }
  });

  test('AudioService has no FlutterTts; native TTS eradicated', () {
    final source = File('lib/core/audio/audio_service.dart').readAsStringSync();
    expect(source.contains('FlutterTts'), isFalse);
    expect(source.contains('flutter_tts'), isFalse);
    expect(source.contains('_flutterTts'), isFalse);
    expect(source.contains('SameLanguageTts'), isFalse);
    expect(File('lib/core/audio/same_language_tts.dart').existsSync(), isFalse);
  });
}
