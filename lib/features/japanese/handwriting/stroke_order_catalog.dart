import 'dart:convert';

import 'package:flutter/services.dart';

/// Licensed KanjiVG paths for basic hiragana/katakana.
/// Empty until [ensureLoaded] reads catalog.json — never invents paths.
class StrokeOrderCatalog {
  StrokeOrderCatalog([Map<String, List<String>>? paths]) : _paths = paths ?? _shared;

  static final Map<String, List<String>> _shared = {};
  static final Map<String, int> _counts = {};
  static bool loaded = false;

  final Map<String, List<String>> _paths;

  List<String> pathsFor(String kanaId) => List<String>.from(_paths[kanaId] ?? const []);

  bool hasPaths(String kanaId) => pathsFor(kanaId).isNotEmpty;

  int strokeCountFor(String kanaId, int fallback) => _counts[kanaId] ?? fallback;

  /// Stable IDs derived from catalog order. Never invented geometry.
  List<String> strokeIdsFor(String kanaId) {
    final n = pathsFor(kanaId).length;
    return [for (var i = 0; i < n; i++) '${kanaId}_s${i + 1}'];
  }

  int declaredStrokeCount(String kanaId) => _counts[kanaId] ?? 0;

  static Future<void> ensureLoaded() async {
    if (loaded && _shared.isNotEmpty) return;
    try {
      final raw = await rootBundle.loadString('assets/content/japanese/strokes/catalog.json');
      loadJson(raw);
    } catch (_) {
      loaded = false;
    }
  }

  static void loadJson(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final chars = data['characters'] as Map<String, dynamic>? ?? {};
    _shared.clear();
    _counts.clear();
    for (final entry in chars.entries) {
      final item = entry.value as Map<String, dynamic>;
      final paths = (item['paths'] as List<dynamic>? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      if (paths.isEmpty) continue;
      _shared[entry.key] = paths;
      _counts[entry.key] = (item['strokeCount'] as num?)?.toInt() ?? paths.length;
    }
    loaded = _shared.isNotEmpty;
  }
}
