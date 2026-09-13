class AudioCatalogEntry {
  final String id;
  final String language;
  final String text;
  final String asset;
  final String source;
  final String license;
  final String attribution;

  const AudioCatalogEntry({
    required this.id,
    required this.language,
    required this.text,
    required this.asset,
    required this.source,
    required this.license,
    required this.attribution,
  });

  factory AudioCatalogEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final asset = json['asset']?.toString() ?? '';
    final isJa = id.startsWith('j_') || asset.contains('/ja/');
    return AudioCatalogEntry(
      id: id,
      language: json['language']?.toString() ?? (isJa ? 'ja' : 'vi'),
      text: json['text']?.toString() ?? id,
      asset: asset,
      source: json['source']?.toString() ?? '',
      license: json['license']?.toString() ?? '',
      attribution: json['attribution']?.toString() ?? '',
    );
  }

  bool get isVietnamese => language == 'vi';
  bool get isJapanese => language == 'ja';
  bool get isEnglish => language == 'en';
}
