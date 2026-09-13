import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/kana_item.dart';
import '../../domain/models/learning_stats.dart';
import '../../domain/repositories/kana_repository.dart';
import '../kana/hiragana_data.dart';
import '../kana/katakana_data.dart';

class KanaRepositoryImpl implements KanaRepository {
  static const String _boxName = 'kana_stats_box';
  late Box _box;
  List<KanaItem> _hiragana = hiraganaData;
  List<KanaItem> _katakana = katakanaData;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    try {
      final hRaw = await rootBundle.loadString('assets/data/japanese/hiragana.json');
      final hList = (jsonDecode(hRaw) as List<dynamic>)
          .map((e) => KanaItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (hList.isNotEmpty) _hiragana = hList;
    } catch (_) {}

    try {
      final kRaw = await rootBundle.loadString('assets/data/japanese/katakana.json');
      final kList = (jsonDecode(kRaw) as List<dynamic>)
          .map((e) => KanaItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (kList.isNotEmpty) _katakana = kList;
    } catch (_) {}
  }

  @override
  List<KanaItem> getAllHiragana() => _hiragana;

  @override
  List<KanaItem> getAllKatakana() => _katakana;

  @override
  KanaItem? getKanaById(String id) {
    try {
      return [..._hiragana, ..._katakana].firstWhere((k) => k.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<LearningStats> getStats(String kanaId) async {
    final String? data = _box.get(kanaId);
    if (data != null) {
      return LearningStats.fromJson(jsonDecode(data));
    }
    return LearningStats(itemId: kanaId);
  }

  @override
  Future<void> saveStats(LearningStats stats) async {
    await _box.put(stats.itemId, jsonEncode(stats.toJson()));
  }

  @override
  Future<List<LearningStats>> getAllStats() async {
    final List<LearningStats> stats = [];
    for (var key in _box.keys) {
      final String? data = _box.get(key);
      if (data != null) {
        stats.add(LearningStats.fromJson(jsonDecode(data)));
      }
    }
    return stats;
  }
}
