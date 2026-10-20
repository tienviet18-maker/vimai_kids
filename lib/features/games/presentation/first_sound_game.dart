import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/audio/kid_guide.dart';
import '../../../core/game/webkit_answer_tap.dart';
import '../../../core/providers.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../logic/first_sound_round.dart';
import 'widgets/game_play_scaffold.dart';

/// "Âm đầu là gì?": Mai says a consonant *sound* ("bờ", "chờ"…), the child
/// taps the picture whose word starts with it, then Mai models the blend
/// ("bờ … bò"). Playable from voice and pictures alone.
class FirstSoundGame extends ConsumerStatefulWidget {
  const FirstSoundGame({super.key});

  @override
  ConsumerState<FirstSoundGame> createState() => _FirstSoundGameState();
}

class _FirstSoundGameState extends ConsumerState<FirstSoundGame> {
  static const _color = Color(0xFF14A3B8);

  final _random = math.Random();
  final _answerTap = WebKitAnswerTap(holdDuration: const Duration(milliseconds: 4300));
  final _timers = <Timer>[];
  final _recentSounds = <String>[];
  final _recentWords = <String>[];
  final _shakes = <String, int>{};

  late FirstSoundRound _round = FirstSoundRound.generate(level: 0, random: _random);
  int _level = 0;
  int _upStreak = 0;
  int _wrongRun = 0;
  bool _missedThisRound = false;
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;
  bool? _correct;
  String? _feedback;
  String? _picked;
  AudioService? _audio;

  int get _age => ref.read(currentProfileProvider)?.age ?? 5;
  int get _goal => GameCatalog.roundsForAge(_age);

  /// Young children stay on three far-apart sounds; look-alike pairs from 4.
  int get _maxLevel => _age <= 3 ? 1 : FirstSound.maxLevel;
  int get _startLevel => _age >= 6 ? 1 : 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audio = ref.read(audioServiceProvider);
      final profile = ref.read(currentProfileProvider);
      _audio?.soundEnabled = profile?.soundEnabled ?? true;
      _audio?.bgmEnabled = profile?.bgmEnabled ?? true;
      _audio?.startGameBgm();
      setState(() {
        _level = _startLevel;
        _nextRound();
      });
      _sayPrompt(intro: true);
    });
  }

  @override
  void dispose() {
    _cancelTimers();
    _answerTap.dispose();
    _audio?.stopGameBgm();
    super.dispose();
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _later(int ms, VoidCallback fn) {
    _timers.add(Timer(Duration(milliseconds: ms), () {
      if (mounted) fn();
    }));
  }

  void _nextRound() {
    _round = FirstSoundRound.generate(
      level: _level,
      random: _random,
      recentSounds: _recentSounds,
      recentWords: _recentWords,
    );
    _recentSounds.add(_round.sound);
    if (_recentSounds.length > 3) _recentSounds.removeAt(0);
    _recentWords.add(_round.answer.word);
    if (_recentWords.length > 10) _recentWords.removeAt(0);
    _shakes.clear();
    _missedThisRound = false;
    _picked = null;
    _correct = null;
    _feedback = null;
  }

  /// "Từ nào bắt đầu bằng âm …" then the consonant sound clip itself.
  void _sayPrompt({bool intro = false}) {
    final audio = ref.read(audioServiceProvider);
    unawaited(audio.speak(
      [if (intro) KidGuide.gameFirstSound, KidGuide.firstSoundAsk],
      trailIds: [_round.soundClip],
      fallbackId: _round.soundClip,
    ));
  }

  void _replay() {
    if (_finished || _picked != null) return;
    _cancelTimers();
    _sayPrompt();
  }

  void _recordMastery(bool ok) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    unawaited(
      ref.read(masteryRepositoryProvider).record(
            childId: profile.id,
            itemId: 'first_sound_${_round.sound}',
            skill: 'game.first_sound',
            correct: ok,
          ),
    );
  }

  void _onCard(FirstSoundWord card) {
    if (_finished || _answerTap.locked || _picked != null) return;
    final audio = ref.read(audioServiceProvider);
    _cancelTimers();
    audio.sfx(Sfx.tap);
    // The picture always says its word first.
    unawaited(audio.playAudio(card.audioId));
    final ok = _round.isCorrect(card);

    if (!ok) {
      _answerTap.handleWrongAnswer(
        setState: setState,
        applyImmediateUi: () {
          _feedback = 'Thử lại nhé!';
          _correct = false;
          _wrong++;
          _shakes[card.word] = (_shakes[card.word] ?? 0) + 1;
          _missedThisRound = true;
          _upStreak = 0;
          _wrongRun++;
          if (_wrongRun >= 2 && _level > 0) {
            _level--;
            _wrongRun = 0;
          }
        },
        playSound: () {
          _later(800, audio.playWrongSound);
          // Then Mai gives the sound again so the child can listen once more.
          _later(3000, () {
            if (_picked == null && !_finished) _sayPrompt();
          });
        },
        sideEffects: () => _recordMastery(false),
      );
      return;
    }

    _answerTap.handleCorrectAnswer(
      setState: setState,
      applyImmediateUi: () {
        _feedback = 'Giỏi lắm!';
        _correct = true;
        _picked = card.word;
        _score++;
        _wrongRun = 0;
        if (!_missedThisRound) _upStreak++;
        if (_upStreak >= 2 && _level < _maxLevel) {
          _level++;
          _upStreak = 0;
        }
      },
      playSound: () {
        audio.sfx(Sfx.pop);
        _later(750, audio.playCorrectSound);
        // Mai models the blend: onset sound → whole word ("bờ … bò").
        _later(2500, () => unawaited(audio.speak(const [], leadIds: [_round.soundClip, card.audioId])));
      },
      sideEffects: () => _recordMastery(true),
      isMounted: () => mounted,
      advanceOrFinish: () {
        if (_score >= _goal) {
          _finished = true;
          _correct = null;
          _feedback = null;
        } else {
          _nextRound();
          _sayPrompt();
        }
      },
    );
  }

  void _restart() {
    _cancelTimers();
    _answerTap.reset();
    setState(() {
      _score = 0;
      _wrong = 0;
      _finished = false;
      _upStreak = 0;
      _wrongRun = 0;
      _level = _startLevel;
      _recentSounds.clear();
      _recentWords.clear();
      _nextRound();
    });
    _sayPrompt();
  }

  @override
  Widget build(BuildContext context) {
    return GamePlayScaffold(
      title: 'Âm đầu là gì?',
      scene: GameScene.meadow,
      finished: _finished,
      correct: _correct,
      complete: GameCompletePanel(
        score: _score,
        wrong: _wrong,
        total: _goal,
        onRetry: _restart,
        hero: const VimaiMascot(mood: MascotMood.celebrating, size: 130),
      ),
      instruction: GameTargetBanner(
        label: 'Từ nào bắt đầu bằng âm',
        glyph: _round.glyph,
        color: _color,
        onTap: _replay,
      ),
      progress: GameProgressBar(current: _score, total: _goal, color: _color),
      feedback: GameFeedbackToast(correct: _correct, message: _feedback),
      playArea: LayoutBuilder(
        builder: (context, constraints) {
          final speaker = (constraints.maxHeight * 0.22).clamp(72.0, 140.0);
          final gap = constraints.maxHeight < 420 ? 8.0 : 16.0;
          return Column(
            children: [
              _SoundSpeaker(size: speaker, pulse: _round.id, onTap: _replay),
              SizedBox(height: gap),
              Expanded(
                child: _CardRow(
                  key: ValueKey(_round.id),
                  round: _round,
                  picked: _picked,
                  shakes: _shakes,
                  onTap: _onCard,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The picture cards, sized to fill the space (one row, or two when that
/// gives bigger cards).
class _CardRow extends StatelessWidget {
  const _CardRow({
    super.key,
    required this.round,
    required this.picked,
    required this.shakes,
    required this.onTap,
  });

  final FirstSoundRound round;
  final String? picked;
  final Map<String, int> shakes;
  final ValueChanged<FirstSoundWord> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final n = round.cards.length;
        final maxW = math.min(constraints.maxWidth, 760.0);
        final maxH = constraints.maxHeight;
        var best = (cols: n, size: 0.0);
        for (final cols in {n, 2}) {
          final rows = (n / cols).ceil();
          final w = (maxW - gap * (cols - 1)) / cols;
          final h = (maxH - gap * (rows - 1)) / rows / 1.1;
          final size = math.min(math.min(w, h), 200.0);
          if (size > best.size) best = (cols: cols, size: size);
        }
        final size = math.max(64.0, best.size);
        final cols = best.cols;
        final rows = (n / cols).ceil();
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < rows; r++) ...[
                  if (r > 0) const SizedBox(height: gap),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var c = 0; c < cols && r * cols + c < n; c++) ...[
                        if (c > 0) const SizedBox(width: gap),
                        _PictureCard(
                          word: round.cards[r * cols + c],
                          size: size,
                          state: picked == null
                              ? _CardState.idle
                              : (round.cards[r * cols + c].word == picked ? _CardState.right : _CardState.dim),
                          shake: shakes[round.cards[r * cols + c].word],
                          onTap: onTap,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _CardState { idle, right, dim }

class _PictureCard extends StatelessWidget {
  const _PictureCard({
    required this.word,
    required this.size,
    required this.state,
    required this.shake,
    required this.onTap,
  });

  final FirstSoundWord word;
  final double size;
  final _CardState state;
  final int? shake;
  final ValueChanged<FirstSoundWord> onTap;

  @override
  Widget build(BuildContext context) {
    final right = state == _CardState.right;
    return AnimatedOpacity(
      duration: VimaiMotion.of(context, const Duration(milliseconds: 250)),
      opacity: state == _CardState.dim ? 0.4 : 1,
      child: ShakeOnChange(
        trigger: shake,
        child: PopOnChange(
          trigger: right ? word.word : null,
          child: SizedBox(
            width: size,
            height: size * 1.1,
            child: ChunkyButton(
              color: right ? const Color(0xFFE9FFF0) : Colors.white,
              outline: right ? VimaiColor.correct : Colors.white,
              outlineWidth: right ? 5 : 3,
              glow: right ? VimaiColor.correct : null,
              radius: 28,
              depth: 7,
              semanticLabel: word.word,
              onTap: () => onTap(word),
              child: Padding(
                padding: EdgeInsets.all(size * 0.08),
                child: Column(
                  children: [
                    Expanded(
                      child: FittedBox(
                        child: Text(word.emoji, style: const TextStyle(fontSize: 80, height: 1.1)),
                      ),
                    ),
                    SizedBox(
                      height: size * 0.2,
                      child: FittedBox(
                        child: Text(
                          word.word,
                          style: VimaiType.cardTitle.copyWith(color: VimaiColor.ink, fontSize: 22, height: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Big speaker with Mai beside it: tap to hear the sound again.
class _SoundSpeaker extends StatelessWidget {
  const _SoundSpeaker({required this.size, required this.pulse, required this.onTap});

  final double size;
  final Object pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VimaiMascot(mood: MascotMood.excited, size: size * 0.8),
          const SizedBox(width: 12),
          PopOnChange(
            trigger: pulse,
            child: SizedBox(
              width: size,
              height: size,
              child: ChunkyButton(
                circle: true,
                depth: 7,
                outlineWidth: 5,
                color: const Color(0xFFFF4F86),
                semanticLabel: 'Nghe lại âm',
                onTap: onTap,
                child: Center(child: Icon(Icons.volume_up_rounded, color: Colors.white, size: size * 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
