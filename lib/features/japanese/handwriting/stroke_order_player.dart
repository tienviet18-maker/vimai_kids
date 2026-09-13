import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../domain/models/kana_item.dart';
import '../../shared/widgets/vimai_ui.dart';
import 'stroke_order_catalog.dart';
import 'svg_path_parser.dart';

enum StrokePlayerPlayback { idle, playing, paused, completed }

/// Teaches official KanjiVG stroke order. Never draws the child's ink.
class StrokeOrderPlayer extends StatefulWidget {
  const StrokeOrderPlayer({
    super.key,
    required this.kana,
    required this.color,
    required this.copy,
    this.onPlayAudio,
  });

  final KanaItem kana;
  final Color color;
  final AppStrings copy;
  final VoidCallback? onPlayAudio;

  @override
  State<StrokeOrderPlayer> createState() => StrokeOrderPlayerState();
}

class StrokeOrderPlayerState extends State<StrokeOrderPlayer> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  int _step = 0;
  StrokePlayerPlayback _playback = StrokePlayerPlayback.idle;

  List<String> get _paths => StrokeOrderCatalog().pathsFor(widget.kana.id);
  List<String> get strokeIds => StrokeOrderCatalog().strokeIdsFor(widget.kana.id);
  int get strokeCount => _paths.length;
  int get currentStrokeNumber => strokeCount == 0 ? 0 : _step + 1;
  StrokePlayerPlayback get playback => _playback;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _anim.addStatusListener(_onAnimStatus);
    if (_paths.isNotEmpty) {
      _playback = StrokePlayerPlayback.playing;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playCurrent();
    });
  }

  @override
  void dispose() {
    _anim.removeStatusListener(_onAnimStatus);
    _anim.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StrokeOrderPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kana.id != widget.kana.id) {
      _step = 0;
      _playback = StrokePlayerPlayback.idle;
      _playCurrent();
    }
  }

  void _onAnimStatus(AnimationStatus status) {
    if (!mounted || status != AnimationStatus.completed) return;
    if (_paths.isEmpty) return;
    if (_step >= _paths.length - 1) {
      setState(() => _playback = StrokePlayerPlayback.completed);
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (!mounted || _playback != StrokePlayerPlayback.playing) return;
      setState(() => _step++);
      _playCurrent(announce: false);
    });
  }

  void _playCurrent({bool announce = true}) {
    if (_paths.isEmpty) {
      setState(() => _playback = StrokePlayerPlayback.idle);
      return;
    }
    if (announce) widget.onPlayAudio?.call();
    _anim.duration = const Duration(milliseconds: 1500);
    setState(() => _playback = StrokePlayerPlayback.playing);
    _anim.forward(from: 0);
  }

  void replay() {
    setState(() {
      _step = 0;
      _playback = StrokePlayerPlayback.playing;
    });
    _playCurrent();
  }

  void nextStroke() {
    if (_paths.isEmpty) return;
    if (_step >= _paths.length - 1) {
      _anim.value = 1;
      setState(() => _playback = StrokePlayerPlayback.completed);
      return;
    }
    setState(() => _step++);
    _playCurrent(announce: false);
  }

  void previousStroke() {
    if (_paths.isEmpty) return;
    if (_playback == StrokePlayerPlayback.completed) {
      setState(() => _step = _paths.length - 1);
      _playCurrent(announce: false);
      return;
    }
    if (_step <= 0) {
      _playCurrent(announce: false);
      return;
    }
    setState(() => _step--);
    _playCurrent(announce: false);
  }

  void togglePlayPause() {
    if (_paths.isEmpty) return;
    if (_playback == StrokePlayerPlayback.playing) {
      _anim.stop();
      setState(() => _playback = StrokePlayerPlayback.paused);
      return;
    }
    if (_playback == StrokePlayerPlayback.completed) {
      replay();
      return;
    }
    setState(() => _playback = StrokePlayerPlayback.playing);
    _anim.forward();
  }

  Path _pathFor(int index, Size size) {
    final d = _paths[index];
    final scale = (size.shortestSide / 109) * 0.82;
    final dx = (size.width - 109 * scale) / 2;
    final dy = (size.height - 109 * scale) / 2;
    return SvgPathParser.parse(d, scale: scale, shift: Offset(dx, dy));
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    final color = widget.color;
    final hasPaths = _paths.isNotEmpty;
    final completed = _playback == StrokePlayerPlayback.completed;

    final compact = MediaQuery.sizeOf(context).height < 700;
    return Column(
      children: [
        Semantics(
          header: true,
          label: widget.kana.character,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.kana.character,
              style: TextStyle(fontSize: compact ? 40 : 56, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ),
        if (hasPaths) ...[
          Semantics(
            liveRegion: true,
            label: completed ? copy.strokeComplete : copy.strokeProgress(currentStrokeNumber, strokeCount),
            child: Text(
              completed ? '✓ ${copy.strokeComplete}' : copy.strokeProgress(currentStrokeNumber, strokeCount),
              style: VimaiType.cardTitle.copyWith(color: color),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              completed ? copy.strokeComplete : copy.watchThisStroke,
              textAlign: TextAlign.center,
              style: VimaiType.cardBody,
            ),
          ],
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(copy.strokeMissing, textAlign: TextAlign.center, style: VimaiType.cardTitle.copyWith(color: color)),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return Semantics(
                    label: hasPaths
                        ? copy.strokeProgress(completed ? strokeCount : currentStrokeNumber, strokeCount)
                        : copy.strokeMissing,
                    child: Container(
                      decoration: BoxDecoration(
                        color: VimaiColor.surface,
                        borderRadius: BorderRadius.circular(VimaiRadius.lg),
                        border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(VimaiRadius.lg),
                        child: hasPaths
                            ? AnimatedBuilder(
                                animation: _anim,
                                builder: (context, _) {
                                  return CustomPaint(
                                    size: size,
                                    painter: StrokeOrderPainter(
                                      paths: [
                                        for (var i = 0; i < _paths.length; i++) _pathFor(i, size),
                                      ],
                                      step: completed ? _paths.length : _step,
                                      t: completed ? 1 : _anim.value,
                                      color: color,
                                      completed: completed,
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Opacity(
                                  opacity: 0.35,
                                  child: Text(
                                    widget.kana.character,
                                    style: TextStyle(fontSize: 56, color: color, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (hasPaths) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _control(copy.replayStrokes, replay),
              _control(copy.strokePrev, previousStroke),
              _control(
                _playback == StrokePlayerPlayback.playing ? copy.strokePause : copy.strokePlay,
                togglePlayPause,
              ),
              _control(copy.strokeNext, nextStroke),
            ],
          ),
        ],
        if (!compact)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(copy.kanjivgCredit, textAlign: TextAlign.center, style: VimaiType.caption),
          ),
      ],
    );
  }

  Widget _control(String label, VoidCallback onTap) {
    return KidButton(label: label, color: widget.color, onPressed: onTap, expanded: false);
  }
}

class StrokeOrderPainter extends CustomPainter {
  StrokeOrderPainter({
    required this.paths,
    required this.step,
    required this.t,
    required this.color,
    required this.completed,
  });

  final List<Path> paths;
  final int step;
  final double t;
  final Color color;
  final bool completed;

  @override
  void paint(Canvas canvas, Size size) {
    final done = Paint()
      ..color = color.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final active = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (completed) {
      for (final path in paths) {
        canvas.drawPath(path, active);
      }
      return;
    }

    for (var i = 0; i < paths.length; i++) {
      if (i < step) {
        canvas.drawPath(paths[i], done);
      } else if (i == step) {
        canvas.drawPath(PathMetricsHelper.extract(paths[i], t), active);
        final start = PathMetricsHelper.start(paths[i]);
        final tan = PathMetricsHelper.tangent(paths[i], 0.12);
        if (start != null && tan != null && tan.distance > 0.1) {
          _arrow(canvas, start, tan, color);
        }
      }
    }
  }

  void _arrow(Canvas canvas, Offset origin, Offset dir, Color color) {
    final n = dir / dir.distance;
    final tip = origin + n * 16;
    final left = origin + Offset(-n.dy, n.dx) * 7;
    final right = origin + Offset(n.dy, -n.dx) * 7;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant StrokeOrderPainter old) =>
      old.step != step || old.t != t || old.completed != completed || old.paths.length != paths.length;
}
