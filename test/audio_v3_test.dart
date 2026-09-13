import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/core/audio/audio_playback_policy.dart';
import 'package:mai_an_learning/core/audio/audio_resolver.dart';

void main() {
  late Map<String, dynamic> content;
  late Map<String, dynamic> preview;
  late Map<String, dynamic> human;
  late List<dynamic> productionManifest;

  setUpAll(() {
    content = jsonDecode(File('tool/audio_content_v3.json').readAsStringSync()) as Map<String, dynamic>;
    preview = jsonDecode(File('tool/audio_preview_manifest.json').readAsStringSync()) as Map<String, dynamic>;
    human = jsonDecode(File('tool/human_audio_inventory.json').readAsStringSync()) as Map<String, dynamic>;
    productionManifest = jsonDecode(File('assets/audio/audio_manifest.json').readAsStringSync()) as List<dynamic>;
  });

  test('production 913 inventory remains intact', () {
    expect(productionManifest, hasLength(913));
    expect(productionManifest.where((e) => e['language'] == 'vi').length, 505);
    expect(productionManifest.where((e) => e['language'] == 'ja').length, 408);
    for (final row in productionManifest) {
      expect(File(row['asset'] as String).existsSync(), isTrue, reason: '${row['id']}');
    }
  });

  test('audio_content_v3 ids are unique and equal HUMAN_REQUIRED 150', () {
    final items = (content['items'] as List).cast<Map<String, dynamic>>();
    final ids = items.map((e) => e['id'] as String).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, hasLength(150));
    final required = (human['items'] as List)
        .where((e) => e['classification'] == 'HUMAN_REQUIRED')
        .map((e) => e['id'] as String)
        .toSet();
    expect(ids.toSet(), required);
    expect(content['protectedExistingFiles'], 763);
  });

  test('production paths exist and stay on the original contract', () {
    final items = (content['items'] as List).cast<Map<String, dynamic>>();
    for (final item in items) {
      final path = item['productionPath'] as String;
      expect(File(path).existsSync(), isTrue, reason: '${item['id']}');
      expect(item['replaceInPlace'], isTrue);
      expect(path.contains('_v2'), isFalse);
      expect(item['currentQuality'], 'TTS_TEMPORARY');
      expect(item['targetQuality'], 'PREMIUM_AI_VOICE');
      expect(item['targetQuality'], isNot('HUMAN_RECORDING'));
      if ((item['language'] as String).startsWith('vi')) {
        expect(path.startsWith('assets/audio/vi/'), isTrue);
      } else {
        expect(path.startsWith('assets/audio/ja/'), isTrue);
      }
    }
  });

  test('curriculum spoken text is preserved for B and Â', () {
    final items = (content['items'] as List).cast<Map<String, dynamic>>();
    Map<String, dynamic> byId(String id) => items.firstWhere((e) => e['id'] == id);
    expect(byId('vi_letter_b_name')['spokenText'], 'bê');
    expect(byId('vi_letter_b_sound')['spokenText'], 'bờ');
    expect(byId('vi_letter_aa_name')['spokenText'], 'â');
    expect(byId('vi_letter_aa_sound')['spokenText'], 'â');
  });

  test('preview mode targets the existing 18 clips under tool/audio_v3_preview only', () {
    final items = (preview['items'] as List).cast<Map<String, dynamic>>();
    expect(items, hasLength(18));
    expect(items.map((e) => e['id']).toSet(), hasLength(18));
    expect(preview['outputRoot'], 'tool/audio_v3_preview');
    const expectedIds = {
      'preview_vi_a',
      'preview_vi_as',
      'preview_vi_ows',
      'preview_vi_bo',
      'preview_vi_co',
      'preview_vi_do',
      'preview_vi_ddo',
      'preview_vi_gioi_lam',
      'preview_vi_dung_roi',
      'preview_vi_thu_lai',
      'preview_ja_h_a',
      'preview_ja_h_i',
      'preview_ja_h_u',
      'preview_ja_h_e',
      'preview_ja_h_o',
      'preview_ja_h_ka',
      'preview_ja_h_ki',
      'preview_ja_jouzu',
    };
    expect(items.map((e) => e['id']).toSet(), expectedIds);
    for (final item in items) {
      final path = item['previewPath'] as String;
      expect(path.startsWith('tool/audio_v3_preview/'), isTrue);
      expect(path.startsWith('assets/audio/'), isFalse);
      expect(path.contains('assets/audio/vi/'), isFalse);
      expect(path.contains('assets/audio/ja/'), isFalse);
    }
  });

  test('language metadata never allows VI to JA or JA to VI fallback', () {
    expect(AudioResolver.isAllowedLocale(AudioLanguage.vietnamese, 'ja-JP'), isFalse);
    expect(AudioResolver.isAllowedLocale(AudioLanguage.japanese, 'vi-VN'), isFalse);
    expect(AudioResolver.vietnameseFallsBackToJapanese('ja-JP'), isTrue);
    expect(AudioPlaybackPolicy.recordedPlaybackRate, 1.0);
  });

  test('example env has empty credentials and repo has no committed audio v3 key file', () {
    final example = File('tool/.env.audio.v3.example').readAsStringSync();
    expect(example.contains('VIMAI_AUDIO_V3_API_KEY='), isTrue);
    expect(example.contains('GOOGLE_CLOUD_PROJECT='), isTrue);
    expect(example.contains('VI_VOICE_NAME='), isTrue);
    expect(example.contains('JA_VOICE_NAME='), isTrue);
    expect(example.contains('sk-'), isFalse);
    expect(example.contains('BEGIN PRIVATE KEY'), isFalse);
    expect(File('tool/.env.audio.v3').existsSync(), isFalse);
    final gen = File('tool/generate_audio_v3.py').readAsStringSync();
    expect(gen.contains('Refusing --force-vi'), isTrue);
  });

  test('human inventory still has zero human recordings', () {
    expect(human['human_recordings_present'], 0);
    expect(human['counts']['EXISTING_HUMAN'], 0);
  });

  test('v3 manifest has no generated HUMAN_RECORDING records', () {
    final v3 = jsonDecode(File('tool/audio_v3_manifest.json').readAsStringSync()) as Map<String, dynamic>;
    final records = v3['records'] as List;
    expect(records, isEmpty);
    expect(records.any((e) => e['quality'] == 'HUMAN_RECORDING'), isFalse);
  });

  test('preview without credentials fails and does not write production wavs', () {
    final gioi = File('assets/audio/vi/phrases/gioi_lam.wav');
    final before = gioi.lastModifiedSync();
    final result = Process.runSync('python', ['tool/generate_audio_v3.py', '--preview']);
    expect(result.exitCode, isNot(0));
    final blob = '${result.stdout}${result.stderr}';
    expect(blob.toLowerCase(), contains('stop'));
    expect(gioi.lastModifiedSync(), before);
    expect(File('tool/audio_v3_preview/vi/a.wav').existsSync(), isFalse);
  });

  test('preview dry-run does not modify production assets', () {
    final result = Process.runSync('python', ['tool/generate_audio_v3.py', '--preview', '--dry-run']);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
    expect('${result.stdout}', contains('DRY-RUN'));
    expect(File('tool/audio_v3_preview/vi/a.wav').existsSync(), isFalse);
  });

  test('production mode requires explicit --yes in the generator', () {
    final gen = File('tool/generate_audio_v3.py').readAsStringSync();
    expect(gen.contains('AUDIO V3 PRODUCTION'), isTrue);
    expect(gen.contains('Non-interactive run requires --yes'), isTrue);
    expect(gen.contains('Type YES to continue'), isTrue);
  });

  test('force-vi is refused in the generator', () {
    final gen = File('tool/generate_audio_v3.py').readAsStringSync();
    expect(gen.contains('Refusing --force-vi'), isTrue);
  });

  test('invalid provider configuration fails safely', () {
    final result = Process.runSync(
      'python',
      ['tool/generate_audio_v3.py', '--preview'],
      environment: {
        ...Platform.environment,
        'VIMAI_AUDIO_V3_PROVIDER': 'revid-invented',
        'VIMAI_AUDIO_V3_API_KEY': 'placeholder',
        'VIMAI_AUDIO_V3_VI_VOICE_ID': 'x',
        'VIMAI_AUDIO_V3_JA_VOICE_ID': 'y',
      },
    );
    expect(result.exitCode, isNot(0));
  });

  test('google tts config does not invent voice names', () {
    final cfg = jsonDecode(File('tool/audio_generation/google_tts_config.json').readAsStringSync())
        as Map<String, dynamic>;
    expect(cfg['provider'], 'google_cloud_texttospeech');
    expect(cfg['vietnamese']['language_code'], 'vi-VN');
    expect(cfg['japanese']['language_code'], 'ja-JP');
    expect(cfg['vietnamese']['voice_name'], '');
    expect(cfg['japanese']['voice_name'], '');
    expect(cfg['pitch'], 0);
    expect(cfg['audio_encoding'], 'LINEAR16');
  });

  test('pronunciation maps are generation-only and cover preview plus educational overlays', () {
    final vi = jsonDecode(File('tool/audio_generation/vimai_kids_pronunciation_map.json').readAsStringSync())
        as Map<String, dynamic>;
    final ja = jsonDecode(File('tool/audio_generation/japanese_pronunciation_map.json').readAsStringSync())
        as Map<String, dynamic>;
    expect(vi['curriculumModified'], isFalse);
    expect(ja['curriculumModified'], isFalse);
    final viItems = (vi['items'] as List).cast<Map<String, dynamic>>();
    final jaItems = (ja['items'] as List).cast<Map<String, dynamic>>();
    Map<String, dynamic> viById(String id) => viItems.firstWhere((e) => e['id'] == id);
    expect(viById('vi_letter_aa_sound')['originalCurriculumText'], 'â');
    expect(viById('vi_letter_aa_sound')['spokenText'], 'ơ');
    expect(viById('vi_letter_y_name')['spokenText'], 'i dài');
    expect(viById('vi_letter_r_name')['spokenText'], 'e-rờ');
    expect(viById('vi_letter_b_sound')['spokenText'], 'bờ');
    expect(viById('vi_letter_c_sound')['spokenText'], 'cờ');
    expect(viById('vi_letter_d_sound')['spokenText'], 'dờ');
    expect(viById('vi_letter_dd_sound')['spokenText'], 'đờ');
    expect(viById('preview_vi_gioi_lam')['spokenText'], 'Giỏi lắm');
    expect(viItems.any((e) => e['id'] == 'vi_phonics_ba' && e['spokenText'] == 'ba'), isTrue);
    expect(viItems.any((e) => e['id'] == 'vi_ph' && e['spokenText'] == 'phờ'), isTrue);
    expect(jaById(jaItems, 'preview_ja_h_a')['spokenText'], 'あ');
    expect(jaById(jaItems, 'preview_ja_jouzu')['spokenText'], 'じょうず');
    expect(jaItems.any((e) => e['spokenText'] == 'a' && (e['id'] as String).contains('h_a')), isFalse);
  });

  test('flutter sources do not contain google credentials or cloud tts clients', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('google_cloud'), isFalse);
    expect(pubspec.contains('texttospeech'), isFalse);
    final audioService = File('lib/core/audio/audio_service.dart').readAsStringSync();
    expect(audioService.contains('GOOGLE_APPLICATION_CREDENTIALS'), isFalse);
    expect(audioService.contains('private_key'), isFalse);
    expect(Directory('assets/audio').listSync().any((e) => e.path.endsWith('.json') && e.path.contains('credential')), isFalse);
  });

  test('preview generator reports google status and never writes production audio', () {
    final result = Process.runSync('python', ['tool/generate_audio_v3.py', '--preview']);
    expect(result.exitCode, isNot(0));
    final blob = '${result.stdout}${result.stderr}';
    expect(blob, contains('AUDIO_V3_GOOGLE_STATUS'));
    expect(blob, contains('Ready for preview:'));
    expect(blob, contains('NO'));
    expect(blob, contains('Production WAV modified:'));
  });
}

Map<String, dynamic> jaById(List<Map<String, dynamic>> items, String id) =>
    items.firstWhere((e) => e['id'] == id);
