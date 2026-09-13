import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/data/content/content_repository.dart';
import 'package:mai_an_learning/data/content/daily_plan_generator.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DailyPlan contains valid activities', () async {
    final repo = ContentRepository();
    await repo.loadAllContent();

    final generator = DailyPlanGenerator(repo);
    final profile = ChildProfile(
      id: 'test',
      name: 'Bé Na',
      age: 5,
      avatar: '🐼',
      createdAt: DateTime.now(),
    );

    final plan = generator.generatePlan(profile);
    expect(plan.recommendedActivities.length, greaterThanOrEqualTo(2));
    expect(plan.recommendedActivities.every((e) => e.id.isNotEmpty), isTrue);
  });
}
