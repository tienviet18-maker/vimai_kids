import 'dart:math';

import '../../../domain/models/kana_item.dart';

/// How hard the choices beside the target letter are, from the child's age.
enum LetterChallenge {
  /// Ages 3–4: every letter on screen looks and sounds clearly different
  /// from every other one (no A/Ă/Â, O/Ô/Ơ, よ/ゆ, シ/ツ side by side).
  distinct,

  /// Age 5: nothing on screen can be mistaken for the target, but the other
  /// choices may resemble each other.
  noLookAlikeOfTarget,

  /// Ages 6–7: one choice deliberately looks like the target (Ă for A,
  /// ぬ for め) so the child has to look closely.
  withLookAlike,
}

class CatchKanaRound {
  CatchKanaRound({required this.target, required this.items});

  final KanaItem target;
  final List<KanaItem> items;

  bool get hasUniqueItems => items.map((e) => e.id).toSet().length == items.length;

  bool get includesTarget => items.any((e) => e.id == target.id);

  static LetterChallenge challengeForAge(int age) {
    if (age <= 4) return LetterChallenge.distinct;
    if (age == 5) return LetterChallenge.noLookAlikeOfTarget;
    return LetterChallenge.withLookAlike;
  }

  /// One round: a target and [distractors] other letters from [pool], chosen
  /// by [challengeForAge] of [age].
  static CatchKanaRound generate({
    required List<KanaItem> pool,
    required Random random,
    int distractors = 3,
    int age = 5,
  }) {
    final basic = pool.where((e) => e.kanaType == KanaType.basic).toList();
    final source = basic.isNotEmpty ? basic : pool;
    final target = source[random.nextInt(source.length)];
    final others = source.where((e) => e.id != target.id).toList()..shuffle(random);
    final want = min(distractors, others.length);
    final picked = <KanaItem>[];

    switch (challengeForAge(age)) {
      case LetterChallenge.distinct:
        for (final o in others) {
          if (picked.length == want) break;
          if (confusable(o, target) || picked.any((p) => confusable(o, p))) continue;
          picked.add(o);
        }
      case LetterChallenge.noLookAlikeOfTarget:
        picked.addAll(others.where((o) => !confusable(o, target)).take(want));
      case LetterChallenge.withLookAlike:
        final twin = others.where((o) => looksAlike(o, target)).firstOrNull;
        if (twin != null && want > 0) picked.add(twin);
        picked.addAll(others.where((o) => o.id != twin?.id).take(want - picked.length));
    }
    // A pool too small for the rule: fill up with anything left.
    if (picked.length < want) {
      picked.addAll(others.where((o) => !picked.contains(o)).take(want - picked.length));
    }
    final items = [target, ...picked]..shuffle(random);
    return CatchKanaRound(target: target, items: items);
  }

  /// Vietnamese letters for Catch. Capitals for the youngest; from age 5
  /// half the rounds use lowercase, the letters children read in books.
  /// Ages 3–4 only get the letters without marks (no Ă Â Đ Ê Ô Ơ Ư): every
  /// one of those has a twin that differs by a small mark.
  static List<KanaItem> vietnamesePool({bool lowercase = false, int age = 5}) {
    const letters = 'AĂÂBCDĐEÊGHIKLMNOÔƠPQRSTUƯVXY';
    final out = <KanaItem>[];
    for (var i = 0; i < letters.length; i++) {
      final upper = letters[i];
      if (age <= 4 && _viMarked.contains(upper)) continue;
      final glyph = lowercase ? upper.toLowerCase() : upper;
      out.add(KanaItem(
        id: lowercase ? 'vi_catch_${i}_lower' : 'vi_catch_$i',
        script: KanaScript.hiragana,
        kanaType: KanaType.basic,
        character: glyph,
        romaji: upper.toLowerCase(),
        pronunciation: upper.toLowerCase(),
        strokeCount: 1,
        ageMin: 3,
        ageMax: 7,
        difficulty: 1,
      ));
    }
    return out;
  }

  bool isCorrect(KanaItem tapped) => tapped.id == target.id;

  /// Whether a small child could take [a] for [b]: they look alike, or
  /// they sound alike when Mai reads them.
  static bool confusable(KanaItem a, KanaItem b) => looksAlike(a, b) || soundsAlike(a, b);

  static bool looksAlike(KanaItem a, KanaItem b) => _sameGroup(_lookGroups, a.character, b.character);

  static bool soundsAlike(KanaItem a, KanaItem b) {
    if (a.id.startsWith('vi_') || b.id.startsWith('vi_')) {
      return _sameGroup(_viSoundGroups, a.character.toUpperCase(), b.character.toUpperCase());
    }
    // Kana: same consonant row (よ/ゆ, か/こ) or a known near-homophone.
    final ra = _kanaRow(a.romaji);
    final rb = _kanaRow(b.romaji);
    if (ra.isNotEmpty && ra == rb) return true;
    return _sameGroup(_kanaSoundGroups, a.character, b.character);
  }

  static bool _sameGroup(List<String> groups, String a, String b) {
    if (a == b) return true;
    for (final g in groups) {
      if (g.contains(a) && g.contains(b)) return true;
    }
    return false;
  }

  /// "ka" → "k", "shi" → "s", "chi"/"tsu" → "t", "fu" → "h"; vowels → "".
  static String _kanaRow(String romaji) {
    const special = {'shi': 's', 'chi': 't', 'tsu': 't', 'fu': 'h', 'n': 'n'};
    final s = special[romaji];
    if (s != null) return s;
    if (romaji.length <= 1) return '';
    return romaji.substring(0, romaji.length - 1);
  }

  static const _viMarked = 'ĂÂĐÊÔƠƯ';

  /// Shapes a 3–5 year old mixes up. Each string is one group; a letter may
  /// sit in several groups.
  static const _lookGroups = [
    // Vietnamese capitals.
    'AĂÂ', 'EÊ', 'OÔƠ', 'UƯ', 'DĐ', 'OQ', 'CG', 'BPR', 'MNW', 'UV', 'IL', 'TY', 'KX',
    // Vietnamese lowercase.
    'aăâ', 'eê', 'oôơ', 'uư', 'dđ', 'bdpq', 'mnhu', 'il', 'ce', 'co', 'uv', 'vy', 'gq',
    // Hiragana.
    'あおめぬ', 'いりこ', 'こにた', 'うらつ', 'さきち', 'るろ', 'わねれ', 'はほま', 'よゆま', 'けは',
    'くへ', 'しもつ', 'そて', 'すむ', 'なた', 'とな',
    // Katakana.
    'シツ', 'ソンノリ', 'クケタワウフ', 'ユヨコロ', 'アマム', 'チテ', 'ナメ', 'ハル', 'セヤ', 'ラヲフ',
    'スヌ', 'エユ', 'カヤ', 'ニコ', 'トナ',
  ];

  /// Vietnamese letter names a child hears as the same sound.
  static const _viSoundGroups = ['CKQ', 'SX', 'IY', 'DR'];

  /// Kana that sound alike across rows.
  static const _kanaSoundGroups = ['すつ', 'しち', 'おを', 'スツ', 'シチ', 'オヲ', 'ずづ', 'じぢ'];
}
