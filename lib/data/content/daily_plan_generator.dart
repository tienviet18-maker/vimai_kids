import '../../domain/content/content_item.dart';
import '../../domain/content/daily_plan.dart';
import '../../domain/models/child_profile.dart';
import '../../domain/models/skill_mastery.dart';
import 'content_repository.dart';
import 'continue_learning.dart';
import 'math_generator.dart';

class DailyPlanGenerator {
  final ContentRepository _contentRepo;
  final MathQuestionGenerator _mathGenerator;

  DailyPlanGenerator(this._contentRepo, {MathQuestionGenerator? mathGenerator})
      : _mathGenerator = mathGenerator ?? MathQuestionGenerator();

  DailyPlan generatePlan(ChildProfile profile, {List<SkillMastery> mastery = const []}) {
    final age = profile.age;
    final activities = <ContentItem>[];

    final suggestion = const ContinueLearningRecommender().recommend(
      profile: profile,
      mastery: mastery,
    );
    activities.add(
      ContentItem(
        id: 'continue_${suggestion.world.name}',
        subject: ContentSubject.japanese,
        ageMin: 3,
        ageMax: 7,
        level: 1,
        skill: suggestion.world.name,
        difficulty: 1,
        title: suggestion.prompt,
        instruction: suggestion.prompt,
        metadata: {'route': suggestion.route},
      ),
    );

    final mathSkill = age <= 3
        ? 'counting'
        : (age == 4
            ? 'addition_under_10'
            : (age == 5 ? 'addition_under_20' : (age == 6 ? 'addition_under_50' : 'addition_under_100')));
    final math = _mathGenerator.generateBySkill(mathSkill, age: age);
    activities.add(math.copyWithRoute('/math/play/$mathSkill'));

    final alphabet = _contentRepo.getVietnameseAlphabet();
    if (alphabet.isNotEmpty) {
      final letter = alphabet.first;
      activities.add(
        letter.copyWithRoute('/vietnamese/learn?id=${letter.id}'),
      );
    }

    activities.add(
      const ContentItem(
        id: 'game_catch_kana',
        subject: ContentSubject.game,
        ageMin: 3,
        ageMax: 7,
        level: 1,
        skill: 'game',
        difficulty: 1,
        title: 'Trò chơi',
        instruction: 'Bắt chữ Hiragana',
        metadata: {'route': '/games/catch-kana'},
      ),
    );

    return DailyPlan(
      date: DateTime.now(),
      recommendedActivities: activities,
    );
  }
}

extension on ContentItem {
  ContentItem copyWithRoute(String route) {
    return ContentItem(
      id: id,
      subject: subject,
      ageMin: ageMin,
      ageMax: ageMax,
      level: level,
      skill: skill,
      difficulty: difficulty,
      title: title,
      instruction: instruction,
      question: question,
      answer: answer,
      choices: choices,
      imageAsset: imageAsset,
      audioAsset: audioAsset,
      metadata: {...?metadata, 'route': route},
      tags: tags,
    );
  }
}
