import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/webkit_answer_tap.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/kana/hiragana_data.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/choice_grid.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../logic/catch_kana_round.dart';
import 'widgets/game_play_scaffold.dart';
import '../../../core/audio/kid_guide.dart';

class ListenKanaGame extends ConsumerStatefulWidget {
  const ListenKanaGame({super.key});

  @override
  ConsumerState<ListenKanaGame> createState() => _ListenKanaGameState();
}

class _ListenKanaGameState extends ConsumerState<ListenKanaGame> {
  final _random = Random();
  final _answerTap = WebKitAnswerTap(holdDuration: const Duration(milliseconds: 500));
  late CatchKanaRound _round;
  String? _feedback;
  bool? _correct;
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;
  final _recent = <String>[];

  int get _goal => GameCatalog.roundsForAge(ref.read(currentProfileProvider)?.age ?? 5);

  @override
  void initState() {
    super.initState();
    _round = CatchKanaRound.generate(pool: hiraganaData, random: _random);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playPrompt());
  }

  @override
  void dispose() {
    _answerTap.dispose();
    super.dispose();
  }

  bool _introDone = false;

  void _playPrompt() {
    final first = !_introDone;
    _introDone = true;
    unawaited(
      ref.read(audioServiceProvider).speak([if (first) KidGuide.gameListenKana], trailIds: [_round.target.audioId]),
    );
  }

  void _prepareNextRound() {
    var next = CatchKanaRound.generate(pool: hiraganaData, random: _random);
    var guard = 0;
    while (_recent.contains(next.target.id) && guard < 12) {
      next = CatchKanaRound.generate(pool: hiraganaData, random: _random);
      guard++;
    }
    _round = next;
    _recent.add(_round.target.id);
    if (_recent.length > 8) _recent.removeAt(0);
    _feedback = null;
    _correct = null;
  }

  void _recordMastery(bool ok) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    unawaited(
      ref.read(masteryRepositoryProvider).record(
            childId: profile.id,
            itemId: _round.target.id,
            skill: 'game.listen_kana',
            correct: ok,
          ),
    );
  }

  void _onChoice(String value) {
    if (_finished || _answerTap.locked) return;
    final tapped = _round.items.firstWhere((e) => e.character == value, orElse: () => _round.target);
    final ok = _round.isCorrect(tapped);
    final audio = ref.read(audioServiceProvider);

    if (!ok) {
      _answerTap.handleWrongAnswer(
        setState: setState,
        applyImmediateUi: () {
          _feedback = 'Thử lại nhé!';
          _correct = false;
          _wrong++;
        },
        playSound: () => unawaited(audio.playRandomTryAgain()),
        sideEffects: () => _recordMastery(false),
      );
      return;
    }

    _answerTap.handleCorrectAnswer(
      setState: setState,
      applyImmediateUi: () {
        _feedback = 'Giỏi lắm!';
        _correct = true;
        _score++;
      },
      playSound: () {
        unawaited(audio.playJapaneseAsset(tapped.audioId));
        unawaited(audio.playRandomSuccess());
      },
      sideEffects: () => _recordMastery(true),
      isMounted: () => mounted,
      advanceOrFinish: () {
        if (_score >= _goal) {
          _finished = true;
          _feedback = null;
          _correct = null;
        } else {
          _prepareNextRound();
          _playPrompt();
        }
      },
    );
  }

  void _restart() {
    _answerTap.reset();
    setState(() {
      _score = 0;
      _wrong = 0;
      _finished = false;
      _recent.clear();
      _prepareNextRound();
    });
    _playPrompt();
  }

  @override
  Widget build(BuildContext context) {
    const color = AppTheme.katakanaColor;
    return GamePlayScaffold(
      title: 'Nghe và bắt chữ',
      scene: GameScene.stage,
      finished: _finished,
      correct: _correct,
      complete: GameCompletePanel(score: _score, wrong: _wrong, total: _goal, onRetry: _restart),
      progress: GameProgressBar(current: _score, total: _goal, color: color),
      feedback: GameFeedbackToast(correct: _correct, message: _feedback),
      playArea: LayoutBuilder(
        builder: (context, constraints) {
          final speaker = (constraints.maxHeight * 0.3).clamp(96.0, 170.0);
          final compact = constraints.maxHeight < 470;
          return Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SpeakerHero(size: speaker, onTap: _playPrompt, pulse: _round.target.id),
                    SizedBox(height: compact ? 14 : 26),
                    ChoiceGrid(
                      choices: _round.items.map((e) => e.character).toList(),
                      color: color,
                      palette: gamePalette,
                      lastCorrect: _correct,
                      maxItemSize: compact ? 76 : 128,
                      onSelected: _onChoice,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Big glowing speaker on the stage: tap to hear Mai say the letter again.
class _SpeakerHero extends StatefulWidget {
  const _SpeakerHero({required this.size, required this.onTap, required this.pulse});

  final double size;
  final VoidCallback onTap;
  final Object pulse;

  @override
  State<_SpeakerHero> createState() => _SpeakerHeroState();
}

class _SpeakerHeroState extends State<_SpeakerHero> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

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
    final s = widget.size;
    return SizedBox(
      width: s * 1.7,
      height: s * 1.18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              size: Size(s * 1.7, s * 1.18),
              painter: _WavesPainter(t: _c.value, radius: s / 2),
            ),
          ),
          PopOnChange(
            trigger: widget.pulse,
            child: SizedBox(
              width: s,
              height: s,
              child: ChunkyButton(
                circle: true,
                depth: 8,
                outlineWidth: 5,
                color: const Color(0xFFFF4F86),
                semanticLabel: 'Nghe lại',
                onTap: widget.onTap,
                child: Center(child: Icon(Icons.volume_up_rounded, color: Colors.white, size: s * 0.5)),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: VimaiMascot(mood: MascotMood.excited, size: s * 0.52),
          ),
        ],
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  _WavesPainter({required this.t, required this.radius});
  final double t;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final k = (t + i / 3) % 1.0;
      canvas.drawCircle(
        c,
        radius * (1 + k * 0.6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * (1 - k) + 1
          ..color = const Color(0xFFFFE680).withValues(alpha: 0.75 * (1 - k)),
      );
    }
    canvas.drawCircle(
      c,
      radius * 1.1,
      Paint()..shader = RadialGradient(colors: [const Color(0xFFFFF3B0).withValues(alpha: 0.5), Colors.transparent]).createShader(Rect.fromCircle(center: c, radius: radius * 1.6)),
    );
  }

  @override
  bool shouldRepaint(covariant _WavesPainter old) => old.t != t || old.radius != radius;
}
