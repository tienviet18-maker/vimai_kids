import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_asset_registry.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/core/audio/audio_playback_policy.dart';
import 'package:mai_an_learning/core/audio/audio_request.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/audio/vietnamese_speech_catalog.dart';

class _TestAudioplayersPlatform extends AudioplayersPlatformInterface {
  final _events = <String, StreamController<AudioEvent>>{};

  @override
  Future<void> create(String playerId) async {
    _events[playerId] = StreamController<AudioEvent>.broadcast();
  }

  @override
  Future<void> dispose(String playerId) async {
    await _events.remove(playerId)?.close();
  }

  @override
  Future<void> emitError(String playerId, String code, String message) async {}

  @override
  Future<void> emitLog(String playerId, String message) async {}

  @override
  Future<int?> getCurrentPosition(String playerId) async => 0;

  @override
  Future<int?> getDuration(String playerId) async => 0;

  @override
  Future<void> pause(String playerId) async {}

  @override
  Future<void> release(String playerId) async {}

  @override
  Future<void> resume(String playerId) async {
    _events[playerId]?.add(const AudioEvent(eventType: AudioEventType.complete));
  }

  @override
  Future<void> seek(String playerId, Duration position) async {}

  @override
  Future<void> setAudioContext(String playerId, AudioContext audioContext) async {}

  @override
  Future<void> setBalance(String playerId, double balance) async {}

  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) async {}

  @override
  Future<void> setPlayerMode(String playerId, PlayerMode playerMode) async {}

  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) async {}

  @override
  Future<void> setSourceBytes(String playerId, Uint8List bytes, {String? mimeType}) async {}

  @override
  Future<void> setSourceUrl(String playerId, String url, {bool? isLocal, String? mimeType}) async {}

  @override
  Future<void> setVolume(String playerId, double volume) async {}

  @override
  Future<void> stop(String playerId) async {}

  @override
  Stream<AudioEvent> getEventStream(String playerId) {
    return _events[playerId]!.stream;
  }
}

class _TestGlobalAudioplayersPlatform extends GlobalAudioplayersPlatformInterface {
  final _events = StreamController<GlobalAudioEvent>.broadcast();

  @override
  Future<void> init() async {}

  @override
  Future<void> setGlobalAudioContext(AudioContext ctx) async {}

  @override
  Future<void> emitGlobalLog(String message) async {}

  @override
  Future<void> emitGlobalError(String code, String message) async {}

  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => _events.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    AudioplayersPlatformInterface.instance = _TestAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance = _TestGlobalAudioplayersPlatform();
    AudioAssetRegistry.loadFromDiskSync();
  });

  test('recorded playback rate is 1.0 so pitch is not bent', () {
    expect(AudioPlaybackPolicy.recordedPlaybackRate, 1.0);
  });

  test('native TTS fallback is permanently disabled', () {
    expect(AudioPlaybackPolicy.allowSameLanguageTtsFallback, isFalse);
  });

  test('AudioRequest does not infer language from text', () {
    const mixed = AudioRequest(
      id: 'vi_letter_b_name',
      language: AudioLanguage.vietnamese,
      text: 'あ',
    );
    expect(mixed.language, AudioLanguage.vietnamese);
    expect(AudioRequest.japanese(id: 'ja_h_a', text: 'a').language, AudioLanguage.japanese);
  });

  test('missing Japanese id cannot resolve a Vietnamese asset', () {
    expect(
      () => AudioAssetRegistry.requireJapanese('vi_letter_b_name'),
      throwsA(isA<StateError>()),
    );
    expect(
      () => AudioAssetRegistry.requireVietnamese('ja_h_a'),
      throwsA(isA<StateError>()),
    );
  });

  test('missing asset playback does not throw', () async {
    final audio = AudioService();
    await audio.init();
    final result = await audio.playVietnameseAsset('vi_does_not_exist');
    expect(result.success, isFalse);
    await audio.dispose();
  });

  test('AudioService uses a single queued player and dispose is safe', () async {
    final audio = AudioService();
    await audio.init();
    await audio.stop();
    await audio.dispose();
    await audio.dispose();
  });

  test('AudioService never imports FlutterTts; native TTS eradicated', () {
    final service = File('lib/core/audio/audio_service.dart').readAsStringSync();
    expect(service.contains('package:flutter_tts'), isFalse);
    expect(service.contains('FlutterTts'), isFalse);
    expect(service.contains('SameLanguageTts'), isFalse);
    expect(service.contains('.speak('), isFalse);
    expect(File('lib/core/audio/same_language_tts.dart').existsSync(), isFalse);
    expect(File('lib/core/audio/tts_voice_selector.dart').existsSync(), isFalse);
  });

  test('letter audio ids hard-map to telex Hoài My MP3 keys', () {
    expect(VietnameseSpeechCatalog.getAudioIdForLetter('ă'), 'v_aw');
    expect(VietnameseSpeechCatalog.getAudioIdForLetter('â'), 'v_aa');
    expect(AudioService.normalizeKey('v_ă'), 'v_aw');
    expect(AudioService.normalizeKey('vi_letter_aw_sound'), 'v_aw');
  });

  test('praise / system clips exist as Hoài My MP3s', () {
    expect(File('assets/audio/sys_success_1.mp3').existsSync(), isTrue);
    expect(File('assets/audio/sys_success_1.mp3').lengthSync(), greaterThan(64));
    expect(File('assets/audio/sys_math_intro.mp3').existsSync(), isTrue);
    expect(File('assets/audio/sys_creativity_intro.mp3').existsSync(), isTrue);
    expect(File('assets/audio/v_aw.mp3').existsSync(), isTrue);
  });

  test('AudioService.normalizeKey maps lesson keys to modern prefixed files', () {
    expect(AudioService.normalizeKey('a'), 'v_a');
    expect(AudioService.normalizeKey('v_a'), 'v_a');
    expect(AudioService.normalizeKey('vi_letter_a_sound'), 'v_a');
    expect(AudioService.normalizeKey('vi_word_ba'), 'v_word_ba');
    expect(AudioService.normalizeKey('ba'), 'v_word_ba');
    expect(AudioService.normalizeKey('ja_a'), 'ja_h_a');
    expect(AudioService.normalizeKey('ja_h_a'), 'ja_h_a');
    expect(AudioService.normalizeKey('sys_math_recognize'), 'sys_math_identify');
    expect(AudioService.normalizeKey('sys_game_memory'), 'sys_thinking_memory');
    expect(AudioService.normalizeKey('intro_math'), 'sys_math_intro');
    expect(AudioService.normalizeKey('sys_success_1'), 'sys_success_1');
    expect(AudioService.normalizeKey('bgm_ambient'), 'bgm_ambient');
    expect(AudioService.normalizeKey('v_aw'), 'v_aw');
    expect(AudioService.normalizeKey('v_ă'), 'v_aw');

    expect(AudioService.introForMathSkill('counting'), 'sys_math_count');
    expect(AudioService.introForMathSkill('comparison'), 'sys_math_compare');
    expect(AudioService.introForMathSkill('number_recognition'), 'sys_math_identify');
    expect(AudioService.introForThinkingSkill('matching'), 'sys_thinking_match');
  });
}
