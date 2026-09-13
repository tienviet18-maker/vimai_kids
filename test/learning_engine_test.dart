import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/domain/learning/mastery_engine.dart';
import 'package:mai_an_learning/domain/learning/spaced_repetition.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/domain/models/skill_mastery.dart';

void main() {
  test('spaced repetition shortens interval on incorrect answers', () {
    final now = DateTime(2026, 1, 1);
    final fail = SpacedRepetition.nextReview(correct: false, streakAfterAnswer: 0, now: now);
    final pass = SpacedRepetition.nextReview(correct: true, streakAfterAnswer: 3, now: now);
    expect(fail.isBefore(pass), isTrue);
    expect(fail.difference(now).inMinutes, 5);
    expect(pass.difference(now).inDays, 4);
  });

  test('progress is zero when there is no learning history', () {
    expect(MasteryEngine().overallPercent(const []), 0);
    expect(MasteryEngine().overallPercent([const SkillMastery(id: 'x', skill: 's')]), 0);
  });

  test('progress is calculated from recorded mastery', () {
    final engine = MasteryEngine();
    var a = const SkillMastery(id: 'a', skill: 'japanese');
    a = engine.recordAttempt(current: a, correct: true);
    a = engine.recordAttempt(current: a, correct: true);
    expect(a.attempts, 2);
    expect(a.mastery, greaterThan(0));
    expect(engine.overallPercent([a]), a.mastery);
  });

  test('child profile round-trips without hardcoded names', () {
    final profile = ChildProfile(
      id: 'id-1',
      name: 'Bé Na',
      age: 5,
      avatar: '🐼',
      createdAt: DateTime(2026, 1, 1),
    );
    final copy = ChildProfile.fromJson(profile.toJson());
    expect(copy.name, 'Bé Na');
    expect(copy.age, 5);
    expect(copy.name, isNot('Mai An'));
  });
}
