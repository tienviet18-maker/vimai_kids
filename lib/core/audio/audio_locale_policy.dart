enum AudioLanguage { japanese, vietnamese, english }

enum EducationalLanguage { japanese, vietnamese }

class AudioPlayResult {
  final bool success;
  final String? locale;
  final String? errorMessageVi;

  const AudioPlayResult.ok(this.locale)
      : success = true,
        errorMessageVi = null;

  const AudioPlayResult.unavailable(this.errorMessageVi)
      : success = false,
        locale = null;
}

/// Educational audio must never fall back to English.
class AudioLocalePolicy {
  static const japaneseLocale = 'ja-JP';
  static const vietnameseLocale = 'vi-VN';
  static const englishLocale = 'en-US';

  static String requiredLocale(EducationalLanguage language) {
    switch (language) {
      case EducationalLanguage.japanese:
        return japaneseLocale;
      case EducationalLanguage.vietnamese:
        return vietnameseLocale;
    }
  }

  static String localeFor(AudioLanguage language) {
    switch (language) {
      case AudioLanguage.japanese:
        return japaneseLocale;
      case AudioLanguage.vietnamese:
        return vietnameseLocale;
      case AudioLanguage.english:
        return englishLocale;
    }
  }

  static EducationalLanguage? educationalOf(AudioLanguage language) {
    switch (language) {
      case AudioLanguage.japanese:
        return EducationalLanguage.japanese;
      case AudioLanguage.vietnamese:
        return EducationalLanguage.vietnamese;
      case AudioLanguage.english:
        return null;
    }
  }

  static bool isEnglishLocale(String locale) {
    final normalized = locale.toLowerCase().replaceAll('_', '-');
    return normalized == 'en' || normalized.startsWith('en-');
  }

  static String? selectAvailable({
    required EducationalLanguage language,
    required Iterable<dynamic> availableLocales,
  }) {
    final required = requiredLocale(language);
    final prefix = required.split('-').first.toLowerCase();
    String? exact;
    String? prefixMatch;

    for (final raw in availableLocales) {
      final locale = raw.toString();
      if (isEnglishLocale(locale)) continue;
      final normalized = locale.replaceAll('_', '-');
      if (normalized.toLowerCase() == required.toLowerCase()) {
        exact = normalized;
        break;
      }
      if (prefixMatch == null && normalized.toLowerCase().startsWith(prefix)) {
        prefixMatch = normalized;
      }
    }

    final selected = exact ?? prefixMatch;
    if (selected == null || isEnglishLocale(selected)) return null;
    return selected;
  }

  static void assertNotEnglish(String locale) {
    if (isEnglishLocale(locale)) {
      throw StateError('Educational audio must not use English locale: $locale');
    }
  }
}
