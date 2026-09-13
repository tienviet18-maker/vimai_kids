import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_catalog_entry.dart';

/// Production audio catalog loaded from bundled [assets/audio/audio_manifest.json].
/// Missing files are errors. There is no TTS fallback.
class AudioAssetRegistry {
  AudioAssetRegistry._();

  static final Map<String, AudioCatalogEntry> _byId = {};
  static bool _loaded = false;

  static bool get isLoaded => _loaded;
  static int get recordedCount => _byId.length;
  static Iterable<AudioCatalogEntry> get entries => _byId.values;

  static Set<String> get recordedVietnamese =>
      _byId.values.where((e) => e.isVietnamese).map((e) => e.asset).toSet();

  static Set<String> get recordedJapanese =>
      _byId.values.where((e) => e.isJapanese).map((e) => e.asset).toSet();

  static Set<String> get recordedEnglish =>
      _byId.values.where((e) => e.isEnglish).map((e) => e.asset).toSet();

  static void resetForTest() {
    _byId.clear();
    _loaded = false;
  }

  static void loadFromDiskSync({String path = 'assets/audio/audio_manifest.json'}) {
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError('Audio manifest missing: $path');
    }
    _parse(file.readAsStringSync());
    _loaded = true;
  }

  static Future<void> ensureLoaded() async {
    if (_loaded && _byId.isNotEmpty) return;
    try {
      final raw = await rootBundle.loadString('assets/audio/audio_manifest.json');
      _parse(raw);
      _loaded = true;
      return;
    } catch (error) {
      debugPrint('[AudioAssetRegistry] bundle load failed: $error');
    }
    final file = File('assets/audio/audio_manifest.json');
    if (file.existsSync()) {
      _parse(file.readAsStringSync());
      _loaded = true;
      return;
    }
    throw StateError('Audio manifest could not be loaded');
  }

  static void _parse(String raw) {
    _byId.clear();
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '{}' || trimmed == '[]') {
      debugPrint('[AudioAssetRegistry] audio manifest is empty');
      return;
    }
    final dynamic decoded = jsonDecode(trimmed);
    if (decoded is List) {
      for (final item in decoded) {
        if (item is Map) {
          final entry = AudioCatalogEntry.fromJson(Map<String, dynamic>.from(item));
          if (entry.id.isNotEmpty) {
            _byId[entry.id] = entry;
          }
        }
      }
    } else if (decoded is Map) {
      if (decoded.containsKey('files') && decoded['files'] is List) {
        for (final item in decoded['files'] as List) {
          if (item is Map) {
            final entry = AudioCatalogEntry.fromJson(Map<String, dynamic>.from(item));
            if (entry.id.isNotEmpty) {
              _byId[entry.id] = entry;
            }
          }
        }
      } else {
        for (final entry in decoded.entries) {
          final k = entry.key.toString();
          final v = entry.value;
          if (v is Map) {
            final map = Map<String, dynamic>.from(v);
            map.putIfAbsent('id', () => k);
            _byId[k] = AudioCatalogEntry.fromJson(map);
          } else if (v is String) {
            final isJa = k.startsWith('j_') || k.contains('_ja_') || v.contains('/ja/');
            _byId[k] = AudioCatalogEntry(
              id: k,
              asset: v,
              language: isJa ? 'ja' : 'vi',
              text: k,
              source: 'EdgeTTS',
              license: 'CC BY 4.0',
              attribution: 'ViMai Kids Audio',
            );
          }
        }
      }
    }
  }

  static AudioCatalogEntry? entryById(String audioId) => _byId[audioId];

  static bool hasId(String audioId) => _byId.containsKey(audioId);

  static bool exists(String? path) {
    if (path == null || path.isEmpty) return false;
    return _byId.values.any((e) => e.asset == path);
  }

  static String? existingOrNull(String? path) => exists(path) ? path : null;

  static AudioCatalogEntry requireVietnamese(String audioId) {
    final entry = _require(audioId);
    if (!entry.isVietnamese) {
      throw StateError('Audio $audioId is ${entry.language}, expected vi');
    }
    if (!entry.asset.contains('/vi/')) {
      throw StateError('Vietnamese audio $audioId is not a vi asset: ${entry.asset}');
    }
    return entry;
  }

  static AudioCatalogEntry requireJapanese(String audioId) {
    final entry = _require(audioId);
    if (!entry.isJapanese) {
      throw StateError('Audio $audioId is ${entry.language}, expected ja');
    }
    if (!entry.asset.contains('/ja/')) {
      throw StateError('Japanese audio $audioId is not a ja asset: ${entry.asset}');
    }
    return entry;
  }

  static AudioCatalogEntry requireEnglish(String audioId) {
    final entry = _require(audioId);
    if (!entry.isEnglish) {
      throw StateError('Audio $audioId is ${entry.language}, expected en');
    }
    return entry;
  }

  static AudioCatalogEntry _require(String audioId) {
    final entry = _byId[audioId];
    if (entry == null) {
      debugPrint('[AudioAssetRegistry] MISSING production audioId=$audioId');
      throw StateError('Missing production audio asset: $audioId');
    }
    return entry;
  }

  static String? idForText({required String language, required String text}) {
    final needle = text.trim();
    if (needle.isEmpty) return null;
    for (final entry in _byId.values) {
      if (entry.language == language && entry.text == needle) return entry.id;
    }
    return null;
  }
}
