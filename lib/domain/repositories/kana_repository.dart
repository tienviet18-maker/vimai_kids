import '../models/kana_item.dart';
import '../models/learning_stats.dart';

abstract class KanaRepository {
  List<KanaItem> getAllHiragana();
  List<KanaItem> getAllKatakana();
  KanaItem? getKanaById(String id);
  
  Future<LearningStats> getStats(String kanaId);
  Future<void> saveStats(LearningStats stats);
  Future<List<LearningStats>> getAllStats();
}
