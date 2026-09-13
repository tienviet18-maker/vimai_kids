import 'package:flutter/material.dart';

class ColoredStroke {
  ColoredStroke({required this.points, required this.color, required this.width});
  final List<Offset> points;
  final Color color;
  final double width;
}

class WritingCanvas extends StatefulWidget {
  final VoidCallback onCleared;
  final Color strokeColor;
  final double strokeWidth;
  final Color boardFill;
  final bool showClearButton;
  final ValueChanged<bool>? onInkChanged;

  const WritingCanvas({
    super.key,
    required this.onCleared,
    required this.strokeColor,
    this.strokeWidth = 14,
    this.boardFill = Colors.white,
    this.showClearButton = true,
    this.onInkChanged,
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
    setState(() {
      currentStroke = ColoredStroke(
        points: [position],
        color: widget.strokeColor,
        width: widget.strokeWidth,
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
        final height = (constraints.maxHeight.isFinite && constraints.maxHeight > 120)
            ? (constraints.maxHeight < 280 ? constraints.maxHeight * 0.85 : 260.0).clamp(160.0, 280.0)
            : (constraints.maxWidth < 400 ? 200.0 : 260.0);
        final bounded = constraints.maxHeight.isFinite && constraints.maxHeight < 8000;
        final board = Container(
          height: bounded ? null : height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.boardFill,
            borderRadius: BorderRadius.circular(24),
            border: widget.boardFill.a == 0 ? null : Border.all(color: widget.strokeColor.withValues(alpha: 0.3), width: 3),
            boxShadow: widget.boardFill.a == 0
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) => _start(event.localPosition),
              onPointerMove: (event) {
                if (event.down) _move(event.localPosition);
              },
              onPointerUp: (_) => currentStroke = null,
              child: CustomPaint(
                painter: StrokePainter(List<ColoredStroke>.from(strokes)),
                size: Size.infinite,
              ),
            ),
          ),
        );
        if (!widget.showClearButton) {
          return bounded ? board : SizedBox(height: height, child: board);
        }
        return Column(
          children: [
            if (bounded) Expanded(child: board) else board,
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: clear,
              icon: const Icon(Icons.refresh, color: Colors.grey),
              label: const Text('Xóa / Vẽ lại', style: TextStyle(color: Colors.grey)),
            )
          ],
        );
      },
    );
  }
}

class StrokePainter extends CustomPainter {
  final List<ColoredStroke> strokes;

  StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
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
