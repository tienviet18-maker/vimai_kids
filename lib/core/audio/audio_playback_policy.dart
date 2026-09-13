/// Production policy: bundled Hoài My / Nanami MP3 assets only.
/// Native device TTS is permanently disabled (zero-fallback).
class AudioPlaybackPolicy {
  /// Educational content (alphabet, phonics, kana) must ship bundled audio.
  static const bundledRequiredTypes = {
    'letter',
    'phonics',
    'rime',
    'kana',
    'phrase',
  };

  static const recordedPlaybackRate = 1.0;

  static const debounce = Duration(milliseconds: 280);

  /// Native TTS fallback is forbidden — every clip must be a bundled MP3.
  static const allowSameLanguageTtsFallback = false;
}
