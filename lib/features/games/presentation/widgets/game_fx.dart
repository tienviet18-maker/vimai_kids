import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'game_art.dart';

const confettiColors = [
  Color(0xFFFF5C8A),
  Color(0xFFFFC21A),
  Color(0xFF4CC9F0),
  Color(0xFF8B5CF6),
  Color(0xFF34D399),
  Color(0xFFFF7A45),
];

/// Juice layer for a game screen: star bursts where the child tapped and
/// stars that fly into the progress row. Everything here is decoration —
/// it ignores pointers and is skipped entirely under reduced motion.
class GameFx extends StatefulWidget {
  const GameFx({super.key, required this.child});

  final Widget child;

  static GameFxState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<GameFxState>();

  @override
  State<GameFx> createState() => GameFxState();
}

class _Particle {
  _Particle(this.pos, this.vel, this.color, this.shape, this.size, this.spin,
      this.life);
  Offset pos;
  Offset vel;
  final Color color;
  final int shape;
  final double size;
  final double spin;
  final double life;
  double age = 0;
  double rot = 0;
}

class _Flight {
  _Flight(this.from, this.to, this.onLand);
  final Offset from;
  final Offset to;
  final VoidCallback? onLand;
  double age = 0;
  static const duration = 0.62;
}

class GameFxState extends State<GameFx> with SingleTickerProviderStateMixin {
  final _layerKey = GlobalKey();
  final _repaint = ValueNotifier<int>(0);
  final _particles = <_Particle>[];
  final _flights = <_Flight>[];
  final _rand = math.Random();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  Offset? _lastPointer;

  /// Mai cheers for a moment after every earned star.
  final cheer = ValueNotifier<int>(0);

  bool get reduced => MediaQuery.disableAnimationsOf(context);

  /// Last place the child touched, in global coordinates.
  Offset? get lastPointer => _lastPointer;

  Offset? _toLocal(Offset? global) {
    if (global == null) return null;
    final box = _layerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.globalToLocal(global);
  }

  Offset _center() {
    final box = _layerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Offset.zero;
    return box.size.center(Offset.zero);
  }

  void _ensureTicking() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  /// Confetti + stars popping out of [global] (defaults to the last tap).
  void burst({Offset? global, int count = 22, double power = 1}) {
    if (!mounted || reduced) return;
    final origin = _toLocal(global ?? _lastPointer) ?? _center();
    for (var i = 0; i < count; i++) {
      final a = _rand.nextDouble() * math.pi * 2;
      final speed = (180 + _rand.nextDouble() * 320) * power;
      _particles.add(
        _Particle(
          origin,
          Offset(math.cos(a) * speed, math.sin(a) * speed - 160 * power),
          confettiColors[i % confettiColors.length],
          i % 3,
          5 + _rand.nextDouble() * 6,
          (_rand.nextDouble() - 0.5) * 12,
          0.75 + _rand.nextDouble() * 0.45,
        ),
      );
    }
    _ensureTicking();
  }

  /// A gold star flies from the last tap to [toGlobal]; [onLand] runs when it
  /// arrives (immediately under reduced motion).
  void flyStar(
      {required Offset toGlobal, Offset? fromGlobal, VoidCallback? onLand}) {
    if (!mounted) return;
    final to = _toLocal(toGlobal);
    final from = _toLocal(fromGlobal ?? _lastPointer) ?? _center();
    if (reduced || to == null) {
      onLand?.call();
      return;
    }
    _flights.add(_Flight(from, to, onLand));
    _ensureTicking();
  }

  void celebrate() => cheer.value++;

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    for (final p in _particles) {
      p.age += dt;
      p.vel = Offset(p.vel.dx * (1 - 1.2 * dt), p.vel.dy + 900 * dt);
      p.pos += p.vel * dt;
      p.rot += p.spin * dt;
    }
    _particles.removeWhere((p) => p.age >= p.life);
    final landed = <_Flight>[];
    for (final f in _flights) {
      f.age += dt;
      if (f.age >= _Flight.duration) landed.add(f);
    }
    for (final f in landed) {
      _flights.remove(f);
      f.onLand?.call();
    }
    _repaint.value++;
    if (_particles.isEmpty && _flights.isEmpty) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    cheer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _lastPointer = e.position,
      child: Stack(
        key: _layerKey,
        fit: StackFit.expand,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _FxPainter(this)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FxPainter extends CustomPainter {
  _FxPainter(this.fx) : super(repaint: fx._repaint);
  final GameFxState fx;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in fx._particles) {
      final fade = (1 - p.age / p.life).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      canvas.rotate(p.rot);
      switch (p.shape) {
        case 0:
          canvas.drawPath(starPath(Offset.zero, p.size * 1.2), paint);
        case 1:
          canvas.drawCircle(Offset.zero, p.size * 0.6, paint);
        default:
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromCenter(
                      center: Offset.zero,
                      width: p.size * 1.4,
                      height: p.size * 0.7),
                  const Radius.circular(2)),
              paint);
      }
      canvas.restore();
    }
    for (final f in fx._flights) {
      final k = Curves.easeInOutCubic
          .transform((f.age / _Flight.duration).clamp(0.0, 1.0));
      final ctrl =
          Offset((f.from.dx + f.to.dx) / 2, math.min(f.from.dy, f.to.dy) - 80);
      final a = Offset.lerp(f.from, ctrl, k)!;
      final b = Offset.lerp(ctrl, f.to, k)!;
      final pos = Offset.lerp(a, b, k)!;
      final r = 26 * (1 - k) + 11 * k + 6 * math.sin(k * math.pi);
      // Sparkle trail.
      for (var i = 1; i <= 4; i++) {
        final kk = (k - i * 0.05).clamp(0.0, 1.0);
        final ta = Offset.lerp(f.from, ctrl, kk)!;
        final tb = Offset.lerp(ctrl, f.to, kk)!;
        canvas.drawCircle(Offset.lerp(ta, tb, kk)!, (5 - i).toDouble(),
            Paint()..color = goldTop.withValues(alpha: 0.7 - i * 0.14));
      }
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(k * math.pi * 2);
      canvas.drawCircle(Offset.zero, r * 1.25,
          Paint()..color = goldTop.withValues(alpha: 0.35));
      final path = starPath(Offset.zero, r, innerRatio: 0.5);
      canvas.drawPath(
        path,
        Paint()
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.25
          ..color = goldDeep,
      );
      canvas.drawPath(path, Paint()..color = goldMid);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FxPainter oldDelegate) => true;
}

/// Gently falling confetti for the win screen. Static (but still festive)
/// under reduced motion.
class ConfettiRain extends StatefulWidget {
  const ConfettiRain({super.key, this.count = 70});
  final int count;

  @override
  State<ConfettiRain> createState() => _ConfettiRainState();
}

class _ConfettiRainState extends State<ConfettiRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6));
  late final List<List<double>> _seeds;

  @override
  void initState() {
    super.initState();
    final r = math.Random(21);
    _seeds = List.generate(
        widget.count, (_) => List.generate(5, (_) => r.nextDouble()));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 0.4;
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
            painter: _RainPainter(_c, _seeds), child: const SizedBox.expand()),
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter(this.t, this.seeds) : super(repaint: t);
  final Animation<double> t;
  final List<List<double>> seeds;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < seeds.length; i++) {
      final s = seeds[i];
      final speed = 0.6 + s[2] * 0.8;
      final k = (t.value * speed + s[1]) % 1.0;
      final x = s[0] * size.width + math.sin((k * 4 + s[3]) * math.pi * 2) * 18;
      final y = -20 + k * (size.height + 40);
      final color = confettiColors[i % confettiColors.length];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((k * 6 + s[4]) * math.pi);
      final w = 6 + s[3] * 6;
      if (i % 4 == 0) {
        canvas.drawPath(starPath(Offset.zero, w * 0.8), Paint()..color = color);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset.zero,
                  width: w,
                  height: w * 0.5 * (0.4 + 0.6 * math.cos(k * 20).abs())),
              const Radius.circular(2)),
          Paint()..color = color,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) => true;
}
