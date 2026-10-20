import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/vimai_tokens.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_ui.dart';
import '../../shared/widgets/vimai_world.dart';

/// A colour emoji drawn at [size] with no extra line height, so it centres
/// cleanly inside circles and cards.
class ExploreEmoji extends StatelessWidget {
  const ExploreEmoji(this.emoji, {super.key, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        emoji,
        textAlign: TextAlign.center,
        textScaler: TextScaler.noScaling,
        style: TextStyle(fontSize: size, height: 1.1, decoration: TextDecoration.none),
      ),
    );
  }
}

/// Soft illustrated backdrop: a [color]-tinted sky fading into cream with
/// floating bubbles and sparkles.
class ExploreBackdrop extends StatelessWidget {
  const ExploreBackdrop({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(color, Colors.white, 0.55)!,
                Color.lerp(color, VimaiColor.bgWarmCream, 0.86)!,
                VimaiColor.bgWarmCream,
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _BubblePainter(color))),
        child,
      ],
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.32);
    final tint = Paint()..color = color.withValues(alpha: 0.08);
    for (var i = 0; i < 14; i++) {
      final c = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.9);
      final r = 18 + rnd.nextDouble() * 70;
      canvas.drawCircle(c, r, i.isEven ? fill : tint);
    }
    final spark = Paint()..color = Colors.white.withValues(alpha: 0.75);
    for (var i = 0; i < 18; i++) {
      final c = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.6);
      final s = 2.0 + rnd.nextDouble() * 3;
      final path = Path()
        ..moveTo(c.dx, c.dy - s * 2)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + s * 2, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s * 2)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - s * 2, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s * 2);
      canvas.drawPath(path, spark);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.color != color;
}

/// A big round icon button (≥64px) for children.
class ExploreRoundButton extends StatelessWidget {
  const ExploreRoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.color = VimaiColor.ink,
    this.background = Colors.white,
    this.size = 64,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Pressable(
      semanticLabel: semanticLabel,
      borderRadius: BorderRadius.circular(size),
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.35,
        duration: VimaiMotion.of(context, VimaiMotion.feedback),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Icon(icon, color: color, size: size * 0.5),
        ),
      ),
    );
  }
}

/// Header row: back button, title pill with an emoji, optional trailing.
class ExploreTopBar extends StatelessWidget {
  const ExploreTopBar({
    super.key,
    required this.title,
    required this.emoji,
    required this.color,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final String emoji;
  final Color color;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // On phones the title gets the whole pill; the topic picture is on screen anyway.
    final narrow = MediaQuery.sizeOf(context).width < 420;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          ExploreRoundButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Quay lại',
            color: color,
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: narrow
                    ? const EdgeInsets.symmetric(horizontal: 14, vertical: 6)
                    : const EdgeInsets.fromLTRB(8, 6, 18, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(VimaiRadius.pill),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!narrow) ...[
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Color.lerp(color, Colors.white, 0.8), shape: BoxShape.circle),
                        child: ExploreEmoji(emoji, size: 26),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: VimaiType.title.copyWith(
                            color: Color.lerp(color, VimaiColor.ink, 0.35), fontSize: narrow ? 18 : 20, height: 1.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          trailing ?? const SizedBox(width: 64),
        ],
      ),
    );
  }
}

/// Mai with a speech bubble. Tapping Mai or the bubble replays her line.
class MaiSays extends StatelessWidget {
  const MaiSays({
    super.key,
    required this.text,
    required this.onTap,
    this.mood = MascotMood.happy,
    this.mascotSize = 84,
    this.color = VimaiColor.mascot,
  });

  final String text;
  final VoidCallback onTap;
  final MascotMood mood;
  final double mascotSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Mai: $text',
      borderRadius: BorderRadius.circular(VimaiRadius.xl),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IdleMascot(mood: mood, color: color, size: mascotSize),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(VimaiRadius.xl),
                boxShadow: VimaiShadow.card,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      style: VimaiType.title.copyWith(fontSize: 18, height: 1.2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.volume_up_rounded, color: VimaiColor.primaryPink, size: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fades and pops a child in, staggered by [index]. Instant under reduced motion.
class ExplorePopIn extends StatelessWidget {
  const ExplorePopIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = VimaiMotion.of(context, Duration(milliseconds: 380 + math.min(index, 12) * 55));
    if (duration == Duration.zero) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      child: child,
      builder: (context, t, child) {
        // The first part of each tile's timeline is its stagger delay.
        final delay = math.min(index, 12) * 55 / duration.inMilliseconds;
        final local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
        final eased = Curves.easeOutBack.transform(local);
        return Opacity(
          opacity: Curves.easeOut.transform(local),
          child: Transform.scale(scale: 0.8 + 0.2 * eased, child: child),
        );
      },
    );
  }
}
