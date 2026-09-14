import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/mai_context.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/game/webkit_answer_tap.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/session/session_binder.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/thinking_generator.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/content/content_item.dart';
import '../../../domain/models/skill_mastery.dart';
import '../../ai/presentation/mai_companion_widget.dart';
import '../../shared/widgets/choice_grid.dart';
import '../../shared/widgets/kids_storybook.dart';
import '../../shared/widgets/vimai_ui.dart';

class ThinkingScreen extends ConsumerStatefulWidget {
  const ThinkingScreen({super.key});

  @override
  ConsumerState<ThinkingScreen> createState() => _ThinkingScreenState();
}

class _ThinkingScreenState extends ConsumerState<ThinkingScreen> {
  late final ThinkingQuestionEngine _engine;
  final _answerTap = WebKitAnswerTap(holdDuration: const Duration(milliseconds: 500));
  ContentItem? _item;
  String? _feedback;
  bool? _correct;
  String? _lastChoice;
  int _score = 0;
  late final MaiCompanionController _maiController;

  @override
  void initState() {
    super.initState();
    _maiController = MaiCompanionController();
    _engine = ThinkingQuestionEngine(bank: ref.read(contentRepositoryProvider).getThinkingPatterns());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _next(playSkillIntro: true);
    });
  }

  @override
  void dispose() {
    _answerTap.dispose();
    _maiController.dispose();
    super.dispose();
  }

  void _applyNextItem({bool playSkillIntro = false}) {
    final profile = ref.read(currentProfileProvider);
    final age = profile?.age ?? 5;
    final mastery = profile == null ? <SkillMastery>[] : ref.read(masteryRepositoryProvider).allForChild(profile.id);
    _maiController.dismissBubble();
    final item = _engine.next(age: age, mastery: mastery);
    _item = item;
    _feedback = null;
    _correct = null;
    _lastChoice = null;
    if (playSkillIntro) {
      unawaited(
        ref.read(audioServiceProvider).playAudio(AudioService.introForThinkingSkill(item.skill)),
      );
    }
  }

  void _next({bool playSkillIntro = false}) {
    setState(() => _applyNextItem(playSkillIntro: playSkillIntro));
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final copy = AppStrings.of(ref.watch(currentProfileProvider), context);
    return SessionBinder(
      subject: 'thinking',
      child: KidsHubShell(
      title: item?.title ?? copy.thinking,
      subtitle: copy.scoreCorrect(_score),
      accent: VimaiColor.grape,
      artAsset: null,
      onBack: () => context.pop(),
      action: IconButton(
        icon: const Icon(Icons.palette_outlined),
        tooltip: 'Vẽ tranh sáng tạo',
        color: VimaiColor.grape,
        onPressed: () => context.push('/drawing'),
      ),
      body: item == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/drawing'),
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF9E6), Color(0xFFFFECEB)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFFF9800), width: 1.5),
                                ),
                                child: const Center(
                                  child: Text('🎨', style: TextStyle(fontSize: 22)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Vẽ tranh sáng tạo',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: VimaiType.cardTitle.copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFFD84315),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF7E40),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Sáng tạo',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Vẽ tự do, tô màu, nối điểm',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Color(0xFFD84315),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    MaiCompanionWidget(
                      context: MaiContext(
                        currentModule: 'thinking',
                        currentLesson: item.skill,
                        currentActivity: 'quiz',
                        currentQuestion: item.instruction,
                        learningObjective: item.title,
                        expectedAnswer: item.answer,
                        choices: item.choices,
                        childAge: ref.watch(currentProfileProvider)?.age ?? 5,
                      ),
                      controller: _maiController,
                      mascotSize: 76,
                      color: VimaiColor.grape,
                    ),
                    const SizedBox(height: 8),
                    SoftSurface(
                      color: VimaiColor.grapeSoft.withValues(alpha: 0.55),
                      borderColor: VimaiColor.grape.withValues(alpha: 0.28),
                      child: Text(item.instruction, textAlign: TextAlign.center, style: VimaiType.title),
                    ),
                    const SizedBox(height: 16),
                    ChoiceGrid(
                      choices: item.choices ?? [],
                      color: VimaiColor.grape,
                      lastChoice: _lastChoice,
                      lastCorrect: _correct,
                      onSelected: (value) {
                        if (_answerTap.locked) return;
                        final ok = value == item.answer;
                        final audio = ref.read(audioServiceProvider);
                        final profile = ref.read(currentProfileProvider);
                        final copyLocal = copy;

                        void sideEffects() {
                          if (profile != null) {
                            unawaited(
                              ref.read(masteryRepositoryProvider).record(
                                    childId: profile.id,
                                    itemId: item.id,
                                    skill: 'thinking.${item.skill}',
                                    correct: ok,
                                  ),
                            );
                          }
                          final aiCtx = MaiContext(
                            currentModule: 'thinking',
                            currentLesson: item.skill,
                            currentActivity: 'quiz',
                            currentQuestion: item.instruction,
                            learningObjective: item.title,
                            expectedAnswer: item.answer,
                            choices: item.choices,
                            childAge: profile?.age ?? 5,
                          );
                          unawaited(() async {
                            try {
                              final mai = ref.read(maiAiServiceProvider);
                              final resp = ok
                                  ? await mai.onCorrectAnswer(aiCtx)
                                  : await mai.onIncorrectAnswer(aiCtx);
                              if (!mounted) return;
                              _maiController.showResponse(resp);
                            } catch (e) {
                              debugPrint('[Thinking] Mai side-effect ignored: $e');
                            }
                          }());
                        }

                        if (!ok) {
                          _answerTap.handleWrongAnswer(
                            setState: setState,
                            applyImmediateUi: () {
                              _correct = false;
                              _lastChoice = value;
                              _feedback = copyLocal.tryAgain;
                            },
                            playSound: () => unawaited(audio.playRandomTryAgain()),
                            sideEffects: sideEffects,
                          );
                          return;
                        }

                        _answerTap.handleCorrectAnswer(
                          setState: setState,
                          applyImmediateUi: () {
                            _correct = true;
                            _lastChoice = value;
                            _feedback = copyLocal.correct;
                            _score++;
                          },
                          playSound: () => unawaited(audio.playRandomSuccess()),
                          sideEffects: sideEffects,
                          isMounted: () => mounted,
                          advanceOrFinish: _applyNextItem,
                        );
                      },
                    ),
                    LessonFeedback(correct: _correct, message: _feedback),
                    if (_correct == false && item.answer != null) ...[
                      const SizedBox(height: 12),
                      SoftSurface(
                        color: VimaiColor.honeySoft.withValues(alpha: 0.55),
                        borderColor: VimaiColor.honey.withValues(alpha: 0.35),
                        child: Text(
                          '${copy.tryAgain}: ${item.answer}',
                          textAlign: TextAlign.center,
                          style: VimaiType.cardTitle.copyWith(color: VimaiColor.honey),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    ),
    );
  }
}
