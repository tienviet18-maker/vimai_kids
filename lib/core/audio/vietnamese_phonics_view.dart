import '../../domain/content/content_item.dart';
import 'vietnamese_phonics_guide.dart';
import 'vietnamese_speech_catalog.dart';

/// Presentation adapter for Vietnamese phonics lessons.
///
/// Does not rewrite curriculum JSON. Distinguishes [letterName] (data) from
/// [phonics] (what a child hears and sees). Child mode never surfaces letter
/// names such as “xê” for C.
class VietnamesePhonicsView {
  const VietnamesePhonicsView({
    required this.letter,
    required this.uppercase,
    required this.lowercase,
    required this.letterName,
    required this.phonics,
    required this.ttsText,
    required this.exampleWord,
    required this.exampleText,
    required this.audioAsset,
    required this.audioType,
    required this.audioId,
  });

  final String letter;
  final String uppercase;
  final String lowercase;
  final String letterName;
  final String phonics;
  final String ttsText;
  final String exampleWord;
  final String exampleText;
  final String audioAsset;
  final String audioType;
  final String audioId;

  /// Child phonics lessons teach sound, not letter name.
  bool get showLetterNameInChildMode => false;

  factory VietnamesePhonicsView.fromItem(ContentItem item) {
    final glyph = (item.question ?? item.letterName).trim();
    final speech = VietnameseSpeechCatalog.letterOf(glyph);
    final phonics = VietnamesePhonicsGuide.primarySpoken(item);
    final audioId = VietnamesePhonicsGuide.primaryAudioId(item);
    return VietnamesePhonicsView(
      letter: glyph,
      uppercase: glyph,
      lowercase: item.lowercase,
      letterName: speech?.name ?? item.letterName,
      phonics: phonics,
      ttsText: phonics,
      exampleWord: item.exampleWord,
      exampleText: item.exampleWord,
      audioAsset: speech?.soundAssetPath ?? item.audioAsset ?? '',
      audioType: 'sound',
      audioId: audioId,
    );
  }
}
