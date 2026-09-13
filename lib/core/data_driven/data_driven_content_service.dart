import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/content/content_item.dart';
import '../../domain/models/kana_item.dart';

/// Configuration for a data-driven educational module.
/// Adding a new language or subject (e.g. English, Science) only requires
/// a JSON manifest entry and corresponding JSON data files + audio assets.
class ModuleConfig {
  final String id;
  final String name;
  final String languageCode;
  final String audioPrefix;
  final String voice;
  final String dataPath;
  final Map<String, String> files;

  const ModuleConfig({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.audioPrefix,
    required this.voice,
    required this.dataPath,
    required this.files,
  });

  factory ModuleConfig.fromJson(Map<String, dynamic> json) {
    return ModuleConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      languageCode: json['languageCode'] as String? ?? 'vi-VN',
      audioPrefix: json['audioPrefix'] as String? ?? 'v_',
      voice: json['voice'] as String? ?? 'vi-VN-HoaiMyNeural',
      dataPath: json['dataPath'] as String? ?? 'assets/data/${json['id']}',
      files: (json['files'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
    );
  }

  String filePath(String key) {
    final fileName = files[key] ?? '$key.json';
    return '$dataPath/$fileName';
  }
}

/// Dynamic Data-Driven Parser and Engine for ViMai Kids.
/// Decouples all educational curriculum and items from Dart code into external JSON.
class DataDrivenContentService {
  final Map<String, ModuleConfig> _modules = {};
  final Map<String, List<ContentItem>> _contentCache = {};
  final Map<String, List<KanaItem>> _kanaCache = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;
  List<ModuleConfig> get registeredModules => _modules.values.toList();

  /// Loads module manifest and pre-parses registered educational content.
  Future<void> init() async {
    if (_initialized) return;
    try {
      final manifestRaw = await rootBundle.loadString('assets/data/manifest.json');
      final manifestJson = jsonDecode(manifestRaw) as Map<String, dynamic>;
      final list = (manifestJson['modules'] as List<dynamic>?) ?? [];
      for (final raw in list) {
        final mod = ModuleConfig.fromJson(raw as Map<String, dynamic>);
        _modules[mod.id] = mod;
      }
    } catch (e) {
      debugPrint('[DataDrivenContentService] manifest load fallback: $e');
    }
    _initialized = true;
  }

  ModuleConfig? getModule(String moduleId) => _modules[moduleId];

  /// Dynamically parses a list of [ContentItem] from any JSON file path.
  Future<List<ContentItem>> loadContentItems(String path) async {
    if (_contentCache.containsKey(path)) {
      return _contentCache[path]!;
    }
    try {
      final jsonString = await rootBundle.loadString(path);
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final items = jsonList
          .map((json) => ContentItem.fromJson(json as Map<String, dynamic>))
          .toList();
      _contentCache[path] = items;
      return items;
    } catch (e) {
      debugPrint('[DataDrivenContentService] Failed to load ContentItems from $path: $e');
      return [];
    }
  }

  /// Dynamically parses a list of [KanaItem] from Japanese kana JSON.
  Future<List<KanaItem>> loadKanaItems(String path) async {
    if (_kanaCache.containsKey(path)) {
      return _kanaCache[path]!;
    }
    try {
      final jsonString = await rootBundle.loadString(path);
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final items = jsonList
          .map((json) => KanaItem.fromJson(json as Map<String, dynamic>))
          .toList();
      _kanaCache[path] = items;
      return items;
    } catch (e) {
      debugPrint('[DataDrivenContentService] Failed to load KanaItems from $path: $e');
      return [];
    }
  }

  /// Generic helper to parse arbitrary JSON list or map.
  Future<dynamic> loadRawJson(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('[DataDrivenContentService] Failed to load raw JSON from $path: $e');
      return null;
    }
  }
}

final dataDrivenContentServiceProvider = Provider<DataDrivenContentService>((ref) {
  return DataDrivenContentService();
});
