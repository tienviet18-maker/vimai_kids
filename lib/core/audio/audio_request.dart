import 'audio_locale_policy.dart';

/// Explicit playback request. Language is never inferred from text.
class AudioRequest {
  final String id;
  final AudioLanguage language;
  final String text;
  final String? assetPath;
  final String type;

  const AudioRequest({
    required this.id,
    required this.language,
    required this.text,
    this.assetPath,
    this.type = 'speech',
  });

  factory AudioRequest.vietnamese({
    required String id,
    required String text,
    String? assetPath,
    String type = 'speech',
  }) {
    return AudioRequest(
      id: id,
      language: AudioLanguage.vietnamese,
      text: text,
      assetPath: assetPath,
      type: type,
    );
  }

  factory AudioRequest.japanese({
    required String id,
    required String text,
    String? assetPath,
    String type = 'speech',
  }) {
    return AudioRequest(
      id: id,
      language: AudioLanguage.japanese,
      text: text,
      assetPath: assetPath,
      type: type,
    );
  }
}
