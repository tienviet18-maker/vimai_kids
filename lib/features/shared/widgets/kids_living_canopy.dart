import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/vimai_tokens.dart';
import 'vimai_mascot.dart';
import 'vimai_world.dart';

/// Warm paper canopy ground.
const Color kCanopyPaper = Color(0xFFFDFBF4);
const Color kCanopyGrass = Color(0xFF8FCB7A);
const Color kCanopyGrassDeep = Color(0xFF6FA85C);
const Color kCanopyHill = Color(0xFFA8D48F);
const Color kCanopyPath = Color(0xFFD9B07A);
const Color kCanopyOak = Color(0xFFB87333);
const Color kCanopyLeaf = Color(0xFF5FAE6A);

const double kKidTouchMin = 56;
const double kHabitatIsland = 90;

/// Elastic press feedback for child taps: 0.94 → 1.0 with easeOutBack.
class TactileNode extends StatefulWidget {
  const TactileNode({
    super.key,
    required this.child,
    required this.onTap,
    this.minSize = kKidTouchMin,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final double minSize;
  final String? semanticLabel;

  @override
  State<TactileNode> createState() => _TactileNodeState();
}

class _TactileNodeState extends State<TactileNode> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _scale = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    _controller.forward();
    HapticFeedback.selectionClick();
  }

  void _up([_]) {
    _controller.reverse();
  }

  void _cancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _cancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: widget.minSize, minHeight: widget.minSize),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Soft layered hills on warm paper — expands naturally on wide canvases.
class CanopyHillsBackground extends StatelessWidget {
  const CanopyHillsBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: kCanopyPaper,
      child: CustomPaint(
        painter: _CanopyHillsPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _CanopyHillsPainter extends CustomPainter {
  const _CanopyHillsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void hill(Path path, Color color, double blur) {
      final shadow = Paint()
        ..color = const Color(0x22000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas.drawPath(path.shift(const Offset(0, 6)), shadow);
      canvas.drawPath(path, Paint()..color = color);
    }

    final far = Path()
      ..moveTo(0, h * 0.42)
      ..quadraticBezierTo(w * 0.22, h * 0.32, w * 0.48, h * 0.4)
      ..quadraticBezierTo(w * 0.78, h * 0.5, w, h * 0.36)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    hill(far, kCanopyHill.withValues(alpha: 0.55), 10);

    final mid = Path()
      ..moveTo(0, h * 0.58)
      ..quadraticBezierTo(w * 0.28, h * 0.48, w * 0.55, h * 0.56)
      ..quadraticBezierTo(w * 0.82, h * 0.64, w, h * 0.52)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    hill(mid, kCanopyGrass.withValues(alpha: 0.72), 12);

    final near = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.3, h * 0.68, w * 0.62, h * 0.76)
      ..quadraticBezierTo(w * 0.88, h * 0.84, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    hill(near, kCanopyGrassDeep.withValues(alpha: 0.55), 14);

    final pathPaint = Paint()
      ..color = kCanopyPath.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.min(48, w * 0.08)
      ..strokeCap = StrokeCap.round;
    final trail = Path()
      ..moveTo(w * 0.5, h * 0.34)
      ..cubicTo(w * 0.42, h * 0.44, w * 0.62, h * 0.52, w * 0.48, h * 0.62)
      ..cubicTo(w * 0.36, h * 0.7, w * 0.58, h * 0.78, w * 0.5, h * 0.88);
    canvas.drawPath(trail, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Organic leaf control — rest / leave play (56×56 child target).
class CanopyLeafButton extends StatelessWidget {
  const CanopyLeafButton({super.key, required this.onTap, this.label = 'Nghỉ ngơi'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TactileNode(
      semanticLabel: label,
      minSize: kKidTouchMin,
      onTap: onTap,
      child: Container(
        width: kKidTouchMin,
        height: kKidTouchMin,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x141B3B2B), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: const CustomPaint(painter: _LeafPainter()),
      ),
    );
  }
}

/// Interface sound / BGM toggle (wires to profile.soundEnabled when available).
class CanopyBgmToggle extends StatelessWidget {
  const CanopyBgmToggle({super.key, required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return TactileNode(
      semanticLabel: enabled ? 'Tắt âm thanh' : 'Bật âm thanh',
      minSize: kKidTouchMin,
      onTap: () => onChanged(!enabled),
      child: Container(
        width: kKidTouchMin,
        height: kKidTouchMin,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? VimaiColor.primaryPink : const Color(0xFFE8D9C4),
            width: 2.5,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x141B3B2B), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Icon(
          enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          color: enabled ? VimaiColor.primaryPink : VimaiColor.inkSoft,
          size: 26,
        ),
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  const _LeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final leaf = Path()
      ..moveTo(cx, cy - 16)
      ..quadraticBezierTo(cx + 16, cy - 2, cx, cy + 16)
      ..quadraticBezierTo(cx - 16, cy - 2, cx, cy - 16)
      ..close();
    canvas.drawPath(
      leaf,
      Paint()..color = kCanopyLeaf,
    );
    canvas.drawLine(
      Offset(cx, cy - 12),
      Offset(cx, cy + 12),
      Paint()
        ..color = const Color(0xFF3F7A48)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bronze acorn parent gate — hold 3s with circular progress.
class ParentOakGate extends StatefulWidget {
  const ParentOakGate({super.key, required this.onUnlocked, this.label = 'Phụ huynh'});

  final VoidCallback onUnlocked;
  final String label;

  @override
  State<ParentOakGate> createState() => _ParentOakGateState();
}

class _ParentOakGateState extends State<ParentOakGate> with SingleTickerProviderStateMixin {
  static const _hold = Duration(seconds: 3);
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: _hold);
    _progress.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        widget.onUnlocked();
        _progress.value = 0;
      }
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _start() {
    _progress.forward(from: 0);
  }

  void _cancel() {
    _progress.stop();
    _progress.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _start(),
        onTapUp: (_) => _cancel(),
        onTapCancel: _cancel,
        child: SizedBox(
          width: kKidTouchMin,
          height: kKidTouchMin,
          child: AnimatedBuilder(
            animation: _progress,
            builder: (context, child) {
              return CustomPaint(
                painter: _OakGatePainter(progress: _progress.value),
                child: child,
              );
            },
            child: const Center(
              child: Icon(Icons.lock_rounded, size: 26, color: Color(0xFF5C3A1E)),
            ),
          ),
        ),
      ),
    );
  }
}

class _OakGatePainter extends CustomPainter {
  const _OakGatePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 2;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = kCanopyOak
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    // Soft bronze fill ring
    canvas.drawCircle(center, r - 5, Paint()..color = kCanopyOak.withValues(alpha: 0.18));
    if (progress > 0) {
      final arc = Paint()
        ..color = VimaiColor.honey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r - 1),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OakGatePainter oldDelegate) => oldDelegate.progress != progress;
}

/// Center stage: breathing Mai + Today's Discovery Nest (Hero Discovery Hearth).
class DiscoveryNest extends StatelessWidget {
  const DiscoveryNest({
    super.key,
    required this.mood,
    required this.mascotColor,
    required this.greeting,
    this.adventure = '',
    this.ctaLabel,
    this.onPlay,
    this.trailing,
  });

  final MascotMood mood;
  final Color mascotColor;
  final String greeting;
  final String adventure;
  final String? ctaLabel;
  final VoidCallback? onPlay;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final tight = constraints.maxHeight > 0 && constraints.maxHeight < 88;
        final mascotSize = tight
            ? (constraints.maxHeight * 0.7).clamp(36.0, 52.0)
            : (wide ? 72.0 : 58.0);
        final padV = tight ? 6.0 : 10.0;
        final padH = wide ? 16.0 : 12.0;
        final titleSize = tight ? 15.0 : (wide ? 20.0 : 17.0);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF7).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x221B3B2B), blurRadius: 14, offset: Offset(0, 6)),
              BoxShadow(color: Color(0x30FFB07A), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IdleMascot(mood: mood, color: mascotColor, size: mascotSize),
              SizedBox(width: wide ? 12 : 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      greeting,
                      maxLines: tight ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: VimaiType.title.copyWith(fontSize: titleSize, height: 1.15),
                    ),
                    if (ctaLabel != null && onPlay != null) ...[
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: TactileNode(
                          semanticLabel: ctaLabel!,
                          minSize: kKidTouchMin,
                          onTap: onPlay!,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: VimaiColor.candyGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(color: Color(0x40FF2A6D), blurRadius: 10, offset: Offset(0, 4)),
                              ],
                            ),
                            child: Text(
                              ctaLabel!,
                              style: VimaiType.button.copyWith(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        );
      },
    );
  }
}

class CanopyDestination {
  const CanopyDestination({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.glyph,
    required this.onTap,
    this.artAsset,
  });

  final String title;
  final String subtitle;
  final Color color;
  final String glyph;
  final VoidCallback onTap;
  final String? artAsset;
}

/// Discovery cards that divide available space evenly (no scroll, no fixed aspect).
class CanopyPathTrail extends StatelessWidget {
  const CanopyPathTrail({
    super.key,
    required this.destinations,
    this.compact = false,
    this.crossAxisCount = 2,
  });

  final List<CanopyDestination> destinations;
  final bool compact;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    assert(destinations.isNotEmpty);
    final cols = crossAxisCount.clamp(1, 3);
    final rows = <List<CanopyDestination>>[];
    for (var i = 0; i < destinations.length; i += cols) {
      rows.add(destinations.sublist(i, math.min(i + cols, destinations.length)));
    }
    final gap = compact ? 8.0 : 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) SizedBox(height: gap),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < cols; c++) ...[
                      if (c > 0) SizedBox(width: gap),
                      Expanded(
                        child: c < rows[r].length
                            ? _ChunkyWorldCard(destination: rows[r][c], compact: compact)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ChunkyWorldCard extends StatelessWidget {
  const _ChunkyWorldCard({required this.destination, this.compact = false});

  final CanopyDestination destination;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final short = constraints.maxHeight < 110;
        final pad = short || compact ? 8.0 : 12.0;
        final icon = (constraints.maxHeight * 0.34).clamp(28.0, 56.0);
        final play = (icon * 0.68).clamp(22.0, 38.0);
        final titleSize = short ? 14.0 : 17.0;
        final subtitleSize = short ? 10.0 : 12.0;

        return TactileNode(
          semanticLabel: destination.title,
          minSize: 48,
          onTap: destination.onTap,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.all(pad),
            decoration: BoxDecoration(
              color: destination.color,
              borderRadius: BorderRadius.circular(short ? 18 : 26),
              border: Border.all(color: Colors.white, width: short ? 2.5 : 3.5),
              boxShadow: [
                BoxShadow(
                  color: destination.color.withValues(alpha: 0.45),
                  blurRadius: short ? 8 : 16,
                  offset: Offset(0, short ? 4 : 8),
                ),
                const BoxShadow(
                  color: Color(0x221B3B2B),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: icon,
                      height: icon,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(icon * 0.32),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: destination.artAsset != null
                          ? Image.asset(
                              destination.artAsset!,
                              fit: BoxFit.cover,
                              cacheWidth: 150,
                              errorBuilder: (_, __, ___) => Center(
                                child: FittedBox(
                                  child: Text(destination.glyph, style: TextStyle(fontSize: icon * 0.5)),
                                ),
                              ),
                            )
                          : Center(
                              child: FittedBox(
                                child: Text(destination.glyph, style: TextStyle(fontSize: icon * 0.5)),
                              ),
                            ),
                    ),
                    const Spacer(),
                    Container(
                      width: play,
                      height: play,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded, color: destination.color, size: play * 0.7),
                    ),
                  ],
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    destination.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: VimaiType.title.copyWith(color: Colors.white, fontSize: titleSize, height: 1.1),
                  ),
                ),
                SizedBox(height: short ? 2 : 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    destination.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VimaiType.subtitle.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
