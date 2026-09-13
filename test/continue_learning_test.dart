import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/data/content/continue_learning.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/domain/models/skill_mastery.dart';

void main() {
  ChildProfile profile({int age = 5}) => ChildProfile(
        id: 'p',
        name: 'Lan',
        age: age,
        avatar: 'peach',
        createdAt: DateTime(2026, 1, 1),
      );

  test('recent Japanese mastery continues Japanese, not Vietnamese', () {
    final suggestion = const ContinueLearningRecommender().recommend(
      profile: profile(),
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
    expect(suggestion.world, LearningWorld.japanese);
    expect(suggestion.route.contains('japanese'), isTrue);
    expect(suggestion.route.contains('h_ka'), isTrue);
  });

  test('recent math mastery continues math', () {
    final suggestion = const ContinueLearningRecommender().recommend(
      profile: profile(age: 6),
      mastery: [
        SkillMastery(
          id: 'q1',
          skill: 'math.addition_under_10',
          attempts: 4,
          correct: 3,
          lastReviewed: DateTime(2026, 8, 29, 11),
        ),
      ],
      now: DateTime(2026, 8, 29, 12),
    );
    expect(suggestion.world, LearningWorld.math);
    expect(suggestion.route, '/math/play/addition_under_10');
  });

  test('fallback with no mastery asks the child to choose', () {
    final a = const ContinueLearningRecommender().recommend(
      profile: profile(age: 4),
      mastery: const [],
      now: DateTime(2026, 8, 29),
    );
    expect(a.needsChoice, isTrue);
    expect(a.prompt.contains('h_ka'), isFalse);
  });

  test('lastWorld prefers that subject among recent mastery', () {
    final suggestion = const ContinueLearningRecommender().recommend(
      profile: ChildProfile(
        id: 'p',
        name: 'Lan',
        age: 5,
        avatar: 'peach',
        createdAt: DateTime(2026, 1, 1),
        settings: const {'lastWorld': 'japanese'},
      ),
      mastery: [
        SkillMastery(
          id: 'q1',
          skill: 'math.addition_under_10',
          attempts: 4,
          correct: 3,
          lastReviewed: DateTime(2026, 8, 29, 11),
        ),
        SkillMastery(
          id: 'h_ka',
          skill: 'japanese.hiragana',
          attempts: 3,
          correct: 2,
          lastReviewed: DateTime(2026, 8, 29, 9),
        ),
      ],
      now: DateTime(2026, 8, 29, 12),
    );
    expect(suggestion.world, LearningWorld.japanese);
    expect(suggestion.route.contains('h_ka'), isTrue);
  });
}
