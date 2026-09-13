import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import 'kids_scene.dart';
import 'vimai_mascot.dart';
import 'vimai_world.dart';

/// One discoverable place embedded in the valley — not a card or labeled thumbnail.
class KidsSceneDestination extends StatefulWidget {
  const KidsSceneDestination({
    super.key,
    required this.title,
    required this.kind,
    required this.look,
    required this.onTap,
    this.progress = 0,
    this.visit = WorldVisit.available,
    this.showMai = false,
    this.wiggle = false,
  });

  final String title;
  final WorldKind kind;
  final SubjectLook look;
  final VoidCallback onTap;
  final double progress;
  final WorldVisit visit;
  final bool showMai;
  final bool wiggle;

  @override
  State<KidsSceneDestination> createState() => _KidsSceneDestinationState();
}

class _KidsSceneDestinationState extends State<KidsSceneDestination> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    if (widget.wiggle || widget.visit == WorldVisit.available) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant KidsSceneDestination oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.wiggle || widget.visit == WorldVisit.available) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final scale = 0.88 + (0.12 * widget.progress.clamp(0, 1));
    final glow = widget.visit == WorldVisit.available || widget.visit == WorldVisit.inProgress;

    return Semantics(
      button: true,
      label: widget.title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final bob = reduced ? 0.0 : math.sin(_pulse.value * math.pi * 2) * 3;
              final tilt = reduced ? 0.0 : math.sin(_pulse.value * math.pi * 2 + 0.5) * 0.02;
              return Transform.translate(
                offset: Offset(0, bob),
                child: Transform.rotate(
                  angle: tilt,
                  child: Transform.scale(
                    scale: _down ? scale * 0.94 : scale,
                    child: child,
                  ),
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(w * 0.2),
                onHighlightChanged: (v) => setState(() => _down = v),
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTap();
                },
                child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    if (glow)
                      Positioned(
                        bottom: h * 0.08,
                        child: Container(
                          width: w * 0.7,
                          height: h * 0.12,
                          decoration: BoxDecoration(
                            color: widget.look.color.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      bottom: h * 0.06,
                      child: Image.asset(
                        _artFor(widget.kind),
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        cacheWidth: 360,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: CustomPaint(
                        painter: _WorldSignPainter(color: widget.look.color),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: VimaiType.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.showMai)
                      const Positioned(
                        right: -6,
                        top: 4,
                        child: IdleMascot(mood: MascotMood.excited, color: VimaiColor.mascot, size: 34),
                      ),
                    if (widget.visit == WorldVisit.mastered || widget.visit == WorldVisit.completed)
                      Positioned(
                        left: 2,
                        top: h * 0.12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: widget.look.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Text('★', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
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
      ),
    );
  }
}

class _WorldSignPainter extends CustomPainter {
  _WorldSignPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(10),
    );
    canvas.drawRRect(r, Paint()..color = color);
    canvas.drawRRect(
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.45, -6, size.width * 0.1, 8),
      Paint()..color = Color.lerp(color, Colors.brown, 0.4)!,
    );
  }

  @override
  bool shouldRepaint(covariant _WorldSignPainter oldDelegate) => oldDelegate.color != color;
}

/// Foreground grass tufts overlapping the valley floor.
class KidsValleyForeground extends StatelessWidget {
  const KidsValleyForeground({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _ValleyGrassPainter(),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _ValleyGrassPainter extends CustomPainter {
  const _ValleyGrassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grass = Paint()..color = VimaiColor.grass.withValues(alpha: 0.55);
    final hill = Path()
      ..moveTo(0, size.height * 0.92)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.82, size.width * 0.5, size.height * 0.88)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.94, size.width, size.height * 0.86)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, grass);

    final tuft = Paint()..color = VimaiColor.grass.withValues(alpha: 0.75);
    for (var i = 0; i < 12; i++) {
      final x = size.width * (0.04 + i * 0.08);
      final h = 8.0 + (i % 3) * 4;
      canvas.drawOval(Rect.fromCenter(center: Offset(x, size.height * 0.9), width: 14, height: h), tuft);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Destination layout inside one continuous valley viewport.
class KidsValleyScene extends StatelessWidget {
  const KidsValleyScene({super.key, required this.destinations});

  final List<Widget> destinations;

  static const _slots = <(double, double, double, double)>[
    (0.01, 0.02, 0.42, 0.36),
    (0.51, 0.00, 0.44, 0.38),
    (0.00, 0.28, 0.40, 0.34),
    (0.52, 0.26, 0.42, 0.36),
    (0.02, 0.52, 0.40, 0.38),
    (0.48, 0.50, 0.44, 0.40),
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
            for (var i = 0; i < destinations.length && i < _slots.length; i++)
              Positioned(
                left: w * _slots[i].$1,
                top: h * _slots[i].$2,
                width: w * _slots[i].$3,
                height: h * _slots[i].$4,
                child: destinations[i],
              ),
            const Positioned(left: 0, right: 0, bottom: 0, height: 72, child: KidsValleyForeground()),
          ],
        );
      },
    );
  }
}

/// Mai-led mini adventure strip — one mission line + playful CTA, not a dashboard block.
class KidsMissionAdventure extends StatelessWidget {
  const KidsMissionAdventure({
    super.key,
    required this.mood,
    required this.mascotColor,
    required this.speech,
    required this.ctaLabel,
    required this.onPlay,
    this.mascotSize = 72,
  });

  final MascotMood mood;
  final Color mascotColor;
  final String speech;
  final String ctaLabel;
  final VoidCallback onPlay;
  final double mascotSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IdleMascot(mood: mood, color: mascotColor, size: mascotSize),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KidsSpeechBubble(
                color: VimaiColor.cream,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(speech, style: VimaiType.title.copyWith(fontSize: 17, height: 1.25)),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: KidsPlayButton(label: ctaLabel, color: VimaiColor.coral, onPressed: onPlay),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Back-compat export: old tests/code may still reference [WorldIsland].
typedef WorldIsland = KidsSceneDestination;

/// Back-compat export: old code may still reference [LivingPlayground].
typedef LivingPlayground = KidsValleyScene;

/// Back-compat export.
typedef WorldMap = KidsValleyScene;
