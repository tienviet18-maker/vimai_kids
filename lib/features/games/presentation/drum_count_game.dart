import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_locale_policy.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/kid_guide.dart';
import '../../../core/providers.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/chunky_button.dart';
import '../logic/drum_count_round.dart';
import 'widgets/game_play_scaffold.dart';

/// "Đếm tiếng trống": Bạn gấu plays a drum (bell, coins…) a few times; the
/// child counts by ear and taps the number. After the answer the beats are
/// replayed while Mai counts aloud and lights come on one by one.
class DrumCountGame extends ConsumerStatefulWidget {
  const DrumCountGame({super.key});

  @override
  ConsumerState<DrumCountGame> createState() => _DrumCountGameState();
}

enum _Phase { listening, answering, counting }

const _accent = Color(0xFFFF7A45);

class _DrumCountGameState extends ConsumerState<DrumCountGame> {
  final _random = math.Random();
  final _timers = <Timer>[];

  late DrumCountRound _round = DrumCountRound.generate(level: 0, age: 5, random: _random);
  int _level = 0;
  int _age = 5;
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;
  bool _firstRound = true;
  _Phase _phase = _Phase.listening;

  /// Bumps on every beat so the drummer bounces.
  int _beat = 0;
  DrumSound _beatSound = DrumSound.drum;

  /// Lights shown during the count-along; -1 hides the row.
  int _lit = -1;

  int _tries = 0;
  int _cleanStreak = 0;
  final _wrongPicks = <int>{};
  bool _showAnswer = false;
  bool? _correct;
  String? _feedback;

  int get _goal => GameCatalog.sessionRounds(GameKind.drumCount, _age);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = ref.read(currentProfileProvider);
      _age = profile?.age ?? 5;
      _level = DrumCountRound.startLevel(_age);
      final audio = ref.read(audioServiceProvider);
      audio.soundEnabled = profile?.soundEnabled ?? true;
      audio.bgmEnabled = profile?.bgmEnabled ?? true;
      // No background music here: its rhythm would muddle the beats the
      // child is counting.
      _round = _newRound();
      _startRound(intro: true);
    });
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  // ------------------------------------------------------------ scheduling

  void _after(int ms, VoidCallback fn) {
    _timers.add(Timer(Duration(milliseconds: ms), () {
      if (mounted) fn();
    }));
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  /// Rough time Mai needs to say [lines], so the beats start after her.
  /// Every clip but the last plays to its end, trailing silence included
  /// (~1.3 s more than the words), before the next one starts.
  static int _speechMs(List<String> lines) =>
      lines.fold(450 + (lines.length - 1) * 1300, (sum, l) => sum + l.length * 68 + 350);

  /// Mai's praise line (speech up to ~2.9 s) before the count-along starts,
  /// so her first number does not cut it off.
  static const _afterPraiseMs = 2900;

  void _sound(DrumSound s) {
    final audio = ref.read(audioServiceProvider);
    switch (s) {
      case DrumSound.drum:
        audio.sfx(Sfx.drum);
      case DrumSound.bell:
        audio.bell(4);
      case DrumSound.coin:
        audio.sfx(Sfx.coin);
    }
  }

  /// Mai says [lines]; [fallback] plays only while a line has no clip yet.
  void _say(List<String> lines, {String? fallback}) {
    final audio = ref.read(audioServiceProvider);
    unawaited(audio.speak(lines, fallbackId: fallback).catchError((Object _) => const AudioPlayResult.unavailable('')));
  }

  void _hit(DrumSound s) {
    _sound(s);
    setState(() {
      _beat++;
      _beatSound = s;
    });
  }

  // ------------------------------------------------------------ round flow

  DrumCountRound _newRound() => DrumCountRound.generate(
        level: _level,
        age: _age,
        random: _random,
        avoidAnswer: _round.answer,
      );

  void _startRound({bool intro = false}) {
    _cancelTimers();
    setState(() {
      _phase = _Phase.listening;
      _lit = -1;
      _tries = 0;
      _wrongPicks.clear();
      _showAnswer = false;
      _correct = null;
      _feedback = null;
      _beatSound = _round.target;
    });
    final lines = [if (intro) KidGuide.gameDrumCount, _round.prompt];
    _say(lines, fallback: 'sys_math_count');
    _playBeats(_speechMs(lines), then: () {
      setState(() => _phase = _Phase.answering);
      if (_firstRound) _say([KidGuide.drumPick]);
    });
  }

  void _playBeats(int delayMs, {required VoidCallback then}) {
    final beats = _round.beats;
    for (var i = 0; i < beats.length; i++) {
      final s = beats[i];
      _after(delayMs + i * _round.tempoMs, () => _hit(s));
    }
    _after(delayMs + beats.length * _round.tempoMs + 200, then);
  }

  /// Replays the beats slowly; Mai says each number of the counted sound
  /// and a light comes on for it.
  void _countAlong(int delayMs, {required VoidCallback then}) {
    setState(() => _lit = 0);
    const step = 780;
    var k = 0;
    final beats = _round.beats;
    for (var i = 0; i < beats.length; i++) {
      final s = beats[i];
      final counted = s == _round.target;
      final n = counted ? ++k : 0;
      _after(delayMs + i * step, () {
        _hit(s);
        if (counted) {
          setState(() => _lit = n);
          _say(['$n']);
        }
      });
    }
    _after(delayMs + beats.length * step + 350, then);
  }

  /// "Nghe lại": Mai asks again and the beats replay.
  void _replay() {
    if (_finished || _phase == _Phase.counting) return;
    ref.read(audioServiceProvider).sfx(Sfx.tap);
    _cancelTimers();
    setState(() => _phase = _Phase.listening);
    _say([_round.prompt], fallback: 'sys_math_count');
    _playBeats(_speechMs([_round.prompt]), then: () => setState(() => _phase = _Phase.answering));
  }

  void _recordMastery(bool ok) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    unawaited(
      ref.read(masteryRepositoryProvider).record(
            childId: profile.id,
            itemId: 'drum_count_${_round.target.name}_${_round.answer}${_round.mixed ? '_mixed' : ''}',
            skill: 'game.drum_count',
            correct: ok,
          ),
    );
  }

  void _onPick(int n) {
    if (_finished || _phase != _Phase.answering || _wrongPicks.contains(n)) return;
    final audio = ref.read(audioServiceProvider);

    if (n == _round.answer) {
      final firstTry = _tries == 0;
      // After "Mình cùng đếm lại nào!" the child just heard the count; a
      // second count-along would only make them wait.
      final countedTogether = _showAnswer;
      setState(() {
        _phase = _Phase.counting;
        _correct = true;
        _feedback = 'Giỏi lắm!';
        _showAnswer = true;
        _score++;
      });
      audio.playCorrectSound();
      if (firstTry) {
        _recordMastery(true);
        _cleanStreak++;
        final cap = DrumCountRound.maxLevel(_age);
        if (_cleanStreak >= 2 && _level < cap) {
          _level++;
          _cleanStreak = 0;
        }
      }
      if (countedTogether) {
        _after(_afterPraiseMs + 300, _advance);
      } else {
        _countAlong(_afterPraiseMs, then: () => _after(500, _advance));
      }
      return;
    }

    setState(() {
      _tries++;
      _wrong++;
      _wrongPicks.add(n);
      _correct = false;
      _feedback = 'Thử lại nhé!';
    });
    if (_tries == 1) _recordMastery(false);
    _cleanStreak = 0;
    if (_tries == 2) {
      // Two misses: step down, then count together so the child hears how.
      // Mai says so at once (a retry line first would be cut off by it).
      audio.sfx(Sfx.wrong);
      if (_level > 0) _level--;
      setState(() {
        _phase = _Phase.counting;
        _showAnswer = true;
      });
      _say([KidGuide.drumCountTogether]);
      _countAlong(1900, then: () => setState(() => _phase = _Phase.answering));
    } else {
      audio.playWrongSound();
    }
  }

  void _advance() {
    if (_score >= _goal) {
      setState(() {
        _finished = true;
        _lit = -1;
      });
      return;
    }
    _firstRound = false;
    _round = _newRound();
    _startRound();
  }

  void _restart() {
    _cancelTimers();
    setState(() {
      _score = 0;
      _wrong = 0;
      _finished = false;
      _cleanStreak = 0;
      _level = DrumCountRound.startLevel(_age);
      _round = _newRound();
    });
    _startRound();
  }

  // ------------------------------------------------------------ view

  static String _glyph(DrumSound s) => switch (s) {
        DrumSound.drum => '🥁',
        DrumSound.bell => '🔔',
        DrumSound.coin => '🪙',
      };

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final listening = _phase == _Phase.listening;
    final showDots = _age <= 4 || _level == 0;
    return GamePlayScaffold(
      title: 'Đếm tiếng trống',
      scene: GameScene.stage,
      finished: _finished,
      correct: _correct,
      complete: GameCompletePanel(
        score: _score,
        wrong: _wrong,
        total: _goal,
        onRetry: _restart,
        hero: const SizedBox(
          width: 150,
          height: 150,
          child: _BearDrummer(beat: 0, sound: DrumSound.drum, mixed: false, celebrate: true),
        ),
      ),
      instruction: GameTargetBanner(
        label: round.prompt,
        glyph: _glyph(round.target),
        color: _accent,
        onTap: _replay,
      ),
      progress: GameProgressBar(current: _score, total: _goal, color: _accent),
      feedback: GameFeedbackToast(correct: _correct, message: _feedback),
      playArea: LayoutBuilder(
        builder: (context, c) {
          final width = math.min(c.maxWidth, 640.0);
          final n = round.choices.length;
          final byWidth = (width - (n - 1) * 12) / n;
          final tight = c.maxHeight < 340;
          final card = math.min(byWidth, tight ? 72.0 : (c.maxHeight * 0.26)).clamp(64.0, 128.0);
          final stage = KeyedSubtree(
            key: ValueKey('drum-count-answer-${round.answer}'),
            child: _Stage(
              beat: _beat,
              sound: _beatSound,
              mixed: round.mixed,
              lit: _lit,
              celebrate: _correct == true,
              listening: listening,
            ),
          );
          final cards = AnimatedOpacity(
            duration: VimaiMotion.of(context, VimaiMotion.feedback),
            opacity: listening ? 0.55 : 1,
            child: IgnorePointer(
              ignoring: _phase != _Phase.answering,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < n; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    _NumberCard(
                      key: ValueKey('drum-card-${round.choices[i]}'),
                      value: round.choices[i],
                      size: card,
                      color: gamePalette[i % gamePalette.length],
                      showDots: showDots,
                      wrong: _wrongPicks.contains(round.choices[i]),
                      right: _showAnswer && round.choices[i] == round.answer,
                      shakeKey: _wrongPicks.contains(round.choices[i]) ? '${round.choices[i]}-$_wrong' : null,
                      onTap: () => _onPick(round.choices[i]),
                    ),
                  ],
                ],
              ),
            ),
          );
          final replay = SizedBox(
            width: math.min(280.0, width),
            height: 68,
            child: ChunkyButton(
              color: VimaiColor.sky,
              depth: 6,
              radius: 26,
              semanticLabel: 'Nghe lại',
              onTap: _phase == _Phase.counting ? null : _replay,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hearing_rounded, color: Colors.white, size: 34),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Nghe lại',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VimaiType.display.copyWith(color: Colors.white, fontSize: 26, height: 1),
                    ),
                  ),
                ],
              ),
            ),
          );
          if (tight) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 170, child: stage),
                  const SizedBox(height: 8),
                  cards,
                  const SizedBox(height: 12),
                  replay,
                ],
              ),
            );
          }
          return Column(
            children: [
              Expanded(child: stage),
              const SizedBox(height: 10),
              cards,
              const SizedBox(height: 14),
              replay,
            ],
          );
        },
      ),
    );
  }
}

/// The spotlight: Bạn gấu with the instrument, and the count-along lights.
class _Stage extends StatelessWidget {
  const _Stage({
    required this.beat,
    required this.sound,
    required this.mixed,
    required this.lit,
    required this.celebrate,
    required this.listening,
  });

  final int beat;
  final DrumSound sound;
  final bool mixed;
  final int lit;
  final bool celebrate;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final lightsH = lit >= 0 ? math.min(52.0, c.maxHeight * 0.24) : 0.0;
        final size = math.min(c.maxWidth, c.maxHeight - lightsH).clamp(60.0, 300.0);
        return Column(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: size,
                  height: size,
                  child:
                      _BearDrummer(beat: beat, sound: sound, mixed: mixed, celebrate: celebrate, listening: listening),
                ),
              ),
            ),
            if (lit >= 0) SizedBox(height: lightsH, child: _CountLights(lit: lit)),
          ],
        );
      },
    );
  }
}

/// Bạn gấu sways gently; every [beat] change makes the instrument bounce,
/// a ring ripple out and a music note float up.
class _BearDrummer extends StatefulWidget {
  const _BearDrummer({
    required this.beat,
    required this.sound,
    required this.mixed,
    this.celebrate = false,
    this.listening = false,
  });

  final int beat;
  final DrumSound sound;
  final bool mixed;
  final bool celebrate;
  final bool listening;

  @override
  State<_BearDrummer> createState() => _BearDrummerState();
}

class _BearDrummerState extends State<_BearDrummer> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  late final AnimationController _hit = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _idle.stop();
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _BearDrummer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.beat != oldWidget.beat) _hit.forward(from: 0);
  }

  @override
  void dispose() {
    _idle.dispose();
    _hit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final s = math.min(c.maxWidth, c.maxHeight);
        return AnimatedBuilder(
          animation: Listenable.merge([_idle, _hit]),
          builder: (context, _) {
            final t = _idle.value;
            final h = still ? 0.0 : _hit.value;
            final pulse = math.sin(h * math.pi); // 0 → 1 → 0 over a beat
            final sway = still ? 0.0 : math.sin(t * math.pi * 2) * (widget.celebrate ? 0.12 : 0.05);
            final hop = widget.celebrate && !still ? -math.sin(t * math.pi * 4).abs() * s * 0.05 : 0.0;
            Widget instrument(DrumSound kind, {required bool active}) {
              final p = active ? pulse : 0.0;
              final glyph = switch (kind) {
                DrumSound.drum => '🥁',
                DrumSound.bell => '🔔',
                DrumSound.coin => '🐷',
              };
              return Transform.translate(
                offset: Offset(0, p * s * 0.03),
                child: Transform.rotate(
                  angle: kind == DrumSound.bell ? math.sin(h * math.pi * 3) * 0.35 * (active ? 1 : 0) : 0,
                  alignment: Alignment.topCenter,
                  child: Transform.scale(
                    scaleX: 1 + p * 0.12,
                    scaleY: 1 - p * 0.1,
                    child: Text(glyph, style: TextStyle(fontSize: s * (widget.mixed ? 0.22 : 0.3), height: 1)),
                  ),
                ),
              );
            }

            final active = widget.sound;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Spotlight.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFF3B0).withValues(alpha: widget.listening ? 0.55 : 0.38),
                          const Color(0xFFFFF3B0).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Ripple ring on every beat.
                if (h > 0 && h < 1)
                  Align(
                    alignment: const Alignment(0, 0.55),
                    child: Opacity(
                      opacity: (1 - h).clamp(0.0, 1.0),
                      child: Container(
                        width: s * (0.3 + h * 0.55),
                        height: s * (0.3 + h * 0.55) * 0.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.elliptical(s, s * 0.5)),
                          border: Border.all(color: const Color(0xFFFFE680), width: 4),
                        ),
                      ),
                    ),
                  ),
                // Bạn gấu.
                Align(
                  alignment: const Alignment(0, -0.45),
                  child: Transform.translate(
                    offset: Offset(0, hop + pulse * s * 0.025),
                    child: Transform.rotate(
                      angle: sway,
                      child: Text('🐻', style: TextStyle(fontSize: s * 0.42, height: 1)),
                    ),
                  ),
                ),
                // Instrument(s) in front.
                Align(
                  alignment: const Alignment(0, 0.72),
                  child: widget.mixed
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            instrument(DrumSound.drum, active: active == DrumSound.drum),
                            SizedBox(width: s * 0.06),
                            instrument(DrumSound.bell, active: active == DrumSound.bell),
                          ],
                        )
                      : instrument(active, active: true),
                ),
                // A coin drops into the piggy bank.
                if (active == DrumSound.coin && h > 0 && h < 1)
                  Align(
                    alignment: Alignment(0.05, -0.1 + h * 0.65),
                    child: Opacity(
                      opacity: h < 0.8 ? 1 : (1 - h) * 5,
                      child: Text('🪙', style: TextStyle(fontSize: s * 0.12, height: 1)),
                    ),
                  ),
                // Music note floats up.
                if (h > 0 && h < 1)
                  Align(
                    alignment: Alignment(0.62 + h * 0.1, 0.1 - h * 0.7),
                    child: Opacity(
                      opacity: (1 - h).clamp(0.0, 1.0),
                      child: Icon(Icons.music_note_rounded, color: const Color(0xFFFFE680), size: s * 0.14),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// One glowing light per counted beat, each showing its number.
class _CountLights extends StatelessWidget {
  const _CountLights({required this.lit});

  final int lit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final d = math.min(c.maxHeight, (c.maxWidth - 9 * 6) / 10).clamp(20.0, 48.0);
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= lit; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('light-$i'),
                    tween: Tween(begin: 0.3, end: 1),
                    duration: VimaiMotion.of(context, const Duration(milliseconds: 380)),
                    curve: Curves.elasticOut,
                    builder: (context, v, child) => Transform.scale(scale: v, child: child),
                    child: Container(
                      width: d,
                      height: d,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          center: Alignment(-0.3, -0.4),
                          colors: [Color(0xFFFFF6C2), Color(0xFFFFC21A)],
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFFFE680).withValues(alpha: 0.7), blurRadius: 14, spreadRadius: 2),
                        ],
                      ),
                      child: FittedBox(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            '$i',
                            style: const TextStyle(
                                color: Color(0xFF8A4B00), fontSize: 26, fontWeight: FontWeight.w900, height: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Big number card; little ones also get the matching dots.
class _NumberCard extends StatelessWidget {
  const _NumberCard({
    super.key,
    required this.value,
    required this.size,
    required this.color,
    required this.showDots,
    required this.wrong,
    required this.right,
    required this.shakeKey,
    required this.onTap,
  });

  final int value;
  final double size;
  final Color color;
  final bool showDots;
  final bool wrong;
  final bool right;
  final Object? shakeKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dot = size * 0.11;
    return ShakeOnChange(
      trigger: shakeKey,
      child: PopOnChange(
        trigger: right ? 'right' : null,
        child: AnimatedOpacity(
          duration: VimaiMotion.of(context, VimaiMotion.feedback),
          opacity: wrong ? 0.45 : 1,
          child: SizedBox(
            width: size,
            height: size * (showDots ? 1.12 : 1),
            child: ChunkyButton(
              color: right ? VimaiColor.correct : color,
              glow: right ? VimaiColor.correct : null,
              depth: 6,
              radius: size * 0.24,
              semanticLabel: 'Số $value',
              onTap: wrong ? null : onTap,
              child: Padding(
                padding: EdgeInsets.all(size * 0.08),
                child: FittedBox(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$value',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.5,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          shadows: const [Shadow(color: Color(0x40000000), offset: Offset(0, 2), blurRadius: 2)],
                        ),
                      ),
                      if (showDots)
                        SizedBox(
                          width: dot * 5 + 4 * 3,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 3,
                            runSpacing: 3,
                            children: [
                              for (var i = 0; i < value; i++)
                                Container(
                                  width: dot,
                                  height: dot,
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
