import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/data_driven/data_driven_content_service.dart';
import 'package:mai_an_learning/features/shared/widgets/lesson_journey.dart';

void main() {
  group('Phase 1: Phonetic Mapping & Hoài My Strict Voice', () {
    test('vocabulary.json has all Kindergarten Phonics overrides and anti-truncation fixes', () {
      final file = File('tools/vocabulary.json');
      expect(file.existsSync(), isTrue);
      final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      // Anti-truncation vowel fixes
      expect(jsonMap['v_ă'], 'á...');
      expect(jsonMap['v_aw'], 'á...');
      expect(jsonMap['v_â'], 'ớ...');
      expect(jsonMap['v_aa'], 'ớ...');
      expect(jsonMap['v_ê'], 'ê...');
      expect(jsonMap['v_ee'], 'ê...');

      // MOET Kindergarten Phonics
      expect(jsonMap['v_b'], 'bờ');
      expect(jsonMap['v_c'], 'cờ');
      expect(jsonMap['v_k'], 'cờ');
      expect(jsonMap['v_d'], 'dờ');
      expect(jsonMap['v_đ'], 'đờ');
      expect(jsonMap['v_dd'], 'đờ');
      expect(jsonMap['v_g'], 'gờ');
      expect(jsonMap['v_h'], 'hờ');
      expect(jsonMap['v_l'], 'lờ');
      expect(jsonMap['v_m'], 'mờ');
      expect(jsonMap['v_n'], 'nờ');
      expect(jsonMap['v_p'], 'pờ');
      expect(jsonMap['v_q'], 'cu');
      expect(jsonMap['v_r'], 'rờ');
      expect(jsonMap['v_s'], 'sờ');
      expect(jsonMap['v_t'], 'tờ');
      expect(jsonMap['v_v'], 'vờ');
      expect(jsonMap['v_x'], 'xờ');
    });

    test('All required audio files exist in assets/audio with valid sizes', () {
      final keys = [
        'v_b', 'v_c', 'v_k', 'v_d', 'v_đ', 'v_g', 'v_h',
        'v_l', 'v_m', 'v_n', 'v_p', 'v_q', 'v_r', 'v_s',
        'v_t', 'v_v', 'v_x', 'v_a', 'v_ao', 'v_ca', 'v_bo',
        'sys_success_1', 'sys_success_2', 'sys_success_3',
        'sys_success_4', 'sys_success_5', 'sys_fail_1',
      ];
      for (final key in keys) {
        final mp3 = File('assets/audio/$key.mp3');
        expect(mp3.existsSync(), isTrue, reason: 'Missing assets/audio/$key.mp3');
        expect(mp3.lengthSync(), greaterThan(1000), reason: 'File too small: $key.mp3');
      }
    });
  });

  group('Phase 2: Audio Engine Refactor - Independent Volume & Preload', () {
    test('AudioService default volumes and constants', () {
      final audio = AudioService();
      expect(audio.voiceVolume, equals(1.0));
      expect(audio.bgmVolume, equals(0.2));
      expect(AudioService.defaultVoiceVolume, equals(1.0));
      expect(AudioService.defaultBgmVolume, equals(0.2));
      expect(AudioService.bgmDuckVolume, equals(0.05));
    });

    test('AudioService independent volume setters clamp correctly', () async {
      final audio = AudioService();
      await audio.setVoiceVolume(0.75);
      expect(audio.voiceVolume, closeTo(0.75, 0.001));

      await audio.setVoiceVolume(1.5);
      expect(audio.voiceVolume, equals(1.0));

      await audio.setVoiceVolume(-0.2);
      expect(audio.voiceVolume, equals(0.0));

      await audio.setBgmVolume(0.4);
      expect(audio.bgmVolume, closeTo(0.4, 0.001));

      await audio.setBgmVolume(2.0);
      expect(audio.bgmVolume, equals(1.0));
    });

    test('Preloaded keys list contains all critical feedback and system clips', () {
      expect(AudioService.preloadedClipKeys, contains('sys_success_1'));
      expect(AudioService.preloadedClipKeys, contains('sys_success_5'));
      expect(AudioService.preloadedClipKeys, contains('sys_fail_1'));
      expect(AudioService.preloadedClipKeys, contains('sys_math_recognize'));
      expect(AudioService.preloadedClipKeys, contains('sys_math_count'));
      expect(AudioService.preloadedClipKeys, contains('sys_math_identify'));
      expect(AudioService.preloadedClipKeys, contains('sys_thinking_match'));
      expect(AudioService.preloadedClipKeys, contains('v_math_dem_so'));
    });
  });

  group('Phase 4: Data-Driven Architecture', () {
    test('assets/data/manifest.json contains modules configuration', () {
      final manifestFile = File('assets/data/manifest.json');
      expect(manifestFile.existsSync(), isTrue);
      final jsonMap = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final modules = (jsonMap['modules'] as List<dynamic>).map((e) => ModuleConfig.fromJson(e as Map<String, dynamic>)).toList();

      expect(modules.any((m) => m.id == 'vietnamese'), isTrue);
      expect(modules.any((m) => m.id == 'japanese'), isTrue);
      expect(modules.any((m) => m.id == 'math'), isTrue);
      expect(modules.any((m) => m.id == 'thinking'), isTrue);

      final vi = modules.firstWhere((m) => m.id == 'vietnamese');
      expect(vi.voice, equals('vi-VN-HoaiMyNeural'));
      expect(vi.audioPrefix, equals('v_'));

      final ja = modules.firstWhere((m) => m.id == 'japanese');
      expect(ja.voice, equals('ja-JP-NanamiNeural'));
      expect(ja.audioPrefix, equals('j_'));
    });

    test('assets/data/ JSON files exist for all subjects', () {
      expect(File('assets/data/vietnamese/alphabet.json').existsSync(), isTrue);
      expect(File('assets/data/vietnamese/words.json').existsSync(), isTrue);
      expect(File('assets/data/japanese/hiragana.json').existsSync(), isTrue);
      expect(File('assets/data/japanese/katakana.json').existsSync(), isTrue);
      expect(File('assets/data/math/questions.json').existsSync(), isTrue);
      expect(File('assets/data/thinking/patterns.json').existsSync(), isTrue);
    });
  });

  group('Phase 2 & 3: Lesson Navigation & Hoai My Audio Mapping', () {
    test('AudioService normalizes all feedback and math clips to Hoai My MP3s', () {
      expect(AudioService.normalizeKey('sys_math_recognize'), 'sys_math_identify');
      expect(AudioService.normalizeKey('sys_math_match'), 'sys_math_match');
      expect(AudioService.normalizeKey('sys_math_count'), 'sys_math_count');
      expect(AudioService.normalizeKey('sys_game_memory'), 'sys_thinking_memory');
      expect(AudioService.normalizeKey('sys_game_catch'), 'sys_game_catch');
      expect(AudioService.normalizeKey('vi_phrase_gioi_lam'), 'sys_success_1');
      expect(AudioService.normalizeKey('success_1'), 'sys_success_1');
      expect(AudioService.normalizeKey('fail_1'), 'sys_fail_1');
    });

    testWidgets('LessonContinuePill renders both [Quay lại] and [Tiếp tục] with correct key binding', (tester) async {
      bool previousTapped = false;
      bool nextTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonContinuePill(
              label: 'Tiếp tục',
              onTap: () => nextTapped = true,
              previousLabel: 'Quay lại',
              onPrevious: () => previousTapped = true,
              canPrevious: true,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('lesson-back-flow')), findsOneWidget);
      expect(find.byKey(const Key('continue-flow')), findsOneWidget);
      expect(find.text('Quay lại'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);

      await tester.tap(find.byKey(const Key('lesson-back-flow')));
      expect(previousTapped, isTrue);

      await tester.tap(find.byKey(const Key('continue-flow')));
      expect(nextTapped, isTrue);
    });

    testWidgets('LessonContinuePill disables [Quay lại] when canPrevious is false (first item)', (tester) async {
      bool previousTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonContinuePill(
              label: 'Tiếp tục',
              onTap: () {},
              previousLabel: 'Quay lại',
              onPrevious: () => previousTapped = true,
              canPrevious: false,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('lesson-back-flow')), findsOneWidget);
      expect(find.byKey(const Key('continue-flow')), findsOneWidget);

      await tester.tap(find.byKey(const Key('lesson-back-flow')), warnIfMissed: false);
      expect(previousTapped, isFalse);
    });
  });
}
