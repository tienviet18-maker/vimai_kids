import 'dart:math';

import '../../../domain/models/kana_item.dart';

class CatchKanaRound {
  CatchKanaRound({required this.target, required this.items});

  final KanaItem target;
  final List<KanaItem> items;

  bool get hasUniqueItems => items.map((e) => e.id).toSet().length == items.length;

  bool get includesTarget => items.any((e) => e.id == target.id);

  static CatchKanaRound generate({
    required List<KanaItem> pool,
    required Random random,
    int distractors = 3,
  }) {
    final basic = pool.where((e) => e.kanaType == KanaType.basic).toList();
    final source = basic.isNotEmpty ? basic : pool;
    final target = source[random.nextInt(source.length)];
    final others = source.where((e) => e.id != target.id).toList()..shuffle(random);
    final take = min(distractors, others.length);
    final items = [target, ...others.take(take)]..shuffle(random);
    return CatchKanaRound(target: target, items: items);
  }

  /// Synthetic pool so Catch can run with Vietnamese alphabet glyphs.
  static List<KanaItem> vietnamesePool() {
    const letters = 'AĂÂBCDĐEÊGHIKLMNOÔƠPQRSTUƯVXY';
    return [
      for (var i = 0; i < letters.length; i++)
        KanaItem(
          id: 'vi_catch_$i',
          script: KanaScript.hiragana,
          kanaType: KanaType.basic,
          character: letters[i],
          romaji: letters[i].toLowerCase(),
          pronunciation: letters[i].toLowerCase(),
          strokeCount: 1,
          ageMin: 3,
          ageMax: 7,
          difficulty: 1,
        ),
    ];
  }

  bool isCorrect(KanaItem tapped) => tapped.id == target.id;
}
