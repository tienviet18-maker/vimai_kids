import 'dart:async';

import '../../../core/audio/audio_service.dart';

/// The right answer that wins the game: the chime and [leadIds] (the letter
/// or sound the child picked) only, no praise line. The win panel opens
/// with Mai's "Bé thắng rồi! Giỏi quá!" ~3 s later; a praise line here
/// would be cut off by it mid-sentence (one voice player).
void playWinningAnswer(AudioService audio, {List<String> leadIds = const []}) {
  audio.sfx(Sfx.correct);
  if (leadIds.isNotEmpty) unawaited(audio.speak(const [], leadIds: leadIds));
}
