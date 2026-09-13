import '../audio/audio_locale_policy.dart';
import '../audio/audio_service.dart';

/// Semantic lesson audio. Does not replace [AudioService] or production WAVs.
enum AudioLessonKind {
  letterSound,
  wordExample,
  instruction,
  encouragement,
  correct,
  wrong,
  completion,
}

class AudioLessonEvent {
  const AudioLessonEvent({
    required this.kind,
    required this.language,
    required this.audioId,
    this.script = '',
  });

  final AudioLessonKind kind;
  final AudioLanguage language;
  final String audioId;
  final String script;
}

class AudioLessonService {
  AudioLessonService(this._audio);

  final AudioService _audio;

  Future<AudioPlayResult> play(AudioLessonEvent event) {
    switch (event.language) {
      case AudioLanguage.japanese:
        return _audio.playJapaneseAsset(event.audioId);
      case AudioLanguage.english:
        return _audio.playEnglishAsset(event.audioId);
      case AudioLanguage.vietnamese:
        return _audio.playVietnameseAsset(event.audioId);
    }
  }
}
