import '../../domain/content/content_item.dart';
import 'audio_locale_policy.dart';
import 'audio_service.dart';
import 'vietnamese_speech_catalog.dart';

/// Runtime pronunciation layer for Vietnamese phonics lessons.
///
/// Curriculum JSON is never rewritten. Letter-name vs phoneme stay as stored.
/// Phonics lessons speak hard-wired Hoài My MP3 IDs (`v_aw`, `v_aa`, …)
/// and display [VietnameseSpeechCatalog.phonicsSpoken].
class VietnamesePhonicsGuide {
  const VietnamesePhonicsGuide._();

  static String primarySpoken(ContentItem letter) {
    final glyph = letter.question ?? letter.letterName;
    return VietnameseSpeechCatalog.phonicsSpoken(glyph);
  }

  static String letterNameSpoken(ContentItem letter) {
    final name = letter.letterName.trim();
    if (name.isNotEmpty) return name;
    return VietnameseSpeechCatalog.nameSpoken(letter.question ?? '');
  }

  static bool nameDiffersFromSound(ContentItem letter) {
    return letterNameSpoken(letter) != primarySpoken(letter);
  }

  static String primaryAudioId(ContentItem letter) {
    final modern = VietnameseSpeechCatalog.getAudioIdForLetter(
      letter.question ?? letter.phoneme,
    );
    if (modern.isNotEmpty) return modern;
    if (letter.audioSoundId.isNotEmpty) return letter.audioSoundId;
    return VietnameseSpeechCatalog.soundAudioId(letter.question ?? letter.phoneme) ?? '';
  }

  static String nameAudioId(ContentItem letter) {
    final modern = VietnameseSpeechCatalog.getAudioIdForLetter(
      letter.question ?? letter.letterName,
    );
    if (modern.isNotEmpty) return modern;
    if (letter.audioNameId.isNotEmpty) return letter.audioNameId;
    return VietnameseSpeechCatalog.nameAudioId(letter.question ?? letter.letterName) ?? '';
  }

  static Future<AudioPlayResult> playPrimary(AudioService audio, ContentItem letter) {
    final id = primaryAudioId(letter);
    if (id.isNotEmpty) return audio.playAsset(id);
    return audio.playVietnameseLetterSound(letter.question ?? letter.phoneme);
  }

  static Future<AudioPlayResult> playName(AudioService audio, ContentItem letter) {
    final id = nameAudioId(letter);
    if (id.isNotEmpty) return audio.playAsset(id);
    return audio.playVietnameseLetterName(letter.question ?? letter.letterName);
  }

  static Future<AudioPlayResult> playExampleWord(AudioService audio, ContentItem letter) {
    final id = letter.wordAudioId;
    if (id.isNotEmpty) return audio.playAsset(id);
    final fromText = VietnameseSpeechCatalog.getAudioIdForWord(letter.exampleWord);
    if (fromText.isNotEmpty) return audio.playAsset(fromText);
    return Future.value(AudioPlayResult.unavailable('Thiếu file âm thanh từ ví dụ'));
  }
}
