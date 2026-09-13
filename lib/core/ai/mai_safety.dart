import '../audio/vietnamese_speech_catalog.dart';
import 'mai_context.dart';
import 'mai_response.dart';

/// Child Safety & Pedagogical Source-of-Truth Guardrail for Mai AI.
class MaiSafety {
  static const int maxResponseLength = 140;

  /// Blocklist for sensitive personal information (PII) and unsuitable topics.
  static final List<Pattern> _piiPatterns = [
    RegExp(r'(?:số điện thoại|sđt|phone|tel|hotline)', caseSensitive: false),
    RegExp(r'\b\d{6,}\b'), // 6 or more contiguous digits (phone numbers, account numbers, etc.)
    RegExp(r'(?:địa chỉ|ở đâu|nhà ở|ngõ|phố|đường|thành phố|quận|huyện)', caseSensitive: false),
    RegExp(r'(?:mật khẩu|password|tài khoản|mã pin|otp)', caseSensitive: false),
    RegExp(r'(?:thẻ ngân hàng|chuyển tiền|tiền mặt|credit card)', caseSensitive: false),
    RegExp(r'(?:căn cước|cmnd|chứng minh)', caseSensitive: false),
    RegExp(r'(?:https?:\/\/|\.com|\.vn|facebook|tiktok|youtube|zalo)', caseSensitive: false),
    RegExp(r'(?:đánh|giết|súng|dao|chết|bạo lực)', caseSensitive: false),
  ];

  /// Checks if any input text contains personal information or unsafe content.
  static bool containsUnsafeContent(String text) {
    for (final pattern in _piiPatterns) {
      if (pattern.allMatches(text).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// Sanitizes and validates a [MaiResponse] against safety rules and curriculum ground truths.
  static MaiResponse screen(MaiResponse response, MaiContext context) {
    var text = response.text;

    // 1. Check for unsafe PII or forbidden content
    if (containsUnsafeContent(text)) {
      return MaiResponse.fallback(
        action: response.action,
        text: 'Mai ở đây để cùng bé học bài thật vui! Chúng mình cùng làm bài nhé!',
        hintLevel: response.hintLevel,
      );
    }

    // 2. Validate Vietnamese Phonics Source of Truth
    if (context.currentModule.toLowerCase() == 'vietnamese') {
      text = enforceVietnamesePhonics(text, context);
    }

    // 3. Ensure child-appropriate length (max ~140 chars)
    if (text.length > maxResponseLength) {
      final periodIdx = text.indexOf('.', 40);
      if (periodIdx != -1 && periodIdx < maxResponseLength) {
        text = text.substring(0, periodIdx + 1);
      } else {
        final exclamationIdx = text.indexOf('!', 40);
        if (exclamationIdx != -1 && exclamationIdx < maxResponseLength) {
          text = text.substring(0, exclamationIdx + 1);
        } else {
          text = '${text.substring(0, maxResponseLength - 3)}...';
        }
      }
    }

    if (text != response.text) {
      return MaiResponse(
        action: response.action,
        text: text,
        hintLevel: response.hintLevel,
        mood: response.mood,
        suggestedChoice: response.suggestedChoice,
        isOfflineFallback: response.isOfflineFallback,
        metadata: response.metadata,
      );
    }

    return response;
  }

  /// Ensures that any phonetic reference matches verified educational content in [VietnameseSpeechCatalog].
  ///
  /// For instance:
  /// - Letter C must be taught with sound "cờ" (or name "xê"), never foreign "xi" or invented sounds.
  /// - Letter B must be "bờ" (or name "bê").
  /// - Letter Ă must be "á" / "ă".
  static String enforceVietnamesePhonics(String text, MaiContext context) {
    // If context specifies a letter lesson, check speech catalog
    for (final entry in VietnameseSpeechCatalog.letters.entries) {
      final glyph = entry.key;
      final speech = entry.value;

      final isTargetLetter = context.currentLesson.toUpperCase().contains(glyph) ||
          context.currentQuestion.toUpperCase().contains(glyph);

      if (isTargetLetter) {
        // Guard against common English phonetic hallucinations (e.g. "C đọc là si", "B đọc là bi")
        final invalidPhonicsRegex = RegExp(
          'chữ $glyph (?:phát âm|đọc) là (?!cờ|bờ|dờ|đờ|gờ|hờ|lờ|mờ|nờ|pờ|quờ|rờ|sờ|tờ|vờ|xờ|${speech.sound}|${speech.name})[a-zA-Z]+',
          caseSensitive: false,
        );
        if (invalidPhonicsRegex.hasMatch(text)) {
          return 'Chữ $glyph phát âm là "${speech.phonicsSpoken}" bé nhé!';
        }
      }
    }
    return text;
  }
}
