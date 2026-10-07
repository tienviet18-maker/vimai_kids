import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/vimai_tokens.dart';

/// A chunky, toy-like 3D button: a glossy coloured face sitting on a darker
/// "edge" that sinks when the child presses it.
///
/// The whole rectangle is the hit target (opaque), so taps register on Safari
/// without hunting for the child.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color = VimaiColor.coral,
    this.depth = 6,
    this.radius = VimaiRadius.lg,
    this.circle = false,
    this.semanticLabel,
    this.padding = EdgeInsets.zero,
    this.outline = Colors.white,
    this.outlineWidth = 3,
    this.glow,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double depth;
  final double radius;
  final bool circle;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;
  final Color outline;
  final double outlineWidth;

  /// Optional coloured halo (e.g. green when the answer is right).
  final Color? glow;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v || !mounted) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final base = enabled
        ? widget.color
        : Color.lerp(widget.color, const Color(0xFFB9BEC6), 0.65)!;
    final edge = Color.lerp(base, Colors.black, 0.28)!;
    final top = Color.lerp(base, Colors.white, 0.28)!;
    final sink = _down ? widget.depth * 0.75 : 0.0;
    final duration = VimaiMotion.of(context, VimaiMotion.tap);
    final shape = widget.circle ? BoxShape.circle : BoxShape.rectangle;
    final radius = widget.circle ? null : BorderRadius.circular(widget.radius);

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: () => _set(false),
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              top: widget.depth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: edge,
                  shape: shape,
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.glow ?? Colors.black)
                          .withValues(alpha: widget.glow == null ? 0.18 : 0.55),
                      blurRadius: widget.glow == null ? 10 : 22,
                      spreadRadius: widget.glow == null ? 0 : 3,
                      offset: Offset(0, widget.glow == null ? 6 : 0),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedPadding(
              duration: duration,
              curve: Curves.easeOut,
              padding: EdgeInsets.only(top: sink, bottom: widget.depth - sink),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: shape,
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [top, base],
                  ),
                  border: widget.outlineWidth > 0
                      ? Border.all(
                          color: widget.outline, width: widget.outlineWidth)
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glossy highlight across the top of the face.
                    if (widget.circle)
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: const Alignment(-0.45, -0.62),
                          widthFactor: 0.34,
                          heightFactor: 0.16,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: FractionallySizedBox(
                          widthFactor: 0.86,
                          child: Container(
                            height: 10,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.32),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    Padding(padding: widget.padding, child: widget.child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shakes its child sideways each time [trigger] changes to a new non-null
/// value — a gentle "not quite" wobble, never a punishment.
class ShakeOnChange extends StatefulWidget {
  const ShakeOnChange(
      {super.key,
      required this.trigger,
      required this.child,
      this.distance = 9});

  final Object? trigger;
  final Widget child;
  final double distance;

  @override
  State<ShakeOnChange> createState() => _ShakeOnChangeState();
}

class _ShakeOnChangeState extends State<ShakeOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 460));

  @override
  void didUpdateWidget(covariant ShakeOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null &&
        widget.trigger != oldWidget.trigger &&
        !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final dx =
            t == 0 || t == 1 ? 0.0 : _wave(t) * widget.distance * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }

  static double _wave(double t) {
    // Three soft swings.
    const turns = 3.0;
    final x = t * turns * 2;
    final f = x - x.floorToDouble();
    final tri = f < 0.5 ? f * 4 - 1 : 3 - f * 4;
    return tri;
  }
}

/// Springs its child up (scale) each time [trigger] changes.
class PopOnChange extends StatefulWidget {
  const PopOnChange(
      {super.key,
      required this.trigger,
      required this.child,
      this.amount = 0.22});

  final Object? trigger;
  final Widget child;
  final double amount;

  @override
  State<PopOnChange> createState() => _PopOnChangeState();
}

class _PopOnChangeState extends State<PopOnChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520), value: 1);

  @override
  void didUpdateWidget(covariant PopOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger &&
        !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        // Quick rise then an elastic settle back to 1.
        final s = t >= 1
            ? 1.0
            : 1 +
                widget.amount *
                    Curves.easeOut.transform(1 - t) *
                    (t < 0.18 ? t / 0.18 : 1);
        return Transform.scale(scale: s, child: child);
      },
      child: widget.child,
    );
  }
}
