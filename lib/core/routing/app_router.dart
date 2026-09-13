import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import 'vimai_route_observer.dart';
import '../../features/creativity/presentation/creativity_screen.dart';
import '../../features/creativity/presentation/drawing_canvas_screen.dart';
import '../../features/games/presentation/games_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/japanese/kana_library/presentation/kana_library_screen.dart';
import '../../features/japanese/presentation/japanese_home_screen.dart';
import '../../features/japanese/presentation/kana_lesson_screen.dart';
import '../../features/math/presentation/math_screen.dart';
import '../../features/onboarding/presentation/create_profile_screen.dart';
import '../../features/onboarding/presentation/profile_select_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/parent/presentation/parent_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/thinking/presentation/thinking_screen.dart';
import '../../features/vietnamese/presentation/vietnamese_activities.dart';
import '../../features/vietnamese/presentation/vietnamese_letter_lesson_screen.dart';
import '../../features/vietnamese/presentation/vietnamese_screen.dart';
import '../../domain/models/kana_item.dart';
import '../../domain/content/content_item.dart';
import '../../data/repositories/profile_repository.dart';

List<ContentItem> _viForAge(WidgetRef ref, List<ContentItem> Function(WidgetRef ref) load) {
  final age = ref.watch(currentProfileProvider)?.age ?? 5;
  final items = load(ref).where((e) => e.suitableForAge(age)).toList();
  return items;
}

final goRouter = GoRouter(
  initialLocation: '/',
  observers: [vimaiRouteObserver],
  routes: [
    GoRoute(path: '/', builder: (context, state) => const InitialGatekeeper()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/profiles', builder: (context, state) => const ProfileSelectScreen()),
    GoRoute(path: '/onboarding/create_profile', builder: (context, state) => const CreateProfileScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/japanese', builder: (context, state) => const JapaneseHomeScreen()),
    GoRoute(
      path: '/japanese/library/:script',
      builder: (context, state) {
        final scriptStr = state.pathParameters['script']!;
        final script = scriptStr == 'hiragana' ? KanaScript.hiragana : KanaScript.katakana;
        return KanaLibraryScreen(script: script);
      },
    ),
    GoRoute(
      path: '/japanese/learn/:script',
      builder: (context, state) {
        final scriptStr = state.pathParameters['script']!;
        final script = scriptStr == 'katakana' ? KanaScript.katakana : KanaScript.hiragana;
        return KanaLessonScreen(
          script: script,
          startId: state.uri.queryParameters['id'],
          typeName: state.uri.queryParameters['type'],
          startMode: state.uri.queryParameters['mode'],
        );
      },
    ),
    GoRoute(
      path: '/kana/:id/look',
      redirect: (context, state) {
        final id = state.pathParameters['id']!;
        final script = id.startsWith('k_') ? 'katakana' : 'hiragana';
        return '/japanese/learn/$script?id=$id';
      },
    ),
    GoRoute(
      path: '/kana/:id/listen',
      redirect: (context, state) => '/kana/${state.pathParameters['id']}/look',
    ),
    GoRoute(
      path: '/kana/:id/read',
      redirect: (context, state) => '/kana/${state.pathParameters['id']}/look',
    ),
    GoRoute(
      path: '/kana/:id/recognize',
      redirect: (context, state) => '/kana/${state.pathParameters['id']}/look',
    ),
    GoRoute(
      path: '/kana/:id/write',
      redirect: (context, state) => '/kana/${state.pathParameters['id']}/look',
    ),
    GoRoute(path: '/math', builder: (context, state) => const MathScreen()),
    GoRoute(path: '/math/play/:skill', builder: (context, state) => MathQuizScreen(skill: state.pathParameters['skill']!)),
    GoRoute(path: '/games', builder: (context, state) => const GamesScreen()),
    GoRoute(
      path: '/games/catch-kana',
      builder: (context, state) {
        final alphabet = state.uri.queryParameters['alphabet'] ?? 'hiragana';
        final kind = switch (alphabet) {
          'katakana' => CatchAlphabet.katakana,
          'vietnamese' => CatchAlphabet.vietnamese,
          _ => CatchAlphabet.hiragana,
        };
        return CatchKanaGame(alphabet: kind);
      },
    ),
    GoRoute(path: '/games/listen-kana', builder: (context, state) => const ListenKanaGame()),
    GoRoute(path: '/games/match-kana', builder: (context, state) => const MatchKanaGame()),
    GoRoute(path: '/games/math-rocket', builder: (context, state) => const MathRocketGame()),
    GoRoute(path: '/games/number-train', builder: (context, state) => const NumberTrainGame()),
    GoRoute(path: '/games/feed-animal', builder: (context, state) => const FeedAnimalGame()),
    GoRoute(path: '/games/find-similar', builder: (context, state) => const FindSimilarGame()),
    GoRoute(path: '/progress', builder: (context, state) => const ProgressScreen()),
    GoRoute(path: '/vietnamese', builder: (context, state) => const VietnameseScreen()),
    GoRoute(path: '/vietnamese/alphabet', builder: (context, state) => const VietnameseAlphabetGridScreen()),
    GoRoute(
      path: '/vietnamese/learn',
      builder: (context, state) => VietnameseLetterLessonScreen(
        startId: state.uri.queryParameters['id'],
        startMode: state.uri.queryParameters['mode'],
      ),
    ),
    GoRoute(
      path: '/vietnamese/letter/:id',
      redirect: (context, state) => '/vietnamese/learn?id=${state.pathParameters['id']}',
    ),
    GoRoute(
      path: '/vietnamese/blend',
      builder: (context, state) => VietnameseQuizListScreen(
        title: 'Ghép âm',
        skill: 'vietnamese.blend',
        loader: (ref) => _viForAge(ref, (r) => r.watch(contentRepositoryProvider).getVietnamesePhonics()),
      ),
    ),
    GoRoute(
      path: '/vietnamese/rimes',
      builder: (context, state) => VietnameseQuizListScreen(
        title: 'Ghép vần',
        skill: 'vietnamese.rime',
        loader: (ref) => _viForAge(ref, (r) => r.watch(contentRepositoryProvider).getVietnameseRimes()),
      ),
    ),
    GoRoute(
      path: '/vietnamese/words',
      builder: (context, state) => VietnameseQuizListScreen(
        title: 'Từ đơn giản',
        skill: 'vietnamese.words',
        loader: (ref) => _viForAge(ref, (r) => r.watch(contentRepositoryProvider).getVietnameseWords()),
      ),
    ),
    GoRoute(
      path: '/vietnamese/vocabulary',
      builder: (context, state) => VietnameseQuizListScreen(
        title: 'Từ vựng',
        skill: 'vietnamese.words',
        loader: (ref) => _viForAge(ref, (r) => r.watch(contentRepositoryProvider).getVietnameseVocabulary()),
      ),
    ),
    GoRoute(
      path: '/vietnamese/sentences',
      builder: (context, state) => VietnameseQuizListScreen(
        title: 'Câu ngắn',
        skill: 'vietnamese.sentence',
        loader: (ref) => _viForAge(ref, (r) => r.watch(contentRepositoryProvider).getVietnameseSentences()),
      ),
    ),
    GoRoute(path: '/vietnamese/choose', builder: (context, state) => const VietnameseChooseLetterScreen()),
    GoRoute(path: '/vietnamese/game', builder: (context, state) => const VietnameseLetterGameScreen()),
    GoRoute(path: '/thinking', builder: (context, state) => const ThinkingScreen()),
    GoRoute(
      path: '/creativity',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'];
        return CreativityScreen(initialMode: mode);
      },
    ),
    GoRoute(path: '/drawing', builder: (context, state) => const DrawingCanvasScreen()),
    GoRoute(path: '/creativity/draw', builder: (context, state) => const DrawingCanvasScreen()),
    GoRoute(path: '/parent', builder: (context, state) => const ParentScreen()),
  ],
);

class InitialGatekeeper extends ConsumerStatefulWidget {
  const InitialGatekeeper({super.key});

  @override
  ConsumerState<InitialGatekeeper> createState() => _InitialGatekeeperState();
}

class _InitialGatekeeperState extends ConsumerState<InitialGatekeeper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profiles = ref.read(profileRepositoryProvider).getAllProfiles();
      if (profiles.isEmpty) {
        context.go('/welcome');
      } else {
        context.go('/profiles');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
