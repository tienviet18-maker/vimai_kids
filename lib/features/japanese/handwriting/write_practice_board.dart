import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../domain/models/kana_item.dart';
import '../../shared/widgets/kids_living_canopy.dart';
import '../writing/presentation/widgets/writing_canvas.dart';
import 'stroke_order_catalog.dart';
import 'stroke_order_player.dart';
import 'svg_path_parser.dart';

/// Child practice canvas with floating candy tools — no full-width button bars.
class WritePracticeBoard extends StatefulWidget {
  const WritePracticeBoard({
    super.key,
    required this.kana,
    required this.color,
    required this.copy,
    this.onShowStrokeOrder,
    this.onShowModel,
  });

  final KanaItem kana;
  final Color color;
  final AppStrings copy;
  final VoidCallback? onShowStrokeOrder;
  final VoidCallback? onShowModel;

  @override
  State<WritePracticeBoard> createState() => _WritePracticeBoardState();
}

class _WritePracticeBoardState extends State<WritePracticeBoard> {
  final GlobalKey<WritingCanvasState> _canvasKey = GlobalKey<WritingCanvasState>();
  bool _hasInk = false;
  bool _showStrokeGuides = false;

  void _clear() {
    _canvasKey.currentState?.clear();
  }

  Future<void> _showModelAnimation() async {
    if (widget.onShowModel != null) {
      widget.onShowModel!();
      return;
    }
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: widget.copy.close,
      barrierColor: Colors.black54,
      pageBuilder: (context, anim, secondary) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                decoration: BoxDecoration(
                  color: VimaiColor.cream,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 24, offset: Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.copy.showModel,
                            style: VimaiType.cardTitle.copyWith(color: widget.color),
                          ),
                        ),
                        TactileNode(
                          semanticLabel: widget.copy.close,
                          minSize: 52,
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, size: 28),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: StrokeOrderPlayer(
                        kana: widget.kana,
                        color: widget.color,
                        copy: widget.copy,
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

  void _toggleStrokeGuides() {
    if (widget.onShowStrokeOrder != null) {
      widget.onShowStrokeOrder!();
      return;
    }
    setState(() => _showStrokeGuides = !_showStrokeGuides);
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    final color = widget.color;
    final hasGuides = StrokeOrderCatalog().hasPaths(widget.kana.id);

    return Column(
      children: [
        if (_hasInk)
          Text(copy.writingDetected, style: VimaiType.cardBody.copyWith(color: color)),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = constraints.biggest.shortestSide;
                      return Semantics(
                        label: widget.kana.character,
                        child: Container(
                          decoration: BoxDecoration(
                            color: VimaiColor.surface,
                            borderRadius: BorderRadius.circular(VimaiRadius.lg),
                            border: Border.all(color: color.withValues(alpha: 0.45), width: 3),
                            boxShadow: [
                              BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(VimaiRadius.lg),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                IgnorePointer(
                                  child: Opacity(
                                    opacity: 0.18,
                                    child: Text(
                                      widget.kana.character,
                                      style: TextStyle(fontSize: side * 0.62, fontWeight: FontWeight.w800, color: color),
                                    ),
                                  ),
                                ),
                                if (_showStrokeGuides && hasGuides)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: _StrokeGuidePainter(
                                          pathData: StrokeOrderCatalog().pathsFor(widget.kana.id),
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned.fill(
                                  child: WritingCanvas(
                                    key: _canvasKey,
                                    strokeColor: color,
                                    boardFill: Colors.transparent,
                                    showClearButton: false,
                                    onCleared: () => setState(() => _hasInk = false),
                                    onInkChanged: (hasInk) {
                                      if (mounted) setState(() => _hasInk = hasInk);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 8,
                child: _FloatingWriteTools(
                  color: color,
                  guidesOn: _showStrokeGuides,
                  hasGuides: hasGuides,
                  onClear: _clear,
                  onShowModel: _showModelAnimation,
                  onToggleGuides: hasGuides ? _toggleStrokeGuides : null,
                  clearLabel: copy.clearWriting,
                  modelLabel: copy.showModel,
                  guidesLabel: copy.strokeMode,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(copy.freeWriteHint, textAlign: TextAlign.center, style: VimaiType.caption),
        ),
      ],
    );
  }
}

class _FloatingWriteTools extends StatelessWidget {
  const _FloatingWriteTools({
    required this.color,
    required this.guidesOn,
    required this.hasGuides,
    required this.onClear,
    required this.onShowModel,
    required this.onToggleGuides,
    required this.clearLabel,
    required this.modelLabel,
    required this.guidesLabel,
  });

  final Color color;
  final bool guidesOn;
  final bool hasGuides;
  final VoidCallback onClear;
  final VoidCallback onShowModel;
  final VoidCallback? onToggleGuides;
  final String clearLabel;
  final String modelLabel;
  final String guidesLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolOrb(
          key: const Key('write-clear'),
          icon: Icons.auto_fix_off_rounded,
          label: clearLabel,
          color: color,
          onTap: onClear,
        ),
        const SizedBox(height: 10),
        _ToolOrb(
          key: const Key('write-retry'),
          icon: Icons.refresh_rounded,
          label: clearLabel,
          color: color,
          onTap: onClear,
        ),
        const SizedBox(height: 10),
        _ToolOrb(
          key: const Key('write-show-model'),
          icon: Icons.play_circle_filled_rounded,
          label: modelLabel,
          color: VimaiColor.accentOrange,
          onTap: onShowModel,
        ),
        if (onToggleGuides != null) ...[
          const SizedBox(height: 10),
          _ToolOrb(
            key: const Key('write-stroke-guides'),
            icon: Icons.format_list_numbered_rounded,
            label: guidesLabel,
            color: guidesOn ? VimaiColor.leafGreen : color,
            selected: guidesOn,
            onTap: onToggleGuides!,
          ),
        ],
      ],
    );
  }
}

class _ToolOrb extends StatelessWidget {
  const _ToolOrb({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return TactileNode(
      semanticLabel: label,
      minSize: VimaiSize.touchKid,
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [color, Color.lerp(color, Colors.white, 0.25)!])
              : LinearGradient(colors: [Colors.white, Color.lerp(color, Colors.white, 0.85)!]),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Icon(icon, size: 30, color: selected ? Colors.white : color),
      ),
    );
  }
}

class _StrokeGuidePainter extends CustomPainter {
  _StrokeGuidePainter({required this.pathData, required this.color});

  final List<String> pathData;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.shortestSide / 109) * 0.82;
    final dx = (size.width - 109 * scale) / 2;
    final dy = (size.height - 109 * scale) / 2;
    final ghost = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < pathData.length; i++) {
      final path = SvgPathParser.parse(pathData[i], scale: scale, shift: Offset(dx, dy));
      _drawDashed(canvas, path, ghost);
      final start = PathMetricsHelper.start(path);
      if (start != null) {
        canvas.drawCircle(start, 14, Paint()..color = color);
        final tp = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, start - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 10.0;
      const gap = 8.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrokeGuidePainter old) =>
      old.pathData != pathData || old.color != color;
}
