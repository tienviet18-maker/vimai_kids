import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/vimai_tokens.dart';
import '../../shared/widgets/kids_living_canopy.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_world.dart';

/// One learning world on the Home archipelago.
class IslandSpec {
  const IslandSpec({
    required this.id,
    required this.title,
    required this.glyph,
    required this.color,
    required this.art,
    required this.onTap,
    this.visited = false,
    this.suggested = false,
  });

  final String id;
  final String title;

  /// Short visual cue a pre-reader recognises (A, あ, 123 …).
  final String glyph;
  final Color color;
  final String art;
  final VoidCallback onTap;

  /// The child has already played here — a flag is planted on the island.
  final bool visited;

  /// Mai is suggesting this island right now — it glows softly.
  final bool suggested;
}

bool _reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Sky meets a calm sea; clouds and ripples drift slowly. Purely decorative.
class DiscoverySeaBackground extends StatefulWidget {
  const DiscoverySeaBackground({super.key, this.horizon = 0.24});

  /// Horizon line as a fraction of the height.
  final double horizon;

  @override
  State<DiscoverySeaBackground> createState() => _DiscoverySeaBackgroundState();
}

class _DiscoverySeaBackgroundState extends State<DiscoverySeaBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(vsync: this, duration: const Duration(seconds: 24));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _drift,
          builder: (context, _) => CustomPaint(
            painter: _SeaPainter(t: _drift.value, horizon: widget.horizon),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _SeaPainter extends CustomPainter {
  const _SeaPainter({required this.t, required this.horizon});

  final double t;
  final double horizon;

  static const _skyTop = Color(0xFF9AD8FF);
  static const _skyLow = Color(0xFFE4F5FF);
  static const _seaHigh = Color(0xFFA6E1F7);
  static const _seaLow = Color(0xFF56B9E3);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final hy = h * horizon;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, hy + 1),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyLow],
        ).createShader(Rect.fromLTWH(0, 0, w, hy + 1)),
    );

    // Warm sun glow, top right.
    final sun = Offset(w * 0.84, hy * 0.38);
    canvas.drawCircle(
      sun,
      math.max(w, h) * 0.22,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFF4C9).withValues(alpha: 0.9), const Color(0x00FFF4C9)],
        ).createShader(Rect.fromCircle(center: sun, radius: math.max(w, h) * 0.22)),
    );

    // Clouds drift one screen-width per loop.
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.85);
    void puff(double x, double y, double s) {
      final cx = ((x + t) % 1.3 - 0.15) * w;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, y), width: s * 2.4, height: s * 0.8), cloud);
      canvas.drawCircle(Offset(cx - s * 0.35, y - s * 0.18), s * 0.42, cloud);
      canvas.drawCircle(Offset(cx + s * 0.25, y - s * 0.28), s * 0.5, cloud);
    }

    final cs = math.min(w, 900.0) * 0.06;
    puff(0.12, hy * 0.42, cs);
    puff(0.58, hy * 0.24, cs * 0.8);
    puff(0.95, hy * 0.62, cs * 0.65);

    final seaRect = Rect.fromLTWH(0, hy, w, h - hy);
    canvas.drawRect(
      seaRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_seaHigh, _seaLow],
        ).createShader(seaRect),
    );
    // Bright horizon line.
    canvas.drawRect(Rect.fromLTWH(0, hy - 1, w, 3), Paint()..color = Colors.white.withValues(alpha: 0.7));

    // Gentle wave glints, denser and larger towards the viewer.
    final glint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final depth = rnd.nextDouble();
      final y = hy + (h - hy) * (0.06 + depth * 0.92);
      final len = 14 + depth * 26;
      final phase = rnd.nextDouble();
      final x = ((rnd.nextDouble() + math.sin((t + phase) * math.pi * 2) * 0.02) % 1.0) * w;
      glint.strokeWidth = 1.6 + depth * 1.6;
      final path = Path()
        ..moveTo(x - len / 2, y)
        ..quadraticBezierTo(x, y - 4 - depth * 3, x + len / 2, y);
      canvas.drawPath(path, glint);
    }
  }

  @override
  bool shouldRepaint(covariant _SeaPainter old) => old.t != t || old.horizon != horizon;
}

/// The six worlds laid out as an archipelago joined by stepping stones.
///
/// Portrait screens get a two-column zig-zag; wide screens a three-column wave.
/// Every island is a full illustration with a name sign — no cards, no scroll.
class DiscoveryArchipelago extends StatefulWidget {
  const DiscoveryArchipelago({super.key, required this.islands});

  final List<IslandSpec> islands;

  @override
  State<DiscoveryArchipelago> createState() => _DiscoveryArchipelagoState();
}

class _DiscoveryArchipelagoState extends State<DiscoveryArchipelago> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(seconds: 5));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _bob.stop();
    } else if (!_bob.isAnimating) {
      _bob.repeat();
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final layout = ArchipelagoLayout.compute(Size(c.maxWidth, c.maxHeight), widget.islands.length);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _SteppingStonesPainter(points: layout.pathPoints)),
              ),
            ),
            for (var i = 0; i < widget.islands.length; i++)
              Positioned(
                left: layout.slots[i].left,
                top: layout.slots[i].top,
                width: layout.slots[i].width,
                height: layout.slots[i].height,
                child: _Island(
                  spec: widget.islands[i],
                  islandSize: layout.islandSize,
                  labelHeight: layout.labelHeight,
                  bob: _bob,
                  phase: i * 1.1,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Pure geometry so it can be unit-tested at every target width.
class ArchipelagoLayout {
  const ArchipelagoLayout({
    required this.slots,
    required this.islandSize,
    required this.labelHeight,
    required this.pathPoints,
  });

  final List<Rect> slots;
  final double islandSize;
  final double labelHeight;

  /// Where the stepping-stone trail touches each island (its shore).
  final List<Offset> pathPoints;

  static ArchipelagoLayout compute(Size size, int count) {
    final w = size.width;
    final h = size.height;
    final wide = w > h * 1.15;
    final cols = wide ? 3 : 2;
    final rows = (count / cols).ceil();
    // Odd columns sit lower so the islands read as a winding trail.
    const stagger = 0.16;
    final slotW = w / cols;
    final slotH = h / (rows + stagger);
    final labelH = (slotH * 0.17).clamp(30.0, 46.0);
    final island = math.max(40.0, math.min(slotW * 0.86, slotH - labelH - 6));
    final itemH = island + labelH;

    final slots = <Rect>[];
    final shore = <Offset>[];
    for (var i = 0; i < count; i++) {
      final row = i ~/ cols;
      // Reverse every other row (boustrophedon) so the trail never jumps across the screen.
      final rawCol = i % cols;
      final col = row.isOdd ? cols - 1 - rawCol : rawCol;
      final cx = slotW * (col + 0.5) + (wide ? 0 : (col == 0 ? -slotW * 0.04 : slotW * 0.04));
      final cy = slotH * (row + 0.5) + (col.isOdd ? slotH * stagger : 0);
      final rect = Rect.fromCenter(center: Offset(cx, cy), width: island, height: itemH);
      slots.add(rect);
      shore.add(Offset(cx, rect.top + island * 0.78));
    }
    return ArchipelagoLayout(slots: slots, islandSize: island, labelHeight: labelH, pathPoints: shore);
  }
}

class _SteppingStonesPainter extends CustomPainter {
  const _SteppingStonesPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final stone = Paint()..color = const Color(0xFFF4DFAA);
    final shine = Paint()..color = const Color(0xFFFFF6DC);
    final rim = Paint()..color = const Color(0x402E6E8E);
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      // Bow each hop downwards a little, like a path across shallow water.
      final mid = Offset((a.dx + b.dx) / 2, math.max(a.dy, b.dy) + (b - a).distance * 0.12);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      final metric = path.computeMetrics().first;
      final len = metric.length;
      final gap = (len / 8).clamp(16.0, 34.0);
      // Skip the ends — they are under the islands.
      for (var d = len * 0.2; d < len * 0.82; d += gap) {
        final p = metric.getTangentForOffset(d)!.position;
        final s = 6.5 + 2.0 * math.sin(d);
        canvas.drawOval(Rect.fromCenter(center: p.translate(0, 2.5), width: s * 2.7, height: s * 1.45), rim);
        canvas.drawOval(Rect.fromCenter(center: p, width: s * 2.5, height: s * 1.3), stone);
        canvas.drawOval(Rect.fromCenter(center: p.translate(-s * 0.3, -s * 0.2), width: s * 1.1, height: s * 0.45), shine);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SteppingStonesPainter old) => old.points != points;
}

class _Island extends StatelessWidget {
  const _Island({
    required this.spec,
    required this.islandSize,
    required this.labelHeight,
    required this.bob,
    required this.phase,
  });

  final IslandSpec spec;
  final double islandSize;
  final double labelHeight;
  final Animation<double> bob;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final s = islandSize;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
    return TactileNode(
      semanticLabel: spec.title,
      minSize: 0,
      onTap: spec.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: s,
            height: s,
            child: AnimatedBuilder(
              animation: bob,
              builder: (context, child) {
                final wave = math.sin(bob.value * math.pi * 2 + phase);
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (spec.suggested)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFFFF1B8).withValues(alpha: 0.85 + 0.15 * wave),
                                const Color(0xFFFFD66B).withValues(alpha: 0.35),
                                const Color(0x00FFD66B),
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                    // Water ripple around the shore.
                    Positioned(
                      left: s * 0.04,
                      right: s * 0.04,
                      bottom: s * 0.02,
                      height: s * 0.26,
                      child: CustomPaint(painter: _RipplePainter(t: (bob.value + phase / 6) % 1.0)),
                    ),
                    Transform.translate(offset: Offset(0, wave * s * 0.022), child: child),
                  ],
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      spec.art,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      cacheWidth: (s * dpr).round().clamp(120, 720),
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(spec.glyph, style: VimaiType.display.copyWith(color: spec.color)),
                      ),
                    ),
                  ),
                  if (spec.visited)
                    Positioned(
                      right: s * 0.06,
                      top: s * 0.02,
                      width: s * 0.2,
                      height: s * 0.24,
                      child: CustomPaint(painter: _FlagPainter(color: spec.color)),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: labelHeight,
            child: _IslandSign(title: spec.title, glyph: spec.glyph, color: spec.color, height: labelHeight),
          ),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawOval(r.deflate(size.height * 0.12), Paint()..color = const Color(0x2A0B5E86));
    final grow = 0.9 + t * 0.2;
    final ring = Rect.fromCenter(center: r.center, width: r.width * grow, height: r.height * grow);
    canvas.drawOval(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.55 * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) => old.t != t;
}

/// Planted pennant: "I have been here".
class _FlagPainter extends CustomPainter {
  const _FlagPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawLine(
      Offset(w * 0.2, h * 0.05),
      Offset(w * 0.2, h),
      Paint()
        ..color = const Color(0xFF6B4A2B)
        ..strokeWidth = math.max(2, w * 0.09)
        ..strokeCap = StrokeCap.round,
    );
    final flag = Path()
      ..moveTo(w * 0.24, h * 0.06)
      ..quadraticBezierTo(w * 0.62, h * 0.0, w * 0.96, h * 0.2)
      ..quadraticBezierTo(w * 0.62, h * 0.34, w * 0.24, h * 0.42)
      ..close();
    canvas.drawPath(flag.shift(const Offset(0, 2)), Paint()..color = const Color(0x33000000));
    canvas.drawPath(flag, Paint()..color = color);
    canvas.drawPath(
      flag,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _FlagPainter old) => old.color != color;
}

class _IslandSign extends StatelessWidget {
  const _IslandSign({required this.title, required this.glyph, required this.color, required this.height});

  final String title;
  final String glyph;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final badge = height - 8;
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          height: height,
          padding: EdgeInsets.fromLTRB(4, 4, height * 0.42, 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: badge,
                height: badge,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: FittedBox(
                    child: Text(
                      glyph,
                      style: VimaiType.title.copyWith(color: color, fontSize: badge * 0.55, height: 1),
                    ),
                  ),
                ),
              ),
              SizedBox(width: height * 0.2),
              Text(
                title,
                maxLines: 1,
                style: VimaiType.title.copyWith(
                  color: Colors.white,
                  fontSize: height * 0.46,
                  height: 1.05,
                  shadows: const [Shadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1))],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mai's speech: greeting, optional hint and the single primary action.
class MaiGuide extends StatelessWidget {
  const MaiGuide({
    super.key,
    required this.mood,
    required this.mascotColor,
    required this.greeting,
    required this.onMaiTap,
    this.hint,
    this.actionLabel,
    this.actionGlyph,
    this.actionColor = VimaiColor.primaryPink,
    this.onAction,
    this.trailing,
    this.vertical = false,
    this.mascotSize = 88,
  });

  final MascotMood mood;
  final Color mascotColor;
  final String greeting;
  final String? hint;
  final String? actionLabel;
  final String? actionGlyph;
  final Color actionColor;
  final VoidCallback? onAction;
  final VoidCallback onMaiTap;
  final Widget? trailing;
  final bool vertical;
  final double mascotSize;

  @override
  Widget build(BuildContext context) {
    final mai = TactileNode(
      semanticLabel: 'Mai',
      minSize: 0,
      onTap: onMaiTap,
      child: IdleMascot(mood: mood, color: mascotColor, size: mascotSize),
    );
    final bubble = _SpeechBubble(
      tailOnTop: vertical,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: vertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  greeting,
                  textAlign: vertical ? TextAlign.center : TextAlign.start,
                  style: VimaiType.title.copyWith(fontSize: vertical ? 21 : 18, height: 1.18),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              textAlign: vertical ? TextAlign.center : TextAlign.start,
              style: VimaiType.subtitle.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            _PrimaryAction(label: actionLabel!, glyph: actionGlyph, color: actionColor, onTap: onAction!),
          ],
        ],
      ),
    );
    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [mai, const SizedBox(height: 6), bubble],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [mai, const SizedBox(width: 4), Expanded(child: bubble)],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.child, this.tailOnTop = false});

  final Widget child;
  final bool tailOnTop;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(tailOnTop: tailOnTop),
      child: Padding(
        padding: tailOnTop ? const EdgeInsets.fromLTRB(16, 22, 16, 14) : const EdgeInsets.fromLTRB(22, 12, 14, 12),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.tailOnTop});

  final bool tailOnTop;

  @override
  void paint(Canvas canvas, Size size) {
    const tail = 10.0;
    final body = tailOnTop
        ? Rect.fromLTWH(0, tail, size.width, size.height - tail)
        : Rect.fromLTWH(tail, 0, size.width - tail, size.height);
    final path = Path()..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(24)));
    if (tailOnTop) {
      final cx = size.width / 2;
      path
        ..moveTo(cx - 12, tail + 1)
        ..lineTo(cx, 0)
        ..lineTo(cx + 12, tail + 1)
        ..close();
    } else {
      final cy = math.min(size.height / 2, 44.0);
      path
        ..moveTo(tail + 1, cy - 11)
        ..lineTo(0, cy + 2)
        ..lineTo(tail + 1, cy + 11)
        ..close();
    }
    canvas.drawShadow(path, const Color(0x661B3B5B), 6, false);
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.tailOnTop != tailOnTop;
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.label, required this.color, required this.onTap, this.glyph});

  final String label;
  final String? glyph;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TactileNode(
      semanticLabel: label,
      minSize: kKidTouchMin,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: kKidTouchMin),
        padding: const EdgeInsets.fromLTRB(6, 6, 18, 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(kKidTouchMin),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: glyph == null
                  ? Icon(Icons.play_arrow_rounded, color: color, size: 30)
                  : FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(glyph!, style: VimaiType.title.copyWith(color: color, height: 1)),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: VimaiType.button.copyWith(color: Colors.white, fontSize: 17),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
          ],
        ),
      ),
    );
  }
}
