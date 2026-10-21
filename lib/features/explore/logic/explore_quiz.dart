import 'dart:math';

import '../data/explore_catalog.dart';

/// One "Đố bé" question: find [target] among four pictures.
class ExploreQuestion {
  const ExploreQuestion({required this.target, required this.choices});

  final ExploreItem target;
  final List<ExploreItem> choices;

  String get prompt => target.question;
}

/// Builds a quiz round for a category: [count] different targets, each
/// shown with three other pictures from the same topic.
class ExploreQuizRound {
  ExploreQuizRound._(this.questions);

  static const defaultLength = 6;
  static const choicesPerQuestion = 4;

  final List<ExploreQuestion> questions;

  factory ExploreQuizRound.generate(ExploreCategory category, {Random? random, int count = defaultLength}) {
    final rnd = random ?? Random();
    final pool = [...category.items]..shuffle(rnd);
    final n = min(count, pool.length);
    final questions = <ExploreQuestion>[];
    for (var i = 0; i < n; i++) {
      final target = pool[i];
      // A picture whose name contains the target's ("Đâu là con cá?" next to
      // "con cá heo", "máy bay" next to "máy bay trực thăng") is also right.
      final clear = category.items.where((e) => e.id != target.id && !namesOverlap(e.name, target.name)).toList()
        ..shuffle(rnd);
      final rest = category.items.where((e) => e.id != target.id && !clear.contains(e)).toList()..shuffle(rnd);
      final others = [...clear, ...rest];
      final choices = [target, ...others.take(choicesPerQuestion - 1)]..shuffle(rnd);
      questions.add(ExploreQuestion(target: target, choices: choices));
    }
    return ExploreQuizRound._(questions);
  }
}

const _classifiers = {'con', 'quả', 'cái', 'củ', 'chùm', 'bắp', 'cây', 'hạt', 'đôi', 'bộ', 'lá', 'bông', 'ngọn', 'cơn', 'đám', 'giọt', 'tia', 'chú', 'cô', 'bác'};

/// True when one name's words (without the classifier "con", "quả", …) sit
/// inside the other's: "con cá" / "con cá heo", "quả đào" / "quả anh đào".
bool namesOverlap(String a, String b) {
  List<String> core(String s) {
    final w = s.toLowerCase().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    return w.length > 1 && _classifiers.contains(w.first) ? w.sublist(1) : w;
  }

  bool inside(List<String> small, List<String> big) {
    if (small.isEmpty || small.length > big.length) return false;
    for (var i = 0; i + small.length <= big.length; i++) {
      var ok = true;
      for (var j = 0; j < small.length && ok; j++) {
        ok = big[i + j] == small[j];
      }
      if (ok) return true;
    }
    return false;
  }

  final x = core(a), y = core(b);
  return inside(x, y) || inside(y, x);
}
