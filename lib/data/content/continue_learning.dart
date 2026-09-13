import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/providers.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/child_profile.dart';
import '../../domain/models/kana_item.dart';
import '../../domain/models/skill_mastery.dart';
import '../kana/hiragana_data.dart';
import '../kana/katakana_data.dart';

enum LearningWorld { japanese, vietnamese, math, thinking, creativity, games }

KanaItem? _kanaById(String id) {
  for (final item in hiraganaData) {
    if (item.id == id) return item;
  }
  for (final item in katakanaData) {
    if (item.id == id) return item;
  }
  return null;
}

class ContinueSuggestion {
  final LearningWorld world;
  final String route;
  final String prompt;
  final String glyph;
  final bool isReview;
  final bool needsChoice;

  const ContinueSuggestion({
    required this.world,
    required this.route,
    required this.prompt,
    required this.glyph,
    this.isReview = false,
    this.needsChoice = false,
  });
}

/// Deterministic, data-driven "what should this child do next?"
class ContinueLearningRecommender {
  const ContinueLearningRecommender();

  ContinueSuggestion recommend({
    required ChildProfile profile,
    required List<SkillMastery> mastery,
    DateTime? now,
    AppStrings? strings,
  }) {
    final copy = strings ?? const AppStrings(UiLang.vi);
    final active = mastery.where((e) => e.attempts > 0).toList();
    SkillMastery? pick;
    var review = false;

    final due = active.where((e) => e.needsReview).toList()
      ..sort(_byRecency);
    if (due.isNotEmpty) {
      pick = _preferLastWorld(due, profile.lastWorld);
      review = true;
    } else if (active.isNotEmpty) {
      active.sort(_byRecency);
      pick = _preferLastWorld(active, profile.lastWorld);
    }

    if (pick != null) {
      return _fromMastery(pick, review: review, copy: copy);
    }
    return ContinueSuggestion(
      world: LearningWorld.vietnamese,
      route: '/home',
      glyph: '★',
      prompt: copy.chooseToday,
      needsChoice: true,
    );
  }

  SkillMastery _preferLastWorld(List<SkillMastery> list, String lastWorld) {
    if (lastWorld.isNotEmpty) {
      final matched = list.where((e) => _worldName(e) == lastWorld).toList();
      if (matched.isNotEmpty) {
        matched.sort(_byRecency);
        return matched.first;
      }
    }
    return list.first;
  }

  String _worldName(SkillMastery item) {
    final skill = item.skill;
    final id = item.id;
    if (skill.startsWith('japanese') || id.startsWith('h_') || id.startsWith('k_')) return 'japanese';
    if (skill.startsWith('math')) return 'math';
    if (skill.startsWith('thinking')) return 'thinking';
    if (skill.startsWith('creativity')) return 'creativity';
    if (skill.startsWith('game')) return 'games';
    if (skill.startsWith('vietnamese') ||
        skill.contains('blend') ||
        skill.contains('phonics') ||
        skill.contains('rime') ||
        skill.contains('word') ||
        skill.contains('sentence')) {
      return 'vietnamese';
    }
    return '';
  }

  static int _byRecency(SkillMastery a, SkillMastery b) {
    final at = a.lastReviewed ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bt = b.lastReviewed ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bt.compareTo(at);
  }

  ContinueSuggestion _fromMastery(SkillMastery item, {required bool review, required AppStrings copy}) {
    final skill = item.skill;
    final id = item.id;

    if (skill.startsWith('japanese') || id.startsWith('h_') || id.startsWith('k_')) {
      final katakana = id.startsWith('k_') || skill.contains('katakana');
      final script = katakana ? 'katakana' : 'hiragana';
      final kanaId = (id.startsWith('h_') || id.startsWith('k_')) ? id : null;
      final route = kanaId == null
          ? '/japanese/learn/$script?type=basic'
          : '/japanese/learn/$script?id=$kanaId';
      final kana = _kanaById(id);
      final glyph = kana?.character ?? (katakana ? 'ア' : 'あ');
      return ContinueSuggestion(
        world: LearningWorld.japanese,
        route: route,
        glyph: glyph,
        isReview: review,
        prompt: review
            ? _t(copy, 'Ôn chữ $glyph nhé', 'Review $glyph', '$glyphをふくしゅう')
            : _t(copy, 'Hôm nay học chữ $glyph', 'Learn $glyph today', '$glyphをまなぼう'),
      );
    }

    if (skill.contains('blend') || skill.contains('phonics')) {
      return ContinueSuggestion(
        world: LearningWorld.vietnamese,
        route: '/vietnamese/blend',
        glyph: 'ba',
        isReview: review,
        prompt: _t(copy, 'Hôm nay cùng ghép âm', "Let's blend some sounds", 'おとをくみあわせよう'),
      );
    }
    if (skill.contains('rime')) {
      return ContinueSuggestion(
        world: LearningWorld.vietnamese,
        route: '/vietnamese/rimes',
        glyph: 'an',
        isReview: review,
        prompt: _t(copy, 'Hôm nay cùng ghép vần', "Let's practice rimes", 'いんをれんしゅう'),
      );
    }
    if (skill.contains('word')) {
      return ContinueSuggestion(
        world: LearningWorld.vietnamese,
        route: '/vietnamese/words',
        glyph: 'A',
        isReview: review,
        prompt: _t(copy, 'Hôm nay cùng đọc từ', "Let's read some words", 'たんごをよもう'),
      );
    }
    if (skill.contains('sentence')) {
      return ContinueSuggestion(
        world: LearningWorld.vietnamese,
        route: '/vietnamese/sentences',
        glyph: 'A',
        isReview: review,
        prompt: _t(copy, 'Hôm nay cùng đọc câu ngắn', "Let's read a short sentence", 'みじかい文をよもう'),
      );
    }
    if (skill.startsWith('vietnamese')) {
      return ContinueSuggestion(
        world: LearningWorld.vietnamese,
        route: '/vietnamese/learn',
        glyph: 'A',
        isReview: review,
        prompt: review
            ? _t(copy, 'Ôn chữ tiếng Việt nhé', 'Review Vietnamese letters', 'ベトナム語の文字をふくしゅう')
            : _t(copy, 'Hôm nay cùng học chữ tiếng Việt', "Let's learn Vietnamese letters", 'ベトナム語の文字をまなぼう'),
      );
    }

    if (skill.startsWith('math')) {
      final mathSkill = skill.startsWith('math.') ? skill.substring(5) : skill;
      final routeSkill = mathSkill.contains('.') ? mathSkill.split('.').last : mathSkill;
      return ContinueSuggestion(
        world: LearningWorld.math,
        route: '/math/play/$routeSkill',
        glyph: '3',
        isReview: review,
        prompt: _mathPrompt(routeSkill, copy),
      );
    }

    if (skill.startsWith('thinking')) {
      return ContinueSuggestion(
        world: LearningWorld.thinking,
        route: '/thinking',
        glyph: '◆',
        isReview: review,
        prompt: _t(copy, 'Tìm quy luật nhé!', 'Find the pattern!', 'ルールをみつけよう'),
      );
    }
    if (skill.startsWith('creativity')) {
      return ContinueSuggestion(
        world: LearningWorld.creativity,
        route: '/creativity',
        glyph: '✎',
        isReview: review,
        prompt: _t(copy, 'Thử một bức tranh mới', 'Make a new picture', 'あたらしい絵をかこう'),
      );
    }
    if (skill.startsWith('game')) {
      return ContinueSuggestion(
        world: LearningWorld.games,
        route: '/games',
        glyph: '▶',
        isReview: review,
        prompt: _t(copy, 'Chơi một game ngắn', 'Play a short game', 'みじかくあそぼう'),
      );
    }

    return ContinueSuggestion(
      world: LearningWorld.vietnamese,
      route: '/vietnamese/learn',
      glyph: 'A',
      isReview: review,
      prompt: _t(copy, 'Hôm nay cùng học chữ tiếng Việt', "Let's learn Vietnamese letters", 'ベトナム語の文字をまなぼう'),
    );
  }

  String _mathPrompt(String skill, AppStrings copy) {
    if (skill.contains('count')) {
      return _t(copy, 'Thử 5 câu nhận biết số', 'Try 5 number questions', 'かずを5もんやってみよう');
    }
    if (skill.contains('subtraction')) {
      return _t(copy, 'Hôm nay cùng làm phép trừ', "Let's practice subtraction", 'ひきざんをしよう');
    }
    if (skill.contains('addition')) {
      return _t(copy, 'Hôm nay cùng làm phép cộng', "Let's practice addition", 'たしざんをしよう');
    }
    return _t(copy, 'Thử 5 câu toán vui', 'Try 5 fun math questions', 'さんすうを5もん');
  }

  String _t(AppStrings copy, String vi, String en, String ja) {
    switch (copy.lang) {
      case UiLang.en:
        return en;
      case UiLang.ja:
        return ja;
      case UiLang.vi:
        return vi;
    }
  }
}

class ReviewPractice {
  static String title(SkillMastery item) {
    final kana = _kanaById(item.id);
    if (kana != null) return 'Chữ ${kana.character}';
    final skill = item.skill;
    if (skill.startsWith('japanese') || item.id.startsWith('h_') || item.id.startsWith('k_')) {
      return 'Tiếng Nhật';
    }
    if (skill.contains('blend') || skill.contains('phonics')) return 'Ghép âm';
    if (skill.contains('rime')) return 'Ghép vần';
    if (skill.contains('word')) return 'Từ đơn giản';
    if (skill.contains('sentence')) return 'Câu ngắn';
    if (skill.startsWith('vietnamese')) return 'Tiếng Việt';
    if (skill.startsWith('math')) return 'Toán';
    if (skill.startsWith('thinking')) return 'Tư duy';
    if (skill.startsWith('creativity')) return 'Sáng tạo';
    if (skill.startsWith('game')) return 'Trò chơi';
    return 'Học tập';
  }

  static String route(SkillMastery item) {
    return const ContinueLearningRecommender()
        .recommend(
          profile: ChildProfile(
            id: 'review',
            name: '',
            age: 5,
            avatar: 'peach',
            createdAt: DateTime(2026, 1, 1),
          ),
          mastery: [item],
          now: DateTime(2026, 1, 1),
        )
        .route;
  }
}

UiLang _uiLangFromProfile(ChildProfile? profile) {
  final stored = profile?.settings['uiLang'] as String?;
  if (stored == 'en') return UiLang.en;
  if (stored == 'ja') return UiLang.ja;
  return UiLang.vi;
}

/// Data-driven "what should this child do next?" for Home / discovery nest.
final continueLearningProvider = Provider<ContinueSuggestion>((ref) {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null) {
    return const ContinueSuggestion(
      world: LearningWorld.vietnamese,
      route: '/home',
      glyph: '★',
      prompt: '',
      needsChoice: true,
    );
  }
  final mastery = ref.watch(masteryRepositoryProvider).allForChild(profile.id);
  return const ContinueLearningRecommender().recommend(
    profile: profile,
    mastery: mastery,
    strings: AppStrings(_uiLangFromProfile(profile)),
  );
});
