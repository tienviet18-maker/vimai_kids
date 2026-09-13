import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';

void main() {
  group('Audio locale policy', () {
    test('Japanese selects ja-JP and never en-US', () {
      final selected = AudioLocalePolicy.selectAvailable(
        language: EducationalLanguage.japanese,
        availableLocales: ['en-US', 'ja-JP', 'vi-VN'],
      );
      expect(selected, 'ja-JP');
      expect(AudioLocalePolicy.isEnglishLocale(selected!), isFalse);
    });

    test('Vietnamese selects vi-VN and never en-US', () {
      final selected = AudioLocalePolicy.selectAvailable(
        language: EducationalLanguage.vietnamese,
        availableLocales: ['en-GB', 'vi-VN', 'en-US'],
      );
      expect(selected, 'vi-VN');
      expect(AudioLocalePolicy.isEnglishLocale(selected!), isFalse);
    });

    test('English is never selected as educational fallback', () {
      expect(
        AudioLocalePolicy.selectAvailable(
          language: EducationalLanguage.japanese,
          availableLocales: ['en-US', 'en-GB', 'en'],
        ),
        isNull,
      );
      expect(
        AudioLocalePolicy.selectAvailable(
          language: EducationalLanguage.vietnamese,
          availableLocales: ['en-US'],
        ),
        isNull,
      );
      expect(AudioLocalePolicy.isEnglishLocale('en-US'), isTrue);
      expect(() => AudioLocalePolicy.assertNotEnglish('en-US'), throwsStateError);
    });

    test('required locales are ja-JP and vi-VN', () {
      expect(AudioLocalePolicy.requiredLocale(EducationalLanguage.japanese), 'ja-JP');
      expect(AudioLocalePolicy.requiredLocale(EducationalLanguage.vietnamese), 'vi-VN');
    });
  });
}
