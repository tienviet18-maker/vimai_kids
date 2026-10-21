import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/mai_context.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/kid_guide.dart';
import '../../../core/audio/speech_id.dart';
import '../../../core/game/webkit_answer_tap.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/routing/nav_utils.dart';
import '../../../core/session/session_binder.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/thinking_generator.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/content/content_item.dart';
import '../../../domain/models/skill_mastery.dart';
import '../../ai/presentation/mai_companion_widget.dart';
import '../../shared/widgets/choice_grid.dart';
import '../../shared/widgets/kids_storybook.dart';
import '../../shared/widgets/listen_prompt.dart';
import '../../shared/widgets/vimai_ui.dart';

class ThinkingScreen extends ConsumerStatefulWidget {
  const ThinkingScreen({super.key, this.engine});

  /// Question source; tests pass one with fixed questions.
  final ThinkingQuestionEngine? engine;

  @override
  ConsumerState<ThinkingScreen> createState() => _ThinkingScreenState();
}

class _ThinkingScreenState extends ConsumerState<ThinkingScreen> {
  late final ThinkingQuestionEngine _engine;
  final _answerTap = WebKitAnswerTap(holdDuration: kPraiseHold);
  ContentItem? _item;
  String? _feedback;
  bool? _correct;
  String? _lastChoice;
  int _score = 0;

  /// Wrong taps on the current question; the answer is shown after two.
  int _misses = 0;
  late final MaiCompanionController _maiController;

  /// Nhớ vị trí: the row is on screen for [_memoryShow], then hidden and
  /// the question is asked. Choices only appear once it is hidden.
  static const _memoryShow = Duration(seconds: 6);
  static const _memoryPeek = Duration(seconds: 3);
  bool _memoryHidden = false;
  Timer? _memoryTimer;

  /// "Chạm vào loa nhỏ…" is said once, on the first question with written answers.
  bool _speakerHintSaid = false;

  @override
  void initState() {
    super.initState();
    _maiController = MaiCompanionController();
    _engine = widget.engine ?? ThinkingQuestionEngine(bank: ref.read(contentRepositoryProvider).getThinkingPatterns());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final item = _generate();
      setState(() => _apply(item));
      unawaited(ref.read(audioServiceProvider).speak(
            const [],
            leadIds: _promptClips(item, intro: true),
            fallbackId: AudioService.introForThinkingSkill(item.skill),
          ));
    });
  }

  @override
  void dispose() {
    _memoryTimer?.cancel();
    _answerTap.dispose();
    _maiController.dispose();
    super.dispose();
  }

  static bool _isMemory(ContentItem item) => item.metadata?['sequence'] is List;

  static List<String> _sequence(ContentItem item) =>
      [for (final e in (item.metadata?['sequence'] as List? ?? const [])) e.toString()];

  /// Clips that say [text]: a number's own clip, else its vi_say_* line.
  static List<String> _clipsFor(String? text) {
    if (text == null || text.trim().isEmpty) return const [];
    final math = AudioService.mathClips(text);
    if (math != null) return math;
    final id = SpeechId.idForLine(text);
    return id == null ? const [] : [id];
  }

  /// A written answer (a word or a number) gets a speaker badge and is said
  /// when tapped; pictures speak for themselves.
  static bool _hearable(String choice) =>
      RegExp(r'^\d+$').hasMatch(choice.trim()) || (SpeechId.isSpeakable(choice) && _clipsFor(choice).isNotEmpty);

  ContentItem _generate() {
    final profile = ref.read(currentProfileProvider);
    final age = profile?.age ?? 5;
    final mastery = profile == null ? <SkillMastery>[] : ref.read(masteryRepositoryProvider).allForChild(profile.id);
    return _engine.next(age: age, mastery: mastery);
  }

  /// What Mai says when [item] comes up: the question (the "look and
  /// remember" line for Nhớ vị trí), with the skill intro first on the
  /// first question and the speaker hint the first time answers are words.
  List<String> _promptClips(ContentItem item, {bool intro = false}) {
    final hint = !_speakerHintSaid && (item.choices ?? const <String>[]).any(_hearable);
    if (hint) _speakerHintSaid = true;
    return [
      if (intro) AudioService.introForThinkingSkill(item.skill),
      if (_isMemory(item))
        ..._clipsFor(KidGuide.memoryLook)
      else ...[
        ..._clipsFor(item.instruction),
        if (item.question != item.instruction) ..._clipsFor(item.question),
        if (hint) ..._clipsFor(KidGuide.tapSmallSpeaker),
      ],
    ];
  }

  /// Shows [item] (call inside setState). Speech is started by the caller.
  void _apply(ContentItem item) {
    _maiController.dismissBubble();
    _item = item;
    _feedback = null;
    _correct = null;
    _lastChoice = null;
    _misses = 0;
    _memoryTimer?.cancel();
    _memoryHidden = false;
    if (_isMemory(item)) _startMemoryTimer(_memoryShow);
  }

  void _startMemoryTimer(Duration show) {
    _memoryTimer?.cancel();
    _memoryTimer = Timer(show, () {
      if (!mounted) return;
      final item = _item;
      if (item == null) return;
      setState(() => _memoryHidden = true);
      unawaited(ref.read(audioServiceProvider).speak([item.instruction]));
    });
  }

  /// "Xem lại": the row comes back for a moment, then hides again.
  void _peek() {
    setState(() => _memoryHidden = false);
    _startMemoryTimer(_memoryPeek);
  }

  void _say(ContentItem item) {
    unawaited(ref.read(audioServiceProvider).speak(
          _isMemory(item)
              ? [_memoryHidden ? item.instruction : KidGuide.memoryLook]
              : [item.instruction, if (item.question != item.instruction) item.question],
        ));
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
        onBack: () => navigateBackToHome(context),
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
                    if (_isMemory(item))
                      _MemoryRow(
                        sequence: _sequence(item),
                        hidden: _memoryHidden,
                        prompt: _memoryHidden ? item.instruction : KidGuide.memoryLook,
                        onListen: () => _say(item),
                        onPeek: _peek,
                      )
                    else
                      Builder(builder: (context) {
                        // "Hai hình này giống hay khác? ● ▲": the pictures were
                        // tiny glyphs at the end of the sentence; show them big.
                        final split = thinkingPromptParts(item.instruction);
                        final puzzle = item.question != null &&
                                item.question!.trim().isNotEmpty &&
                                item.question != item.instruction
                            ? item.question!
                            : split.$2;
                        return ListenPrompt(
                          text: split.$1,
                          color: VimaiColor.grape,
                          onTap: () => _say(item),
                          // The puzzle itself ("🔴🔵🔴🔵 ?", the shape to find) was
                          // only spoken, never shown, when it differs from the text.
                          child: puzzle == null
                              ? null
                              : Text(
                                  puzzle,
                                  textAlign: TextAlign.center,
                                  style: VimaiType.display.copyWith(color: VimaiColor.ink),
                                ),
                        );
                      }),
                    const SizedBox(height: 16),
                    // Nhớ vị trí: nothing to answer until the row is hidden.
                    if (!_isMemory(item) || _memoryHidden)
                    ChoiceGrid(
                      choices: item.choices ?? [],
                      color: VimaiColor.grape,
                      lastChoice: _lastChoice,
                      lastCorrect: _correct,
                      hearable: _hearable,
                      onHear: (value) => unawaited(
                        ref.read(audioServiceProvider).speak(const [], leadIds: _clipsFor(value)),
                      ),
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
                              final resp = ok ? await mai.onCorrectAnswer(aiCtx) : await mai.onIncorrectAnswer(aiCtx);
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
                              _misses++;
                            },
                            // A written answer is said first, then the nudge.
                            playSound: () => unawaited(
                              audio.playRandomTryAgain(leadIds: _hearable(value) ? _clipsFor(value) : const []),
                            ),
                            sideEffects: sideEffects,
                          );
                          return;
                        }

                        final upcoming = _generate();
                        _answerTap.handleCorrectAnswer(
                          setState: setState,
                          applyImmediateUi: () {
                            _correct = true;
                            _lastChoice = value;
                            _feedback = copyLocal.correct;
                            _score++;
                          },
                          // One sequence: the answer, the praise, then the next
                          // question. Asked on the advance timer, it cut the praise.
                          playSound: () => unawaited(audio.playRandomSuccess(
                                leadIds: _hearable(value) ? _clipsFor(value) : const [],
                                trailIds: _promptClips(upcoming),
                              )),
                          sideEffects: sideEffects,
                          isMounted: () => mounted,
                          advanceOrFinish: () => _apply(upcoming),
                        );
                      },
                    ),
                    LessonFeedback(correct: _correct, message: _feedback),
                    // Give the answer away only after two tries, not on the first miss.
                    if (_correct == false && _misses >= 2 && item.answer != null) ...[
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

/// Nhớ vị trí: the row to remember, then the same number of covered cards.
class _MemoryRow extends StatelessWidget {
  const _MemoryRow({
    required this.sequence,
    required this.hidden,
    required this.prompt,
    required this.onListen,
    required this.onPeek,
  });

  final List<String> sequence;
  final bool hidden;
  final String prompt;
  final VoidCallback onListen;
  final VoidCallback onPeek;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListenPrompt(text: prompt, color: VimaiColor.grape, onTap: onListen),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < sequence.length; i++)
              AnimatedSwitcher(
                duration: VimaiMotion.of(context, VimaiMotion.feedback),
                child: Container(
                  key: ValueKey('mem-$i-$hidden'),
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hidden ? VimaiColor.grape : Colors.white,
                    borderRadius: BorderRadius.circular(VimaiRadius.lg),
                    border: Border.all(color: VimaiColor.grape.withValues(alpha: 0.4), width: 2),
                    boxShadow: VimaiShadow.lift,
                  ),
                  child: Text(
                    hidden ? '?' : sequence[i],
                    style: hidden
                        ? VimaiType.display.copyWith(color: Colors.white, fontSize: 36)
                        : const TextStyle(fontSize: 40, color: VimaiColor.ink, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
        if (hidden) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onPeek,
            icon: const Icon(Icons.visibility_rounded, color: VimaiColor.grape),
            label: Text('Xem lại', style: VimaiType.cardTitle.copyWith(color: VimaiColor.grape)),
          ),
        ],
      ],
    );
  }
}

/// Splits "Hai hình này giống hay khác? ● ▲" into the sentence and the
/// pictures after it, so the pictures can be shown big. The second part is
/// null when the text has no picture tail (or the tail has words).
(String, String?) thinkingPromptParts(String instruction) {
  final m = RegExp(r'^(.*?[?:])\s+([^]+)$').firstMatch(instruction.trim());
  if (m == null) return (instruction, null);
  final tail = m[2]!.trim();
  final hasWord = RegExp(r'[A-Za-zÀ-ỹĐđ]{2,}').hasMatch(tail);
  if (tail.isEmpty || hasWord) return (instruction, null);
  return (m[1]!, tail);
}
