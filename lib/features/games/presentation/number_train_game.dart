import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/chunky_button.dart';
import 'widgets/game_art.dart';
import 'widgets/game_play_scaffold.dart';
import '../../../core/audio/kid_guide.dart';

class NumberTrainGame extends ConsumerStatefulWidget {
  const NumberTrainGame({super.key});

  @override
  ConsumerState<NumberTrainGame> createState() => _NumberTrainGameState();
}

class _NumberTrainGameState extends ConsumerState<NumberTrainGame> {
  late List<int> _numbers;
  final _selected = <int>[];
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;
  String? _feedback;
  bool? _correct;
  int _trainLap = 0;

  int get _goal => GameCatalog.roundsForAge(ref.read(currentProfileProvider)?.age ?? 5);

  @override
  void initState() {
    super.initState();
    _numbers = [1, 2, 3, 4, 5]..shuffle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(_reset);
        unawaited(ref.read(audioServiceProvider).speak([KidGuide.gameNumberTrain], fallbackId: 'sys_math_order'));
      }
    });
  }

  void _reset() {
    final age = ref.read(currentProfileProvider)?.age ?? 5;
    _numbers = GameCatalog.numberTrain(age, Random());
    _trainLap++;
    _selected.clear();
    _feedback = null;
    _correct = null;
  }

  void _pick(int n) {
    if (_finished || _selected.contains(n)) return;
    setState(() => _selected.add(n));
    final expected = List<int>.from(_numbers)..sort();
    if (_selected.length != expected.length) return;
    final ok = _selected.join() == expected.join();
    if (ok) {
      unawaited(ref.read(audioServiceProvider).playRandomSuccess());
      setState(() {
        _score++;
        _correct = true;
        _feedback = 'Giỏi lắm!';
        if (_score >= _goal) {
          _finished = true;
        }
      });
      if (!_finished) {
        Future<void>.delayed(const Duration(milliseconds: 650), () {
          if (!mounted || _finished) return;
          setState(_reset);
        });
      }
    } else {
      unawaited(ref.read(audioServiceProvider).playRandomTryAgain());
      setState(() {
        _wrong++;
        _correct = false;
        _feedback = 'Thử lại nhé!';
        _selected.clear();
      });
    }
  }

  void _sayHowTo() => unawaited(ref.read(audioServiceProvider).speak([KidGuide.gameNumberTrain]));

  @override
  Widget build(BuildContext context) {
    final ordered = List<int>.from(_numbers)..sort();
    return GamePlayScaffold(
      title: 'Tàu số',
      scene: GameScene.railway,
      finished: _finished,
      correct: _correct,
      complete: GameCompletePanel(
        score: _score,
        wrong: _wrong,
        total: _goal,
        hero: const SizedBox(width: 150, height: 120, child: _Engine(width: 150)),
        onRetry: () => setState(() {
          _score = 0;
          _wrong = 0;
          _finished = false;
          _reset();
        }),
      ),
      instruction: GameTargetBanner(
        label: 'Xếp số từ nhỏ đến lớn',
        glyph: '123',
        color: VimaiColor.sky,
        onTap: _sayHowTo,
      ),
      progress: GameProgressBar(current: _score, total: _goal, color: VimaiColor.sky),
      feedback: GameFeedbackToast(correct: _correct, message: _feedback),
      playArea: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 420;
          final cargo = ((constraints.maxWidth - 4 * 10) / 5).clamp(64.0, 88.0);
          final wide = constraints.maxWidth > 560 && constraints.maxHeight > 420;
          return Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRect(
                      child: SizedBox(
                        height: compact ? 120 : (wide ? 200 : 150),
                        child: Stack(
                          children: [
                            const Positioned(left: 0, right: 0, bottom: 0, height: 26, child: CustomPaint(painter: _TrackPainter())),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 12,
                              top: 0,
                              child: TweenAnimationBuilder<double>(
                                key: ValueKey('lap-$_trainLap'),
                                tween: Tween(begin: MediaQuery.disableAnimationsOf(context) ? 0 : -1.3, end: 0),
                                duration: VimaiMotion.of(context, const Duration(milliseconds: 900)),
                                curve: Curves.easeOutCubic,
                                builder: (context, v, child) => FractionalTranslation(translation: Offset(v, 0), child: child),
                                child: AnimatedSlide(
                                  offset: _correct == true ? const Offset(1.4, 0) : Offset.zero,
                                  duration: VimaiMotion.of(context, const Duration(milliseconds: 620)),
                                  curve: Curves.easeInCubic,
                                  child: ShakeOnChange(
                                    trigger: _wrong == 0 ? null : _wrong,
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      alignment: Alignment.bottomCenter,
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          for (var i = 0; i < ordered.length; i++) ...[
                                            _Wagon(
                                              value: i < _selected.length ? _selected[i] : null,
                                              color: gamePalette[i % gamePalette.length],
                                              next: i == _selected.length,
                                            ),
                                            const _Coupler(),
                                          ],
                                          const _Engine(width: 100),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 16 : 28),
                    Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var i = 0; i < _numbers.length; i++)
                          _CargoBox(
                            key: ValueKey('cargo-${_numbers[i]}'),
                            value: _numbers[i],
                            size: cargo,
                            color: gamePalette[(i + 2) % gamePalette.length],
                            used: _selected.contains(_numbers[i]),
                            onTap: () => _pick(_numbers[i]),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      footer: Center(
        child: SizedBox(
          height: 52,
          child: ChunkyButton(
            color: Colors.white,
            outlineWidth: 0,
            depth: 4,
            radius: 26,
            semanticLabel: 'Làm lại',
            padding: const EdgeInsets.symmetric(horizontal: 18),
            onTap: () => setState(_reset),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.replay_rounded, color: VimaiColor.sky),
                const SizedBox(width: 6),
                Text('Làm lại', style: VimaiType.button.copyWith(color: VimaiColor.sky)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Wagon extends StatelessWidget {
  const _Wagon({required this.value, required this.color, required this.next});

  final int? value;
  final Color color;
  final bool next;

  @override
  Widget build(BuildContext context) {
    const w = 56.0;
    const h = 82.0;
    final dark = Color.lerp(color, Colors.black, 0.28)!;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 6,
            bottom: 14,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(color, Colors.white, 0.25)!, color],
                ),
                border: Border(bottom: BorderSide(color: dark, width: 6)),
              ),
              padding: const EdgeInsets.fromLTRB(5, 6, 5, 4),
              child: AnimatedContainer(
                duration: VimaiMotion.of(context, VimaiMotion.feedback),
                decoration: BoxDecoration(
                  color: value == null ? Colors.white.withValues(alpha: next ? 0.75 : 0.35) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: next ? Border.all(color: Colors.white, width: 2.5) : null,
                ),
                alignment: Alignment.center,
                child: value == null
                    ? (next ? Icon(Icons.arrow_downward_rounded, color: dark, size: 22) : null)
                    : PopOnChange(
                        trigger: value,
                        amount: 0.35,
                        child: FittedBox(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text('$value', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: dark, height: 1)),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          for (final x in const [6.0, 32.0])
            Positioned(
              left: x,
              bottom: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A48),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFC21A), width: 4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Coupler extends StatelessWidget {
  const _Coupler();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 6,
      margin: const EdgeInsets.only(bottom: 24),
      color: const Color(0xFF3A3A48),
    );
  }
}

class _Engine extends StatefulWidget {
  const _Engine({required this.width});
  final double width;

  @override
  State<_Engine> createState() => _EngineState();
}

class _EngineState extends State<_Engine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
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
    return SizedBox(
      width: widget.width,
      height: widget.width * 0.8,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: TrainEnginePainter(puff: _c.value)),
      ),
    );
  }
}

class _CargoBox extends StatelessWidget {
  const _CargoBox({super.key, required this.value, required this.size, required this.color, required this.used, required this.onTap});

  final int value;
  final double size;
  final Color color;
  final bool used;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: VimaiMotion.of(context, VimaiMotion.feedback),
      opacity: used ? 0.35 : 1,
      child: AnimatedScale(
        duration: VimaiMotion.of(context, VimaiMotion.feedback),
        scale: used ? 0.86 : 1,
        child: SizedBox(
          width: size,
          height: size,
          child: ChunkyButton(
            color: color,
            radius: 20,
            depth: 7,
            semanticLabel: '$value',
            onTap: used ? null : onTap,
            child: Center(
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: size * 0.44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                  shadows: const [Shadow(color: Color(0x40000000), offset: Offset(0, 2), blurRadius: 2)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sleeper = Paint()..color = const Color(0xFF8B5A2B);
    for (var x = 4.0; x < size.width; x += 22) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height * 0.35, 12, size.height * 0.5), const Radius.circular(3)), sleeper);
    }
    final rail = Paint()..color = const Color(0xFF6B7185);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.3, size.width, 5), rail);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.62, size.width, 5), rail);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
