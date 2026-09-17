import 'package:flutter/material.dart';

import '../../../core/theme/vimai_tokens.dart';

enum BubbleTailPosition { bottomCenter, leftCenter, topCenter }

/// Kid-friendly, reactive speech bubble used by Mai AI Companion.
class MaiSpeechBubble extends StatelessWidget {
  final String text;
  final BubbleTailPosition tailPosition;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final Widget? trailingAction;

  const MaiSpeechBubble({
    super.key,
    required this.text,
    this.tailPosition = BubbleTailPosition.bottomCenter,
    this.backgroundColor = Colors.white,
    this.borderColor = VimaiColor.honey,
    this.textColor = VimaiColor.ink,
    this.onTap,
    this.onDismiss,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Lời nói của Mai: $text',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          painter: _SpeechBubblePainter(
            color: backgroundColor,
            borderColor: borderColor,
            tailPosition: tailPosition,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              tailPosition == BubbleTailPosition.leftCenter ? 20 : 14,
              tailPosition == BubbleTailPosition.topCenter ? 20 : 12,
              14,
              tailPosition == BubbleTailPosition.bottomCenter ? 20 : 12,
            ),
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Text(
                        text,
                        style: VimaiType.cardTitle.copyWith(
                          fontSize: 14,
                          height: 1.35,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (onDismiss != null)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onDismiss,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.close_rounded, size: 18, color: VimaiColor.inkSoft),
                        ),
                      ),
                  ],
                ),
                if (trailingAction != null) ...[
                  const SizedBox(height: 6),
                  trailingAction!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final BubbleTailPosition tailPosition;

  _SpeechBubblePainter({
    required this.color,
    required this.borderColor,
    required this.tailPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 18.0;
    const tailWidth = 14.0;
    const tailHeight = 8.0;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    Rect bubbleRect;
    switch (tailPosition) {
      case BubbleTailPosition.bottomCenter:
        bubbleRect = Rect.fromLTWH(0, 0, size.width, size.height - tailHeight);
        break;
      case BubbleTailPosition.topCenter:
        bubbleRect = Rect.fromLTWH(0, tailHeight, size.width, size.height - tailHeight);
        break;
      case BubbleTailPosition.leftCenter:
        bubbleRect = Rect.fromLTWH(tailHeight, 0, size.width - tailHeight, size.height);
        break;
    }

    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(bubbleRect, const Radius.circular(radius)));

    // Draw tail
    switch (tailPosition) {
      case BubbleTailPosition.bottomCenter:
        final cx = size.width * 0.5;
        path.moveTo(cx - tailWidth / 2, size.height - tailHeight);
        path.lineTo(cx, size.height);
        path.lineTo(cx + tailWidth / 2, size.height - tailHeight);
        break;
      case BubbleTailPosition.topCenter:
        final cx = size.width * 0.5;
        path.moveTo(cx - tailWidth / 2, tailHeight);
        path.lineTo(cx, 0);
        path.lineTo(cx + tailWidth / 2, tailHeight);
        break;
      case BubbleTailPosition.leftCenter:
        final cy = size.height * 0.5;
        path.moveTo(tailHeight, cy - tailWidth / 2);
        path.lineTo(0, cy);
        path.lineTo(tailHeight, cy + tailWidth / 2);
        break;
    }

    // Shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.08), 4, true);
    // Body
    canvas.drawPath(path, fillPaint);
    // Border
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.tailPosition != tailPosition;
  }
}
