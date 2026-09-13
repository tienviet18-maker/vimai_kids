import 'dart:math';
import 'package:flutter/material.dart';

/// Lightweight, high-performance particle celebration (confetti + stars + fireworks).
/// Uses pure CustomPainter with zero external dependencies.
class CelebrationOverlay {
  static OverlayEntry? _activeEntry;

  /// Shows celebratory fireworks / confetti across the screen for ~1.5s.
  /// Completely non-blocking (IgnorePointer) so child interaction is uninterrupted.
  static void show(BuildContext context) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _activeEntry?.remove();
    _activeEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => IgnorePointer(
        child: _CelebrationParticleCanvas(
          onFinished: () {
            if (_activeEntry == entry) {
              entry.remove();
              _activeEntry = null;
            }
          },
        ),
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }
}

class _CelebrationParticleCanvas extends StatefulWidget {
  final VoidCallback onFinished;

  const _CelebrationParticleCanvas({required this.onFinished});

  @override
  State<_CelebrationParticleCanvas> createState() => _CelebrationParticleCanvasState();
}

class _CelebrationParticleCanvasState extends State<_CelebrationParticleCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  static const List<Color> _palette = [
    Color(0xFFFF5252), // Red/coral
    Color(0xFFFFD700), // Gold/star
    Color(0xFF4CAF50), // Green/mint
    Color(0xFF2196F3), // Sky blue
    Color(0xFFFF4081), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF9800), // Orange
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Seed particles
    for (int i = 0; i < 48; i++) {
      _particles.add(_createParticle());
    }

    _controller.forward().then((_) {
      if (mounted) widget.onFinished();
    });
  }

  _Particle _createParticle() {
    final angle = _rnd.nextDouble() * 2 * pi;
    final speed = 180 + _rnd.nextDouble() * 320;
    return _Particle(
      color: _palette[_rnd.nextInt(_palette.length)],
      vx: cos(angle) * speed,
      vy: sin(angle) * speed - 150, // slight upward bias
      size: 6 + _rnd.nextDouble() * 10,
      isStar: _rnd.nextBool(),
      rotationSpeed: (_rnd.nextDouble() - 0.5) * 8,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            particles: _particles,
            progress: progress,
          ),
        );
      },
    );
  }
}

class _Particle {
  final Color color;
  final double vx;
  final double vy;
  final double size;
  final bool isStar;
  final double rotationSpeed;

  _Particle({
    required this.color,
    required this.vx,
    required this.vy,
    required this.size,
    required this.isStar,
    required this.rotationSpeed,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final gravity = 420.0 * progress * progress;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final x = center.dx + p.vx * progress;
      final y = center.dy + p.vy * progress + gravity;
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotationSpeed);

      if (p.isStar) {
        _drawStar(canvas, p.size * (1.0 - progress * 0.3), paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * pi / 180;
      final innerAngle = (i * 72 + 36 - 90) * pi / 180;
      final ox = cos(outerAngle) * radius;
      final oy = sin(outerAngle) * radius;
      final ix = cos(innerAngle) * (radius * 0.45);
      final iy = sin(innerAngle) * (radius * 0.45);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
