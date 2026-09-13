import '../../domain/models/kana_item.dart';
import '../../domain/models/skill_mastery.dart';
import '../kana/hiragana_data.dart';
import '../kana/katakana_data.dart';
import 'continue_learning.dart';

/// Child/parent facing labels. Never show raw IDs such as h_he or vietnamese.blend.
class ProgressLabels {
  static KanaItem? kanaFor(String id) {
    for (final item in hiraganaData) {
      if (item.id == id) return item;
    }
    for (final item in katakanaData) {
      if (item.id == id) return item;
    }
    return null;
  }

  static String title(SkillMastery item) {
    final kana = kanaFor(item.id);
    if (kana != null) return 'Chữ ${kana.character}';
    return ReviewPractice.title(item);
  }

  static String subject(SkillMastery item) {
    final skill = item.skill;
    if (skill.startsWith('japanese') || item.id.startsWith('h_') || item.id.startsWith('k_')) return 'Tiếng Nhật';
    if (skill.startsWith('vietnamese')) return 'Tiếng Việt';
    if (skill.startsWith('math')) return 'Toán';
    if (skill.startsWith('thinking')) return 'Tư duy';
    if (skill.startsWith('creativity')) return 'Sáng tạo';
    if (skill.startsWith('game')) return 'Trò chơi';
    return 'Học tập';
  }

  static String mostPracticed(List<SkillMastery> items) {
    if (items.isEmpty) return '—';
    final counts = <String, int>{};
    for (final item in items.where((e) => e.attempts > 0)) {
      final key = subject(item);
      counts[key] = (counts[key] ?? 0) + item.attempts;
    }
    if (counts.isEmpty) return '—';
    final best = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return best.key;
  }

  static int rememberedCount(List<SkillMastery> items) {
    return items.where((e) => e.isMastered).length;
  }
}
