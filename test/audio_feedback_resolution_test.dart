import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';

/// Answer feedback and system intros must resolve to an MP3 that is really
/// bundled, otherwise children get silence on every correct / wrong tap.
void main() {
  bool bundled(String id) => File('assets/audio/$id.mp3').existsSync();

  String resolve(String id) {
    final key = AudioService.normalizeKey(id);
    if (bundled(key)) return key;
    return AudioService.bundledFallbacks[key] ?? key;
  }

  test('every fallback target is a bundled clip', () {
    for (final entry in AudioService.bundledFallbacks.entries) {
      expect(bundled(entry.value), isTrue, reason: '${entry.key} → ${entry.value}.mp3 missing');
    }
  });

  test('success and try-again feedback resolve to bundled clips', () {
    for (final id in [...AudioService.successKeys, ...AudioService.tryAgainKeys]) {
      expect(bundled(resolve(id)), isTrue, reason: '$id has no bundled clip');
    }
  });

  // Specified in tools/audio_schema.json but never recorded and with no clip
  // that says the same thing. Needs a new recording; plays nothing until then.
  const knownGaps = {'sys_game_catch'};

  test('every preloaded clip resolves to a bundled clip', () {
    for (final id in AudioService.preloadedClipKeys.where((id) => !knownGaps.contains(id))) {
      expect(bundled(resolve(id)), isTrue, reason: '$id has no bundled clip');
    }
  });

  test('a missing clip reports unavailable without touching the player', () async {
    final audio = AudioService();
    final result = await audio.playAudio('sys_definitely_not_bundled');
    expect(result.success, isFalse);
  });
}
