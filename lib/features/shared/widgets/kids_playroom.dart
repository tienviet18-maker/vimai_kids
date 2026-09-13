import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/vimai_tokens.dart';
import 'kids_scene.dart';
import 'vimai_mascot.dart';
import 'vimai_world.dart';

/// Subject discovery shape — each activity has a unique silhouette, not a recolored card.
enum ActivityShape { lantern, book, blocks, puzzle, brush, ball }

ActivityShape activityShapeFor(WorldKind kind) {
  switch (kind) {
    case WorldKind.japanese:
      return ActivityShape.lantern;
    case WorldKind.vietnamese:
      return ActivityShape.book;
    case WorldKind.math:
      return ActivityShape.blocks;
    case WorldKind.thinking:
      return ActivityShape.puzzle;
    case WorldKind.creativity:
      return ActivityShape.brush;
    case WorldKind.games:
      return ActivityShape.ball;
  }
}

/// Soft play-room backdrop — composition, not a world map photo with islands.
class KidsPlayRoomBackdrop extends StatelessWidget {
  const KidsPlayRoomBackdrop({super.key, this.t = 0});

  final double t;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _PlayRoomPainter(t: t),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PlayRoomPainter extends CustomPainter {
  _PlayRoomPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF9FD0F0), Color(0xFFE8F6FF), Color(0xFFFFF6E8)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    // Window light
    final window = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.62, size.height * 0.06, size.width * 0.28, size.height * 0.28),
      const Radius.circular(18),
    );
    canvas.drawRRect(window, Paint()..color = const Color(0xFF7EC8F0).withValues(alpha: 0.55));
    canvas.drawRRect(window, Paint()..color = Colors.white.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 4);

    // Floor band
    final floor = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.66, size.width, size.height * 0.74)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(floor, Paint()..color = const Color(0xFFE8C89A).withValues(alpha: 0.55));

    // Soft rug
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.38, size.height * 0.82), width: size.width * 0.55, height: size.height * 0.14),
      Paint()..color = VimaiColor.coral.withValues(alpha: 0.18),
    );

    // Shelf toys (decorative, non-interactive)
    final shelfY = size.height * 0.48;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.04, shelfY, size.width * 0.22, 10), const Radius.circular(4)),
      Paint()..color = const Color(0xFFC9956C),
    );
    canvas.drawCircle(Offset(size.width * 0.1, shelfY - 14), 12, Paint()..color = VimaiColor.mint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.14, shelfY - 28, 18, 28), const Radius.circular(4)),
      Paint()..color = VimaiColor.honey,
    );

    if (t > 0) {
      final drift = math.sin(t * math.pi * 2) * 8;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.2 + drift, size.height * 0.12), width: 54, height: 22),
        Paint()..color = Colors.white.withValues(alpha: 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlayRoomPainter oldDelegate) => oldDelegate.t != t;
}

/// Home hero: Mai + adventure speech + primary CTA. One focal composition.
class KidsPlayRoomHero extends StatelessWidget {
  const KidsPlayRoomHero({
    super.key,
    required this.mood,
    required this.mascotColor,
    required this.greeting,
    required this.adventure,
    required this.ctaLabel,
    required this.onPlay,
    this.wide = false,
  });

  final MascotMood mood;
  final Color mascotColor;
  final String greeting;
  final String adventure;
  final String ctaLabel;
  final VoidCallback onPlay;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final mascot = IdleMascot(mood: mood, color: mascotColor, size: wide ? 168 : 120);
    final bubble = KidsSpeechBubble(
      children: [
        Text(greeting, style: VimaiType.greeting.copyWith(fontSize: wide ? 28 : 22)),
        const SizedBox(height: 6),
        Text(adventure, style: VimaiType.title.copyWith(fontSize: wide ? 18 : 16, height: 1.3)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: KidsPlayButton(label: ctaLabel, color: VimaiColor.coral, onPressed: onPlay),
        ),
      ],
    );

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(flex: 4, child: Align(alignment: Alignment.bottomCenter, child: mascot)),
          const SizedBox(width: 16),
          Expanded(flex: 6, child: bubble),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: mascot),
        const SizedBox(height: 8),
        bubble,
      ],
    );
  }
}

/// Asymmetric subject sticker — unique shape per activity.
class KidsActivitySticker extends StatefulWidget {
  const KidsActivitySticker({
    super.key,
    required this.title,
    required this.subtitle,
    required this.look,
    required this.shape,
    required this.onTap,
    this.progress = 0,
    this.emphasized = false,
  });

  final String title;
  final String subtitle;
  final SubjectLook look;
  final ActivityShape shape;
  final VoidCallback onTap;
  final double progress;
  final bool emphasized;

  @override
  State<KidsActivitySticker> createState() => _KidsActivityStickerState();
}

class _KidsActivityStickerState extends State<KidsActivitySticker> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.emphasized ? 108.0 : 92.0;
    final scale = _down ? 0.92 : (_hover ? 1.05 : 1.0);

    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.subtitle}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: AnimatedScale(
            scale: scale,
            duration: VimaiMotion.of(context, VimaiMotion.tap),
            curve: VimaiMotion.curve,
            child: SizedBox(
              width: size + 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size.square(size),
                          painter: _ActivityShapePainter(
                            shape: widget.shape,
                            color: widget.look.color,
                            soft: widget.look.soft,
                          ),
                        ),
                        Text(
                          widget.look.glyph,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: size * 0.28,
                            shadows: const [Shadow(color: Color(0x33000000), blurRadius: 4)],
                          ),
                        ),
                        if (widget.progress >= 0.4)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: VimaiColor.honey,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(3),
                                child: Text('★', style: TextStyle(fontSize: 10, color: Colors.white)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VimaiType.label.copyWith(color: widget.look.color, fontSize: 13),
                  ),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VimaiType.caption.copyWith(fontSize: 11),
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

class _ActivityShapePainter extends CustomPainter {
  _ActivityShapePainter({required this.shape, required this.color, required this.soft});

  final ActivityShape shape;
  final Color color;
  final Color soft;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final face = Paint()..color = color;
    final softP = Paint()..color = soft;
    final rim = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    switch (shape) {
      case ActivityShape.lantern:
        final body = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(0, 4), width: size.width * 0.62, height: size.height * 0.7),
          const Radius.circular(18),
        );
        canvas.drawOval(Rect.fromCenter(center: c.translate(0, size.height * 0.38), width: size.width * 0.5, height: 12), softP);
        canvas.drawRRect(body, face);
        canvas.drawRRect(body, rim);
        canvas.drawLine(Offset(c.dx, c.dy - size.height * 0.42), Offset(c.dx, c.dy - size.height * 0.28), Paint()..color = color..strokeWidth = 4);
        break;
      case ActivityShape.book:
        final page = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: size.width * 0.72, height: size.height * 0.58),
          const Radius.circular(10),
        );
        canvas.drawRRect(page.shift(const Offset(3, 4)), Paint()..color = Color.lerp(color, Colors.black, 0.15)!);
        canvas.drawRRect(page, face);
        canvas.drawRRect(page, rim);
        canvas.drawLine(Offset(c.dx, c.dy - size.height * 0.22), Offset(c.dx, c.dy + size.height * 0.22), Paint()..color = Colors.white.withValues(alpha: 0.7)..strokeWidth = 3);
        break;
      case ActivityShape.blocks:
        final a = RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.12, size.height * 0.42, size.width * 0.38, size.height * 0.38), const Radius.circular(8));
        final b = RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.42, size.height * 0.22, size.width * 0.4, size.height * 0.4), const Radius.circular(8));
        canvas.drawRRect(a, Paint()..color = Color.lerp(color, Colors.white, 0.15)!);
        canvas.drawRRect(b, face);
        canvas.drawRRect(a, rim);
        canvas.drawRRect(b, rim);
        break;
      case ActivityShape.puzzle:
        final path = Path()
          ..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: size.width * 0.7, height: size.height * 0.7), const Radius.circular(16)));
        canvas.drawCircle(c.translate(0, -size.height * 0.28), size.width * 0.14, softP);
        canvas.drawPath(path, face);
        canvas.drawPath(path, rim);
        canvas.drawCircle(c.translate(size.width * 0.28, 0), size.width * 0.12, Paint()..color = Colors.white.withValues(alpha: 0.35));
        break;
      case ActivityShape.brush:
        canvas.drawOval(Rect.fromCenter(center: c.translate(0, size.height * 0.18), width: size.width * 0.55, height: size.height * 0.45), face);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: c.translate(0, -size.height * 0.12), width: size.width * 0.18, height: size.height * 0.48), const Radius.circular(8)),
          Paint()..color = Color.lerp(color, Colors.brown, 0.35)!,
        );
        canvas.drawCircle(c.translate(0, size.height * 0.18), size.width * 0.22, rim);
        break;
      case ActivityShape.ball:
        canvas.drawCircle(c, size.width * 0.36, face);
        canvas.drawCircle(c, size.width * 0.36, rim);
        canvas.drawArc(Rect.fromCircle(center: c, radius: size.width * 0.36), -0.4, 1.2, false, Paint()..color = Colors.white.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 5);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityShapePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}

/// Horizontal discovery strip of unique activity stickers.
class KidsActivityStrip extends StatelessWidget {
  const KidsActivityStrip({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            children[i],
          ],
        ],
      ),
    );
  }
}
