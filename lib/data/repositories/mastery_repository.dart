import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/learning/mastery_engine.dart';
import '../../domain/models/skill_mastery.dart';

class MasteryRepository {
  static const _boxName = 'mastery_box_v1';
  Box<String>? _box;
  final MasteryEngine engine = MasteryEngine();

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  String _key(String childId, String itemId) => '$childId|$itemId';

  SkillMastery get(String childId, String itemId, {String skill = 'general'}) {
    final box = _box;
    if (box == null) return SkillMastery(id: itemId, skill: skill);
    final raw = box.get(_key(childId, itemId));
    if (raw == null) return SkillMastery(id: itemId, skill: skill);
    return SkillMastery.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<SkillMastery> record({
    required String childId,
    required String itemId,
    required String skill,
    required bool correct,
    double responseTimeMs = 0,
  }) async {
    final current = get(childId, itemId, skill: skill);
    final updated = engine.recordAttempt(
      current: current.attempts == 0 && current.skill != skill
          ? SkillMastery(id: itemId, skill: skill)
          : current,
      correct: correct,
      responseTimeMs: responseTimeMs,
    );
    await _box?.put(_key(childId, itemId), jsonEncode(updated.toJson()));
    return updated;
  }

  List<SkillMastery> allForChild(String childId) {
    final box = _box;
    if (box == null) return [];
    final prefix = '$childId|';
    final result = <SkillMastery>[];
    for (final key in box.keys) {
      if (!key.toString().startsWith(prefix)) continue;
      final raw = box.get(key);
      if (raw == null) continue;
      result.add(SkillMastery.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    }
    return result;
  }

  List<SkillMastery> bySkillPrefix(String childId, String prefix) {
    return allForChild(childId).where((e) => e.skill.startsWith(prefix)).toList();
  }

  Future<void> clearChild(String childId) async {
    final box = _box;
    if (box == null) return;
    final keyPrefix = '$childId|';
    final keys = box.keys.where((k) => k.toString().startsWith(keyPrefix)).toList();
    for (final key in keys) {
      await box.delete(key);
    }
  }
}
