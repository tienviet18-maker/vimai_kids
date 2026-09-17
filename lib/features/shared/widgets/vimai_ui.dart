import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/vimai_tokens.dart';

class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.semanticLabel,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final duration = VimaiMotion.of(context, _down ? VimaiMotion.tap : VimaiMotion.hover);
    final scale = _down ? 0.94 : (_hover ? 1.015 : 1.0);
    final child = AnimatedScale(
      scale: scale,
      duration: duration,
      curve: _down ? Curves.easeOutCubic : VimaiMotion.bounceOut,
      child: widget.child,
    );
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(VimaiRadius.md),
            // Opaque hit target so Safari registers taps without child hunting.
            onTap: widget.onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    widget.onTap!();
                  },
            onHighlightChanged: (v) => setState(() => _down = v),
            child: child,
          ),
        ),
      ),
    );
  }
}

class KidButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool expanded;

  const KidButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = VimaiColor.coral,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
      child: Pressable(
        semanticLabel: label,
        borderRadius: BorderRadius.circular(VimaiRadius.lg),
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(VimaiRadius.lg),
            boxShadow: VimaiShadow.soft,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(label, style: VimaiType.button.copyWith(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class PageScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? background;
  final bool maxWidth;

  const PageScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.leading,
    this.background,
    this.maxWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background ?? VimaiColor.cream,
      appBar: title == null
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              leading: leading,
              title: Text(title!, style: VimaiType.title),
              actions: actions,
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(0, maxWidth ? VimaiSpace.maxWide : constraints.maxWidth);
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width.toDouble(),
                height: constraints.maxHeight,
                child: body,
              ),
            );
          },
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Text(text, style: VimaiType.title.copyWith(fontSize: 18)),
    );
  }
}

class HubTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String glyph;
  final Color color;
  final Color soft;
  final VoidCallback onTap;

  const HubTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: '$title. $subtitle',
      borderRadius: BorderRadius.circular(VimaiRadius.lg),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: VimaiColor.surface,
          borderRadius: BorderRadius.circular(VimaiRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.28), width: 1.6),
          boxShadow: VimaiShadow.soft,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(VimaiRadius.md),
                ),
                child: Text(
                  glyph,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: VimaiType.cardTitle.copyWith(color: color)),
                    const SizedBox(height: 2),
                    Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: VimaiType.cardBody),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExploreCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String glyph;
  final Color color;
  final Color soft;
  final double progress;
  final VoidCallback onTap;

  const ExploreCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.color,
    required this.soft,
    required this.onTap,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: title,
      borderRadius: BorderRadius.circular(VimaiRadius.lg),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VimaiRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [VimaiColor.surface, soft.withValues(alpha: 0.7)],
          ),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 1.5),
          boxShadow: VimaiShadow.soft,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  glyph,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                ),
              ),
              const Spacer(),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: VimaiType.cardTitle.copyWith(color: color)),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: VimaiType.cardBody),
              if (progress > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.12),
                    color: color,
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

class LessonFeedback extends StatelessWidget {
  final bool? correct;
  final String? message;

  const LessonFeedback({super.key, this.correct, this.message});

  @override
  Widget build(BuildContext context) {
    if (correct == null || message == null) return const SizedBox.shrink();
    final color = correct! ? VimaiColor.correct : VimaiColor.retry;
    return Semantics(
      liveRegion: true,
      label: message,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: AnimatedScale(
          scale: 1,
          duration: VimaiMotion.of(context, VimaiMotion.feedback),
          child: TweenAnimationBuilder<double>(
            key: ValueKey(message),
            tween: Tween(begin: 0.92, end: 1),
            duration: VimaiMotion.of(context, VimaiMotion.feedback),
            curve: VimaiMotion.curve,
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(VimaiRadius.md),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  correct! ? Icons.check_circle_rounded : Icons.refresh_rounded,
                  color: color,
                  size: 28,
                  semanticLabel: correct! ? 'correct' : 'try again',
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: VimaiType.cardTitle.copyWith(color: color, fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

class SoftSurface extends StatelessWidget {
  const SoftSurface({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(VimaiSpace.md),
    this.borderColor,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? VimaiColor.surface,
        borderRadius: BorderRadius.circular(VimaiRadius.lg),
        border: Border.all(color: borderColor ?? VimaiColor.line, width: 1.4),
        boxShadow: VimaiShadow.soft,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class HubIntro extends StatelessWidget {
  const HubIntro({
    super.key,
    required this.title,
    required this.body,
    required this.color,
    required this.glyph,
    this.icon,
  });

  final String title;
  final String body;
  final Color color;
  final String glyph;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SoftSurface(
      color: color.withValues(alpha: 0.08),
      borderColor: color.withValues(alpha: 0.22),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(VimaiRadius.md),
              boxShadow: VimaiShadow.soft,
            ),
            child: icon != null && glyph.isEmpty
                ? Icon(icon, color: Colors.white, size: 30)
                : Text(glyph, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: VimaiType.cardTitle.copyWith(color: color, fontSize: 18)),
                const SizedBox(height: 4),
                Text(body, style: VimaiType.cardBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 56,
    this.child,
  });

  final double value;
  final Color color;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: VimaiMotion.of(context, VimaiMotion.enter),
        curve: VimaiMotion.curve,
        builder: (context, v, _) {
          return CustomPaint(
            painter: _RingPainter(value: v, color: color),
            child: Center(child: child),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.12;
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke);
    final bg = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(inset, -1.57, 6.2832, false, bg);
    if (value > 0) canvas.drawArc(inset, -1.57, 6.2832 * value, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value || old.color != color;
}

class WorldTile extends StatelessWidget {
  const WorldTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.look,
    required this.onTap,
    this.progress = 0,
  });

  final String title;
  final String subtitle;
  final SubjectLook look;
  final VoidCallback onTap;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: '$title. $subtitle',
      borderRadius: BorderRadius.circular(VimaiRadius.lg),
      onTap: onTap,
        child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VimaiRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [look.soft, look.color.withValues(alpha: 0.16)],
          ),
          border: Border.all(color: look.color.withValues(alpha: 0.28), width: 1.6),
          boxShadow: VimaiShadow.soft,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                look.cue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: look.color,
                  height: 1.1,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: VimaiType.cardTitle.copyWith(color: look.color)),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: VimaiType.cardBody),
              if (progress > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.clamp(0, 1)),
                    duration: VimaiMotion.of(context, VimaiMotion.enter),
                    builder: (context, v, _) {
                      return LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        backgroundColor: look.color.withValues(alpha: 0.12),
                        color: look.color,
                      );
                    },
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

class LessonStage extends StatelessWidget {
  const LessonStage({
    super.key,
    required this.color,
    required this.child,
    this.companion,
  });

  final Color color;
  final Widget child;
  final Widget? companion;

  @override
  Widget build(BuildContext context) {
    return SoftSurface(
      color: const Color(0xFFFFF8EE),
      borderColor: color.withValues(alpha: 0.28),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VimaiRadius.md),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, const Color(0xFFFFF8EE), 0.92)!,
              const Color(0xFFFFF1DC),
              Color.lerp(color, Colors.white, 0.85)!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (companion != null) ...[
                companion!,
                const SizedBox(height: 8),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class PlaygroundBackdrop extends StatelessWidget {
  const PlaygroundBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _PlaygroundPainter())),
        ),
        child,
      ],
    );
  }
}

class _PlaygroundPainter extends CustomPainter {
  const _PlaygroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    void blob(Offset c, double r, Color color) {
      canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: 0.18));
    }

    blob(Offset(size.width * 0.08, size.height * 0.12), 72, VimaiColor.coral);
    blob(Offset(size.width * 0.92, size.height * 0.18), 88, VimaiColor.sky);
    blob(Offset(size.width * 0.15, size.height * 0.78), 64, VimaiColor.mint);
    blob(Offset(size.width * 0.88, size.height * 0.72), 70, VimaiColor.honey);
    blob(Offset(size.width * 0.5, size.height * 0.06), 40, VimaiColor.peach);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
