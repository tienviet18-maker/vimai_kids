import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/webkit_answer_tap.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/content/math_generator.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/choice_grid.dart';
import '../../shared/widgets/chunky_button.dart';
import 'widgets/game_art.dart';
import 'widgets/game_play_scaffold.dart';
import '../../../core/audio/kid_guide.dart';

class MathRocketGame extends ConsumerStatefulWidget {
  const MathRocketGame({super.key});

  @override
  ConsumerState<MathRocketGame> createState() => _MathRocketGameState();
}

class _MathRocketGameState extends ConsumerState<MathRocketGame> {
  final _generator = MathQuestionGenerator();
  final _answerTap = WebKitAnswerTap(holdDuration: const Duration(milliseconds: 500));
  late var _item = _generator.generateAddition(10);
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;
  String? _feedback;
  bool? _correct;

  int get _goal => GameCatalog.roundsForAge(ref.read(currentProfileProvider)?.age ?? 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final age = ref.read(currentProfileProvider)?.age ?? 5;
      final skill = MathQuestionGenerator.skillForAge(age, addition: true);
      setState(() => _item = _generator.generateBySkill(skill, age: age));
      final audio = ref.read(audioServiceProvider);
      final profile = ref.read(currentProfileProvider);
      audio.soundEnabled = profile?.soundEnabled ?? true;
      audio.bgmEnabled = profile?.bgmEnabled ?? true;
      audio.startGameBgm();
      unawaited(audio.speak([KidGuide.gameMathRocket, _item.question], fallbackId: 'sys_math_calc_add'));
    });
  }

  @override
  void dispose() {
    _answerTap.dispose();
    super.dispose();
  }

  void _nextItem() {
    final age = ref.read(currentProfileProvider)?.age ?? 5;
    final skill = MathQuestionGenerator.skillForAge(age, addition: true);
    _item = _generator.generateBySkill(skill, age: age);
    unawaited(ref.read(audioServiceProvider).speak([_item.question]));
  }

  void _recordMastery(bool ok) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    unawaited(
      ref.read(masteryRepositoryProvider).record(
            childId: profile.id,
            itemId: _item.id,
            skill: 'game.math_rocket',
            correct: ok,
          ),
    );
  }

  void _onChoice(String value) {
    if (_finished || _answerTap.locked) return;
    final ok = value == _item.answer;
    final audio = ref.read(audioServiceProvider);

    if (!ok) {
      _answerTap.handleWrongAnswer(
        setState: setState,
        applyImmediateUi: () {
          _feedback = 'Thử lại nhé!';
          _correct = false;
          _wrong++;
        },
        playSound: () => unawaited(audio.playRandomTryAgain()),
        sideEffects: () => _recordMastery(false),
      );
      return;
    }

    _answerTap.handleCorrectAnswer(
      setState: setState,
      applyImmediateUi: () {
        _feedback = 'Giỏi lắm!';
        _correct = true;
        _score++;
      },
      playSound: () => unawaited(audio.playRandomSuccess()),
      sideEffects: () => _recordMastery(true),
      isMounted: () => mounted,
      advanceOrFinish: () {
        _feedback = null;
        _correct = null;
        if (_score >= _goal) {
          _finished = true;
        } else {
          _nextItem();
        }
      },
    );
  }

  void _restart() {
    _answerTap.reset();
    setState(() {
      _score = 0;
      _wrong = 0;
      _finished = false;
      _feedback = null;
      _correct = null;
      _nextItem();
    });
  }

  void _sayQuestion() => unawaited(ref.read(audioServiceProvider).speak([_item.question]));

  @override
  Widget build(BuildContext context) {
    final goal = _goal;
    final progress = goal <= 0 ? 0.0 : (_score / goal).clamp(0.0, 1.0);
    return GamePlayScaffold(
      title: 'Tên lửa toán',
      scene: GameScene.space,
      finished: _finished,
      correct: _correct,
      complete: GameCompletePanel(
        score: _score,
        wrong: _wrong,
        total: goal,
        onRetry: _restart,
        hero: const _RocketLaunchHero(),
      ),
      progress: GameProgressBar(current: _score, total: goal, color: AppTheme.mathColor),
      feedback: GameFeedbackToast(correct: _correct, message: _feedback),
      playArea: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 460;
          final trackW = constraints.maxWidth < 420 ? 76.0 : 104.0;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: trackW,
                    child: _RocketTrack(progress: progress, boost: _correct == true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QuestionPanel(
                              text: _item.question ?? '',
                              onTap: _sayQuestion,
                              compact: compact,
                            ),
                            SizedBox(height: compact ? 14 : 24),
                            ChoiceGrid(
                              choices: _item.choices ?? [],
                              color: AppTheme.mathColor,
                              palette: const [Color(0xFFFF4F86), Color(0xFF14B8C4), Color(0xFF8B5CF6), Color(0xFF4C8DDB)],
                              lastCorrect: _correct,
                              maxItemSize: compact ? 80 : 124,
                              onSelected: _onChoice,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Glassy "control panel" showing the sum; tap to hear it again.
class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel({required this.text, required this.onTap, required this.compact});

  final String text;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Nghe lại: $text',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: PopOnChange(
          trigger: text,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(10, compact ? 8 : 14, 14, compact ? 8 : 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF8FE8FF).withValues(alpha: 0.75), width: 2.5),
              boxShadow: [BoxShadow(color: const Color(0xFF4CC9F0).withValues(alpha: 0.35), blurRadius: 24)],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: Color(0xFF4CC9F0), shape: BoxShape.circle),
                  child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      style: VimaiType.display.copyWith(
                        color: Colors.white,
                        fontSize: compact ? 38 : 50,
                        height: 1.1,
                        shadows: const [Shadow(color: Color(0xFF4CC9F0), blurRadius: 16)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Launch tower: the rocket climbs one notch per correct answer toward
/// the moon at the top.
class _RocketTrack extends StatefulWidget {
  const _RocketTrack({required this.progress, required this.boost});

  final double progress;
  final bool boost;

  @override
  State<_RocketTrack> createState() => _RocketTrackState();
}

class _RocketTrackState extends State<_RocketTrack> with SingleTickerProviderStateMixin {
  late final AnimationController _flame = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _flame.stop();
    } else if (!_flame.isAnimating) {
      _flame.repeat();
    }
  }

  @override
  void dispose() {
    _flame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final rocketW = w * 0.72;
        final rocketH = rocketW * 1.75;
        final top = w * 0.9;
        final bottom = math.max(top, c.maxHeight - rocketH - 14);
        final y = bottom - (bottom - top) * widget.progress;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Rail.
            Positioned(
              left: w / 2 - 5,
              top: w * 0.5,
              bottom: 10,
              child: Container(
                width: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            // Filled trail behind the rocket.
            AnimatedPositioned(
              duration: VimaiMotion.of(context, const Duration(milliseconds: 750)),
              curve: Curves.easeOutBack,
              left: w / 2 - 5,
              top: y + rocketH * 0.6,
              bottom: 10,
              width: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFE066), Color(0xFFFF7A1A)],
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            // Moon goal.
            Positioned(
              left: w * 0.12,
              top: 0,
              width: w * 0.76,
              height: w * 0.76,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(center: Alignment(-0.3, -0.3), colors: [Color(0xFFFFF7CC), Color(0xFFF5D76E)]),
                  boxShadow: [BoxShadow(color: const Color(0xFFFFF3B0).withValues(alpha: 0.6), blurRadius: 18)],
                ),
                child: const Center(child: Icon(Icons.flag_rounded, color: Color(0xFFFF4F86))),
              ),
            ),
            // Launch pad.
            Positioned(
              left: 4,
              right: 4,
              bottom: 0,
              height: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(color: const Color(0xFF8B93B8), borderRadius: BorderRadius.circular(8)),
              ),
            ),
            AnimatedPositioned(
              duration: VimaiMotion.of(context, const Duration(milliseconds: 750)),
              curve: Curves.easeOutBack,
              left: (w - rocketW) / 2,
              top: y,
              width: rocketW,
              height: rocketH,
              child: AnimatedBuilder(
                animation: _flame,
                builder: (context, _) => CustomPaint(
                  painter: RocketPainter(flame: _flame.value, boost: widget.boost ? 1 : 0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Win hero: the rocket blasts off in a loop with a fiery trail.
class _RocketLaunchHero extends StatefulWidget {
  const _RocketLaunchHero();

  @override
  State<_RocketLaunchHero> createState() => _RocketLaunchHeroState();
}

class _RocketLaunchHeroState extends State<_RocketLaunchHero> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 0.3;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 130,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final lift = Curves.easeIn.transform(((t - 0.25) / 0.75).clamp(0.0, 1.0));
            final shake = t < 0.25 ? (t * 80).remainder(2) - 1 : 0.0;
            return Transform.translate(
              offset: Offset(shake * 2, 30 - lift * 200),
              child: Center(
                child: SizedBox(
                  width: 54,
                  height: 96,
                  child: CustomPaint(painter: RocketPainter(flame: t, boost: 1)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
