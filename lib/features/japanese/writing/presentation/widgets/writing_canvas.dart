import 'package:flutter/material.dart';

class ColoredStroke {
  ColoredStroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
  });
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
}

class WritingCanvas extends StatefulWidget {
  final VoidCallback onCleared;
  final Color strokeColor;
  final double strokeWidth;
  final Color boardFill;
  final bool showClearButton;
  final bool isEraser;
  final ValueChanged<bool>? onInkChanged;

  /// Preferred height when parent does not constrain vertically (e.g. scroll views).
  final double fallbackHeight;

  const WritingCanvas({
    super.key,
    required this.onCleared,
    required this.strokeColor,
    this.strokeWidth = 14,
    this.boardFill = Colors.white,
    this.showClearButton = true,
    this.isEraser = false,
    this.onInkChanged,
    this.fallbackHeight = 320,
  });

  @override
  WritingCanvasState createState() => WritingCanvasState();
}

class WritingCanvasState extends State<WritingCanvas> {
  final List<ColoredStroke> strokes = [];
  ColoredStroke? currentStroke;

  bool get hasInk => strokes.isNotEmpty;

  void clear() {
    setState(() {
      strokes.clear();
      currentStroke = null;
    });
    widget.onCleared();
    widget.onInkChanged?.call(false);
  }

  void _start(Offset position) {
    final width = widget.isEraser ? (widget.strokeWidth * 2.2).clamp(22.0, 48.0) : widget.strokeWidth;
    setState(() {
      currentStroke = ColoredStroke(
        points: [position],
        color: widget.isEraser ? widget.boardFill : widget.strokeColor,
        width: width,
        isEraser: widget.isEraser,
      );
      strokes.add(currentStroke!);
    });
    widget.onInkChanged?.call(true);
  }

  void _move(Offset position) {
    final stroke = currentStroke;
    if (stroke == null) return;
    setState(() => stroke.points.add(position));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expand = constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight < 8000 &&
            constraints.maxHeight > 120;
        final height = expand ? constraints.maxHeight : widget.fallbackHeight;

        return SizedBox(
          width: double.infinity,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.boardFill,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.strokeColor.withValues(alpha: 0.28), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (event) => _start(event.localPosition),
                    onPointerMove: (event) {
                      if (event.down) _move(event.localPosition);
                    },
                    onPointerUp: (_) => currentStroke = null,
                    child: CustomPaint(
                      painter: StrokePainter(
                        List<ColoredStroke>.from(strokes),
                        boardFill: widget.boardFill,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  if (widget.showClearButton)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: const Color(0xFFFFEBEE),
                        elevation: 2,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Xóa',
                          iconSize: 26,
                          padding: const EdgeInsets.all(10),
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          onPressed: clear,
                          icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFC62828)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class StrokePainter extends CustomPainter {
  final List<ColoredStroke> strokes;
  final Color boardFill;

  StrokePainter(this.strokes, {this.boardFill = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.isEraser ? boardFill : stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) => true;
}
