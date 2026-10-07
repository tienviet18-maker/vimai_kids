import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import 'audio_locale_policy.dart';
import 'audio_playback_policy.dart';
import 'audio_request.dart';
import 'speech_id.dart';
import 'vietnamese_speech_catalog.dart';

/// Bundled Hoài My / Nanami MP3 only — zero native TTS.
///
/// Primary API: [playAudio] with an ASCII schema id (`v_aw`, `sys_math_intro`, `ja_h_ga`).
/// Playback always stops the previous clip before starting a new one.
class AudioService {
  AudioPlayer? _player;
  AudioPlayer? _bgmPlayer;
  final Random _random = Random();
  AppLifecycleListener? _lifecycle;
  bool soundEnabled = true;
  bool bgmEnabled = true;
  bool _homeBgmWanted = false;

  double voiceVolume = defaultVoiceVolume;
  double bgmVolume = defaultBgmVolume;
  static const double defaultVoiceVolume = 1.0;
  static const double defaultBgmVolume = 0.2;
  static const double bgmDuckVolume = 0.05;

  double _bgmTargetVolume = defaultBgmVolume;
  int _duckDepth = 0;
  AudioLanguage? _lastSpoken;
  String? _lastRequestKey;
  DateTime? _lastRequestAt;
  Completer<void>? _currentPlay;
  bool _webAudioUnlocked = false;

  static const Duration _opTimeout = Duration(milliseconds: 1200);
  static const Duration _completeTimeout = Duration(seconds: 3);

  static const bgmAsset = 'audio/bgm_ambient.mp3';

  static const List<String> preloadedClipKeys = [
    'sys_success_1',
    'sys_success_2',
    'sys_success_3',
    'sys_success_4',
    'sys_success_5',
    'sys_fail_1',
    'sys_fail_2',
    'sys_fail_3',
    'sys_fail_4',
    'sys_math_intro',
    'sys_math_count',
    'sys_math_identify',
    'sys_math_compare',
    'sys_math_match',
    'sys_math_calc_add',
    'sys_math_calc_sub',
    'sys_math_shapes',
    'sys_math_order',
    'sys_math_recognize',
    'sys_creativity_intro',
    'sys_thinking_intro',
    'sys_thinking_find',
    'sys_thinking_match',
    'sys_thinking_shadow',
    'sys_thinking_memory',
    'sys_thinking_maze',
    'sys_thinking_diff',
    'sys_game_memory',
    'sys_game_catch',
    'sys_japanese_intro',
    'v_math_dem_so',
  ];

  /// Skill / screen → bundled system intro id (Hoài My MP3).
  static String introForMathSkill(String skill) {
    switch (skill) {
      case 'counting':
        return 'sys_math_count';
      case 'comparison':
      case 'compare_expressions':
        return 'sys_math_compare';
      case 'number_recognition':
      case 'classify_numbers':
      case 'odd_even':
      case 'find_correct_op':
        return 'sys_math_identify';
      case 'number_match':
        return 'sys_math_match';
      case 'picture_math':
        return 'sys_math_shapes';
      case 'number_pattern':
      case 'number_line':
      case 'missing_number':
      case 'before_after':
      case 'sort_numbers':
        return 'sys_math_order';
      case 'addition_under_5':
      case 'addition_under_10':
      case 'addition_under_20':
      case 'addition_under_50':
      case 'addition_under_100':
      case 'word_problem':
      case 'fill_plus_minus':
        return 'sys_math_calc_add';
      case 'subtraction_under_5':
      case 'subtraction_under_10':
      case 'subtraction_under_20':
      case 'subtraction_under_50':
      case 'subtraction_under_100':
        return 'sys_math_calc_sub';
      default:
        if (skill.startsWith('addition')) return 'sys_math_calc_add';
        if (skill.startsWith('subtraction')) return 'sys_math_calc_sub';
        return 'sys_math_intro';
    }
  }

  static String introForThinkingSkill(String skill) {
    switch (skill) {
      case 'matching':
      case 'pairs':
        return 'sys_thinking_match';
      case 'memory':
        return 'sys_thinking_memory';
      case 'paths':
      case 'maze':
        return 'sys_thinking_maze';
      case 'same_diff':
      case 'odd_one_out':
        return 'sys_thinking_diff';
      case 'shadow':
        return 'sys_thinking_shadow';
      case 'missing_shape':
      case 'pattern':
      case 'patterns':
      case 'sequence':
      case 'sizes':
      case 'classes':
        return 'sys_thinking_find';
      default:
        return 'sys_thinking_intro';
    }
  }

  final Set<String> _preloadedKeys = {};
  bool _preloaded = false;

  /// Clip ids that the code asks for but that were never bundled, mapped to the
  /// bundled clip that says the same thing. Used only when the requested file
  /// is missing, so shipping the original file later takes over automatically.
  static const Map<String, String> bundledFallbacks = {
    'sys_success_1': 'sys_praise_1',
    'sys_success_2': 'sys_praise_2',
    'sys_success_3': 'sys_praise_3',
    'sys_success_4': 'sys_praise_4',
    'sys_success_5': 'sys_correct',
    'sys_fail_1': 'sys_try_again',
    'sys_fail_2': 'sys_try_again_1',
    'sys_fail_3': 'sys_try_again_2',
    'sys_fail_4': 'sys_try_again',
    'sys_japanese_intro': 'sys_ja_intro',
    'sys_math_recognize': 'sys_math_identify',
    'sys_game_memory': 'sys_thinking_memory',
    'v_math_dem_so': 'sys_math_count',
  };

  /// `assets/audio/<id>.mp3` ids present in the asset manifest; null until
  /// loaded (or when the manifest is unavailable, in which case every id is tried).
  Set<String>? _bundledIds;
  Future<void>? _bundledIdsLoading;

  Future<void> _ensureBundledIds() {
    return _bundledIdsLoading ??= () async {
      try {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        const prefix = 'assets/audio/';
        _bundledIds = {
          for (final asset in manifest.listAssets())
            if (asset.startsWith(prefix) && asset.endsWith('.mp3') && !asset.substring(prefix.length).contains('/'))
              asset.substring(prefix.length, asset.length - '.mp3'.length),
        };
      } catch (e) {
        debugPrint('[AudioService] asset manifest unavailable, trying every id: $e');
      }
    }();
  }

  bool _isBundled(String id) => _bundledIds?.contains(id) ?? true;

  /// The id that will actually play for [id]: itself when bundled, else its
  /// [bundledFallbacks] entry when that is bundled.
  String _resolveBundled(String id) {
    if (_isBundled(id)) return id;
    final fallback = bundledFallbacks[id];
    if (fallback != null && _isBundled(fallback)) return fallback;
    return id;
  }

  static const successKeys = [
    'sys_success_1',
    'sys_success_2',
    'sys_success_3',
    'sys_success_4',
    'sys_success_5',
  ];
  static const tryAgainKeys = [
    'sys_fail_1',
    'sys_fail_2',
    'sys_fail_3',
    'sys_fail_4',
  ];

  /// Telex slug ↔ Unicode for Vietnamese letters. Filenames NEVER use Unicode.
  static const Map<String, String> _viCharToSlug = {
    'ă': 'aw',
    'â': 'aa',
    'đ': 'dd',
    'ê': 'ee',
    'ô': 'oo',
    'ơ': 'ow',
    'ư': 'uw',
  };

  /// Explicit short word aliases from tools/audio_schema.json.
  static const Map<String, String> _wordAliases = {
    'ấm': 'v_word_aasm',
    'áo': 'v_word_ao',
    'ăn': 'v_word_an',
    'bố': 'v_word_bo',
    'cá': 'v_word_ca',
  };

  static String getAudioIdForLetter(String letter) {
    return VietnameseSpeechCatalog.getAudioIdForLetter(letter);
  }

  /// Normalize any legacy / Unicode key to an ASCII schema id.
  static String normalizeKey(String key, {String? defaultPrefix}) {
    var k = key.trim().toLowerCase();
    if (k.endsWith('.mp3')) {
      k = k.substring(0, k.length - 4);
    }
    if (k.startsWith('assets/audio/')) {
      k = k.substring('assets/audio/'.length);
    }
    if (k.startsWith('audio/')) {
      k = k.substring('audio/'.length);
    }

    if (k.startsWith('v_') || k.startsWith('j_') || k.startsWith('ja_') || k.startsWith('sys_') || k.startsWith('bgm_')) {
      if (k.startsWith('v_')) {
        final sub = k.substring(2);
        if (_viCharToSlug.containsKey(sub)) {
          return 'v_${_viCharToSlug[sub]}';
        }
      }
      // Legacy j_hira_ga → prefer ja_h_ga when playing Japanese schema files.
      if (k.startsWith('j_hira_')) {
        return 'ja_h_${k.substring('j_hira_'.length)}';
      }
      if (k.startsWith('j_kata_')) {
        return 'ja_k_${k.substring('j_kata_'.length)}';
      }
      // Legacy short vowel ids (ja_a) → modern schema (ja_h_a). Prefer ja_h_/ja_k_ at play time.
      if (RegExp(r'^ja_[aiueo]$').hasMatch(k)) {
        return 'ja_h_${k.substring(3)}';
      }
      // Old game intros → new context-specific clips.
      if (k == 'sys_math_recognize') return 'sys_math_identify';
      if (k == 'sys_game_memory') return 'sys_thinking_memory';
      return k;
    }

    if (k.startsWith('vi_')) {
      final sub = k.substring(3);
      if (sub.startsWith('letter_')) {
        final parts = sub.split('_');
        if (parts.length >= 2) {
          final slug = parts[1];
          return 'v_${_viCharToSlug[slug] ?? slug}';
        }
      }
      if (sub == 'phrase_gioi_lam') return 'sys_success_1';
      if (sub.startsWith('word_')) {
        return 'v_$sub';
      }
      // Legacy curriculum ids → bundled brand-voice schema.
      if (sub.startsWith('phonics_')) {
        return 'v_blend_${sub.substring('phonics_'.length)}';
      }
      if (sub.startsWith('rime_')) {
        return 'v_rime_${sub.substring('rime_'.length)}';
      }
      return 'v_$sub';
    }

    if (k.startsWith('v_phonics_')) {
      return 'v_blend_${k.substring('v_phonics_'.length)}';
    }

    if (k.startsWith('success_') || k.startsWith('fail_')) {
      return 'sys_$k';
    }
    if (k.startsWith('intro_')) {
      final sub = k.substring(6);
      if (sub == 'game') return 'sys_game_memory';
      if (sub == 'catch') return 'sys_game_catch';
      if (sub == 'math') return 'sys_math_intro';
      return 'sys_$sub';
    }
    if (k == 'japanese_intro') return 'sys_japanese_intro';
    if (k.startsWith('math_')) {
      if (k == 'math_recognize' || k == 'math_match' || k == 'math_count') {
        return 'sys_$k';
      }
      return 'v_$k';
    }
    if (k.startsWith('game_')) return 'sys_$k';
    if (k.startsWith('hira_') || k.startsWith('kata_')) return 'j_$k';
    if (k.startsWith('word_')) return 'v_$k';
    if (k.startsWith('h_') || k.startsWith('k_')) return 'ja_$k';

    final letterId = getAudioIdForLetter(k);
    if (letterId.isNotEmpty && k.length <= 2) return letterId;

    final alias = _wordAliases[k] ?? _wordAliases[key.trim()];
    if (alias != null) return alias;

    const viWords = {
      'ba', 'me', 'be', 'bo', 'anh', 'chi', 'em', 'nha', 'cay', 'hoa', 'ban', 'cho', 'meo', 'ga', 'ao', 'an', 'am', 'aasm',
    };
    if (viWords.contains(k)) return 'v_word_$k';

    if (defaultPrefix != null && defaultPrefix.isNotEmpty) {
      final pfx = defaultPrefix.endsWith('_') ? defaultPrefix : '${defaultPrefix}_';
      return '$pfx$k';
    }
    return 'v_$k';
  }

  String _personaName = 'Mai';
  String get personaName => _personaName;
  set personaName(String name) {
    if (name.trim().isNotEmpty) {
      _personaName = name.trim();
    }
  }

  AudioLanguage? get lastSpokenLanguage => _lastSpoken;
  bool get isHomeBgmWanted => _homeBgmWanted;

  Future<void> preloadFeedbackAndSystemClips() async {
    if (_preloaded) return;
    _preloaded = true;
    await _ensureBundledIds();
    final keys = {
      for (final key in preloadedClipKeys) _resolveBundled(normalizeKey(key)),
    }.where(_isBundled).toList();
    final files = <String>[
      for (final key in keys) 'audio/$key.mp3',
      bgmAsset,
    ];
    try {
      // Browser GET warm-up on web; temp-file copy on mobile — avoids first-play stutter.
      await AudioCache.instance.loadAll(files);
      _preloadedKeys.addAll(keys);
    } catch (e) {
      debugPrint('[AudioService] AudioCache.loadAll fallback: $e');
      for (final key in keys) {
        try {
          await rootBundle.load('assets/audio/$key.mp3');
          _preloadedKeys.add(key);
        } catch (_) {}
      }
      try {
        await rootBundle.load('assets/$bgmAsset');
      } catch (_) {}
    }
  }

  Future<void> setVoiceVolume(double volume) async {
    voiceVolume = volume.clamp(0.0, 1.0);
    try {
      await _player?.setVolume(voiceVolume);
    } catch (_) {}
  }

  Future<void> setBgmVolume(double volume) async {
    bgmVolume = volume.clamp(0.0, 1.0);
    _bgmTargetVolume = bgmVolume;
    try {
      if (_duckDepth == 0) {
        await _bgmPlayer?.setVolume(_bgmTargetVolume);
      }
    } catch (_) {}
  }

  Future<void> init() async {
    _player ??= AudioPlayer();
    await _player!.setReleaseMode(ReleaseMode.stop);
    await _player!.setPlaybackRate(AudioPlaybackPolicy.recordedPlaybackRate);
    await _player!.setVolume(voiceVolume);
    _bgmPlayer ??= AudioPlayer();
    await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer!.setVolume(bgmVolume);
    _lifecycle?.dispose();
    _lifecycle = AppLifecycleListener(
      onHide: pauseForAppBackground,
      onPause: pauseForAppBackground,
      onResume: () {
        if (_homeBgmWanted) {
          unawaited(startHomeBgm());
        }
      },
    );
    // Warm cache in background if caller did not await preload yet.
    unawaited(preloadFeedbackAndSystemClips());
  }

  Future<void> playBGM(String path) async {
    _homeBgmWanted = true;
    final asset = path.startsWith('assets/') ? path.substring('assets/'.length) : path;
    await _startBgmLoop(asset, volume: bgmVolume);
  }

  Future<void> startHomeBgm() async {
    _homeBgmWanted = true;
    await _startBgmLoop(bgmAsset, volume: bgmVolume);
  }

  Future<void> startGameBgm() async {
    _homeBgmWanted = false;
    await _startBgmLoop(bgmAsset, volume: bgmVolume);
  }

  Future<void> _startBgmLoop(String asset, {double volume = defaultBgmVolume}) async {
    _bgmTargetVolume = volume;
    if (!soundEnabled || !bgmEnabled) {
      await _bgmPlayer?.stop();
      return;
    }
    try {
      _bgmPlayer ??= AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setVolume(_duckDepth > 0 ? bgmDuckVolume : volume);
      final state = _bgmPlayer!.state;
      if (state == PlayerState.playing) return;
      if (state == PlayerState.paused) {
        await _bgmPlayer!.resume();
        return;
      }
      await _bgmPlayer!.play(AssetSource(asset));
    } catch (error) {
      debugPrint('[AudioService] BGM failed: $error');
    }
  }

  Future<void> _duckBgm() async {
    _duckDepth++;
    if (_duckDepth != 1) return;
    try {
      await _bgmPlayer?.setVolume(bgmDuckVolume).timeout(_opTimeout);
    } catch (_) {}
  }

  Future<void> _unduckBgm() async {
    if (_duckDepth > 0) _duckDepth--;
    if (_duckDepth > 0) return;
    try {
      await _bgmPlayer?.setVolume(_bgmTargetVolume).timeout(_opTimeout);
    } catch (_) {}
  }

  Future<void> stopHomeBgm() async {
    _homeBgmWanted = false;
    _duckDepth = 0;
    try {
      await _bgmPlayer?.stop();
    } catch (_) {}
  }

  Future<void> stopGameBgm() async {
    _duckDepth = 0;
    try {
      await _bgmPlayer?.stop();
    } catch (_) {}
  }

  Future<void> setBgmEnabled(bool enabled) async {
    bgmEnabled = enabled;
    if (!enabled) {
      try {
        await _bgmPlayer?.stop();
      } catch (_) {}
      return;
    }
    if (_homeBgmWanted) await startHomeBgm();
  }

  Future<void> pauseForAppBackground() async {
    await stop();
    try {
      await _bgmPlayer?.pause();
    } catch (_) {}
  }

  /// Hard-stop current voice clip.
  Future<void> stop() async {
    _speechToken++;
    if (_currentPlay != null && !_currentPlay!.isCompleted) {
      _currentPlay!.complete();
    }
    _currentPlay = null;
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _lifecycle?.dispose();
    _lifecycle = null;
    await stop();
    await stopHomeBgm();
    await _player?.dispose();
    _player = null;
    await _bgmPlayer?.dispose();
    _bgmPlayer = null;
  }

  /// Primary playback API — ASCII schema id only (e.g. `v_aw`, `sys_math_intro`).
  ///
  /// By default returns as soon as playback *starts* (Safari-safe). Pass
  /// [waitForComplete] only when sequencing clips (e.g. onset → rime → syllable).
  Future<AudioPlayResult> playAudio(String id, {bool waitForComplete = false}) =>
      _play(id, waitForComplete: waitForComplete, completeTimeout: _completeTimeout, interruptSpeech: true);

  Future<AudioPlayResult> _play(
    String id, {
    required bool waitForComplete,
    required Duration completeTimeout,
    required bool interruptSpeech,
  }) async {
    // Any other clip (feedback, a tapped card) cuts a running [speak] sequence.
    if (interruptSpeech) _speechToken++;
    final audioId = normalizeKey(id);
    if (!soundEnabled) {
      return const AudioPlayResult.unavailable('Âm thanh đang tắt.');
    }
    if (_debounced('audio:$audioId')) {
      final lang = audioId.startsWith('ja_') || audioId.startsWith('j_')
          ? AudioLanguage.japanese
          : AudioLanguage.vietnamese;
      return AudioPlayResult.ok(AudioLocalePolicy.localeFor(lang));
    }

    await _ensureBundledIds();
    final candidates = <String>{
      audioId,
      if (bundledFallbacks[audioId] != null) bundledFallbacks[audioId]!,
      if (audioId.startsWith('vi_word_')) 'v_${audioId.substring(3)}',
      if (audioId.startsWith('v_word_')) 'vi_${audioId.substring(2)}',
      if (audioId.startsWith('ja_h_')) 'j_hira_${audioId.substring(5)}',
      if (audioId.startsWith('ja_k_')) 'j_kata_${audioId.substring(5)}',
      if (audioId.startsWith('j_hira_')) 'ja_h_${audioId.substring(7)}',
      if (audioId.startsWith('j_kata_')) 'ja_k_${audioId.substring(7)}',
      if (audioId.startsWith('ja_h_') && audioId.length > 5) 'ja_${audioId.substring(5)}',
      if (audioId.startsWith('ja_k_') && audioId.length > 5) 'ja_${audioId.substring(5)}',
      if (audioId.endsWith('_example')) audioId.substring(0, audioId.length - '_example'.length),
      if (audioId.startsWith('v_rime_')) 'v_blend_${audioId.substring(7)}',
      if (audioId.startsWith('v_rime_')) 'v_word_${audioId.substring(7)}',
      if (audioId.startsWith('v_rime_')) 'v_v_${audioId.substring(7)}',
    }.where(_isBundled).toList();
    if (candidates.isEmpty) {
      debugPrint('[AudioService] Missing bundled MP3 for id=$audioId (expected assets/audio/$audioId.mp3).');
      return AudioPlayResult.unavailable('Thiếu file âm thanh: $audioId');
    }

    _player ??= AudioPlayer();
    await _safePlayerOp(() => _player!.stop());

    await _duckBgm();
    try {
      for (final key in candidates) {
        final ok = await _playRecorded(
          'assets/audio/$key.mp3',
          duckExternally: true,
          waitForComplete: waitForComplete,
          completeTimeout: completeTimeout,
        );
        if (ok) {
          _lastSpoken = key.startsWith('ja_') || key.startsWith('j_')
              ? AudioLanguage.japanese
              : AudioLanguage.vietnamese;
          return AudioPlayResult.ok(AudioLocalePolicy.localeFor(_lastSpoken!));
        }
      }

      debugPrint(
        '[AudioService] Missing bundled MP3 for id=$audioId '
        '(expected assets/audio/$audioId.mp3). Zero native TTS fallback.',
      );
      return AudioPlayResult.unavailable('Thiếu file âm thanh: $audioId');
    } finally {
      // When not waiting for complete, unduck immediately so game UI never stalls.
      if (!waitForComplete) {
        unawaited(_unduckBgm());
      } else {
        await _unduckBgm();
      }
    }
  }

  /// Fire-and-forget feedback/clip play — never blocks Safari game loops.
  /// Scheduled as a microtask so it starts on the same gesture frame.
  void playFireAndForget(String id) {
    scheduleMicrotask(() {
      try {
        unawaited(
          playAudio(id, waitForComplete: false).catchError((Object e, StackTrace st) {
            debugPrint('[AudioService] Safari/web audio ignored for $id: $e');
            return const AudioPlayResult.unavailable('audio ignored');
          }),
        );
      } catch (e) {
        debugPrint('[AudioService] Sound error: $e');
      }
    });
  }

  void playCorrectSound() => playFireAndForget(
        successKeys[_random.nextInt(successKeys.length)],
      );

  void playWrongSound() => playFireAndForget(
        tryAgainKeys[_random.nextInt(tryAgainKeys.length)],
      );

  /// Call from the first user gesture so Safari unlocks the Web Audio context.
  Future<void> unlockWebAudioContext() async {
    if (_webAudioUnlocked) return;
    _webAudioUnlocked = true;
    try {
      _player ??= AudioPlayer();
      // Extremely short silent kick: stop is enough to resume suspended contexts
      // on many WebKit builds; play+stop a known system clip if available.
      await _safePlayerOp(() => _player!.stop());
      await _safePlayerOp(() => _player!.setVolume(0.01));
      await _ensureBundledIds();
      final kick = _resolveBundled(successKeys.first);
      await _safePlayerOp(
        () => _player!.play(AssetSource('audio/$kick.mp3')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
      await _safePlayerOp(() => _player!.stop());
      await _safePlayerOp(() => _player!.setVolume(voiceVolume));
      debugPrint('[AudioService] Web audio context unlock attempted');
    } catch (e) {
      debugPrint('[AudioService] Web audio unlock ignored: $e');
    }
  }

  Future<AudioPlayResult> playVoice(
    String textOrKey, {
    AudioLanguage language = AudioLanguage.vietnamese,
    String? assetPath,
  }) async {
    if (assetPath != null && assetPath.isNotEmpty) {
      final stem = assetPath.split('/').last.replaceAll(RegExp(r'\.(mp3|wav)$'), '');
      return playAudio(stem);
    }
    if (language == AudioLanguage.vietnamese) {
      final letterId = getAudioIdForLetter(textOrKey);
      if (letterId.isNotEmpty && textOrKey.trim().length <= 2) {
        return playAudio(letterId);
      }
      final wordId = VietnameseSpeechCatalog.getAudioIdForWord(textOrKey);
      if (wordId.isNotEmpty) return playAudio(wordId);
      return playAudio(normalizeKey(textOrKey, defaultPrefix: 'v_'));
    }
    if (language == AudioLanguage.japanese) {
      return playAudio(normalizeKey(textOrKey, defaultPrefix: 'ja_'));
    }
    return playAudio(textOrKey);
  }

  Future<AudioPlayResult> playAsset(String assetKey, {bool waitForComplete = false}) =>
      playAudio(assetKey, waitForComplete: waitForComplete);

  Future<AudioPlayResult> playSystem(String systemKey) =>
      playAudio(normalizeKey(systemKey, defaultPrefix: 'sys_'));

  Future<AudioPlayResult> playSound(String assetPathOrKey) => playAudio(assetPathOrKey);

  /// Warm the asset bundle only — never touch [_player] (avoids killing active playback).
  Future<void> preloadLessonAssets(List<String> assetKeysOrPaths) async {
    for (final item in assetKeysOrPaths) {
      if (item.isEmpty) continue;
      try {
        final key = normalizeKey(item);
        final asset = item.endsWith('.mp3') || item.endsWith('.wav')
            ? (item.startsWith('assets/') ? item.substring('assets/'.length) : item)
            : 'audio/$key.mp3';
        await rootBundle.load('assets/$asset');
        _preloadedKeys.add(key);
      } catch (_) {}
    }
  }

  Future<void> preloadAsset(String assetKeyOrPath) async {
    await preloadLessonAssets([assetKeyOrPath]);
  }

  Future<AudioPlayResult> playRequest(AudioRequest request) => playAudio(request.id);

  Future<AudioPlayResult> playVietnameseAsset(String audioId) => playAudio(audioId);

  Future<AudioPlayResult> playJapaneseAsset(String audioId) => playAudio(audioId);

  Future<AudioPlayResult> playEnglishAsset(String audioId) => playAudio(audioId);

  Future<AudioPlayResult> playJapanese(String japaneseText, {String? audioAsset}) {
    if (audioAsset != null && audioAsset.isNotEmpty) {
      final stem = audioAsset.split('/').last.replaceAll(RegExp(r'\.(mp3|wav)$'), '');
      return playAudio(stem);
    }
    return playAudio(normalizeKey(japaneseText, defaultPrefix: 'ja_'));
  }

  Future<AudioPlayResult> playVietnamese(String vietnameseText, {String? audioAsset}) {
    final spoken = vietnameseText.trim();
    final letterId = getAudioIdForLetter(spoken);
    if (letterId.isNotEmpty && spoken.length <= 2) return playAudio(letterId);
    final wordId = VietnameseSpeechCatalog.getAudioIdForWord(spoken);
    if (wordId.isNotEmpty) return playAudio(wordId);
    if (audioAsset != null && audioAsset.isNotEmpty) {
      final stem = audioAsset.split('/').last.replaceAll(RegExp(r'\.(mp3|wav)$'), '');
      return playAudio(stem);
    }
    return playAudio(normalizeKey(spoken, defaultPrefix: 'v_'));
  }

  Future<AudioPlayResult> playVietnameseLetterName(String letter, {String? audioAsset}) {
    final id = getAudioIdForLetter(letter);
    if (id.isEmpty) {
      return Future.value(AudioPlayResult.unavailable('Thiếu file âm thanh: $letter'));
    }
    return playAudio(id);
  }

  Future<AudioPlayResult> playVietnameseLetterSound(String letter, {String? audioAsset}) {
    return playVietnameseLetterName(letter, audioAsset: audioAsset);
  }

  Future<AudioPlayResult> playVietnameseLetter(String letterOrName, {String? audioAsset}) {
    return playVietnameseLetterName(letterOrName, audioAsset: audioAsset);
  }

  Future<AudioPlayResult> playVietnamesePhonics(String syllable, {String? audioAsset}) {
    if (audioAsset != null && audioAsset.isNotEmpty) {
      return playAsset(audioAsset);
    }
    final trimmed = syllable.trim().toLowerCase();
    final slug = VietnameseSpeechCatalog.slug(trimmed);
    // Brand-voice blend clips first (v_blend_ba), then legacy schema ids.
    return playAsset('v_blend_$slug');
  }

  Future<AudioPlayResult> playVietnameseWord(String word, {String? audioAsset}) {
    if (audioAsset != null && audioAsset.isNotEmpty) {
      return playAsset(audioAsset);
    }
    final id = VietnameseSpeechCatalog.getAudioIdForWord(word);
    if (id.isEmpty) {
      return Future.value(AudioPlayResult.unavailable('Thiếu file âm thanh: $word'));
    }
    return playAsset(id);
  }

  // ---------------------------------------------------------------------------
  // Every on-screen line, voiced.
  // ---------------------------------------------------------------------------

  static const Duration _lineTimeout = Duration(seconds: 9);
  int _speechToken = 0;

  /// Bundled clip ids that say [text], best first: a content word clip, the
  /// clips of a math expression, else the line's own `vi_say_*` clip.
  /// Empty when nothing bundled can say it.
  Future<List<String>> clipsForLine(String text) async {
    await _ensureBundledIds();
    final t = text.trim();
    if (t.isEmpty) return const [];
    final math = mathClips(t);
    if (math != null) return math.every(_isBundled) ? math : const [];
    final wordId = VietnameseSpeechCatalog.getAudioIdForWord(t);
    if (wordId.isNotEmpty && _isBundled(normalizeKey(wordId))) return [wordId];
    final lineId = SpeechId.idForLine(t);
    if (lineId != null && _isBundled(lineId)) return [lineId];
    return const [];
  }

  /// Clips for a pure math expression ("3 + 4 = ?", "12 > 9"), or null when
  /// [text] is not one. Numbers 0–100 each have their own clip.
  static List<String>? mathClips(String text) {
    final t = text.replaceAll('−', '-').replaceAll('×', 'x').trim();
    if (!RegExp(r'^[\d\s+\-=?<>_.]+$').hasMatch(t) || !RegExp(r'\d').hasMatch(t)) return null;
    final out = <String>[];
    for (final m in RegExp(r'\d+|[+\-=<>]').allMatches(t)) {
      final token = m[0]!;
      final n = int.tryParse(token);
      if (n != null) {
        if (n > 100) return null;
        out.add('math_num_$n');
      } else {
        out.add(const {'+': 'math_op_plus', '-': 'math_op_minus', '=': 'math_op_equal', '>': 'math_cmp_greater', '<': 'math_cmp_less'}[token]!);
      }
    }
    return out.isEmpty ? null : out;
  }

  /// Says [lines] one after another in Mai's voice (instruction, then the
  /// question, …). A newer [speak] call or [stop] interrupts the sequence.
  /// Lines without a bundled clip are skipped; when none can be said,
  /// [fallbackId] (e.g. a skill intro) plays instead.
  Future<AudioPlayResult> speak(List<String?> lines, {String? fallbackId}) async {
    final token = ++_speechToken;
    final seen = <String>{};
    final queue = <String>[];
    for (final line in lines) {
      if (line == null || !seen.add(line.trim())) continue;
      queue.addAll(await clipsForLine(line));
    }
    if (token != _speechToken) return const AudioPlayResult.unavailable('Đã chuyển câu khác.');
    if (queue.isEmpty) {
      if (fallbackId == null) return const AudioPlayResult.unavailable('Chưa có giọng đọc cho câu này.');
      return _play(fallbackId, waitForComplete: false, completeTimeout: _completeTimeout, interruptSpeech: false);
    }
    AudioPlayResult last = const AudioPlayResult.unavailable('');
    for (var i = 0; i < queue.length; i++) {
      if (token != _speechToken) break;
      _lastRequestKey = null; // the same clip may repeat inside one sentence ("2 + 2").
      last = await _play(
        queue[i],
        waitForComplete: i < queue.length - 1,
        completeTimeout: _lineTimeout,
        interruptSpeech: false,
      );
    }
    return last;
  }

  /// Convenience for one line.
  Future<AudioPlayResult> speakLine(String text, {String? fallbackId}) => speak([text], fallbackId: fallbackId);

  /// True when [text] has a bundled voice.
  Future<bool> canSpeak(String text) async => (await clipsForLine(text)).isNotEmpty;

  Future<AudioPlayResult> playWrongAnswerSound() => playRandomTryAgain();

  Future<AudioPlayResult> playRandomSuccess() {
    final key = successKeys[_random.nextInt(successKeys.length)];
    // Never block UI / game loops waiting for Safari audio completion.
    playFireAndForget(key);
    return Future.value(AudioPlayResult.ok(AudioLocalePolicy.localeFor(AudioLanguage.vietnamese)));
  }

  Future<AudioPlayResult> playRandomTryAgain() {
    final key = tryAgainKeys[_random.nextInt(tryAgainKeys.length)];
    playFireAndForget(key);
    return Future.value(AudioPlayResult.ok(AudioLocalePolicy.localeFor(AudioLanguage.vietnamese)));
  }

  Future<AudioPlayResult> playIntro(String introKey) =>
      playAudio(normalizeKey(introKey, defaultPrefix: 'sys_'));

  Future<AudioPlayResult> playLessonVoice(String textKey, {String? prefix}) =>
      playAudio(normalizeKey(textKey, defaultPrefix: prefix));

  Future<AudioPlayResult> playKanaCharacter(String character, {String? audioAsset}) {
    return playJapanese(character, audioAsset: audioAsset);
  }

  Future<AudioPlayResult> playEnglish(String text, {String? audioAsset}) {
    if (audioAsset != null && audioAsset.isNotEmpty) {
      final stem = audioAsset.split('/').last.replaceAll(RegExp(r'\.(mp3|wav)$'), '');
      return playAudio(stem);
    }
    return playAudio(normalizeKey(text, defaultPrefix: 'sys_'));
  }

  Future<AudioPlayResult> playForLanguage(AudioLanguage language, String text, {String? audioAsset}) {
    switch (language) {
      case AudioLanguage.vietnamese:
        return playVietnamese(text, audioAsset: audioAsset);
      case AudioLanguage.japanese:
        return playJapanese(text, audioAsset: audioAsset);
      case AudioLanguage.english:
        return playEnglish(text, audioAsset: audioAsset);
    }
  }

  @Deprecated('Use playJapanese with the kana character, not romaji')
  Future<void> playKana(String pronunciation) async {
    await playJapanese(pronunciation);
  }

  Future<AudioPlayResult> playFallback(String messageVi) async {
    return AudioPlayResult.unavailable(messageVi);
  }

  static void notify(BuildContext context, AudioPlayResult result) {
    if (result.success) return;
    final message = result.errorMessageVi;
    if (message == null || message.isEmpty || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  bool _debounced(String key) {
    final now = DateTime.now();
    if (_lastRequestKey == key &&
        _lastRequestAt != null &&
        now.difference(_lastRequestAt!) < AudioPlaybackPolicy.debounce) {
      return true;
    }
    _lastRequestKey = key;
    _lastRequestAt = now;
    return false;
  }

  /// Stop then play — Safari-safe timeouts; completion wait is opt-in.
  Future<bool> _playRecorded(
    String assetPath, {
    bool duckExternally = false,
    bool waitForComplete = false,
    Duration completeTimeout = _completeTimeout,
  }) async {
    if (!duckExternally) await _duckBgm();
    StreamSubscription<void>? sub;
    try {
      _player ??= AudioPlayer();
      await _safePlayerOp(() => _player!.stop());
      await _safePlayerOp(() => _player!.setPlaybackRate(AudioPlaybackPolicy.recordedPlaybackRate));
      await _safePlayerOp(() => _player!.setVolume(voiceVolume));
      final source = assetPath.startsWith('assets/') ? assetPath.substring('assets/'.length) : assetPath;
      final done = Completer<void>();
      _currentPlay = done;
      sub = _player!.onPlayerComplete.listen((_) {
        if (!done.isCompleted) done.complete();
      });
      debugPrint('[AudioService] Playing audio: $assetPath');
      await _safePlayerOp(() => _player!.play(AssetSource(source)));

      if (waitForComplete) {
        await done.future.timeout(completeTimeout, onTimeout: () {
          debugPrint('[AudioService] complete timeout (Safari-safe): $assetPath');
        });
      } else {
        // Detach completion listener so ducking can restore later without blocking.
        unawaited(
          done.future.timeout(_completeTimeout, onTimeout: () {}).whenComplete(() async {
            try {
              await sub?.cancel();
            } catch (_) {}
            if (!duckExternally) {
              await _unduckBgm();
            }
          }),
        );
        return true;
      }
      await sub.cancel();
      return true;
    } catch (error) {
      debugPrint('[AudioService] recorded asset failed path=$assetPath: $error');
      try {
        await sub?.cancel();
      } catch (_) {}
      return false;
    } finally {
      if (waitForComplete && !duckExternally) await _unduckBgm();
    }
  }

  Future<void> _safePlayerOp(Future<void> Function() op) async {
    try {
      await op().timeout(_opTimeout, onTimeout: () {
        debugPrint('[AudioService] player op timed out (Safari/WebKit)');
      });
    } catch (e) {
      debugPrint('[AudioService] player op ignored: $e');
    }
  }
}
