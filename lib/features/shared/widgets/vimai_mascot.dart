import 'package:flutter/material.dart';

import '../../../core/theme/vimai_tokens.dart';

enum MascotMood { happy, excited, thinking, celebrating, encouraging }

class VimaiMascot extends StatelessWidget {
  final MascotMood mood;
  final double size;
  final Color? color;

  const VimaiMascot({
    super.key,
    this.mood = MascotMood.happy,
    this.size = 88,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ViMai',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _MascotPainter(mood: mood, color: color ?? VimaiColor.mascot),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final MascotMood mood;
  final Color color;

  _MascotPainter({required this.mood, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final body = Paint()..color = color;
    final belly = Paint()..color = VimaiColor.mascotBelly;
    final ink = Paint()..color = VimaiColor.ink.withValues(alpha: 0.82);
    final blush = Paint()..color = VimaiColor.mascotBlush.withValues(alpha: 0.55);
    final white = Paint()..color = Colors.white;
    final accent = Paint()..color = VimaiColor.honey;

    final cx = w * 0.5;
    final cy = w * 0.54;
    final r = w * 0.36;

    if (mood == MascotMood.celebrating || mood == MascotMood.excited) {
      final spark = Paint()
        ..color = VimaiColor.honey
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w * 0.16, w * 0.18), Offset(w * 0.24, w * 0.26), spark);
      canvas.drawLine(Offset(w * 0.84, w * 0.16), Offset(w * 0.76, w * 0.26), spark);
      canvas.drawCircle(Offset(w * 0.18, w * 0.42), w * 0.03, accent);
      canvas.drawCircle(Offset(w * 0.84, w * 0.4), w * 0.028, accent);
    }

    canvas.drawOval(Rect.fromCircle(center: Offset(cx - r * 0.62, cy - r * 0.7), radius: r * 0.28), body);
    canvas.drawOval(Rect.fromCircle(center: Offset(cx + r * 0.62, cy - r * 0.7), radius: r * 0.28), body);
    canvas.drawCircle(Offset(cx, cy), r, body);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + r * 0.18), width: r * 1.15, height: r * 0.95), belly);

    canvas.drawCircle(Offset(cx - r * 0.32, cy + r * 0.22), r * 0.12, blush);
    canvas.drawCircle(Offset(cx + r * 0.32, cy + r * 0.22), r * 0.12, blush);

    final eyeY = mood == MascotMood.thinking ? cy - r * 0.08 : cy - r * 0.12;
    final eyeS = mood == MascotMood.excited ? r * 0.13 : r * 0.11;
    if (mood == MascotMood.happy || mood == MascotMood.encouraging) {
      final lid = Paint()
        ..color = VimaiColor.ink.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: Offset(cx - r * 0.28, eyeY), radius: eyeS), 3.5, 2.4, false, lid);
      canvas.drawArc(Rect.fromCircle(center: Offset(cx + r * 0.28, eyeY), radius: eyeS), 3.5, 2.4, false, lid);
    } else {
      canvas.drawCircle(Offset(cx - r * 0.28, eyeY), eyeS, white);
      canvas.drawCircle(Offset(cx + r * 0.28, eyeY), eyeS, white);
      final pupil = mood == MascotMood.thinking ? Offset(cx - r * 0.22, eyeY) : Offset(cx - r * 0.28, eyeY);
      final pupil2 = mood == MascotMood.thinking ? Offset(cx + r * 0.34, eyeY) : Offset(cx + r * 0.28, eyeY);
      canvas.drawCircle(pupil, eyeS * 0.55, ink);
      canvas.drawCircle(pupil2, eyeS * 0.55, ink);
    }

    final mouth = Path();
    final my = cy + r * 0.28;
    if (mood == MascotMood.celebrating || mood == MascotMood.excited) {
      mouth.addOval(Rect.fromCenter(center: Offset(cx, my + r * 0.02), width: r * 0.42, height: r * 0.32));
      canvas.drawPath(mouth, ink);
    } else if (mood == MascotMood.thinking) {
      final p = Paint()
        ..color = VimaiColor.ink.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: Offset(cx + r * 0.06, my), width: r * 0.28, height: r * 0.18), 0.2, 2.2, false, p);
    } else {
      final p = Paint()
        ..color = VimaiColor.ink.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: Offset(cx, my), width: r * 0.42, height: r * 0.28), 0.2, 2.7, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) {
    return oldDelegate.mood != mood || oldDelegate.color != color;
  }
}

Color mascotColorForAvatar(String avatar) {
  switch (avatar) {
    case 'mint':
      return VimaiColor.mint;
    case 'sky':
      return VimaiColor.sky;
    case 'grape':
      return VimaiColor.grape;
    case 'honey':
      return VimaiColor.honey;
    case 'coral':
      return VimaiColor.coral;
    case 'peach':
      return VimaiColor.peach;
    default:
      return VimaiColor.mascot;
  }
}
