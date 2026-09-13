import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/data/content/continue_learning.dart';
import 'package:mai_an_learning/data/content/progress_labels.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/domain/models/skill_mastery.dart';
import 'package:mai_an_learning/features/japanese/handwriting/stroke_order_board.dart';

void main() {
  test('progress labels never expose curriculum ids', () {
    const kana = SkillMastery(id: 'h_a', skill: 'japanese.recognize', attempts: 2, correct: 1);
    expect(ProgressLabels.title(kana), 'Chữ あ');
    expect(ProgressLabels.title(kana).contains('h_a'), isFalse);
    const blend = SkillMastery(id: 'ph_be', skill: 'vietnamese.blend', attempts: 1, correct: 1);
    expect(ProgressLabels.title(blend), isNot(contains('ph_be')));
    expect(ProgressLabels.title(blend), isNot(contains('vietnamese.blend')));
    expect(ProgressLabels.subject(blend), 'Tiếng Việt');
  });

  test('continue learning japanese prompt uses the character, not the id', () {
    final suggestion = const ContinueLearningRecommender().recommend(
      profile: ChildProfile(id: 'p', name: 'Lan', age: 5, avatar: 'peach', createdAt: DateTime(2026, 1, 1)),
      mastery: [
        SkillMastery(
          id: 'h_ka',
          skill: 'japanese.hiragana',
          attempts: 3,
          correct: 2,
          lastReviewed: DateTime(2026, 8, 29, 10),
        ),
      ],
      now: DateTime(2026, 8, 29, 12),
    );
    expect(suggestion.glyph, 'か');
    expect(suggestion.prompt.contains('h_ka'), isFalse);
    expect(suggestion.prompt.contains('か'), isTrue);
  });

  test('stroke-order catalog loads KanjiVG paths for あ, not an empty stub', () {
    final raw = File('assets/content/japanese/strokes/catalog.json').readAsStringSync();
    StrokeOrderCatalog.loadJson(raw);
    final catalog = StrokeOrderCatalog();
    expect(catalog.pathsFor('h_a').length, 3);
    expect(catalog.hasPaths('h_a'), isTrue);
    expect(catalog.pathsFor('k_a'), isNotEmpty);
  });
}
