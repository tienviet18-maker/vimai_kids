import 'audio_locale_policy.dart';
import 'audio_resolver.dart';

/// Pure playback plan used by [AudioService] and tests.
/// Locales are locked: Vietnamese=vi-VN, Japanese=ja-JP, English=en-US.
class AudioPlaybackPlan {
  final AudioLanguage language;
  final String locale;
  final String text;
  final String? recordedAsset;

  const AudioPlaybackPlan({
    required this.language,
    required this.locale,
    required this.text,
    this.recordedAsset,
  });

  bool get usesRecordedAsset => recordedAsset != null;

  bool get usesJapaneseLocale {
    final n = locale.replaceAll('_', '-').toLowerCase();
    return n == 'ja-jp' || n.startsWith('ja');
  }

  bool get usesEnglishLocale => AudioLocalePolicy.isEnglishLocale(locale);

  bool get usesVietnameseLocale {
    final n = locale.replaceAll('_', '-').toLowerCase();
    return n == 'vi-vn' || n.startsWith('vi');
  }

  static AudioPlaybackPlan fromResolved(ResolvedAudio resolved) {
    return AudioPlaybackPlan(
      language: resolved.language,
      locale: resolved.locale,
      text: resolved.text,
      recordedAsset: resolved.recordedAsset,
    );
  }

  static AudioPlaybackPlan vietnamese(String text, {String? audioAsset}) {
    return fromResolved(AudioResolver.vietnamese(text, audioAsset: audioAsset));
  }

  static AudioPlaybackPlan japanese(String text, {String? audioAsset}) {
    return fromResolved(AudioResolver.japanese(text, audioAsset: audioAsset));
  }

  static AudioPlaybackPlan english(String text, {String? audioAsset}) {
    return fromResolved(AudioResolver.english(text, audioAsset: audioAsset));
  }
}
