import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/ai/mai_context.dart';
import '../../../core/game/webkit_answer_tap.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/session/session_binder.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/content/math_generator.dart';
import '../../../data/content/quiz_session.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/content/content_item.dart';
import '../../ai/presentation/mai_companion_widget.dart';
import '../../shared/widgets/choice_grid.dart';
import '../../shared/widgets/kids_scene.dart';
import '../../shared/widgets/kids_storybook.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_ui.dart';
import '../../shared/widgets/vimai_world.dart';

class MathScreen extends ConsumerWidget {
  const MathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final age = profile?.age ?? 5;
    final copy = AppStrings.of(profile, context);
    final cards = <_MathCard>[
      const _MathCard('Đếm số', '1', 'counting', VimaiColor.mint),
      const _MathCard('Nhận biết số', '2', 'number_recognition', VimaiColor.sky),
      const _MathCard('So sánh', '>', 'comparison', VimaiColor.peach),
      const _MathCard('Ghép số', '=', 'number_match', VimaiColor.sky),
      const _MathCard('Toán hình', '△', 'picture_math', VimaiColor.honey),
    ];
    if (age >= 4) {
      cards.add(const _MathCard('Cộng trong 5', '+', 'addition_under_5', VimaiColor.mint));
      cards.add(const _MathCard('Trừ trong 5', '−', 'subtraction_under_5', VimaiColor.coral));
      cards.add(const _MathCard('Cộng trong 10', '+', 'addition_under_10', VimaiColor.mint));
      cards.add(const _MathCard('Trừ trong 10', '−', 'subtraction_under_10', VimaiColor.coral));
      cards.add(const _MathCard('Quy luật số', '…', 'number_pattern', VimaiColor.grape));
      cards.add(const _MathCard('Tia số', '—', 'number_line', VimaiColor.teal));
    }
    if (age >= 5) {
      cards.add(const _MathCard('Cộng trong 20', '+', 'addition_under_20', VimaiColor.teal));
      cards.add(const _MathCard('Trừ trong 20', '−', 'subtraction_under_20', VimaiColor.peach));
      cards.add(const _MathCard('Số còn thiếu', '?', 'missing_number', VimaiColor.sky));
      cards.add(const _MathCard('Trước / sau', '<>', 'before_after', VimaiColor.grape));
      cards.add(const _MathCard('Phân loại số', 'n', 'classify_numbers', VimaiColor.honey));
    }
    if (age >= 6) {
      cards.add(const _MathCard('Cộng trong 50', '+', 'addition_under_50', VimaiColor.grape));
      cards.add(const _MathCard('Trừ trong 50', '−', 'subtraction_under_50', VimaiColor.peach));
      cards.add(const _MathCard('Toán lời văn', '…', 'word_problem', VimaiColor.coral));
      cards.add(const _MathCard('Sắp xếp số', '123', 'sort_numbers', VimaiColor.teal));
      cards.add(const _MathCard('Tìm phép tính', '+−', 'find_correct_op', VimaiColor.peach));
    }
    if (age >= 7) {
      cards.add(const _MathCard('Cộng trong 100', '+', 'addition_under_100', VimaiColor.grape));
      cards.add(const _MathCard('Trừ trong 100', '−', 'subtraction_under_100', VimaiColor.teal));
      cards.add(const _MathCard('So sánh phép tính', '>', 'compare_expressions', VimaiColor.grape));
      cards.add(const _MathCard('Điền + hoặc −', '□', 'fill_plus_minus', VimaiColor.mint));
      cards.add(const _MathCard('Chẵn / lẻ', '2', 'odd_even', VimaiColor.honey));
    }

    return KidsHubShell(
      title: copy.math,
      subtitle: copy.mathSub,
      accent: VimaiColor.mint,
      artAsset: VimaiArt.mathValley,
      onBack: () => context.pop(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          for (var i = 0; i < cards.length; i++)
            KidsChapterBanner(
              title: cards[i].title,
              subtitle: copy.mathAction,
              color: cards[i].color,
              glyph: cards[i].glyph,
              featured: i == 0,
              artAsset: i == 0 ? VimaiArt.mathValley : null,
              onTap: () => context.push('/math/play/${cards[i].skill}'),
            ),
        ],
      ),
    );
  }
}

class _MathCard {
  final String title;
  final String glyph;
  final String skill;
  final Color color;
  const _MathCard(this.title, this.glyph, this.skill, this.color);
}

class MathQuizScreen extends ConsumerStatefulWidget {
  final String skill;
  const MathQuizScreen({super.key, required this.skill});

  @override
  ConsumerState<MathQuizScreen> createState() => _MathQuizScreenState();
}

class _MathQuizScreenState extends ConsumerState<MathQuizScreen> {
  final _generator = MathQuestionGenerator();
  final _answerTap = WebKitAnswerTap(holdDuration: const Duration(milliseconds: 500));
  late QuizSession _session;
  AudioService? _audio;
  late final MaiCompanionController _maiController;

  ContentItem get _item => _session.item;
  int get _goal => _session.totalQuestions;

  @override
  void initState() {
    super.initState();
    _maiController = MaiCompanionController();
    final age = ref.read(currentProfileProvider)?.age ?? 5;
    _session = QuizSession(
      totalQuestions: GameCatalog.roundsForAge(age),
      generate: () => _generator.generateBySkill(widget.skill, age: age),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audio = ref.read(audioServiceProvider);
      final profile = ref.read(currentProfileProvider);
      _audio?.soundEnabled = profile?.soundEnabled ?? true;
      _audio?.bgmEnabled = profile?.bgmEnabled ?? true;
      _audio?.startGameBgm();
      unawaited(_audio!.playAudio(AudioService.introForMathSkill(widget.skill)));
    });
  }

  @override
  void dispose() {
    _answerTap.dispose();
    _audio?.stopGameBgm();
    _maiController.dispose();
    super.dispose();
  }

  void _fireMaiAndMastery({required bool ok, required String choice}) {
    final profile = ref.read(currentProfileProvider);
    final mathCtx = MaiContext(
      currentModule: 'math',
      currentLesson: widget.skill,
      currentActivity: 'quiz',
      currentQuestion: _item.question ?? _item.instruction,
      learningObjective: _item.instruction,
      expectedAnswer: _item.answer,
      choices: _item.choices,
      childAge: profile?.age ?? 5,
    );

    if (profile != null) {
      unawaited(
        ref.read(masteryRepositoryProvider).record(
              childId: profile.id,
              itemId: '${widget.skill}:${_item.question}',
              skill: 'math.${widget.skill}',
              correct: ok,
            ),
      );
    }

    // Never await Gemini / network on the answer critical path (Safari freeze).
    unawaited(() async {
      try {
        final mai = ref.read(maiAiServiceProvider);
        final resp = ok ? await mai.onCorrectAnswer(mathCtx) : await mai.onIncorrectAnswer(mathCtx);
        if (!mounted) return;
        _maiController.showResponse(resp);
      } catch (e) {
        debugPrint('[MathQuiz] Mai side-effect ignored: $e');
      }
    }());
  }

  void _onChoice(String value) {
    if (_session.finished || _answerTap.locked) return;
    final ok = value == _item.answer;
    final audio = ref.read(audioServiceProvider);

    if (!ok) {
      _answerTap.handleWrongAnswer(
        setState: setState,
        applyImmediateUi: () {
          _session.lastCorrect = false;
          _session.lastChoice = value;
          _session.feedback = 'Thử lại nhé';
          _session.wrong++;
          _session.busy = false;
        },
        playSound: () => unawaited(audio.playRandomTryAgain()),
        sideEffects: () => _fireMaiAndMastery(ok: false, choice: value),
      );
      return;
    }

    _answerTap.handleCorrectAnswer(
      setState: setState,
      applyImmediateUi: () {
        _session.busy = true;
        _session.lastCorrect = true;
        _session.lastChoice = value;
        _session.feedback = 'Giỏi lắm!';
        _session.score++;
        _session.currentIndex++;
      },
      playSound: () => unawaited(audio.playRandomSuccess()),
      sideEffects: () => _fireMaiAndMastery(ok: true, choice: value),
      isMounted: () => mounted,
      advanceOrFinish: () {
        _session.busy = false;
        if (_session.score >= _goal) {
          _session.finished = true;
        } else {
          _session.generateNewQuestion();
          _maiController.dismissBubble();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final finished = _session.finished;
    final score = _session.score;
    final wrong = _session.wrong;
    final feedback = _session.feedback;
    final correct = _session.lastCorrect;
    final lastChoice = _session.lastChoice;

    final page = finished
      ? KidsHubShell(
        title: _item.title,
        accent: VimaiColor.mint,
        artAsset: VimaiArt.mathValley,
        onBack: () => context.pop(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Giỏi lắm!', style: VimaiType.greeting.copyWith(color: VimaiColor.correct)),
                const SizedBox(height: 8),
                const IdleMascot(mood: MascotMood.celebrating, color: VimaiColor.mascot, size: 88),
                const SizedBox(height: 8),
                Text('$score đúng / $wrong sai', style: VimaiType.subtitle),
                const SizedBox(height: 24),
                KidsPlayButton(
                  label: 'Chơi lại',
                  color: AppTheme.mathColor,
                  onPressed: () {
                    setState(() => _session.restart());
                    _maiController.dismissBubble();
                  },
                ),
              ],
            ),
          ),
        ),
      )
      : KidsHubShell(
      title: _item.title,
      accent: VimaiColor.mint,
      onBack: () => context.pop(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight, maxWidth: VimaiSpace.maxContent),
              child: Column(
                children: [
                  Text('Đúng $score / $_goal', style: VimaiType.cardTitle.copyWith(color: AppTheme.mathColor)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: _goal == 0 ? 0 : (score / _goal).clamp(0, 1),
                      minHeight: 10,
                      color: AppTheme.mathColor,
                      backgroundColor: AppTheme.mathColor.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MaiCompanionWidget(
                    context: MaiContext(
                      currentModule: 'math',
                      currentLesson: widget.skill,
                      currentActivity: 'quiz',
                      currentQuestion: _item.question ?? _item.instruction,
                      learningObjective: _item.instruction,
                      expectedAnswer: _item.answer,
                      choices: _item.choices,
                      childAge: ref.watch(currentProfileProvider)?.age ?? 5,
                    ),
                    controller: _maiController,
                    mascotSize: 64,
                    color: AppTheme.mathColor,
                  ),
                  const SizedBox(height: 12),
                  SoftSurface(
                    color: VimaiColor.mintSoft.withValues(alpha: 0.45),
                    borderColor: AppTheme.mathColor.withValues(alpha: 0.28),
                    child: Column(
                      children: [
                        Text(_item.instruction, style: VimaiType.subtitle, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(
                          _item.question ?? '',
                          textAlign: TextAlign.center,
                          style: VimaiType.display.copyWith(color: VimaiColor.ink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ChoiceGrid(
                    choices: _item.choices ?? [],
                    onSelected: _onChoice,
                    color: AppTheme.mathColor,
                    lastChoice: lastChoice,
                    lastCorrect: correct,
                  ),
                  LessonFeedback(correct: correct, message: feedback),
                ],
              ),
            ),
          );
        },
      ),
    );
    return SessionBinder(subject: 'math', child: page);
  }
}
