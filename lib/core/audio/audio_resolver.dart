import '../../domain/content/content_item.dart';
import 'audio_asset_registry.dart';
import 'audio_locale_policy.dart';
import 'vietnamese_speech_catalog.dart';

class ResolvedAudio {
  final AudioLanguage language;
  final String locale;
  final String text;
  final String? recordedAsset;

  const ResolvedAudio({
    required this.language,
    required this.locale,
    required this.text,
    this.recordedAsset,
  });

  bool get usesRecordedAsset => recordedAsset != null;
}

/// Single source of truth for which language/locale a lesson item may speak.
class AudioResolver {
  static ResolvedAudio japanese(String text, {String? audioAsset}) {
    return ResolvedAudio(
      language: AudioLanguage.japanese,
      locale: AudioLocalePolicy.japaneseLocale,
      text: text,
      recordedAsset: AudioAssetRegistry.existingOrNull(audioAsset),
    );
  }

  static ResolvedAudio vietnamese(String text, {String? audioAsset}) {
    final recorded = AudioAssetRegistry.existingOrNull(audioAsset) ??
        VietnameseSpeechCatalog.assetForSpokenText(text);
    return ResolvedAudio(
      language: AudioLanguage.vietnamese,
      locale: AudioLocalePolicy.vietnameseLocale,
      text: text,
      recordedAsset: recorded,
    );
  }

  static ResolvedAudio english(String text, {String? audioAsset}) {
    return ResolvedAudio(
      language: AudioLanguage.english,
      locale: AudioLocalePolicy.englishLocale,
      text: text,
      recordedAsset: AudioAssetRegistry.existingOrNull(audioAsset),
    );
  }

  static ResolvedAudio forContent(ContentItem item, {String? speakText}) {
    final text = (speakText ?? item.audioText).trim();
    switch (item.subject) {
      case ContentSubject.japanese:
        return japanese(text, audioAsset: item.audioAsset);
      case ContentSubject.vietnamese:
        return vietnamese(text, audioAsset: item.audioAsset);
      case ContentSubject.math:
      case ContentSubject.thinking:
      case ContentSubject.creativity:
      case ContentSubject.game:
        return vietnamese(text, audioAsset: item.audioAsset);
    }
  }

  static bool isAllowedLocale(AudioLanguage language, String locale) {
    final normalized = locale.replaceAll('_', '-').toLowerCase();
    switch (language) {
      case AudioLanguage.japanese:
        return normalized == 'ja-jp' || normalized.startsWith('ja');
      case AudioLanguage.vietnamese:
        return normalized == 'vi-vn' || normalized.startsWith('vi');
      case AudioLanguage.english:
        return AudioLocalePolicy.isEnglishLocale(normalized);
    }
  }

  static bool vietnameseFallsBackToJapanese(String locale) {
    final n = locale.replaceAll('_', '-').toLowerCase();
    return n == 'ja-jp' || n.startsWith('ja');
  }

  static bool fallsBackToEnglish(String locale) => AudioLocalePolicy.isEnglishLocale(locale);
}
