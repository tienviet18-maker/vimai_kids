import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import 'vimai_mascot.dart';
import 'vimai_ui.dart';

enum WorldKind { japanese, vietnamese, math, thinking, creativity, games }

String _artFor(WorldKind kind) {
  switch (kind) {
    case WorldKind.japanese:
      return VimaiArt.japaneseVillage;
    case WorldKind.vietnamese:
      return VimaiArt.vietnameseGarden;
    case WorldKind.math:
      return VimaiArt.mathValley;
    case WorldKind.thinking:
      return VimaiArt.thinkingCave;
    case WorldKind.creativity:
      return VimaiArt.creativeStudio;
    case WorldKind.games:
      return VimaiArt.gamesPlayground;
  }
}

/// Full-bleed illustrated valley. Photo first, not a gradient fill.
class WorldSky extends StatelessWidget {
  const WorldSky({super.key, this.t = 0});

  final double t;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            VimaiArt.homeWorld,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            cacheWidth: 900,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stack) => const ColoredBox(color: VimaiColor.skyTop),
          ),
          if (t > 0) CustomPaint(painter: _CloudDriftPainter(t: t), child: const SizedBox.expand()),
        ],
      ),
    );
  }
}

class _CloudDriftPainter extends CustomPainter {
  _CloudDriftPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cloud = Paint()..color = VimaiColor.cloud.withValues(alpha: 0.28);
    final drift = math.sin(t * math.pi * 2) * 14;
    void puff(double x, double y, double s) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: s * 2.2, height: s * 0.7), cloud);
    }

    puff(size.width * 0.18 + drift, size.height * 0.08, 22);
    puff(size.width * 0.62 - drift, size.height * 0.11, 26);
  }

  @override
  bool shouldRepaint(covariant _CloudDriftPainter oldDelegate) => oldDelegate.t != t;
}


class IdleMascot extends StatefulWidget {
  const IdleMascot({
    super.key,
    required this.mood,
    required this.color,
    this.size = VimaiSize.mascotHero,
  });

  final MascotMood mood;
  final Color color;
  final double size;

  @override
  State<IdleMascot> createState() => _IdleMascotState();
}

class _IdleMascotState extends State<IdleMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return VimaiMascot(mood: widget.mood, size: widget.size, color: widget.color);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(offset: Offset(0, -4 * _c.value), child: child),
      child: VimaiMascot(mood: widget.mood, size: widget.size, color: widget.color),
    );
  }
}

class MissionScene extends StatelessWidget {
  const MissionScene({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.cta,
    required this.mood,
    required this.mascotColor,
    required this.color,
    required this.onPlay,
    this.timeLabel,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String cta;
  final String? timeLabel;
  final MascotMood mood;
  final Color mascotColor;
  final Color color;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: '$title. $cta',
      borderRadius: BorderRadius.circular(40),
      onTap: onPlay,
      child: CustomPaint(
        painter: _MissionHillPainter(color: color),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IdleMascot(mood: mood, color: mascotColor, size: 96),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomPaint(
                      painter: _SpeechBubblePainter(color: color),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 14, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(eyebrow, style: VimaiType.caption.copyWith(color: color, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(title, style: VimaiType.cardTitle.copyWith(fontSize: 17, color: VimaiColor.ink, height: 1.2)),
                            const SizedBox(height: 4),
                            Text(body, style: VimaiType.cardBody.copyWith(fontSize: 14)),
                            if (timeLabel != null)
                              Text(timeLabel!, style: VimaiType.caption.copyWith(fontWeight: FontWeight.w800, color: color)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: VimaiSize.touchKid, minWidth: double.infinity),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(VimaiRadius.pill),
                    boxShadow: VimaiShadow.soft,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Text(cta, style: VimaiType.button.copyWith(color: Colors.white, fontSize: 18)),
                    ),
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

class _SpeechBubblePainter extends CustomPainter {
  _SpeechBubblePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(8, 0, size.width - 8, size.height - 8), const Radius.circular(22));
    canvas.drawRRect(r, Paint()..color = Colors.white.withValues(alpha: 0.92));
    canvas.drawRRect(
      r,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final tail = Path()
      ..moveTo(10, size.height * 0.42)
      ..lineTo(0, size.height * 0.5)
      ..lineTo(10, size.height * 0.58)
      ..close();
    canvas.drawPath(tail, Paint()..color = Colors.white.withValues(alpha: 0.92));
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) => oldDelegate.color != color;
}

class _MissionHillPainter extends CustomPainter {
  _MissionHillPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ground = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(36));
    canvas.drawRRect(ground, Paint()..color = color.withValues(alpha: 0.16));
    canvas.drawRRect(
      ground,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.22, size.height * 0.78), width: size.width * 0.5, height: 48),
      Paint()..color = VimaiColor.grass.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _MissionHillPainter oldDelegate) => oldDelegate.color != color;
}

/// A tappable place inside the Home world. Illustration + name sticker, not a card.
class WorldIsland extends StatelessWidget {
  const WorldIsland({
    super.key,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.look,
    required this.onTap,
    this.progress = 0,
    this.alignEnd = false,
    this.visit = WorldVisit.available,
    this.showMai = false,
    this.goLabel = '',
  });

  final String title;
  final String subtitle;
  final WorldKind kind;
  final SubjectLook look;
  final VoidCallback onTap;
  final double progress;
  final bool alignEnd;
  final WorldVisit visit;
  final bool showMai;
  final String goLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth.isFinite ? constraints.maxWidth : 140.0).clamp(88.0, 240.0);
        final badge = visit == WorldVisit.available ? (goLabel.isNotEmpty ? goLabel : subtitle) : subtitle;
        final depth = 0.92 + (0.08 * progress.clamp(0, 1));
        return Transform.rotate(
          angle: alignEnd ? 0.04 : -0.05,
          child: Transform.scale(
            scale: depth,
            child: Pressable(
            semanticLabel: '$title. $subtitle',
            borderRadius: BorderRadius.circular(size * 0.28),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size + 18,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: size,
                child: Image.asset(
                  _artFor(kind),
                  fit: BoxFit.contain,
                  cacheWidth: 320,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              if (showMai)
                const Positioned(
                  right: -8,
                  top: 8,
                  child: IdleMascot(mood: MascotMood.excited, color: VimaiColor.mascot, size: 36),
                ),
              if (visit == WorldVisit.mastered || visit == WorldVisit.completed)
                Positioned(
                  left: 4,
                  top: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: look.color, borderRadius: BorderRadius.circular(99)),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      child: Text('★', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              Positioned(
                left: 4,
                right: 4,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: look.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ),
              if (badge == 'Bắt đầu' || badge == 'Start' || badge == 'はじめる')
                Positioned(
                  top: size * 0.08,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: VimaiColor.honey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Text(badge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ),
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

/// One living playground. Destinations sit in the scenery at different depths.
/// There is no path, no equal island row, and no map chrome.
class LivingPlayground extends StatelessWidget {
  const LivingPlayground({super.key, required this.children});

  final List<Widget> children;

  static const _slots = <(double, double, double)>[
    (0.00, 0.00, 0.42),
    (0.54, 0.04, 0.38),
    (0.04, 0.30, 0.34),
    (0.58, 0.32, 0.36),
    (0.02, 0.56, 0.36),
    (0.52, 0.54, 0.44),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < children.length && i < _slots.length; i++)
              Positioned(
                left: w * _slots[i].$1,
                top: h * _slots[i].$2,
                width: w * _slots[i].$3,
                child: children[i],
              ),
          ],
        );
      },
    );
  }
}

/// Kept for older hub call sites that still pass a map-shaped child list.
class WorldMap extends StatelessWidget {
  const WorldMap({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LivingPlayground(children: children);
}

class WorldTrail extends StatelessWidget {
  const WorldTrail({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _TrailSpinePainter()))),
        Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) _PathDash(even: i.isEven),
              children[i],
            ],
          ],
        ),
      ],
    );
  }
}

class _TrailSpinePainter extends CustomPainter {
  const _TrailSpinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VimaiColor.path.withValues(alpha: 0.55)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(size.width * 0.5, 8);
    const steps = 6;
    for (var i = 1; i <= steps; i++) {
      final y = size.height * (i / steps);
      final x = size.width * (i.isEven ? 0.32 : 0.68);
      path.quadraticBezierTo(size.width * 0.5, y - size.height / steps * 0.5, x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PathDash extends StatelessWidget {
  const _PathDash({required this.even});
  final bool even;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter(flip: even)),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter({required this.flip});
  final bool flip;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VimaiColor.path
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * (flip ? 0.28 : 0.72), 0)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.5, size.width * (flip ? 0.72 : 0.28), size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) => false;
}

class WorldActivity extends StatelessWidget {
  const WorldActivity({
    super.key,
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.color,
    required this.onTap,
    this.alignEnd = false,
  });

  final String title;
  final String subtitle;
  final String glyph;
  final Color color;
  final VoidCallback onTap;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: alignEnd ? 0.03 : -0.03,
      child: Pressable(
        semanticLabel: '$title. $subtitle',
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: SizedBox(
          width: 118,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Text(glyph, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: VimaiType.cardTitle.copyWith(color: color, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IllustratedScaffold extends StatelessWidget {
  const IllustratedScaffold({
    super.key,
    required this.body,
    this.title,
    this.leading,
    this.actions,
    this.skyT = 0,
  });

  final Widget body;
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final double skyT;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VimaiColor.skyTop,
      body: Stack(
        fit: StackFit.expand,
        children: [
          WorldSky(t: skyT),
          SafeArea(
            child: Column(
              children: [
                if (title != null)
                  SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        leading ?? const SizedBox(width: 48),
                        Expanded(child: Text(title!, textAlign: TextAlign.center, style: VimaiType.title)),
                        ...(actions ?? const [SizedBox(width: 48)]),
                      ],
                    ),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: VimaiSpace.maxContent),
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
