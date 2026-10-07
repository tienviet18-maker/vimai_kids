import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_art.dart';

/// The painted world each game lives in.
enum GameScene { sky, space, meadow, railway, table, stage, arcade }

extension GameSceneLook on GameScene {
  /// Solid colour behind the painting (also the Scaffold background).
  Color get base {
    switch (this) {
      case GameScene.sky:
        return const Color(0xFF8FD3FF);
      case GameScene.space:
        return const Color(0xFF140F3C);
      case GameScene.meadow:
        return const Color(0xFFB8EBFF);
      case GameScene.railway:
        return const Color(0xFFFFE7B8);
      case GameScene.table:
        return const Color(0xFF6A4FC8);
      case GameScene.stage:
        return const Color(0xFF2B1240);
      case GameScene.arcade:
        return const Color(0xFFFFE08A);
    }
  }

  bool get isDark =>
      this == GameScene.space ||
      this == GameScene.stage ||
      this == GameScene.table;
}

/// Full-bleed animated scene. Loops gently; freezes when the platform asks
/// for reduced motion.
class GameSceneBackdrop extends StatefulWidget {
  const GameSceneBackdrop(
      {super.key, required this.scene, this.animate = true});

  final GameScene scene;
  final bool animate;

  @override
  State<GameSceneBackdrop> createState() => _GameSceneBackdropState();
}

class _GameSceneBackdropState extends State<GameSceneBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 40), value: 0.12);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant GameSceneBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final still = !widget.animate || MediaQuery.disableAnimationsOf(context);
    if (still) {
      if (_c.isAnimating) _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: GameScenePainter(scene: widget.scene, time: _c),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class GameScenePainter extends CustomPainter {
  GameScenePainter({required this.scene, required this.time})
      : super(repaint: time);

  final GameScene scene;
  final Animation<double> time;

  static final _rand = math.Random(11);
  static final List<Offset> _stars =
      List.generate(90, (_) => Offset(_rand.nextDouble(), _rand.nextDouble()));
  static final List<double> _phase =
      List.generate(90, (_) => _rand.nextDouble());

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    switch (scene) {
      case GameScene.sky:
        _sky(canvas, size, t);
      case GameScene.space:
        _space(canvas, size, t);
      case GameScene.meadow:
        _meadow(canvas, size, t);
      case GameScene.railway:
        _railway(canvas, size, t);
      case GameScene.table:
        _table(canvas, size, t);
      case GameScene.stage:
        _stage(canvas, size, t);
      case GameScene.arcade:
        _arcade(canvas, size, t);
    }
  }

  // ---------------------------------------------------------------- helpers

  void _gradient(Canvas canvas, Size size, List<Color> colors,
      [List<double>? stops]) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: stops,
        ).createShader(rect),
    );
  }

  void _cloud(Canvas canvas, Offset c, double s, [double alpha = 0.92]) {
    final p = Paint()..color = Colors.white.withValues(alpha: alpha);
    final shade = Paint()
      ..color = const Color(0xFFDCEBFA).withValues(alpha: alpha);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: c.translate(0, s * 0.18),
              width: s * 2.4,
              height: s * 0.7),
          Radius.circular(s)),
      shade,
    );
    canvas.drawCircle(c.translate(-s * 0.6, s * 0.05), s * 0.45, p);
    canvas.drawCircle(c.translate(0, -s * 0.15), s * 0.62, p);
    canvas.drawCircle(c.translate(s * 0.62, s * 0.08), s * 0.42, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: c.translate(0, s * 0.12),
              width: s * 2.2,
              height: s * 0.55),
          Radius.circular(s)),
      p,
    );
  }

  double _drift(double t, double speed, double width, double offset) {
    final span = width + 260;
    return ((offset * span + t * speed * span) % span) - 130;
  }

  void _sun(Canvas canvas, Offset c, double r, double t) {
    final rays = Paint()
      ..color = const Color(0xFFFFE36E).withValues(alpha: 0.55)
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = t * math.pi * 2 + i * math.pi / 6;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r * 1.3,
        c + Offset(math.cos(a), math.sin(a)) * r * 1.75,
        rays,
      );
    }
    canvas.drawCircle(c, r * 1.15,
        Paint()..color = const Color(0xFFFFF3A8).withValues(alpha: 0.6));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader =
            const RadialGradient(colors: [Color(0xFFFFF6B0), Color(0xFFFFC93C)])
                .createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  void _hill(Canvas canvas, Size size, double baseY, double amp, double phase,
      Color color) {
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, baseY);
    const steps = 24;
    for (var i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      final y = baseY - math.sin(i / steps * math.pi * 1.6 + phase) * amp;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _balloon(Canvas canvas, Offset c, double r, Color color) {
    final string = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final s = Path()
      ..moveTo(c.dx, c.dy + r * 1.15)
      ..quadraticBezierTo(
          c.dx - r * 0.3, c.dy + r * 1.8, c.dx + r * 0.1, c.dy + r * 2.6);
    canvas.drawPath(s, string);
    final rect = Rect.fromCenter(center: c, width: r * 1.8, height: r * 2.2);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [Color.lerp(color, Colors.white, 0.45)!, color],
        ).createShader(rect),
    );
    final knot = Path()
      ..moveTo(c.dx - r * 0.14, c.dy + r * 1.22)
      ..lineTo(c.dx + r * 0.14, c.dy + r * 1.22)
      ..lineTo(c.dx, c.dy + r * 1.05)
      ..close();
    canvas.drawPath(knot, Paint()..color = color);
  }

  static const _candy = [
    Color(0xFFFF5C8A),
    Color(0xFFFFB020),
    Color(0xFF4CC9F0),
    Color(0xFF8B5CF6),
    Color(0xFF34D399),
    Color(0xFFFF7A45),
  ];

  // ----------------------------------------------------------------- scenes

  void _sky(Canvas canvas, Size size, double t) {
    _gradient(
        canvas,
        size,
        const [Color(0xFF55B6F5), Color(0xFF9ED9FB), Color(0xFFE6F7FF)],
        const [0, 0.55, 1]);
    _sun(canvas, Offset(size.width * 0.86, size.height * 0.1),
        math.min(46, size.shortestSide * 0.09), t * 0.5);
    // Background balloons rising slowly.
    for (var i = 0; i < 6; i++) {
      final x =
          size.width * (0.08 + i * 0.17) + math.sin(t * math.pi * 8 + i) * 10;
      final span = size.height + 160;
      final y = size.height + 80 - ((t * 2 + i / 6) % 1.0) * span;
      _balloon(canvas, Offset(x, y), 13 + (i % 3) * 3,
          _candy[i].withValues(alpha: 0.55));
    }
    for (var i = 0; i < 4; i++) {
      final s = 26.0 + i * 8;
      _cloud(
          canvas,
          Offset(_drift(t, 1 + i * 0.5, size.width, i * 0.27),
              size.height * (0.12 + i * 0.2)),
          s,
          0.82);
    }
    _hill(canvas, size, size.height * 0.92, 18, 0.3, const Color(0xFF9BE48A));
    _hill(canvas, size, size.height * 0.97, 12, 2.0, const Color(0xFF62C85A));
  }

  void _space(Canvas canvas, Size size, double t) {
    _gradient(
        canvas,
        size,
        const [Color(0xFF070A26), Color(0xFF1B1452), Color(0xFF3B1E6E)],
        const [0, 0.55, 1]);
    // Nebula glows.
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.35),
      size.shortestSide * 0.5,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFF5CA8).withValues(alpha: 0.18),
          Colors.transparent
        ]).createShader(Rect.fromCircle(
            center: Offset(size.width * 0.2, size.height * 0.35),
            radius: size.shortestSide * 0.5)),
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.7),
      size.shortestSide * 0.55,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFF4CC9F0).withValues(alpha: 0.16),
          Colors.transparent
        ]).createShader(Rect.fromCircle(
            center: Offset(size.width * 0.85, size.height * 0.7),
            radius: size.shortestSide * 0.55)),
    );
    for (var i = 0; i < _stars.length; i++) {
      final a = 0.35 +
          0.65 * (0.5 + 0.5 * math.sin((t * 24 + _phase[i]) * math.pi * 2));
      final p = Offset(_stars[i].dx * size.width, _stars[i].dy * size.height);
      final r = i % 7 == 0 ? 2.4 : 1.3;
      canvas.drawCircle(
          p, r, Paint()..color = Colors.white.withValues(alpha: a));
      if (i % 11 == 0) {
        canvas.drawPath(starPath(p, 5.5 * a, innerRatio: 0.3, points: 4),
            Paint()..color = Colors.white.withValues(alpha: a * 0.9));
      }
    }
    // Ringed planet.
    final pc = Offset(size.width * 0.9, size.height * 0.9);
    final pr = math.min(70.0, size.shortestSide * 0.16);
    canvas.drawCircle(
      pc,
      pr,
      Paint()
        ..shader =
            const LinearGradient(colors: [Color(0xFFFFB86B), Color(0xFFFF5C8A)])
                .createShader(Rect.fromCircle(center: pc, radius: pr)),
    );
    canvas.save();
    canvas.translate(pc.dx, pc.dy);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: pr * 3.2, height: pr * 0.8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = pr * 0.14
        ..color = const Color(0xFFFFE08A).withValues(alpha: 0.85),
    );
    canvas.restore();
    // Moon.
    final mc = Offset(size.width * 0.9, size.height * 0.24);
    final mr = math.min(34.0, size.shortestSide * 0.08);
    canvas.drawCircle(mc, mr * 1.6,
        Paint()..color = const Color(0xFFFFF6C8).withValues(alpha: 0.12));
    canvas.drawCircle(mc, mr, Paint()..color = const Color(0xFFFFF3B8));
    canvas.drawCircle(mc.translate(-mr * 0.3, mr * 0.2), mr * 0.18,
        Paint()..color = const Color(0xFFF0DC8A));
    canvas.drawCircle(mc.translate(mr * 0.35, -mr * 0.25), mr * 0.12,
        Paint()..color = const Color(0xFFF0DC8A));
    // Shooting star now and then.
    final s = (t * 5) % 1.0;
    if (s < 0.12) {
      final k = s / 0.12;
      final start = Offset(size.width * 0.3, size.height * 0.05);
      final head = start + Offset(size.width * 0.45, size.height * 0.22) * k;
      canvas.drawLine(
        head,
        head - Offset(size.width * 0.12, size.height * 0.06),
        Paint()
          ..shader = LinearGradient(
                  colors: [Colors.white, Colors.white.withValues(alpha: 0)])
              .createShader(Rect.fromPoints(
                  head, head - Offset(size.width * 0.12, size.height * 0.06)))
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _meadow(Canvas canvas, Size size, double t) {
    _gradient(
        canvas,
        size,
        const [Color(0xFF6CC8F7), Color(0xFFBDEBFF), Color(0xFFE9FAFF)],
        const [0, 0.5, 1]);
    _sun(canvas, Offset(size.width * 0.14, size.height * 0.1),
        math.min(40, size.shortestSide * 0.08), t * 0.5);
    for (var i = 0; i < 3; i++) {
      _cloud(
          canvas,
          Offset(_drift(t, 0.8 + i * 0.4, size.width, 0.2 + i * 0.33),
              size.height * (0.1 + i * 0.12)),
          24.0 + i * 7,
          0.9);
    }
    _hill(canvas, size, size.height * 0.62, 26, 0.8, const Color(0xFFA8E890));
    _hill(canvas, size, size.height * 0.74, 20, 2.4, const Color(0xFF7AD66A));
    _hill(canvas, size, size.height * 0.86, 14, 4.0, const Color(0xFF4FBF57));
    // Bamboo at the edges.
    void bamboo(double x, double h, double sway) {
      final seg = Paint()..color = const Color(0xFF3FA34D);
      final node = Paint()..color = const Color(0xFF2E7D3A);
      const w = 12.0;
      final top = size.height - h;
      for (var y = size.height; y > top; y -= 46) {
        final dx = sway * (size.height - y) / h;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(x + dx, y - 44, w, 44), const Radius.circular(5)),
            seg);
        canvas.drawRect(Rect.fromLTWH(x + dx - 1, y - 46, w + 2, 4), node);
      }
      final leaf = Paint()..color = const Color(0xFF58C060);
      final tip = Offset(x + sway + w / 2, top);
      for (var k = 0; k < 3; k++) {
        canvas.save();
        canvas.translate(tip.dx, tip.dy + k * 26);
        canvas.rotate(-0.9 + k * 0.7 + sway * 0.02);
        canvas.drawOval(const Rect.fromLTWH(0, -6, 38, 12), leaf);
        canvas.restore();
      }
    }

    final sway = math.sin(t * math.pi * 16) * 6;
    bamboo(10, size.height * 0.55, sway);
    bamboo(30, size.height * 0.42, -sway * 0.8);
    bamboo(size.width - 24, size.height * 0.5, -sway);
    bamboo(size.width - 46, size.height * 0.38, sway * 0.7);
    // Flowers.
    final r = math.Random(5);
    for (var i = 0; i < 18; i++) {
      final x = r.nextDouble() * size.width;
      final y = size.height * (0.8 + r.nextDouble() * 0.18);
      final c = _candy[i % _candy.length];
      final bob = math.sin(t * math.pi * 20 + i) * 2;
      for (var k = 0; k < 5; k++) {
        final a = k * math.pi * 2 / 5;
        canvas.drawCircle(
            Offset(x + math.cos(a) * 4, y + bob + math.sin(a) * 4),
            3.2,
            Paint()..color = c);
      }
      canvas.drawCircle(
          Offset(x, y + bob), 2.4, Paint()..color = const Color(0xFFFFF3A8));
    }
  }

  void _railway(Canvas canvas, Size size, double t) {
    _gradient(
        canvas,
        size,
        const [Color(0xFF7FD0F7), Color(0xFFCDEEFF), Color(0xFFFFEFD0)],
        const [0, 0.5, 1]);
    _sun(canvas, Offset(size.width * 0.82, size.height * 0.12),
        math.min(40, size.shortestSide * 0.08), t * 0.5);
    for (var i = 0; i < 3; i++) {
      _cloud(
          canvas,
          Offset(_drift(t, 0.7 + i * 0.4, size.width, 0.1 + i * 0.3),
              size.height * (0.08 + i * 0.1)),
          22.0 + i * 6,
          0.9);
    }
    // Mountains.
    final mountain = Paint()..color = const Color(0xFF9C8CE8);
    final mountain2 = Paint()..color = const Color(0xFF7F6FD6);
    final snow = Paint()..color = Colors.white;
    void peak(double cx, double base, double w, double h, Paint p) {
      final path = Path()
        ..moveTo(cx - w / 2, base)
        ..lineTo(cx, base - h)
        ..lineTo(cx + w / 2, base)
        ..close();
      canvas.drawPath(path, p);
      final cap = Path()
        ..moveTo(cx - w * 0.12, base - h * 0.76)
        ..lineTo(cx, base - h)
        ..lineTo(cx + w * 0.12, base - h * 0.76)
        ..lineTo(cx + w * 0.04, base - h * 0.8)
        ..lineTo(cx - w * 0.03, base - h * 0.72)
        ..close();
      canvas.drawPath(cap, snow);
    }

    final base = size.height * 0.62;
    peak(
        size.width * 0.2, base, size.width * 0.5, size.height * 0.26, mountain);
    peak(size.width * 0.62, base, size.width * 0.6, size.height * 0.32,
        mountain2);
    peak(size.width * 0.95, base, size.width * 0.45, size.height * 0.22,
        mountain);
    _hill(canvas, size, size.height * 0.64, 16, 1.2, const Color(0xFF8EDB7A));
    _hill(canvas, size, size.height * 0.78, 10, 3.0, const Color(0xFF5FC35E));
    // Trees.
    final r = math.Random(3);
    for (var i = 0; i < 9; i++) {
      final x = r.nextDouble() * size.width;
      final y = size.height * (0.66 + r.nextDouble() * 0.1);
      canvas.drawRect(Rect.fromLTWH(x - 2, y, 4, 12),
          Paint()..color = const Color(0xFF8B5A2B));
      canvas.drawCircle(Offset(x, y - 4), 10 + r.nextDouble() * 5,
          Paint()..color = const Color(0xFF3FA34D));
    }
  }

  void _table(Canvas canvas, Size size, double t) {
    _gradient(
        canvas,
        size,
        const [Color(0xFF5B45C2), Color(0xFF7B5FE0), Color(0xFF9B7BF0)],
        const [0, 0.5, 1]);
    // Polka-dot wallpaper.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.07);
    const step = 34.0;
    for (var y = 0.0; y < size.height; y += step) {
      final odd = ((y / step).round()).isOdd;
      for (var x = odd ? step / 2 : 0.0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 5, dot);
      }
    }
    // Floating sparkles.
    for (var i = 0; i < 14; i++) {
      final p = Offset(_stars[i].dx * size.width, _stars[i].dy * size.height);
      final a = 0.3 +
          0.7 * (0.5 + 0.5 * math.sin((t * 16 + _phase[i]) * math.pi * 2));
      canvas.drawPath(starPath(p, 6 * a, innerRatio: 0.35, points: 4),
          Paint()..color = const Color(0xFFFFE680).withValues(alpha: a * 0.8));
    }
    // Wooden table top at the bottom.
    final top = size.height * 0.9;
    canvas.drawRect(Rect.fromLTWH(0, top, size.width, size.height - top),
        Paint()..color = const Color(0xFFB8743F));
    canvas.drawRect(Rect.fromLTWH(0, top, size.width, 6),
        Paint()..color = const Color(0xFFD8955A));
  }

  void _stage(Canvas canvas, Size size, double t) {
    _gradient(
        canvas,
        size,
        const [Color(0xFF1E0B30), Color(0xFF3A1656), Color(0xFF4A1E66)],
        const [0, 0.6, 1]);
    // Spotlight cone.
    final pulse = 0.85 + 0.15 * math.sin(t * math.pi * 12);
    final cone = Path()
      ..moveTo(size.width * 0.44, 0)
      ..lineTo(size.width * 0.56, 0)
      ..lineTo(size.width * 0.86, size.height * 0.88)
      ..lineTo(size.width * 0.14, size.height * 0.88)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFF3B0).withValues(alpha: 0.42 * pulse),
            const Color(0xFFFFF3B0).withValues(alpha: 0.06)
          ],
        ).createShader(Offset.zero & size),
    );
    // Floor.
    final floorTop = size.height * 0.84;
    canvas.drawRect(
        Rect.fromLTWH(0, floorTop, size.width, size.height - floorTop),
        Paint()..color = const Color(0xFF8B5A2B));
    for (var x = 0.0; x < size.width; x += 60) {
      canvas.drawLine(
          Offset(x, floorTop),
          Offset(x - 30, size.height),
          Paint()
            ..color = const Color(0xFF6E4420)
            ..strokeWidth = 2);
    }
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(size.width / 2, floorTop + 18),
          width: size.width * 0.72,
          height: 40),
      Paint()..color = const Color(0xFFFFF3B0).withValues(alpha: 0.28 * pulse),
    );
    // Curtains.
    final curtainW = math.min(size.width * 0.16, 120.0);
    void curtain(double x0, bool left) {
      for (var i = 0; i < 4; i++) {
        final fx = left ? x0 + i * curtainW / 4 : x0 - (i + 1) * curtainW / 4;
        final rect = Rect.fromLTWH(fx, 0, curtainW / 4, size.height);
        canvas.drawRect(
          rect,
          Paint()
            ..shader = const LinearGradient(colors: [
              Color(0xFF9E1030),
              Color(0xFFE0284F),
              Color(0xFF9E1030)
            ]).createShader(rect),
        );
      }
    }

    curtain(0, true);
    curtain(size.width, false);
    // Valance with scallops and bulbs.
    final valH = math.min(46.0, size.height * 0.07);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, valH),
        Paint()..color = const Color(0xFFC81E45));
    final sc = Paint()..color = const Color(0xFFC81E45);
    const scW = 40.0;
    for (var x = 0.0; x < size.width + scW; x += scW) {
      canvas.drawArc(
          Rect.fromLTWH(x, valH - scW / 2, scW, scW), 0, math.pi, true, sc);
    }
    canvas.drawRect(Rect.fromLTWH(0, valH - 4, size.width, 4),
        Paint()..color = const Color(0xFFFFC21A));
    for (var i = 0; (i * scW + scW / 2) < size.width; i++) {
      final on = ((t * 30).floor() + i) % 3 != 0;
      canvas.drawCircle(
          Offset(i * scW + scW / 2, valH + scW / 2 - 4),
          4,
          Paint()
            ..color = on ? const Color(0xFFFFE680) : const Color(0xFFB88A2A));
    }
  }

  void _arcade(Canvas canvas, Size size, double t) {
    _gradient(
        canvas,
        size,
        const [Color(0xFFFFC94D), Color(0xFFFFE7A3), Color(0xFFFFF6E0)],
        const [0, 0.4, 1]);
    // Sunburst.
    final c = Offset(size.width / 2, -size.height * 0.1);
    final burst = Paint()..color = Colors.white.withValues(alpha: 0.16);
    for (var i = 0; i < 16; i++) {
      final a0 = t * math.pi * 0.6 + i * math.pi / 8;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a0) * size.longestSide * 1.5,
            c.dy + math.sin(a0) * size.longestSide * 1.5)
        ..lineTo(c.dx + math.cos(a0 + math.pi / 16) * size.longestSide * 1.5,
            c.dy + math.sin(a0 + math.pi / 16) * size.longestSide * 1.5)
        ..close();
      canvas.drawPath(path, burst);
    }
    // Bunting across the top.
    final sway = math.sin(t * math.pi * 14) * 3;
    final line = Paint()
      ..color = const Color(0xFF8B5A2B).withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final rope = Path()
      ..moveTo(0, 6)
      ..quadraticBezierTo(size.width / 2, 34 + sway, size.width, 6);
    canvas.drawPath(rope, line);
    const flagW = 26.0;
    final count = (size.width / (flagW + 8)).floor();
    for (var i = 0; i <= count; i++) {
      final x = i * (size.width / count);
      final k = x / size.width;
      final y = 6 + (1 - math.pow(2 * k - 1, 2)) * (28 + sway);
      final flag = Path()
        ..moveTo(x - flagW / 2, y)
        ..lineTo(x + flagW / 2, y)
        ..lineTo(x, y + 26)
        ..close();
      canvas.drawPath(flag, Paint()..color = _candy[i % _candy.length]);
    }
    // Balloons drifting up along the sides.
    for (var i = 0; i < 5; i++) {
      final x = i.isEven
          ? size.width * (0.04 + i * 0.015)
          : size.width * (0.96 - i * 0.015);
      final span = size.height + 160;
      final y = size.height + 80 - ((t * 1.6 + i / 5) % 1.0) * span;
      _balloon(canvas, Offset(x + math.sin(t * math.pi * 10 + i) * 8, y), 14,
          _candy[(i + 2) % _candy.length].withValues(alpha: 0.7));
    }
  }

  @override
  bool shouldRepaint(covariant GameScenePainter old) =>
      old.scene != scene || old.time != time;
}
