import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/gamification/celebration_overlay.dart';
import '../../../core/providers.dart';
import '../../../core/routing/nav_utils.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/listen_prompt.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_ui.dart';
import '../../shared/widgets/vimai_world.dart';
import '../data/explore_catalog.dart';
import '../explore_guide.dart';
import '../logic/explore_quiz.dart';
import 'explore_widgets.dart';

/// "Đố bé": Mai asks "Đâu là con mèo?" and the child taps one of four big
/// pictures. Stars live only for this round; nothing is stored.
class ExploreQuizScreen extends ConsumerWidget {
  const ExploreQuizScreen({super.key, required this.categoryId, this.random});

  final String categoryId;

  /// Fixed seed for tests.
  final math.Random? random;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(exploreCatalogProvider);
    return catalog.when(
      loading: () =>
          const Scaffold(backgroundColor: VimaiColor.bgWarmCream, body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const Scaffold(backgroundColor: VimaiColor.bgWarmCream, body: SizedBox.shrink()),
      data: (data) {
        final category = data.byId(categoryId);
        if (category == null || category.items.length < ExploreQuizRound.choicesPerQuestion) {
          return Scaffold(
            backgroundColor: VimaiColor.bgWarmCream,
            body: SafeArea(
              child: ExploreTopBar(
                  title: 'Đố bé', emoji: '🎯', color: VimaiColor.sky, onBack: () => popLearningScreen(context)),
            ),
          );
        }
        return _QuizView(category: category, random: random);
      },
    );
  }
}

enum _Mark { none, wrong, right }

class _QuizView extends ConsumerStatefulWidget {
  const _QuizView({required this.category, this.random});

  final ExploreCategory category;
  final math.Random? random;

  @override
  ConsumerState<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends ConsumerState<_QuizView> {
  late final math.Random _rnd = widget.random ?? math.Random();
  late ExploreQuizRound _round;
  int _q = 0;
  final Map<String, _Mark> _marks = {};
  final List<bool> _firstTry = [];
  bool _missed = false;
  bool _locked = false;
  bool _done = false;
  int _shake = 0;
  Timer? _timer;

  ExploreQuestion get _question => _round.questions[_q];

  @override
  void initState() {
    super.initState();
    _start(intro: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start({required bool intro}) {
    _round = ExploreQuizRound.generate(widget.category, random: _rnd);
    _q = 0;
    _marks.clear();
    _firstTry.clear();
    _missed = false;
    _locked = false;
    _done = false;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 380), () {
      if (mounted) _speak([intro ? ExploreGuide.quizStart : ExploreGuide.playAgain, _question.prompt]);
    });
  }

  void _speak(List<String> lines) => unawaited(ref.read(audioServiceProvider).speak(lines));

  void _pick(ExploreItem item) {
    if (_locked || _done) return;
    if (item.id == _question.target.id) {
      HapticFeedback.lightImpact();
      setState(() {
        _marks[item.id] = _Mark.right;
        _locked = true;
        _firstTry.add(!_missed);
      });
      if (!MediaQuery.disableAnimationsOf(context)) CelebrationOverlay.show(context);
      final line = ExploreGuide.correct[_rnd.nextInt(ExploreGuide.correct.length)];
      _speak([line, item.name]);
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 2300), _next);
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _marks[item.id] = _Mark.wrong;
        _missed = true;
        _shake++;
      });
      final line = ExploreGuide.wrong[_rnd.nextInt(ExploreGuide.wrong.length)];
      _speak([line, _question.prompt]);
    }
  }

  void _next() {
    if (!mounted) return;
    if (_q + 1 >= _round.questions.length) {
      final perfect = _firstTry.every((e) => e);
      setState(() => _done = true);
      _speak([perfect ? ExploreGuide.quizPerfect : ExploreGuide.quizDone]);
      return;
    }
    setState(() {
      _q++;
      _marks.clear();
      _missed = false;
      _locked = false;
    });
    _speak([_question.prompt]);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.category.color;
    final avatar = ref.watch(currentProfileProvider)?.avatar ?? '';
    final mascotColor = mascotColorForAvatar(avatar);
    final switchDuration = VimaiMotion.of(context, const Duration(milliseconds: 420));
    return Scaffold(
      backgroundColor: VimaiColor.bgWarmCream,
      body: ExploreBackdrop(
        color: c,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    ExploreRoundButton(
                      icon: Icons.close_rounded,
                      semanticLabel: 'Thoát',
                      color: c,
                      onTap: () {
                        unawaited(ref.read(audioServiceProvider).stop());
                        popLearningScreen(context);
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Center(
                        child: _StarTrack(
                          total: _round.questions.length,
                          current: _done ? _round.questions.length : _q,
                          earned: _firstTry,
                        ),
                      ),
                    ),
                    const SizedBox(width: 74),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: switchDuration,
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(a), child: child),
                  ),
                  child: _done
                      ? _RewardPanel(
                          key: const ValueKey('reward'),
                          color: c,
                          mascotColor: mascotColor,
                          earned: _firstTry,
                          onReplay: () {
                            setState(() => _start(intro: false));
                          },
                          onExit: () => popLearningScreen(context),
                        )
                      : _QuestionBoard(
                          key: ValueKey('q$_q'),
                          question: _question,
                          color: c,
                          mascotColor: mascotColor,
                          marks: _marks,
                          shake: _shake,
                          solved: _locked,
                          onPick: _pick,
                          onListen: () => _speak([_question.prompt]),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarTrack extends StatelessWidget {
  const _StarTrack({required this.total, required this.current, required this.earned});

  final int total;
  final int current;
  final List<bool> earned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(VimaiRadius.pill),
        boxShadow: VimaiShadow.soft,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _StarSlot(
                  state: i < earned.length ? (earned[i] ? 2 : 1) : 0,
                  current: i == current,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StarSlot extends StatelessWidget {
  const _StarSlot({required this.state, required this.current});

  /// 0 = to do, 1 = solved after a retry, 2 = solved first try.
  final int state;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      state == 0 ? Icons.star_outline_rounded : Icons.star_rounded,
      size: current ? 38 : 32,
      color: switch (state) {
        2 => VimaiColor.honey,
        1 => const Color(0xFFF6C96B),
        _ => current ? VimaiColor.primaryPink : const Color(0xFFC7CDD6),
      },
    );
    final d = VimaiMotion.of(context, const Duration(milliseconds: 520));
    if (state == 0 || d == Duration.zero) return icon;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.2, end: 1),
      duration: d,
      curve: Curves.elasticOut,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: icon,
    );
  }
}

class _QuestionBoard extends StatelessWidget {
  const _QuestionBoard({
    super.key,
    required this.question,
    required this.color,
    required this.mascotColor,
    required this.marks,
    required this.shake,
    required this.solved,
    required this.onPick,
    required this.onListen,
  });

  final ExploreQuestion question;
  final Color color;
  final Color mascotColor;
  final Map<String, _Mark> marks;
  final int shake;
  final bool solved;
  final ValueChanged<ExploreItem> onPick;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final anyWrong = marks.values.contains(_Mark.wrong);
    final mood = solved ? MascotMood.celebrating : (anyWrong ? MascotMood.encouraging : MascotMood.thinking);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final compact = w < 520;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: EdgeInsets.fromLTRB(compact ? 14 : 24, 6, compact ? 14 : 24, 16),
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Row(
                      children: [
                        IdleMascot(mood: mood, color: mascotColor, size: compact ? 64 : 84),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ListenPrompt(
                            text: question.prompt,
                            color: color,
                            style: VimaiType.title.copyWith(fontSize: compact ? 22 : 26),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, area) {
                        const gap = 14.0;
                        final row = area.maxWidth > area.maxHeight * 2.1;
                        final cols = row ? 4 : 2;
                        final rows = row ? 1 : 2;
                        final size = math
                            .min((area.maxWidth - gap * (cols - 1)) / cols, (area.maxHeight - gap * (rows - 1)) / rows)
                            .clamp(64.0, 280.0);
                        return Center(
                          child: SizedBox(
                            // Exactly [cols] cards per line, so 2×2 never becomes 3+1.
                            width: size * cols + gap * (cols - 1),
                            child: Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              alignment: WrapAlignment.center,
                              children: [
                                for (var i = 0; i < question.choices.length; i++)
                                  SizedBox.square(
                                    dimension: size,
                                    child: ExplorePopIn(
                                      index: i,
                                      child: _ChoiceCard(
                                        item: question.choices[i],
                                        color: color,
                                        mark: marks[question.choices[i].id] ?? _Mark.none,
                                        shake: marks[question.choices[i].id] == _Mark.wrong ? shake : 0,
                                        faded: solved && marks[question.choices[i].id] != _Mark.right,
                                        onTap: () => onPick(question.choices[i]),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.item,
    required this.color,
    required this.mark,
    required this.shake,
    required this.faded,
    required this.onTap,
  });

  final ExploreItem item;
  final Color color;
  final _Mark mark;
  final int shake;
  final bool faded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = switch (mark) {
      _Mark.right => VimaiColor.correct,
      _Mark.wrong => VimaiColor.retry,
      _Mark.none => Colors.white,
    };
    final fb = VimaiMotion.of(context, VimaiMotion.feedback);
    Widget card = LayoutBuilder(
      builder: (context, box) {
        final s = box.maxWidth;
        return AnimatedContainer(
          duration: fb,
          decoration: BoxDecoration(
            color: mark == _Mark.right ? const Color(0xFFE9FBEF) : Colors.white,
            borderRadius: BorderRadius.circular(s * 0.16),
            border: Border.all(color: border, width: mark == _Mark.none ? 4 : 6),
            boxShadow: [
              BoxShadow(
                color: (mark == _Mark.right ? VimaiColor.correct : color)
                    .withValues(alpha: mark == _Mark.right ? 0.45 : 0.22),
                blurRadius: mark == _Mark.right ? 26 : 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: s * 0.78,
                  height: s * 0.78,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Color.lerp(color, Colors.white, 0.86)),
                  child: ExploreEmoji(item.emoji, size: s * 0.46),
                ),
              ),
              if (mark != _Mark.none)
                Positioned(
                  right: s * 0.06,
                  top: s * 0.06,
                  child: Container(
                    width: math.max(30, s * 0.2),
                    height: math.max(30, s * 0.2),
                    decoration: BoxDecoration(color: border, shape: BoxShape.circle),
                    child: Icon(
                      mark == _Mark.right ? Icons.check_rounded : Icons.refresh_rounded,
                      color: Colors.white,
                      size: math.max(20, s * 0.14),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (mark == _Mark.wrong && shake > 0 && fb != Duration.zero) {
      card = TweenAnimationBuilder<double>(
        key: ValueKey('shake$shake'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 480),
        child: card,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(math.sin(t * math.pi * 5) * 10 * (1 - t), 0),
          child: child,
        ),
      );
    }

    return AnimatedOpacity(
      duration: fb,
      opacity: faded ? 0.35 : (mark == _Mark.wrong ? 0.7 : 1),
      child: AnimatedScale(
        duration: VimaiMotion.of(context, const Duration(milliseconds: 360)),
        curve: Curves.easeOutBack,
        scale: mark == _Mark.right ? 1.06 : (faded ? 0.94 : 1),
        child: Pressable(
          semanticLabel: item.name,
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}

class _RewardPanel extends StatelessWidget {
  const _RewardPanel({
    super.key,
    required this.color,
    required this.mascotColor,
    required this.earned,
    required this.onReplay,
    required this.onExit,
  });

  final Color color;
  final Color mascotColor;
  final List<bool> earned;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final gold = earned.where((e) => e).length;
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 520;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: EdgeInsets.fromLTRB(20, compact ? 18 : 26, 20, compact ? 20 : 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Color.lerp(color, Colors.white, 0.6)!, width: 5),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 14))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: compact ? 150 : 180,
                          height: compact ? 150 : 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                                colors: [const Color(0xFFFFF3C4), Color.lerp(color, Colors.white, 0.75)!]),
                          ),
                        ),
                        IdleMascot(mood: MascotMood.celebrating, color: mascotColor, size: compact ? 120 : 148),
                        const Positioned(top: 0, right: 8, child: ExploreEmoji('🏆', size: 44)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      gold == earned.length ? 'Bé đúng hết rồi!' : 'Bé giỏi quá!',
                      textAlign: TextAlign.center,
                      style: VimaiType.display
                          .copyWith(color: Color.lerp(color, VimaiColor.ink, 0.4), fontSize: compact ? 28 : 32),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (var i = 0; i < earned.length; i++)
                          ExplorePopIn(
                            index: i + 2,
                            child: Icon(
                              Icons.star_rounded,
                              size: compact ? 46 : 54,
                              color: earned[i] ? VimaiColor.honey : const Color(0xFFF6C96B),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: compact ? 16 : 36,
                      runSpacing: 12,
                      children: [
                        _RewardAction(
                          icon: Icons.replay_rounded,
                          label: 'Chơi lại',
                          color: color,
                          onTap: onReplay,
                        ),
                        _RewardAction(
                          icon: Icons.grid_view_rounded,
                          label: 'Xem hình',
                          color: VimaiColor.primaryPink,
                          onTap: onExit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RewardAction extends StatelessWidget {
  const _RewardAction({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExploreRoundButton(
            icon: icon, semanticLabel: label, color: Colors.white, background: color, size: 76, onTap: onTap),
        const SizedBox(height: 6),
        Text(label, style: VimaiType.label.copyWith(fontSize: 16, color: Color.lerp(color, VimaiColor.ink, 0.4))),
      ],
    );
  }
}
