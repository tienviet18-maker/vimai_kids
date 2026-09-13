import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/ai/mai_context.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/session/session_binder.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/content/math_generator.dart';
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
  late ContentItem _item;
  String? _feedback;
  bool? _correct;
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;
  AudioService? _audio;
  late final MaiCompanionController _maiController;

  String? _lastChoice;

  int get _goal => GameCatalog.roundsForAge(ref.read(currentProfileProvider)?.age ?? 5);

  @override
  void initState() {
    super.initState();
    _maiController = MaiCompanionController();
    _next();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audio = ref.read(audioServiceProvider);
      final profile = ref.read(currentProfileProvider);
      _audio?.soundEnabled = profile?.soundEnabled ?? true;
      _audio?.bgmEnabled = profile?.bgmEnabled ?? true;
      _audio?.startGameBgm();
      // Hard-wired Hoài My system intro — skill-specific instruction clip.
      unawaited(_audio!.playAudio(AudioService.introForMathSkill(widget.skill)));
    });
  }

  @override
  void dispose() {
    _audio?.stopGameBgm();
    _maiController.dispose();
    super.dispose();
  }

  void _next() {
    final age = ref.read(currentProfileProvider)?.age ?? 5;
    _maiController.dismissBubble();
    setState(() {
      _item = _generator.generateBySkill(widget.skill, age: age);
      _feedback = null;
      _correct = null;
      _lastChoice = null;
    });
  }

  Future<void> _onChoice(String value) async {
    if (_finished) return;
    final ok = value == _item.answer;
    final profile = ref.read(currentProfileProvider);
    if (profile != null) {
      await ref.read(masteryRepositoryProvider).record(
            childId: profile.id,
            itemId: '${widget.skill}:${_item.question}',
            skill: 'math.${widget.skill}',
            correct: ok,
          );
    }

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

    setState(() {
      _correct = ok;
      _lastChoice = value;
      _feedback = ok ? 'Giỏi lắm!' : 'Thử lại nhé';
      if (ok) {
        _score++;
      } else {
        _wrong++;
      }
    });

    if (!ok) {
      final hintResp = await ref.read(maiAiServiceProvider).onIncorrectAnswer(mathCtx);
      _maiController.showResponse(hintResp);
      await ref.read(audioServiceProvider).playRandomTryAgain();
      return;
    }

    final praiseResp = await ref.read(maiAiServiceProvider).onCorrectAnswer(mathCtx);
    _maiController.showResponse(praiseResp);
    await ref.read(audioServiceProvider).playRandomSuccess();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (_score >= _goal) {
      setState(() => _finished = true);
    } else {
      _next();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _finished
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
                Text('$_score đúng / $_wrong sai', style: VimaiType.subtitle),
                const SizedBox(height: 24),
                KidsPlayButton(
                  label: 'Chơi lại',
                  color: AppTheme.mathColor,
                  onPressed: () {
                    setState(() {
                      _score = 0;
                      _wrong = 0;
                      _finished = false;
                    });
                    _next();
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
                  Text('Đúng $_score / $_goal', style: VimaiType.cardTitle.copyWith(color: AppTheme.mathColor)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: _goal == 0 ? 0 : (_score / _goal).clamp(0, 1),
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
                    lastChoice: _lastChoice,
                    lastCorrect: _correct,
                  ),
                  LessonFeedback(correct: _correct, message: _feedback),
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
