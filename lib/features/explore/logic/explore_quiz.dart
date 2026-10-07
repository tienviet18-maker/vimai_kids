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
      final others = category.items.where((e) => e.id != target.id).toList()..shuffle(rnd);
      final choices = [target, ...others.take(choicesPerQuestion - 1)]..shuffle(rnd);
      questions.add(ExploreQuestion(target: target, choices: choices));
    }
    return ExploreQuizRound._(questions);
  }
}
