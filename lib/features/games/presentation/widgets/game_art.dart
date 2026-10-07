import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hand-painted game art (no image assets, no network): stars, trophy,
/// panda, rocket, train engine.

Path starPath(Offset c, double outer,
    {double innerRatio = 0.48,
    int points = 5,
    double rotation = -math.pi / 2}) {
  final path = Path();
  final inner = outer * innerRatio;
  for (var i = 0; i < points * 2; i++) {
    final r = i.isEven ? outer : inner;
    final a = rotation + i * math.pi / points;
    final p = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  return path..close();
}

const goldTop = Color(0xFFFFE680);
const goldMid = Color(0xFFFFC21A);
const goldDeep = Color(0xFFE08A00);

/// A fat, rounded, glossy gold star (or an empty slot when [filled] is false).
class GameStar extends StatelessWidget {
  const GameStar(
      {super.key, required this.size, this.filled = true, this.emptyColor});

  final double size;
  final bool filled;
  final Color? emptyColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StarPainter(
          filled: filled,
          emptyColor: emptyColor ?? Colors.white.withValues(alpha: 0.55)),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.filled, required this.emptyColor});
  final bool filled;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.53);
    final r = size.shortestSide * 0.5;
    final path = starPath(c, r, innerRatio: 0.5);
    final join = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = r * 0.28;
    if (!filled) {
      canvas.drawPath(path, join..color = emptyColor);
      canvas.drawPath(path, Paint()..color = emptyColor);
      final inner = starPath(c, r * 0.62, innerRatio: 0.5);
      canvas.drawPath(
          inner, Paint()..color = Colors.black.withValues(alpha: 0.06));
      return;
    }
    canvas.drawPath(path.shift(Offset(0, r * 0.12)), join..color = goldDeep);
    canvas.drawPath(path.shift(Offset(0, r * 0.12)), Paint()..color = goldDeep);
    final rect = Rect.fromCircle(center: c, radius: r);
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [goldTop, goldMid],
      ).createShader(rect);
    canvas.drawPath(path, join..color = goldMid);
    canvas.drawPath(path, fill);
    // Shine.
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(-r * 0.18, -r * 0.22),
          width: r * 0.42,
          height: r * 0.24),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) =>
      old.filled != filled || old.emptyColor != emptyColor;
}

/// Gold trophy cup with a star.
class TrophyPainter extends CustomPainter {
  TrophyPainter({this.shine = 0});
  final double shine;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [goldDeep, goldMid, goldTop, goldMid, goldDeep],
        stops: [0, 0.25, 0.45, 0.7, 1],
      ).createShader(Offset.zero & size);
    final deep = Paint()..color = goldDeep;

    // Handles.
    final handle = Paint()
      ..color = goldMid
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.22, h * 0.3),
            width: w * 0.3,
            height: h * 0.28),
        math.pi * 0.5,
        math.pi * 1.1,
        false,
        handle);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.78, h * 0.3),
            width: w * 0.3,
            height: h * 0.28),
        -math.pi * 0.6,
        math.pi * 1.1,
        false,
        handle);

    // Cup.
    final cup = Path()
      ..moveTo(w * 0.2, h * 0.1)
      ..lineTo(w * 0.8, h * 0.1)
      ..quadraticBezierTo(w * 0.8, h * 0.58, w * 0.5, h * 0.62)
      ..quadraticBezierTo(w * 0.2, h * 0.58, w * 0.2, h * 0.1)
      ..close();
    canvas.drawPath(cup, gold);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.1), width: w * 0.6, height: h * 0.07),
        deep);
    // Stem and base.
    canvas.drawRect(Rect.fromLTWH(w * 0.44, h * 0.6, w * 0.12, h * 0.14), gold);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.3, h * 0.72, w * 0.4, h * 0.08),
            Radius.circular(w * 0.03)),
        gold);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.24, h * 0.8, w * 0.52, h * 0.13),
          Radius.circular(w * 0.04)),
      Paint()..color = const Color(0xFF8B4FD8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.34, h * 0.835, w * 0.32, h * 0.055),
          Radius.circular(w * 0.02)),
      Paint()..color = goldTop,
    );
    // Star on cup.
    canvas.drawPath(starPath(Offset(w * 0.5, h * 0.32), w * 0.13),
        Paint()..color = Colors.white.withValues(alpha: 0.92));
    // Moving shine streak.
    final sx = w * (0.15 + 0.7 * shine);
    canvas.save();
    canvas.clipPath(cup);
    canvas.drawRect(
      Rect.fromLTWH(sx, 0, w * 0.08, h),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TrophyPainter old) => old.shine != shine;
}

/// Friendly panda head. [mouth] 0 = closed smile, 1 = wide open (eating).
class PandaPainter extends CustomPainter {
  PandaPainter({this.mouth = 0, this.happy = false, this.blink = false});

  final double mouth;
  final bool happy;
  final bool blink;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final ox = (size.width - s) / 2;
    final oy = (size.height - s) / 2;
    Offset p(double x, double y) => Offset(ox + x * s, oy + y * s);
    final black = Paint()..color = const Color(0xFF26262E);
    final white = Paint()..color = Colors.white;

    // Body + paws peeking under the head.
    canvas.drawOval(
        Rect.fromCenter(center: p(0.5, 0.98), width: s * 0.78, height: s * 0.5),
        black);
    canvas.drawOval(
        Rect.fromCenter(center: p(0.5, 1.0), width: s * 0.46, height: s * 0.36),
        white);

    // Ears.
    canvas.drawCircle(p(0.2, 0.2), s * 0.13, black);
    canvas.drawCircle(p(0.8, 0.2), s * 0.13, black);
    canvas.drawCircle(
        p(0.2, 0.2), s * 0.06, Paint()..color = const Color(0xFF4A4A56));
    canvas.drawCircle(
        p(0.8, 0.2), s * 0.06, Paint()..color = const Color(0xFF4A4A56));

    // Head with soft shading.
    final headRect =
        Rect.fromCenter(center: p(0.5, 0.5), width: s * 0.8, height: s * 0.72);
    canvas.drawOval(
      headRect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.35),
          radius: 0.9,
          colors: [Colors.white, Color(0xFFF1F1F6), Color(0xFFDADAE6)],
          stops: [0, 0.7, 1],
        ).createShader(headRect),
    );

    // Eye patches.
    void patch(Offset c, double angle) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: s * 0.17, height: s * 0.23),
          black);
      canvas.restore();
    }

    patch(p(0.35, 0.46), 0.5);
    patch(p(0.65, 0.46), -0.5);

    // Eyes.
    if (happy || blink) {
      final lid = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.025
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
          Rect.fromCenter(
              center: p(0.355, 0.47), width: s * 0.08, height: s * 0.07),
          math.pi * 1.1,
          math.pi * 0.8,
          false,
          lid);
      canvas.drawArc(
          Rect.fromCenter(
              center: p(0.645, 0.47), width: s * 0.08, height: s * 0.07),
          math.pi * 1.1,
          math.pi * 0.8,
          false,
          lid);
    } else {
      canvas.drawCircle(p(0.36, 0.46), s * 0.045, white);
      canvas.drawCircle(p(0.64, 0.46), s * 0.045, white);
      canvas.drawCircle(p(0.365, 0.465), s * 0.028, black);
      canvas.drawCircle(p(0.635, 0.465), s * 0.028, black);
      canvas.drawCircle(p(0.372, 0.452), s * 0.01, white);
      canvas.drawCircle(p(0.642, 0.452), s * 0.01, white);
    }

    // Blush.
    final blush = Paint()
      ..color = const Color(0xFFFF9AAE).withValues(alpha: 0.6);
    canvas.drawOval(
        Rect.fromCenter(
            center: p(0.27, 0.62), width: s * 0.1, height: s * 0.06),
        blush);
    canvas.drawOval(
        Rect.fromCenter(
            center: p(0.73, 0.62), width: s * 0.1, height: s * 0.06),
        blush);

    // Nose.
    canvas.drawOval(
        Rect.fromCenter(
            center: p(0.5, 0.585), width: s * 0.09, height: s * 0.06),
        black);

    // Mouth.
    final m = mouth.clamp(0.0, 1.0);
    if (m > 0.05) {
      final mouthRect = Rect.fromCenter(
          center: p(0.5, 0.685 + m * 0.02),
          width: s * (0.12 + 0.06 * m),
          height: s * (0.04 + 0.13 * m));
      canvas.drawOval(mouthRect, Paint()..color = const Color(0xFF7A1F2E));
      canvas.save();
      canvas.clipPath(Path()..addOval(mouthRect));
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(mouthRect.center.dx,
                mouthRect.bottom - mouthRect.height * 0.15),
            width: mouthRect.width * 0.8,
            height: mouthRect.height * 0.55),
        Paint()..color = const Color(0xFFFF7A90),
      );
      canvas.restore();
    } else {
      final smile = Paint()
        ..color = const Color(0xFF26262E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.018
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
          Rect.fromCenter(
              center: p(0.46, 0.64), width: s * 0.08, height: s * 0.07),
          0.2,
          math.pi * 0.8,
          false,
          smile);
      canvas.drawArc(
          Rect.fromCenter(
              center: p(0.54, 0.64), width: s * 0.08, height: s * 0.07),
          0.0,
          math.pi * 0.8,
          false,
          smile);
    }

    // Paws holding up.
    canvas.drawOval(
        Rect.fromCenter(
            center: p(0.24, 0.86), width: s * 0.16, height: s * 0.13),
        black);
    canvas.drawOval(
        Rect.fromCenter(
            center: p(0.76, 0.86), width: s * 0.16, height: s * 0.13),
        black);
  }

  @override
  bool shouldRepaint(covariant PandaPainter old) =>
      old.mouth != mouth || old.happy != happy || old.blink != blink;
}

/// Cartoon rocket pointing up, with a flickering flame. [flame] 0..1 animates.
class RocketPainter extends CustomPainter {
  RocketPainter({this.flame = 0, this.boost = 0});
  final double flame;
  final double boost;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final bodyTop = h * 0.04;
    final bodyBottom = h * 0.7;
    final bw = w * 0.46;

    // Flame.
    final flick = 0.85 + 0.15 * math.sin(flame * math.pi * 2 * 6);
    final fl = h * (0.2 + 0.14 * boost) * flick;
    final outer = Path()
      ..moveTo(cx - bw * 0.32, bodyBottom)
      ..quadraticBezierTo(
          cx - bw * 0.4, bodyBottom + fl * 0.6, cx, bodyBottom + fl)
      ..quadraticBezierTo(
          cx + bw * 0.4, bodyBottom + fl * 0.6, cx + bw * 0.32, bodyBottom)
      ..close();
    canvas.drawPath(outer, Paint()..color = const Color(0xFFFF7A1A));
    final inner = Path()
      ..moveTo(cx - bw * 0.18, bodyBottom)
      ..quadraticBezierTo(
          cx - bw * 0.2, bodyBottom + fl * 0.45, cx, bodyBottom + fl * 0.72)
      ..quadraticBezierTo(
          cx + bw * 0.2, bodyBottom + fl * 0.45, cx + bw * 0.18, bodyBottom)
      ..close();
    canvas.drawPath(inner, Paint()..color = const Color(0xFFFFE066));

    // Fins.
    final finPaint = Paint()..color = const Color(0xFFFF3D6E);
    final finL = Path()
      ..moveTo(cx - bw * 0.42, h * 0.46)
      ..quadraticBezierTo(cx - w * 0.5, h * 0.62, cx - w * 0.46, h * 0.76)
      ..lineTo(cx - bw * 0.36, h * 0.66)
      ..close();
    final finR = Path()
      ..moveTo(cx + bw * 0.42, h * 0.46)
      ..quadraticBezierTo(cx + w * 0.5, h * 0.62, cx + w * 0.46, h * 0.76)
      ..lineTo(cx + bw * 0.36, h * 0.66)
      ..close();
    canvas.drawPath(finL, finPaint);
    canvas.drawPath(finR, finPaint);

    // Body.
    final body = Path()
      ..moveTo(cx, bodyTop)
      ..cubicTo(cx + bw * 0.75, h * 0.16, cx + bw * 0.55, h * 0.6,
          cx + bw * 0.38, bodyBottom)
      ..lineTo(cx - bw * 0.38, bodyBottom)
      ..cubicTo(cx - bw * 0.55, h * 0.6, cx - bw * 0.75, h * 0.16, cx, bodyTop)
      ..close();
    final bodyRect =
        Rect.fromLTRB(cx - bw / 2, bodyTop, cx + bw / 2, bodyBottom);
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFDCE3F0), Colors.white, Color(0xFFC9D2E3)],
          stops: [0, 0.45, 1],
        ).createShader(bodyRect),
    );
    // Nose cone.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(Rect.fromLTRB(0, 0, w, h * 0.2),
        Paint()..color = const Color(0xFFFF3D6E));
    canvas.drawRect(Rect.fromLTRB(0, h * 0.6, w, h * 0.64),
        Paint()..color = const Color(0xFF7B63E0));
    canvas.restore();

    // Window.
    final wc = Offset(cx, h * 0.36);
    canvas.drawCircle(wc, bw * 0.27, Paint()..color = const Color(0xFF7B63E0));
    canvas.drawCircle(
      wc,
      bw * 0.2,
      Paint()
        ..shader =
            const RadialGradient(colors: [Color(0xFFBFE8FF), Color(0xFF4C8DDB)])
                .createShader(Rect.fromCircle(center: wc, radius: bw * 0.2)),
    );
    canvas.drawCircle(wc.translate(-bw * 0.07, -bw * 0.07), bw * 0.05,
        Paint()..color = Colors.white.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(covariant RocketPainter old) =>
      old.flame != flame || old.boost != boost;
}

/// Little steam engine facing right. [puff] 0..1 animates the smoke.
class TrainEnginePainter extends CustomPainter {
  TrainEnginePainter({this.puff = 0, this.color = const Color(0xFFFF3D6E)});
  final double puff;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final dark = Color.lerp(color, Colors.black, 0.3)!;
    // Smoke puffs.
    for (var i = 0; i < 3; i++) {
      final t = (puff + i / 3) % 1.0;
      final r = h * (0.06 + 0.1 * t);
      canvas.drawCircle(
        Offset(w * 0.72 - t * w * 0.35, h * 0.12 - t * h * 0.2),
        r,
        Paint()..color = Colors.white.withValues(alpha: 0.85 * (1 - t)),
      );
    }
    // Chimney.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.66, h * 0.14, w * 0.12, h * 0.22),
            Radius.circular(w * 0.02)),
        Paint()..color = const Color(0xFF3A3A48));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.62, h * 0.1, w * 0.2, h * 0.07),
            Radius.circular(w * 0.03)),
        Paint()..color = const Color(0xFF3A3A48));
    // Boiler.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.38, h * 0.34, w * 0.58, h * 0.36),
          Radius.circular(h * 0.16)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.3)!, color],
        ).createShader(Rect.fromLTWH(0, h * 0.34, w, h * 0.36)),
    );
    // Cabin.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.04, h * 0.12, w * 0.4, h * 0.58),
          Radius.circular(w * 0.06)),
      Paint()..color = dark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.06, w * 0.48, h * 0.1),
          Radius.circular(w * 0.04)),
      Paint()..color = const Color(0xFFFFC21A),
    );
    // Window.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.11, h * 0.22, w * 0.24, h * 0.2),
          Radius.circular(w * 0.04)),
      Paint()..color = const Color(0xFFBFE8FF),
    );
    // Front lamp + buffer.
    canvas.drawCircle(Offset(w * 0.95, h * 0.44), h * 0.06,
        Paint()..color = const Color(0xFFFFE066));
    canvas.drawRect(Rect.fromLTWH(w * 0.02, h * 0.68, w * 0.96, h * 0.06),
        Paint()..color = const Color(0xFF3A3A48));
    // Wheels.
    final wheel = Paint()..color = const Color(0xFF3A3A48);
    final hub = Paint()..color = const Color(0xFFFFC21A);
    for (final x in [0.2, 0.55, 0.82]) {
      final r = x == 0.2 ? h * 0.15 : h * 0.12;
      final c = Offset(w * x, h * 0.84 - (x == 0.2 ? 0 : h * 0.03));
      canvas.drawCircle(c, r, wheel);
      canvas.drawCircle(c, r * 0.4, hub);
    }
  }

  @override
  bool shouldRepaint(covariant TrainEnginePainter old) =>
      old.puff != puff || old.color != color;
}
