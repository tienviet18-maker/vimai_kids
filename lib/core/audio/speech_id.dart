import 'emoji_names.dart';

/// Stable clip id for a spoken Vietnamese line.
///
/// Any instruction, question or word a child sees can be voiced by bundling
/// `assets/audio/<id>.mp3`. The same FNV-1a hash is computed by
/// `tools/generate_missing_audio.py`, so the generator and the app always
/// agree on the filename without a lookup table.
class SpeechId {
  static const prefix = 'vi_say_';

  /// Normalises whitespace and trailing punctuation so "Đọc từ này" and
  /// "Đọc từ này." share one clip.
  static String normalize(String text) {
    var t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    while (t.isNotEmpty && '.!?…:'.contains(t[t.length - 1])) {
      t = t.substring(0, t.length - 1).trimRight();
    }
    return t.toLowerCase();
  }

  static String forText(String text) {
    final bytes = _utf8(normalize(text));
    var hash = 0x811c9dc5;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return '$prefix${hash.toRadixString(16).padLeft(8, '0')}';
  }

  /// The words a narrator says for an on-screen line: emoji and shapes become
  /// their Vietnamese names, math signs become words. Returns null when
  /// nothing speakable is left (a bare emoji row, a single letter label).
  static String? spokenText(String text) {
    var t = text.replaceAll('\u{FE0F}', '').replaceAll('\u{20E3}', '');
    // A picture label ("🍎 Táo", "🫖 ấm") already says the word: drop the picture.
    final label = RegExp(r'^([^A-Za-zÀ-ỹĐđ0-9]+)\s+([A-Za-zÀ-ỹĐđ].*)$').firstMatch(t.trim());
    if (label != null && !RegExp(r'[A-Za-zÀ-ỹĐđ]').hasMatch(label[1]!)) {
      final rest = label[2]!;
      if (!_emojiKeysLongestFirst.any(rest.contains)) t = rest;
    }
    t = t.replaceAllMapped(_emojiThenWord, (m) {
      final name = kEmojiSpokenNames[m[1]]!;
      final next = m[3]!;
      if (next.isNotEmpty && name.toLowerCase().split(' ').contains(next.toLowerCase())) return ' $next';
      return ' $name${m[2]}$next';
    });
    t = t
        .replaceAll('\u{200D}', '')
        .replaceAll(RegExp(r'\s*\+\s*'), ' cộng ')
        .replaceAll(RegExp(r'\s[-−]\s'), ' trừ ')
        .replaceAll(RegExp(r'\s*=\s*\?'), ' bằng mấy')
        .replaceAll(RegExp(r'\s*=\s*'), ' bằng ')
        .replaceAll(RegExp(r'\s+>\s+'), ' lớn hơn ')
        .replaceAll(RegExp(r'\s+<\s+'), ' bé hơn ')
        .replaceAll(RegExp(r'''[^0-9A-Za-zÀ-ỹĐđ\s,.!?…:;'"()%]'''), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(RegExp(r' ([,.!?…:;])'), (m) => m[1]!)
        .replaceAll(RegExp(r'([,:;])(?=[,.!?…:;])'), '')
        .trim();
    while (t.isNotEmpty && ',;:'.contains(t[0])) {
      t = t.substring(1).trimLeft();
    }
    if (!isSpeakable(t)) return null;
    final letters = t.replaceAll(RegExp(r'[^A-Za-zÀ-ỹĐđ]'), '');
    if (letters.length < 2) return null;
    return t;
  }

  /// Clip id for what [spokenText] would say, or null when nothing is said.
  static String? idForLine(String text) {
    final spoken = spokenText(text);
    return spoken == null ? null : forText(spoken);
  }

  // Longest names first so ZWJ sequences (👨‍⚕) win over their parts.
  static final RegExp _emojiThenWord =
      RegExp('(${_emojiKeysLongestFirst.map(RegExp.escape).join('|')})(\\s*)([A-Za-zÀ-ỹĐđ]*)');

  static final List<String> _emojiKeysLongestFirst = kEmojiSpokenNames.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  /// True when [text] has something to say (letters, not only emoji/shapes/digits).
  static bool isSpeakable(String text) => RegExp(r'[A-Za-zÀ-ỹĐđ]').hasMatch(text);

  static List<int> _utf8(String s) {
    final out = <int>[];
    for (final rune in s.runes) {
      if (rune < 0x80) {
        out.add(rune);
      } else if (rune < 0x800) {
        out..add(0xC0 | (rune >> 6))..add(0x80 | (rune & 0x3F));
      } else if (rune < 0x10000) {
        out..add(0xE0 | (rune >> 12))..add(0x80 | ((rune >> 6) & 0x3F))..add(0x80 | (rune & 0x3F));
      } else {
        out
          ..add(0xF0 | (rune >> 18))
          ..add(0x80 | ((rune >> 12) & 0x3F))
          ..add(0x80 | ((rune >> 6) & 0x3F))
          ..add(0x80 | (rune & 0x3F));
      }
    }
    return out;
  }
}
