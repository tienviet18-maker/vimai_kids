import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_locale_policy.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/kid_guide.dart';
import '../../../core/providers.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/chunky_button.dart';
import '../logic/melody_memory_session.dart';
import 'widgets/game_fx.dart';
import 'widgets/game_play_scaffold.dart';

/// One bell bar: its colour and animal let a child who cannot read tell the
/// bars apart. Indexed by bell (0 = lowest note).
class MelodyBar {
  const MelodyBar(this.color, this.animal, this.name);
  final Color color;
  final String animal;
  final String name;
}

const melodyBars = [
  MelodyBar(Color(0xFFFF4D5E), '🐞', 'bọ rùa'),
  MelodyBar(Color(0xFFFF9124), '🦊', 'cáo'),
  MelodyBar(Color(0xFFFFC21A), '🐥', 'gà con'),
  MelodyBar(Color(0xFF2FC46B), '🐸', 'ếch'),
  MelodyBar(Color(0xFF3D8BFF), '🐳', 'cá voi'),
  MelodyBar(Color(0xFFA25BF0), '🦄', 'kỳ lân'),
];

/// Shelf colour for this game.
const melodyGameColor = Color(0xFF8E4BD8);

enum _Phase { listening, yourTurn, celebrate, oops, concert }

/// "Giai điệu bí ẩn": Mai rings a little melody on the bells, the child
/// rings it back. Every success adds a note; slips replay it gently.
class MelodyMemoryGame extends ConsumerStatefulWidget {
  const MelodyMemoryGame({super.key});

  @override
  ConsumerState<MelodyMemoryGame> createState() => _MelodyMemoryGameState();
}

class _MelodyMemoryGameState extends ConsumerState<MelodyMemoryGame> {
  late MelodyMemorySession _session = MelodyMemorySession(age: 5);
  final _timers = <Timer>[];
  final _hits = List<int>.filled(6, 0);
  AudioService? _audio;
  _Phase _phase = _Phase.listening;
  bool _finished = false;
  int? _lit;

  /// Notes of the melody shown as filled dots (Mai's playback or the child's).
  int _dots = 0;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = ref.read(currentProfileProvider);
      _audio = ref.read(audioServiceProvider);
      _audio?.soundEnabled = profile?.soundEnabled ?? true;
      _audio?.bgmEnabled = profile?.bgmEnabled ?? true;
      _audio?.startGameBgm();
      setState(() => _session = MelodyMemorySession(age: profile?.age ?? 5));
      _say(KidGuide.gameMelodyIntro, fallbackId: 'sys_thinking_memory');
      _playMelody(lead: const Duration(milliseconds: 3600));
    });
  }

  @override
  void dispose() {
    _cancelTimers();
    _audio?.stopGameBgm();
    super.dispose();
  }

  // ------------------------------------------------------------- helpers

  AudioService get _sound => _audio ?? ref.read(audioServiceProvider);

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _after(Duration d, VoidCallback fn) {
    late final Timer timer;
    timer = Timer(d, () {
      _timers.remove(timer);
      if (mounted) fn();
    });
    _timers.add(timer);
  }

  void _say(String line, {String? fallbackId}) {
    final audio = _sound;
    unawaited(audio.speak([line], fallbackId: fallbackId).catchError((Object _) => const AudioPlayResult.unavailable('')));
  }

  /// Lights a bar, rings its bell and makes it bounce.
  void _ring(int bell) {
    _sound.bell(bell);
    setState(() {
      _lit = bell;
      _hits[bell]++;
    });
    final hit = _hits[bell];
    _after(const Duration(milliseconds: 380), () {
      if (_lit == bell && _hits[bell] == hit) setState(() => _lit = null);
    });
  }

  /// Mai plays the current melody, then hands the turn to the child.
  void _playMelody({Duration lead = const Duration(milliseconds: 1500), bool announceTurn = true}) {
    _cancelTimers();
    final melody = List.of(_session.sequence);
    final gap = _session.noteGap;
    setState(() {
      _phase = _Phase.listening;
      _session.resetAttempt();
      _dots = 0;
      _lit = null;
    });
    for (var i = 0; i < melody.length; i++) {
      _after(lead + gap * i, () {
        _ring(melody[i]);
        setState(() => _dots = i + 1);
      });
    }
    _after(lead + gap * melody.length + const Duration(milliseconds: 250), () {
      setState(() {
        _phase = _Phase.yourTurn;
        _dots = 0;
      });
      if (announceTurn) _say(KidGuide.gameMelodyYourTurn);
    });
  }

  void _startRound({bool newBell = false}) {
    if (newBell) {
      _say(KidGuide.gameMelodyNewBell);
      _playMelody(lead: const Duration(milliseconds: 2600));
    } else {
      _say(KidGuide.gameMelodyListen);
      _playMelody();
    }
  }

  void _recordMastery(bool ok) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    unawaited(
      ref.read(masteryRepositoryProvider).record(
            childId: profile.id,
            itemId: 'melody_${_session.barCount}b_${_session.sequence.length}n',
            skill: 'game.melody_memory',
            correct: ok,
          ),
    );
  }

  // ------------------------------------------------------------- input

  void _onBar(int bell) {
    if (_finished || _phase != _Phase.yourTurn) return;
    _ring(bell);
    if (_session.tap(bell)) {
      setState(() => _dots = _session.position);
      if (_session.attemptComplete) _onMelodyDone();
      return;
    }
    _onMiss();
  }

  void _onMelodyDone() {
    final audio = _sound;
    _recordMastery(true);
    final addedBell = _session.completeMelody();
    setState(() => _phase = _Phase.celebrate);
    audio.playCorrectSound();
    GameFx.maybeOf(context)?.burst(count: 26);
    _after(const Duration(milliseconds: 2300), () {
      if (_session.finished) {
        _startConcert();
      } else {
        _startRound(newBell: addedBell);
      }
    });
  }

  void _onMiss() {
    final audio = _sound;
    _recordMastery(false);
    final outcome = _session.miss();
    setState(() {
      _phase = _Phase.oops;
      _shake++;
      _dots = 0;
    });
    audio.playWrongSound();
    _after(const Duration(milliseconds: 2400), () {
      if (outcome == MelodyMiss.shortened) {
        _say(KidGuide.gameMelodyShorter);
        _playMelody(lead: const Duration(milliseconds: 2200));
      } else {
        _playMelody(lead: const Duration(milliseconds: 300));
      }
    });
  }

  void _replay() {
    if (_finished || _phase != _Phase.yourTurn) return;
    _sound.sfx(Sfx.tap);
    _playMelody(lead: const Duration(milliseconds: 350), announceTurn: false);
  }

  /// Finale: the child's longest melody, played back as a little concert.
  void _startConcert() {
    _cancelTimers();
    final song = _session.longest.isEmpty ? List.of(_session.sequence) : List.of(_session.longest);
    final audio = _sound;
    setState(() {
      _phase = _Phase.concert;
      _dots = 0;
    });
    _say(KidGuide.gameMelodyConcert);
    const lead = Duration(milliseconds: 3400);
    const gap = Duration(milliseconds: 460);
    for (var i = 0; i < song.length; i++) {
      _after(lead + gap * i, () {
        _ring(song[i]);
        setState(() => _dots = i + 1);
      });
    }
    final end = lead + gap * song.length;
    _after(end + const Duration(milliseconds: 200), () {
      audio.sfx(Sfx.win);
      setState(() {
        for (final b in _session.bells) {
          _hits[b]++;
        }
      });
    });
    _after(end + const Duration(milliseconds: 1600), () => setState(() => _finished = true));
  }

  void _restart() {
    _cancelTimers();
    setState(() {
      _session.restart();
      _finished = false;
      _lit = null;
      _dots = 0;
    });
    _startRound();
  }

  void _sayPrompt() {
    switch (_phase) {
      case _Phase.yourTurn:
        _say(KidGuide.gameMelodyYourTurn);
      case _Phase.concert:
        _say(KidGuide.gameMelodyConcert);
      default:
        _say(KidGuide.gameMelodyIntro);
    }
  }

  // ------------------------------------------------------------- build

  Widget _replayButton({bool iconOnly = false}) {
    return ChunkyButton(
      color: VimaiColor.sky,
      depth: 6,
      radius: 26,
      semanticLabel: 'Nghe lại',
      onTap: _phase == _Phase.yourTurn ? _replay : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.replay_rounded, color: Colors.white, size: 34),
          if (!iconOnly) ...[
            const SizedBox(width: 6),
            Icon(Icons.hearing_rounded, color: Colors.white.withValues(alpha: 0.9), size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Nghe lại',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VimaiType.display.copyWith(color: Colors.white, fontSize: 24, height: 1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (label, glyph) = switch (_phase) {
      _Phase.listening => ('Nghe Mai gõ chuông', '👂'),
      _Phase.yourTurn => ('Đến lượt bé!', '👆'),
      _Phase.celebrate => ('Giỏi quá!', '🎉'),
      _Phase.oops => ('Mình nghe lại nhé', '👂'),
      _Phase.concert => ('Buổi hoà nhạc của bé', '🎵'),
    };
    final melodyLength = _phase == _Phase.concert ? _session.longest.length : _session.sequence.length;
    return GamePlayScaffold(
      title: 'Giai điệu bí ẩn',
      scene: GameScene.stage,
      finished: _finished,
      correct: switch (_phase) {
        _Phase.celebrate || _Phase.concert => true,
        _Phase.oops => false,
        _ => null,
      },
      feedback: switch (_phase) {
        _Phase.celebrate => const GameFeedbackToast(correct: true, message: 'Giỏi quá!'),
        _Phase.oops => const GameFeedbackToast(correct: false, message: 'Nghe lại nhé!'),
        _ => null,
      },
      complete: GameCompletePanel(
        score: _session.solved,
        wrong: _session.mistakes,
        total: _session.goal,
        onRetry: _restart,
        hero: const SizedBox(width: 150, height: 120, child: MelodyShelfArt()),
      ),
      progress: _NoteProgress(collected: _session.solved, total: _session.goal),
      instruction: GameTargetBanner(label: label, glyph: glyph, color: melodyGameColor, onTap: _sayPrompt),
      playArea: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, c) {
                final showReplay = _phase != _Phase.concert;
                // Landscape phones: the replay button moves beside the bars.
                final compact = c.maxHeight < 260;
                final board = ShakeOnChange(
                  trigger: _shake == 0 ? null : _shake,
                  child: _BarBoard(
                    bells: _session.bells,
                    lit: _lit,
                    hits: _hits,
                    active: _phase == _Phase.yourTurn,
                    onTap: _onBar,
                  ),
                );
                return Column(
                  children: [
                    if (!compact || c.maxHeight >= 140) ...[
                      _MelodyDots(
                        length: melodyLength,
                        filled: _dots,
                        listening: _phase == _Phase.listening || _phase == _Phase.concert,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Expanded(
                      child: compact
                          ? Row(
                              children: [
                                Expanded(child: board),
                                if (showReplay) ...[
                                  const SizedBox(width: 12),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: SizedBox.square(dimension: 76, child: _replayButton(iconOnly: true)),
                                  ),
                                ],
                              ],
                            )
                          : board,
                    ),
                    if (showReplay && !compact) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: SizedBox(
                          height: 68,
                          width: math.min(260, c.maxWidth),
                          child: _replayButton(),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          if (_phase == _Phase.concert) const Positioned.fill(child: ConfettiRain(count: 60)),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- widgets

/// The bell bars. One xylophone row when they fit at a kid-friendly width,
/// otherwise a 3-column grid.
class _BarBoard extends StatelessWidget {
  const _BarBoard({
    required this.bells,
    required this.lit,
    required this.hits,
    required this.active,
    required this.onTap,
  });

  final List<int> bells;
  final int? lit;
  final List<int> hits;
  final bool active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final n = bells.length;
        final w = c.maxWidth;
        final h = c.maxHeight;
        final rowWidth = (w - gap * (n - 1)) / n;
        final oneRow = rowWidth >= 72;
        final columns = oneRow ? n : 3;
        final rows = (n / columns).ceil();
        final barW = ((w - gap * (columns - 1)) / columns).clamp(64.0, 132.0);
        final cellH = ((h - gap * (rows - 1)) / rows).clamp(64.0, 300.0);
        Widget bar(int bell) {
          // Xylophone look: lower notes are longer bars (row layout only).
          final factor = oneRow ? 1 - 0.07 * bell : 1.0;
          return SizedBox(
            width: barW,
            height: cellH,
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: barW,
                height: math.max(64.0, cellH * factor),
                child: _XyloBar(
                  bar: melodyBars[bell],
                  lit: lit == bell,
                  hits: hits[bell],
                  active: active,
                  onTap: () => onTap(bell),
                ),
              ),
            ),
          );
        }

        final grid = <Widget>[];
        for (var r = 0; r < rows; r++) {
          final slice = bells.skip(r * columns).take(columns).toList();
          grid.add(Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < slice.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                bar(slice[i]),
              ],
            ],
          ));
          if (r < rows - 1) grid.add(const SizedBox(height: gap));
        }
        // Very short screens (landscape phones): shrink rather than overflow.
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(mainAxisSize: MainAxisSize.min, children: grid),
          ),
        );
      },
    );
  }
}

class _XyloBar extends StatelessWidget {
  const _XyloBar({
    required this.bar,
    required this.lit,
    required this.hits,
    required this.active,
    required this.onTap,
  });

  final MelodyBar bar;
  final bool lit;
  final int hits;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final face = lit ? Color.lerp(bar.color, Colors.white, 0.4)! : bar.color;
    return PopOnChange(
      trigger: hits,
      amount: 0.14,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              duration: VimaiMotion.of(context, VimaiMotion.feedback),
              opacity: active || lit ? 1 : 0.86,
              child: ChunkyButton(
                color: face,
                depth: 7,
                radius: 22,
                outlineWidth: lit ? 5 : 3,
                glow: lit ? const Color(0xFFFFF3B0) : null,
                semanticLabel: 'Chuông ${bar.name}',
                onTap: onTap,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final pegs = c.maxHeight >= 110;
                    final emoji = math.min(c.maxWidth * 0.62, c.maxHeight * (pegs ? 0.42 : 0.66)).clamp(16.0, 64.0);
                    final peg = (c.maxWidth * 0.16).clamp(8.0, 16.0);
                    if (!pegs) {
                      return Center(child: Text(bar.animal, style: TextStyle(fontSize: emoji, height: 1)));
                    }
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(height: peg * 0.6),
                        _Peg(size: peg),
                        Text(bar.animal, style: TextStyle(fontSize: emoji, height: 1)),
                        _Peg(size: peg),
                        SizedBox(height: peg * 0.6),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          // A little note floats up each time the bar rings.
          if (hits > 0)
            Positioned(
              left: 0,
              right: 0,
              top: -6,
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(hits),
                  tween: Tween(begin: 0, end: 1),
                  duration: VimaiMotion.of(context, const Duration(milliseconds: 900)),
                  builder: (context, t, _) => Opacity(
                    opacity: t >= 1 ? 0 : (1 - t),
                    child: Transform.translate(
                      offset: Offset(math.sin(t * math.pi * 2) * 6, -34 * t),
                      child: Icon(Icons.music_note_rounded, size: 30, color: Color.lerp(bar.color, Colors.white, 0.5)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Peg extends StatelessWidget {
  const _Peg({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.85),
        boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 1.5))],
      ),
    );
  }
}

/// One dot per note of the current melody; dots fill as notes are played.
class _MelodyDots extends StatelessWidget {
  const _MelodyDots({required this.length, required this.filled, required this.listening});

  final int length;
  final int filled;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(listening ? Icons.hearing_rounded : Icons.touch_app_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              for (var i = 0; i < length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedContainer(
                    duration: VimaiMotion.of(context, VimaiMotion.feedback),
                    width: i < filled ? 16 : 12,
                    height: i < filled ? 16 : 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < filled ? const Color(0xFFFFE680) : Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Melodies collected so far, as little music notes filling a pill.
class _NoteProgress extends StatefulWidget {
  const _NoteProgress({required this.collected, required this.total});

  final int collected;
  final int total;

  @override
  State<_NoteProgress> createState() => _NoteProgressState();
}

class _NoteProgressState extends State<_NoteProgress> {
  @override
  void didUpdateWidget(covariant _NoteProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.collected > oldWidget.collected) {
      GameFx.maybeOf(context)?.celebrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = math.max(0, widget.total);
    return Container(
      height: 46,
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                if (total == 0) return const SizedBox.shrink();
                const gap = 2.0;
                final size = ((c.maxWidth - gap * (total - 1)) / total).clamp(12.0, 32.0);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < total; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      SizedBox(
                        width: size,
                        height: size,
                        child: i < widget.collected
                            ? TweenAnimationBuilder<double>(
                                key: ValueKey('note-on-$i'),
                                tween: Tween(begin: 0.2, end: 1),
                                duration: VimaiMotion.of(context, const Duration(milliseconds: 560)),
                                curve: Curves.elasticOut,
                                builder: (context, v, child) => Transform.scale(scale: v, child: child),
                                child: FittedBox(
                                  child: Icon(Icons.music_note_rounded, color: melodyBars[i % melodyBars.length].color),
                                ),
                              )
                            : const FittedBox(child: Icon(Icons.music_note_outlined, color: Color(0xFFC9CEDB))),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(melodyGameColor, Colors.white, 0.2)!, melodyGameColor],
              ),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${widget.collected} / ${widget.total}',
              style: VimaiType.cardTitle.copyWith(fontSize: 16, color: Colors.white, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painted mini xylophone with a couple of floating notes: the games-shelf
/// tile art and the win-panel hero.
class MelodyShelfArt extends StatelessWidget {
  const MelodyShelfArt({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final s = math.min(c.maxWidth, c.maxHeight);
        final barW = s * 0.12;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: -0.12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < melodyBars.length; i++)
                    Container(
                      width: barW,
                      height: s * (0.66 - i * 0.07),
                      margin: EdgeInsets.symmetric(horizontal: s * 0.012),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color.lerp(melodyBars[i].color, Colors.white, 0.3)!, melodyBars[i].color],
                        ),
                        borderRadius: BorderRadius.circular(barW * 0.4),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(color: Color.lerp(melodyBars[i].color, Colors.black, 0.35)!, offset: const Offset(0, 3)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: c.maxWidth * 0.08,
              top: c.maxHeight * 0.06,
              child: Icon(Icons.music_note_rounded, size: s * 0.24, color: const Color(0xFFFFE680)),
            ),
            Positioned(
              right: c.maxWidth * 0.1,
              top: c.maxHeight * 0.14,
              child: Icon(Icons.music_note_rounded, size: s * 0.18, color: Colors.white),
            ),
          ],
        );
      },
    );
  }
}
