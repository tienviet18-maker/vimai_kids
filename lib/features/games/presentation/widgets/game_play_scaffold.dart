import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/audio/kid_guide.dart';
import '../../../../core/routing/nav_utils.dart';
import '../../../../core/session/session_binder.dart';
import '../../../../core/theme/vimai_tokens.dart';
import '../../../shared/widgets/chunky_button.dart';
import '../../../shared/widgets/listen_prompt.dart';
import '../../../shared/widgets/vimai_mascot.dart';
import '../../../shared/widgets/vimai_world.dart';
import '../../logic/game_board_metrics.dart';
import 'game_art.dart';
import 'game_fx.dart';
import 'game_scene.dart';

export 'game_scene.dart' show GameScene;

/// Shared kid-game stage: a painted scene, a header with a big back button,
/// Mai reacting to answers, a star progress row, then the playfield.
class GamePlayScaffold extends StatelessWidget {
  const GamePlayScaffold({
    super.key,
    required this.title,
    required this.playArea,
    this.instruction,
    this.progress,
    this.feedback,
    this.footer,
    this.complete,
    this.finished = false,
    this.scene = GameScene.sky,
    this.correct,
  });

  final String title;
  final Widget? instruction;
  final Widget? progress;

  /// Shown as Mai's speech bubble in the header while [correct] is set.
  final Widget? feedback;
  final Widget playArea;
  final Widget? footer;
  final Widget? complete;
  final bool finished;
  final GameScene scene;

  /// Last answer: true → Mai celebrates, false → Mai encourages.
  final bool? correct;

  @override
  Widget build(BuildContext context) {
    final done = finished && complete != null;
    return SessionBinder(
      subject: 'games',
      child: Scaffold(
        backgroundColor: scene.base,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GameSceneBackdrop(scene: scene),
            SafeArea(
              child: GameFx(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: VimaiSpace.maxWide),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _GameHeader(
                          title: title,
                          scene: scene,
                          correct: done ? true : correct,
                          feedback: done ? null : feedback,
                        ),
                        if (done)
                          Expanded(child: complete!)
                        else ...[
                          if (progress != null)
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 2, 14, 6),
                                child: progress),
                          if (instruction != null)
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 0, 14, 8),
                                child: instruction),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                              child: playArea,
                            ),
                          ),
                          if (footer != null)
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: footer),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader(
      {required this.title,
      required this.scene,
      required this.correct,
      required this.feedback});

  final String title;
  final GameScene scene;
  final bool? correct;
  final Widget? feedback;

  @override
  Widget build(BuildContext context) {
    final showBubble = feedback != null && correct != null;
    return SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 4),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: ChunkyButton(
                circle: true,
                depth: 4,
                color: Colors.white,
                outlineWidth: 0,
                semanticLabel: 'Quay lại',
                onTap: () => popLearningScreen(context),
                child: const Center(
                  child: Icon(Icons.arrow_back_rounded,
                      size: 30, color: VimaiColor.ink),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: VimaiMotion.of(context, VimaiMotion.feedback),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(
                      parent: anim, curve: VimaiMotion.bounceOut)),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: showBubble
                    ? KeyedSubtree(
                        key: ValueKey('bubble-$correct'), child: feedback!)
                    : _TitleChip(key: const ValueKey('title'), title: title),
              ),
            ),
            const SizedBox(width: 4),
            _HeaderMai(correct: correct),
          ],
        ),
      ),
    );
  }
}

class _TitleChip extends StatelessWidget {
  const _TitleChip({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(99),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: VimaiType.title.copyWith(fontSize: 18, color: VimaiColor.ink),
        ),
      ),
    );
  }
}

/// Mai in the corner: bobs while idle, cheers on every earned star and
/// encourages after a miss.
class _HeaderMai extends StatefulWidget {
  const _HeaderMai({required this.correct});
  final bool? correct;

  @override
  State<_HeaderMai> createState() => _HeaderMaiState();
}

class _HeaderMaiState extends State<_HeaderMai> {
  GameFxState? _fx;
  Timer? _calm;
  bool _cheering = false;
  int _pops = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fx = GameFx.maybeOf(context);
    if (fx != _fx) {
      _fx?.cheer.removeListener(_onCheer);
      _fx = fx;
      _fx?.cheer.addListener(_onCheer);
    }
  }

  @override
  void didUpdateWidget(covariant _HeaderMai oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.correct != oldWidget.correct && widget.correct != null) _pops++;
  }

  void _onCheer() {
    if (!mounted) return;
    setState(() {
      _cheering = true;
      _pops++;
    });
    _calm?.cancel();
    _calm = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _cheering = false);
    });
  }

  @override
  void dispose() {
    _calm?.cancel();
    _fx?.cheer.removeListener(_onCheer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = widget.correct == false
        ? MascotMood.encouraging
        : (_cheering || widget.correct == true
            ? MascotMood.celebrating
            : MascotMood.happy);
    return PopOnChange(
      trigger: _pops,
      amount: 0.18,
      child: SizedBox(
        width: 62,
        height: 62,
        child: IdleMascot(mood: mood, color: VimaiColor.mascot, size: 62),
      ),
    );
  }
}

/// Mai's speech bubble ("Giỏi lắm!" / "Thử lại nhé!"), shown in the header.
class GameFeedbackToast extends StatelessWidget {
  const GameFeedbackToast({super.key, this.correct, this.message});

  final bool? correct;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (correct == null || message == null) return const SizedBox.shrink();
    final color = correct! ? VimaiColor.correct : VimaiColor.retry;
    return Semantics(
      liveRegion: true,
      label: message,
      child: Align(
        alignment: Alignment.centerRight,
        child: CustomPaint(
          painter: _BubbleTailPainter(color: Colors.white),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(
                    correct! ? Icons.star_rounded : Icons.refresh_rounded,
                    color: Colors.white,
                    size: 22,
                    semanticLabel: correct! ? 'correct' : 'try again',
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VimaiType.title.copyWith(fontSize: 19, color: color),
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

class _BubbleTailPainter extends CustomPainter {
  _BubbleTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final path = Path()
      ..moveTo(size.width - 12, y - 7)
      ..lineTo(size.width, y)
      ..lineTo(size.width - 12, y + 7)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter old) => old.color != color;
}

/// "What to find" card: a big glyph tile, a short label for grown-ups and,
/// when [onTap] is set, a speaker so the child can hear the target again.
class GameTargetBanner extends StatelessWidget {
  const GameTargetBanner({
    super.key,
    required this.label,
    required this.glyph,
    required this.color,
    this.onTap,
  });

  final String label;
  final String glyph;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          if (onTap != null) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(color, Colors.white, 0.3)!, color],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.volume_up_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 10),
          ] else
            const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: VimaiType.cardTitle
                  .copyWith(color: VimaiColor.ink, fontSize: 18),
            ),
          ),
          const SizedBox(width: 8),
          PopOnChange(
            trigger: glyph,
            child: Container(
              constraints: const BoxConstraints(minWidth: 60, minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(color, Colors.white, 0.25)!, color],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Color.lerp(color, Colors.black, 0.3)!,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Text(
                glyph,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  shadows: [
                    Shadow(
                        color: Color(0x40000000),
                        offset: Offset(0, 2),
                        blurRadius: 2)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: 'Nghe lại: $label',
      child: GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: onTap, child: card),
    );
  }
}

/// Row of goal stars that fill as the child answers. Each new star flies
/// in from where the child tapped, then pops into its slot.
class GameProgressBar extends StatefulWidget {
  const GameProgressBar({
    super.key,
    required this.current,
    required this.total,
    required this.color,
  });

  final int current;
  final int total;
  final Color color;

  @override
  State<GameProgressBar> createState() => _GameProgressBarState();
}

class _GameProgressBarState extends State<GameProgressBar> {
  late int _landed = widget.current;
  final _slots = <GlobalKey>[];

  void _syncSlots() {
    while (_slots.length < widget.total) {
      _slots.add(GlobalKey());
    }
  }

  @override
  void didUpdateWidget(covariant GameProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSlots();
    if (widget.current < oldWidget.current || widget.current < _landed) {
      _landed = widget.current;
      return;
    }
    if (widget.current > oldWidget.current) {
      final fx = GameFx.maybeOf(context);
      fx?.burst();
      fx?.celebrate();
      for (var i = oldWidget.current; i < widget.current; i++) {
        final target = i;
        final slot = target < _slots.length ? _slots[target] : null;
        final box = slot?.currentContext?.findRenderObject() as RenderBox?;
        void land() {
          if (!mounted) return;
          setState(() => _landed =
              math.max(_landed, math.min(target + 1, widget.current)));
        }

        if (fx == null || box == null || !box.hasSize) {
          land();
        } else {
          fx.flyStar(
              toGlobal: box.localToGlobal(box.size.center(Offset.zero)),
              onLand: land);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncSlots();
    final total = math.max(0, widget.total);
    return Container(
      height: 46,
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                if (total == 0) return const SizedBox.shrink();
                const gap = 3.0;
                final size = ((c.maxWidth - gap * (total - 1)) / total)
                    .clamp(10.0, 30.0);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < total; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      SizedBox(
                        key: _slots[i],
                        width: size,
                        height: size,
                        child: i < _landed
                            ? TweenAnimationBuilder<double>(
                                key: ValueKey('star-on-$i'),
                                tween: Tween(begin: 0.2, end: 1),
                                duration: VimaiMotion.of(
                                    context, const Duration(milliseconds: 520)),
                                curve: Curves.elasticOut,
                                builder: (context, v, child) =>
                                    Transform.scale(scale: v, child: child),
                                child: GameStar(size: size),
                              )
                            : GameStar(
                                size: size,
                                filled: false,
                                emptyColor: const Color(0xFFD3D8E4)),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [goldMid, goldDeep]),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${widget.current} / ${widget.total}',
              style: VimaiType.cardTitle
                  .copyWith(fontSize: 16, color: Colors.white, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Win screen: trophy, 1–3 stars from accuracy, confetti, big "Chơi tiếp".
class GameCompletePanel extends StatelessWidget {
  const GameCompletePanel({
    super.key,
    required this.score,
    required this.wrong,
    required this.total,
    required this.onRetry,
    this.onContinue,
    this.hero,
  });

  final int score;
  final int wrong;
  final int total;
  final VoidCallback onRetry;
  final VoidCallback? onContinue;

  /// Optional game-specific hero (rocket launching, train leaving…).
  final Widget? hero;

  static int starsFor(int score, int wrong) {
    final attempts = score + wrong;
    if (attempts <= 0) return 1;
    final accuracy = score / attempts;
    if (accuracy >= 0.85) return 3;
    if (accuracy >= 0.6) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return SpeakOnOpen(
      lines: const [KidGuide.gameWin],
      delay: const Duration(milliseconds: 900),
      child: _WinPanel(
        stars: starsFor(score, wrong),
        score: score,
        wrong: wrong,
        onRetry: onRetry,
        onContinue: onContinue ?? () => popLearningScreen(context),
        hero: hero,
      ),
    );
  }
}

class _WinPanel extends StatefulWidget {
  const _WinPanel({
    required this.stars,
    required this.score,
    required this.wrong,
    required this.onRetry,
    required this.onContinue,
    this.hero,
  });

  final int stars;
  final int score;
  final int wrong;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  final Widget? hero;

  @override
  State<_WinPanel> createState() => _WinPanelState();
}

class _WinPanelState extends State<_WinPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _phase(double start, double end, {Curve curve = Curves.elasticOut}) {
    final v = ((_c.value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(v);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ConfettiRain(),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 560;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - 20)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => _card(compact),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _card(bool compact) {
    final heroSize = compact ? 104.0 : 140.0;
    final cardIn = _phase(0, 0.3, curve: Curves.easeOutBack);
    return Opacity(
      opacity: cardIn.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.85 + 0.15 * cardIn,
        child: Container(
          padding: EdgeInsets.fromLTRB(20, compact ? 12 : 18, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFFFFE08A), width: 4),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 30,
                  offset: Offset(0, 14))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: heroSize,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Transform.rotate(
                      angle: _c.value * math.pi * 0.5,
                      child: CustomPaint(
                          size: Size.square(heroSize * 1.25),
                          painter: _RaysPainter()),
                    ),
                    Transform.scale(
                      scale: _phase(0.1, 0.5),
                      child: widget.hero ??
                          CustomPaint(
                            size: Size.square(heroSize * 0.82),
                            painter: TrophyPainter(
                                shine: _phase(0.4, 1, curve: Curves.easeInOut)),
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 4 : 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: EdgeInsets.only(
                          left: 6, right: 6, bottom: i == 1 ? 10 : 0),
                      child: Transform.scale(
                        scale: i < widget.stars
                            ? _phase(0.3 + i * 0.15, 0.65 + i * 0.15)
                            : 1,
                        child: GameStar(
                          size: i == 1 ? 62 : 50,
                          filled: i < widget.stars,
                          emptyColor: const Color(0xFFE3E6EE),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: compact ? 4 : 8),
              Text('Giỏi lắm!',
                  style: VimaiType.display.copyWith(
                      color: VimaiColor.correct, fontSize: compact ? 30 : 36)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Tally(
                      icon: Icons.check_rounded,
                      color: VimaiColor.correct,
                      value: widget.score,
                      label: 'đúng'),
                  const SizedBox(width: 12),
                  _Tally(
                      icon: Icons.refresh_rounded,
                      color: VimaiColor.retry,
                      value: widget.wrong,
                      label: 'sai'),
                ],
              ),
              SizedBox(height: compact ? 14 : 20),
              SizedBox(
                height: 74,
                width: double.infinity,
                child: ChunkyButton(
                  color: VimaiColor.correct,
                  depth: 7,
                  radius: 28,
                  semanticLabel: 'Chơi tiếp',
                  onTap: widget.onRetry,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 40),
                      const SizedBox(width: 6),
                      Text('Chơi tiếp',
                          style: VimaiType.display.copyWith(
                              color: Colors.white, fontSize: 28, height: 1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 58,
                width: double.infinity,
                child: ChunkyButton(
                  color: const Color(0xFFEFF2F8),
                  outline: const Color(0xFFDDE2EC),
                  depth: 5,
                  radius: 24,
                  semanticLabel: 'Về khu vui chơi',
                  onTap: widget.onContinue,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.grid_view_rounded,
                          color: VimaiColor.ink, size: 24),
                      const SizedBox(width: 8),
                      Text('Trò khác',
                          style: VimaiType.button
                              .copyWith(color: VimaiColor.ink, fontSize: 20)),
                    ],
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

class _Tally extends StatelessWidget {
  const _Tally(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text('$value $label',
              style: VimaiType.label.copyWith(color: color, fontSize: 16)),
        ],
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFE680).withValues(alpha: 0.75),
          const Color(0xFFFFE680).withValues(alpha: 0)
        ]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final ray = Paint()
      ..color = const Color(0xFFFFD84D).withValues(alpha: 0.32);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - 0.12) * r, c.dy + math.sin(a - 0.12) * r)
        ..lineTo(c.dx + math.cos(a + 0.12) * r, c.dy + math.sin(a + 0.12) * r)
        ..close();
      canvas.drawPath(path, ray);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Constrained playfield (≤ [GameBoardMetrics.maxWidth]) drawn as a sky
/// window. Reports its real size so games lay tokens out in board space.
class GameBoard extends StatefulWidget {
  const GameBoard({
    super.key,
    required this.child,
    required this.onSize,
    this.color = VimaiColor.skySoft,
  });

  final Widget child;
  final ValueChanged<Size> onSize;
  final Color color;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  Size? _reported;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitted =
            GameBoardMetrics.fit(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox(
            key: const ValueKey('game-playfield'),
            width: fitted.width,
            height: fitted.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.42),
                    Color.lerp(widget.color, Colors.white, 0.4)!
                        .withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(VimaiRadius.xl),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9), width: 4),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x2A0B3D6B),
                      blurRadius: 22,
                      offset: Offset(0, 10))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(VimaiRadius.xl - 4),
                child: LayoutBuilder(
                  builder: (context, board) {
                    final size = Size(board.maxWidth, board.maxHeight);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || size.width < 8 || size.height < 8) return;
                      final last = _reported;
                      if (last != null &&
                          (last.width - size.width).abs() < 0.5 &&
                          (last.height - size.height).abs() < 0.5) {
                        return;
                      }
                      _reported = size;
                      widget.onSize(size);
                    });
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                            painter: _BoardDecorPainter(), size: Size.infinite),
                        widget.child,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    void cloud(double x, double y, double r) {
      canvas.drawCircle(Offset(x, y), r, paint);
      canvas.drawCircle(Offset(x + r * 0.9, y + r * 0.1), r * 0.75, paint);
      canvas.drawCircle(Offset(x - r * 0.8, y + r * 0.2), r * 0.6, paint);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTRB(x - r * 1.3, y, x + r * 1.6, y + r * 0.8),
              Radius.circular(r)),
          paint);
    }

    cloud(size.width * 0.2, size.height * 0.14, size.shortestSide * 0.07);
    cloud(size.width * 0.76, size.height * 0.36, size.shortestSide * 0.06);
    cloud(size.width * 0.4, size.height * 0.7, size.shortestSide * 0.08);
    // Soft grass strip at the bottom of the window.
    final grass = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 18)
      ..quadraticBezierTo(size.width * 0.25, size.height - 32, size.width * 0.5,
          size.height - 20)
      ..quadraticBezierTo(
          size.width * 0.75, size.height - 8, size.width, size.height - 24)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(grass,
        Paint()..color = const Color(0xFF7BD66A).withValues(alpha: 0.75));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A falling letter: a glossy candy bubble that wobbles on a miss and pops
/// big on a catch.
class GameLetterToken extends StatelessWidget {
  const GameLetterToken({
    super.key,
    required this.character,
    required this.size,
    required this.color,
    required this.onTap,
    this.shake = false,
    this.celebrate = false,
    this.semanticLabel,
  });

  final String character;
  final double size;
  final Color color;
  final VoidCallback onTap;
  final bool shake;
  final bool celebrate;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final duration = VimaiMotion.of(context, const Duration(milliseconds: 260));
    return Semantics(
      button: true,
      label: semanticLabel ?? character,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: ShakeOnChange(
            trigger: shake ? true : null,
            child: AnimatedScale(
              scale: celebrate ? 1.22 : 1,
              duration: duration,
              curve: VimaiMotion.bounceOut,
              child: AnimatedOpacity(
                opacity: celebrate ? 0.0 : 1,
                duration:
                    VimaiMotion.of(context, const Duration(milliseconds: 420)),
                curve: const Interval(0.5, 1),
                child: CustomPaint(
                  painter:
                      _BubblePainter(color: shake ? VimaiColor.retry : color),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.16),
                      child: FittedBox(
                        child: Text(
                          character,
                          style: TextStyle(
                            fontSize: size * 0.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                            shadows: const [
                              Shadow(
                                  color: Color(0x55000000),
                                  offset: Offset(0, 2),
                                  blurRadius: 3)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
        c.translate(0, 3),
        r,
        Paint()
          ..color =
              Color.lerp(color, Colors.black, 0.35)!.withValues(alpha: 0.55));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.95,
          colors: [
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.18)!
          ],
          stops: const [0, 0.6, 1],
        ).createShader(rect),
    );
    canvas.drawCircle(
      c,
      r - 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(-r * 0.5, -r * 0.56),
          width: r * 0.36,
          height: r * 0.2),
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
    canvas.drawCircle(c.translate(r * 0.5, r * 0.45), r * 0.07,
        Paint()..color = Colors.white.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.color != color;
}

/// Card table: lays [itemCount] cards out so they all fit without
/// scrolling, as big as the space allows, on a soft play mat.
class GameCardGrid extends StatelessWidget {
  const GameCardGrid({
    super.key,
    required this.itemCount,
    required this.builder,
    this.aspect = 0.8,
  });

  final int itemCount;
  final IndexedWidgetBuilder builder;

  /// Card width / height.
  final double aspect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (itemCount == 0) return const SizedBox.shrink();
        const pad = 12.0;
        const gap = 10.0;
        final maxW = math.min(constraints.maxWidth, 620.0) - pad * 2;
        final maxH = constraints.maxHeight - pad * 2;
        var best = (cols: 3, w: 0.0, h: 0.0);
        for (var cols = 2; cols <= 6; cols++) {
          final rows = (itemCount / cols).ceil();
          final cellW = (maxW - gap * (cols - 1)) / cols;
          final cellH = (maxH - gap * (rows - 1)) / rows;
          if (cellW <= 0 || cellH <= 0) continue;
          var h = math.min(cellH, cellW / aspect);
          var w = h * aspect;
          w = math.min(w, 150);
          h = w / aspect;
          if (w > best.w) best = (cols: cols, w: w, h: h);
        }
        final cols = best.cols;
        final rows = (itemCount / cols).ceil();
        final w = math.max(40.0, best.w);
        final h = math.max(48.0, best.h);
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.all(pad),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var r = 0; r < rows; r++) ...[
                    if (r > 0) const SizedBox(height: gap),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var c = 0; c < cols; c++) ...[
                          if (c > 0) const SizedBox(width: gap),
                          SizedBox(
                            width: w,
                            height: h,
                            child: r * cols + c < itemCount
                                ? builder(context, r * cols + c)
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A playing card that really flips (3D, around the Y axis). Matched cards
/// glow and bob gently.
class GameFlipCard extends StatelessWidget {
  const GameFlipCard({
    super.key,
    required this.open,
    required this.face,
    required this.onTap,
    this.matched = false,
    this.color = VimaiColor.grape,
    this.semanticLabel,
  });

  final bool open;
  final bool matched;
  final Widget face;
  final Color color;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final duration = VimaiMotion.of(context, const Duration(milliseconds: 420));
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedScale(
          scale: matched ? 1.04 : 1,
          duration: duration,
          curve: VimaiMotion.bounceOut,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: open || matched ? 1 : 0),
            duration: duration,
            curve: Curves.easeInOutBack,
            builder: (context, v, _) {
              final angle = v * math.pi;
              final showFace = v >= 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0014)
                  ..rotateY(angle),
                child: showFace
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _CardFace(
                            matched: matched, color: color, child: face),
                      )
                    : _CardBack(color: color),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final edge = Color.lerp(color, Colors.black, 0.3)!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: edge,
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 5))
        ],
      ),
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, 0.25)!, color],
          ),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: CustomPaint(
          painter: _CardBackPainter(),
          child: LayoutBuilder(
            builder: (context, c) => Center(
              child: GameStar(size: math.min(c.maxWidth, c.maxHeight) * 0.42),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.16);
    const step = 12.0;
    for (var y = 6.0; y < size.height; y += step) {
      for (var x = ((y / step).floor().isOdd ? 12.0 : 6.0);
          x < size.width;
          x += step) {
        canvas.drawCircle(Offset(x, y), 2, dot);
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
          const Radius.circular(12)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardFace extends StatelessWidget {
  const _CardFace(
      {required this.matched, required this.color, required this.child});
  final bool matched;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ring = matched ? VimaiColor.correct : Colors.white;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: matched ? const Color(0xFF1E9E4A) : const Color(0xFFD9DCE6),
        boxShadow: [
          BoxShadow(
            color: matched
                ? VimaiColor.correct.withValues(alpha: 0.55)
                : const Color(0x33000000),
            blurRadius: matched ? 16 : 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFFF7EC)]),
          border: Border.all(color: ring, width: 3),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: FittedBox(child: child)),
            ),
            if (matched)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                      color: VimaiColor.correct, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded,
                      size: 15, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Colours for answer buttons, balloons and cards.
const gamePalette = [
  Color(0xFFFF4F86),
  Color(0xFF4C8DDB),
  Color(0xFF8B5CF6),
  Color(0xFF14B8C4),
  Color(0xFFD946EF),
  Color(0xFF6366F1),
];
