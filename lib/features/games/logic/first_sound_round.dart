import 'dart:math';

/// A picture word for "Âm đầu là gì?": the word, the emoji that clearly
/// shows it, and its bundled word clip (from assets/data/vietnamese/words.json).
class FirstSoundWord {
  const FirstSoundWord(this.word, this.emoji, this.audioId);

  final String word;
  final String emoji;
  final String audioId;

  /// Written onset ("ch", "ngh", "b"…), or null when the word starts with a vowel.
  String? get onset => FirstSound.onsetOf(word);

  /// What the onset *sounds* like: c/k → c, g/gh → g, ng/ngh → ng.
  String get sound => FirstSound.soundOf(onset!);
}

/// Sound-first onset rules for Vietnamese (consonants are said "bờ", "cờ",
/// "chờ"…, never by letter name).
class FirstSound {
  FirstSound._();

  static const _clusters = ['ngh', 'ng', 'nh', 'ch', 'tr', 'th', 'kh', 'ph', 'gh', 'gi', 'qu'];
  static const _singles = 'bcdđghklmnprstvx';

  /// The written onset of [word]'s first syllable, or null for a vowel start.
  static String? onsetOf(String word) {
    final w = word.trim().toLowerCase();
    if (w.isEmpty) return null;
    for (final c in _clusters) {
      // "gi" + vowel is an onset; "gì"/"gìn" still start with the gi sound.
      if (w.startsWith(c) && w.length > c.length) return c;
    }
    final first = w[0];
    return _singles.contains(first) ? first : null;
  }

  /// Spellings that make the same sound share one key.
  static String soundOf(String onset) => switch (onset) {
        'k' => 'c',
        'gh' => 'g',
        'ngh' => 'ng',
        _ => onset,
      };

  /// Bundled clip that says the consonant sound: v_b "bờ", v_dd "đờ",
  /// v_c_ch "chờ"…
  static String clipFor(String sound) {
    if (sound == 'đ') return 'v_dd';
    if (sound.length == 1) return 'v_$sound';
    return 'v_c_$sound';
  }

  /// How the onset is written on screen ("B", "Ch", "Ngh").
  static String glyphFor(String onset) => onset[0].toUpperCase() + onset.substring(1);

  /// Sounds that are said the same in the northern voice Mai uses: never put
  /// them in one round.
  static const _sameSound = {'d', 'gi', 'r'};

  /// Pairs a young ear easily mixes up: only used on the hardest level.
  static const near = <String, List<String>>{
    'd': ['đ'],
    'đ': ['d'],
    'ch': ['tr'],
    'tr': ['ch', 't'],
    's': ['x'],
    'x': ['s'],
    'n': ['ng', 'l', 'nh'],
    'ng': ['n'],
    'nh': ['n'],
    'l': ['n'],
    't': ['th', 'tr'],
    'th': ['t'],
  };

  /// True when [a] and [b] could not be told apart by ear at all.
  static bool sameSound(String a, String b) => a == b || (_sameSound.contains(a) && _sameSound.contains(b));

  static bool isNear(String a, String b) => near[a]?.contains(b) == true || near[b]?.contains(a) == true;

  /// Sounds a 3-year-old hears apart most easily (easy level).
  static const easySounds = {'b', 'm', 'c', 'h', 'v', 'g', 's', 'l', 't', 'n'};

  /// Picture words whose emoji clearly shows the word. Abstract words,
  /// vowel-initial words and duplicate pictures are left out.
  static const words = [
    FirstSoundWord('bà', '👵', 'v_word_baf'),
    FirstSoundWord('bò', '🐮', 'v_word_bof'),
    FirstSoundWord('bé', '👶', 'v_word_bes'),
    FirstSoundWord('bóng', '⚽', 'v_word_bosng'),
    FirstSoundWord('bánh', '🍞', 'v_word_basnh'),
    FirstSoundWord('bút', '✏️', 'v_word_bust'),
    FirstSoundWord('biển', '🌊', 'v_word_bieern'),
    FirstSoundWord('cá', '🐟', 'v_word_cas'),
    FirstSoundWord('cây', '🌳', 'v_word_caay'),
    FirstSoundWord('cam', '🍊', 'v_word_cam'),
    FirstSoundWord('cơm', '🍚', 'v_word_cowm'),
    FirstSoundWord('cửa', '🚪', 'v_word_cuwra'),
    FirstSoundWord('kẹo', '🍬', 'v_word_kejo'),
    FirstSoundWord('kem', '🍦', 'v_word_kem'),
    FirstSoundWord('kéo', '✂️', 'v_word_keso'),
    FirstSoundWord('chó', '🐶', 'v_word_chos'),
    FirstSoundWord('chim', '🐦', 'v_word_chim'),
    FirstSoundWord('chuối', '🍌', 'v_word_chuoosi'),
    FirstSoundWord('chân', '🦶', 'v_word_chaan'),
    FirstSoundWord('chuông', '🔔', 'v_word_chuoong'),
    FirstSoundWord('dưa', '🍉', 'v_word_duwa'),
    FirstSoundWord('dâu', '🍓', 'v_word_daau'),
    FirstSoundWord('đèn', '💡', 'v_word_ddefn'),
    FirstSoundWord('đũa', '🥢', 'v_word_dduxa'),
    FirstSoundWord('đàn', '🎸', 'v_word_ddafn'),
    FirstSoundWord('gà', '🐔', 'v_word_gaf'),
    FirstSoundWord('gấu', '🧸', 'v_word_gaasu'),
    FirstSoundWord('ghế', '🪑', 'v_word_ghees'),
    FirstSoundWord('gạo', '🌾', 'v_word_gajo'),
    FirstSoundWord('giấy', '📄', 'v_word_giaasy'),
    FirstSoundWord('hoa', '🌸', 'v_word_hoa'),
    FirstSoundWord('heo', '🐷', 'v_word_heo'),
    FirstSoundWord('hộp', '📦', 'v_word_hoojp'),
    FirstSoundWord('hát', '🎤', 'v_word_hast'),
    FirstSoundWord('khóc', '😭', 'v_word_khosc'),
    FirstSoundWord('lá', '🍃', 'v_word_las'),
    FirstSoundWord('mèo', '🐱', 'v_word_mefo'),
    FirstSoundWord('mẹ', '👩', 'v_word_mej'),
    FirstSoundWord('mũ', '🧢', 'v_word_mux'),
    FirstSoundWord('mắt', '👁️', 'v_word_mawst'),
    FirstSoundWord('mũi', '👃', 'v_word_muxi'),
    FirstSoundWord('mưa', '🌧️', 'v_word_muwa'),
    FirstSoundWord('mây', '☁️', 'v_word_maay'),
    FirstSoundWord('nước', '💧', 'v_word_nuwowsc'),
    FirstSoundWord('nồi', '🍲', 'v_word_noofi'),
    FirstSoundWord('núi', '⛰️', 'v_word_nusi'),
    FirstSoundWord('nắng', '☀️', 'v_word_nawsng'),
    FirstSoundWord('ngựa', '🐴', 'v_word_nguwja'),
    FirstSoundWord('ngủ', '😴', 'v_word_ngur'),
    FirstSoundWord('nhà', '🏠', 'v_word_nhaf'),
    FirstSoundWord('nho', '🍇', 'v_word_nho'),
    FirstSoundWord('nhạc', '🎵', 'v_word_nhajc'),
    FirstSoundWord('phở', '🍜', 'v_word_phowr'),
    FirstSoundWord('rau', '🥬', 'v_word_rau'),
    FirstSoundWord('răng', '🦷', 'v_word_rawng'),
    FirstSoundWord('rừng', '🌲', 'v_word_ruwfng'),
    FirstSoundWord('sữa', '🥛', 'v_word_suwxa'),
    FirstSoundWord('sách', '📖', 'v_word_sasch'),
    FirstSoundWord('sao', '⭐', 'v_word_sao'),
    FirstSoundWord('tôm', '🦐', 'v_word_toom'),
    FirstSoundWord('táo', '🍎', 'v_word_taso'),
    FirstSoundWord('tay', '✋', 'v_word_tay'),
    FirstSoundWord('tai', '👂', 'v_word_tai'),
    FirstSoundWord('tàu', '🚆', 'v_word_tafu'),
    FirstSoundWord('thỏ', '🐰', 'v_word_thor'),
    FirstSoundWord('thìa', '🥄', 'v_word_thifa'),
    FirstSoundWord('thuyền', '⛵', 'v_word_thuyeefn'),
    FirstSoundWord('thịt', '🍖', 'v_word_thijt'),
    FirstSoundWord('trà', '🍵', 'v_word_traf'),
    FirstSoundWord('trăng', '🌙', 'v_word_trawng'),
    FirstSoundWord('trứng', '🥚', 'v_word_truwsng'),
    FirstSoundWord('trống', '🥁', 'v_word_troosng'),
    FirstSoundWord('vịt', '🦆', 'v_word_vijt'),
    FirstSoundWord('voi', '🐘', 'v_word_voi'),
    FirstSoundWord('xe', '🚗', 'v_word_xe'),
    FirstSoundWord('xoài', '🥭', 'v_word_xoafi'),
  ];

  /// Words grouped by onset sound.
  static final Map<String, List<FirstSoundWord>> bySound = () {
    final out = <String, List<FirstSoundWord>>{};
    for (final w in words) {
      if (w.onset == null) continue;
      out.putIfAbsent(w.sound, () => []).add(w);
    }
    return out;
  }();

  static const maxLevel = 2;

  /// Cards shown at [level]: 3, then 4 on the hardest level.
  static int cardsFor(int level) => level >= 2 ? 4 : 3;
}

/// One round: Mai says a consonant sound, the child picks the one picture
/// whose word starts with it.
class FirstSoundRound {
  FirstSoundRound._(this.answer, this.cards, this.level);

  final FirstSoundWord answer;
  final List<FirstSoundWord> cards;
  final int level;

  String get sound => answer.sound;
  String get soundClip => FirstSound.clipFor(sound);
  String get glyph => FirstSound.glyphFor(answer.onset!);
  String get id => '${answer.word}_$level';

  bool isCorrect(FirstSoundWord w) => w.sound == sound;

  /// Level 0: easy, very different sounds. Level 1: any sounds, still far
  /// apart. Level 2: four cards and one look-alike sound (d/đ, ch/tr, s/x, n/ng…).
  static FirstSoundRound generate({
    required int level,
    required Random random,
    Iterable<String> recentSounds = const [],
    Iterable<String> recentWords = const [],
  }) {
    level = level.clamp(0, FirstSound.maxLevel);
    final bySound = FirstSound.bySound;
    List<String> targetsFor(int lv) {
      final all = bySound.keys.toList();
      if (lv == 0) return all.where(FirstSound.easySounds.contains).toList();
      if (lv == 2) {
        return all
            .where((s) => FirstSound.near[s]?.any((n) => bySound.containsKey(n) && !FirstSound.sameSound(s, n)) == true)
            .toList();
      }
      return all;
    }

    var targets = targetsFor(level).where((s) => !recentSounds.contains(s)).toList();
    if (targets.isEmpty) targets = targetsFor(level);
    final sound = targets[random.nextInt(targets.length)];
    var options = bySound[sound]!.where((w) => !recentWords.contains(w.word)).toList();
    if (options.isEmpty) options = bySound[sound]!;
    final answer = options[random.nextInt(options.length)];

    final picked = <String>[sound];
    final cards = <FirstSoundWord>[answer];
    bool fits(String s, {bool allowNearTarget = false}) {
      for (final p in picked) {
        if (FirstSound.sameSound(s, p)) return false;
        if (FirstSound.isNear(s, p) && !(allowNearTarget && p == sound)) return false;
      }
      return true;
    }

    void addFrom(String s) {
      final pool = bySound[s]!.where((w) => cards.every((c) => c.emoji != w.emoji)).toList();
      if (pool.isEmpty) return;
      picked.add(s);
      cards.add(pool[random.nextInt(pool.length)]);
    }

    final count = FirstSound.cardsFor(level);
    if (level == 2) {
      final nears = FirstSound.near[sound]!.where((s) => bySound.containsKey(s) && fits(s, allowNearTarget: true)).toList();
      if (nears.isNotEmpty) addFrom(nears[random.nextInt(nears.length)]);
    }
    final pool = (level == 0 ? FirstSound.easySounds.where(bySound.containsKey) : bySound.keys).toList()..shuffle(random);
    for (final s in pool) {
      if (cards.length >= count) break;
      if (fits(s)) addFrom(s);
    }
    // Safety net: any sound that is at least not the same as one already in.
    if (cards.length < count) {
      for (final s in bySound.keys.toList()..shuffle(random)) {
        if (cards.length >= count) break;
        if (picked.every((p) => !FirstSound.sameSound(s, p))) addFrom(s);
      }
    }
    cards.shuffle(random);
    return FirstSoundRound._(answer, cards, level);
  }
}
