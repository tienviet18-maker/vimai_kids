import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/game/webkit_answer_tap.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/kana/hiragana_data.dart';
import '../../../data/kana/katakana_data.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/models/kana_item.dart';
import '../logic/catch_kana_round.dart';
import '../logic/falling_layout.dart';
import '../logic/final_cheer.dart';
import 'widgets/game_play_scaffold.dart';
import '../../../core/audio/kid_guide.dart';

enum CatchAlphabet { hiragana, katakana, vietnamese }

class CatchKanaGame extends ConsumerStatefulWidget {
  const CatchKanaGame({
    super.key,
    this.alphabet = CatchAlphabet.hiragana,
  });

  final CatchAlphabet alphabet;

  @override
  ConsumerState<CatchKanaGame> createState() => _CatchKanaGameState();
}

class _CatchKanaGameState extends ConsumerState<CatchKanaGame> with SingleTickerProviderStateMixin {
  final _random = Random();
  final _answerTap = WebKitAnswerTap(holdDuration: const Duration(milliseconds: 900));
  late CatchKanaRound _round;
  /// The round after this one, picked on a right answer so Mai can say its
  /// letter right after the praise instead of cutting the praise off.
  CatchKanaRound? _upcoming;
  final _recent = <String>[];
  List<_Falling> _items = [];
  Size _board = Size.zero;
  Ticker? _ticker;
  Timer? _shakeTimer;
  Duration _lastTick = Duration.zero;
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;
  String? _feedback;
  bool? _correct;
  String? _shakeId;
  String? _celebrateId;
  AudioService? _audio;

  /// Fall speed multiplier — 0.5 ≈ 2× slower than the original pace.
  static const _fallSlowdown = 0.5;

  int get _goal {
    return GameCatalog.sessionRounds(GameKind.catchLetters, ref.read(currentProfileProvider)?.age ?? 5);
  }

  Color get _accent {
    switch (widget.alphabet) {
      case CatchAlphabet.katakana:
        return AppTheme.katakanaColor;
      case CatchAlphabet.vietnamese:
        return VimaiColor.sky;
      case CatchAlphabet.hiragana:
        return AppTheme.hiraganaColor;
    }
  }

  String get _title {
    switch (widget.alphabet) {
      case CatchAlphabet.katakana:
        return 'Bắt chữ Katakana';
      case CatchAlphabet.vietnamese:
        return 'Bắt chữ Tiếng Việt';
      case CatchAlphabet.hiragana:
        return 'Bắt chữ Hiragana';
    }
  }

  int get _age => ref.read(currentProfileProvider)?.age ?? 5;

  /// Letters for the next round. Vietnamese: capitals (no marked letters)
  /// for ages 3–4; from 5 on, about half the rounds are lowercase.
  List<KanaItem> _pool() {
    switch (widget.alphabet) {
      case CatchAlphabet.katakana:
        return katakanaData;
      case CatchAlphabet.vietnamese:
        final age = _age;
        return CatchKanaRound.vietnamesePool(age: age, lowercase: age >= 5 && _random.nextBool());
      case CatchAlphabet.hiragana:
        return hiraganaData;
    }
  }

  /// The clip that says [kana]: Japanese kana have their own clip, the
  /// Vietnamese letters use the letter-name clips (v_a, v_aw, …).
  String _clipFor(KanaItem kana) => widget.alphabet == CatchAlphabet.vietnamese
      ? AudioService.getAudioIdForLetter(kana.character)
      : kana.audioId;

  /// A new round whose target was not one of the last few, so the same
  /// letter does not come back again and again.
  CatchKanaRound _generate() {
    final pool = _pool();
    final age = _age;
    // Keyed by sound, so "a" does not follow "A" straight away.
    var next = CatchKanaRound.generate(pool: pool, random: _random, age: age);
    for (var guard = 0; guard < 12 && _recent.contains(next.target.romaji); guard++) {
      next = CatchKanaRound.generate(pool: pool, random: _random, age: age);
    }
    _recent.add(next.target.romaji);
    if (_recent.length > 4) _recent.removeAt(0);
    return next;
  }

  @override
  void initState() {
    super.initState();
    _round = _generate();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audio = ref.read(audioServiceProvider);
      final profile = ref.read(currentProfileProvider);
      _audio?.soundEnabled = profile?.soundEnabled ?? true;
      _audio?.bgmEnabled = profile?.bgmEnabled ?? true;
      _audio?.startGameBgm();
      unawaited(
        _audio?.speak([KidGuide.gameCatchKana], trailIds: [_clipFor(_round.target)], fallbackId: 'sys_game_catch') ??
            Future.value(),
      );
    });
  }

  /// Going straight from one alphabet's catch game to another reuses this
  /// State; start over so katakana letters never linger in a hiragana game.
  @override
  void didUpdateWidget(covariant CatchKanaGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alphabet != widget.alphabet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _restart();
      });
    }
  }

  @override
  void dispose() {
    _answerTap.dispose();
    _shakeTimer?.cancel();
    _ticker?.dispose();
    _audio?.stopGameBgm();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_finished || _board == Size.zero || _items.isEmpty) return;
    if (_lastTick != Duration.zero && elapsed - _lastTick < const Duration(milliseconds: 40)) return;
    final dtMs = _lastTick == Duration.zero ? 40 : max(1, (elapsed - _lastTick).inMilliseconds);
    _lastTick = elapsed;
    final pixels = GameCatalog.catchSpeed(_age) * _fallSlowdown * (dtMs / 40.0);
    setState(() {
      for (final item in _items) {
        item.top = FallingLayout.advanceY(
          top: item.top,
          size: item.size,
          boardHeight: _board.height,
          pixels: pixels,
        );
      }
    });
  }

  void _onBoardSize(Size size) {
    final first = _board == Size.zero;
    final changed = (_board.width - size.width).abs() > 8 || (_board.height - size.height).abs() > 8;
    if (!first && !changed && _items.isNotEmpty) {
      _board = size;
      return;
    }
    setState(() {
      _board = size;
      _layoutLetters();
    });
    if (first && !(_ticker?.isActive ?? false) && !_finished) {
      _lastTick = Duration.zero;
      _ticker?.start();
    }
  }

  void _layoutLetters() {
    if (_board.width < 8 || _board.height < 8) return;
    final boxes = FallingLayout.placeLanes(
      width: _board.width,
      height: _board.height,
      count: _round.items.length,
      random: _random,
    );
    _items = [
      for (var i = 0; i < _round.items.length; i++)
        _Falling(kana: _round.items[i], left: boxes[i].left, top: boxes[i].top, size: boxes[i].size),
    ];
  }

  void _nextRound({bool say = true}) {
    _round = _upcoming ?? _generate();
    _upcoming = null;
    _shakeId = null;
    _celebrateId = null;
    _layoutLetters();
    // Mai says the kana to catch this round.
    if (say) _sayTarget();
  }

  void _tap(KanaItem kana) {
    if (_finished || _answerTap.locked) return;
    final ok = _round.isCorrect(kana);
    final audio = ref.read(audioServiceProvider);

    void recordMastery() {
      final profile = ref.read(currentProfileProvider);
      if (profile == null) return;
      unawaited(
        ref.read(masteryRepositoryProvider).record(
              childId: profile.id,
              itemId: _round.target.id,
              skill: 'game.catch_kana',
              correct: ok,
            ),
      );
    }

    if (!ok) {
      _answerTap.handleWrongAnswer(
        setState: setState,
        applyImmediateUi: () {
          _wrong++;
          _shakeId = kana.id;
          _correct = false;
          _feedback = 'Thử lại nhé!';
        },
        // "Try again" and then the letter once more, so the child remembers
        // what to look for.
        playSound: () => unawaited(audio.playRandomTryAgain(trailIds: [_clipFor(_round.target)])),
        sideEffects: recordMastery,
      );
      _shakeTimer?.cancel();
      _shakeTimer = Timer(const Duration(milliseconds: 420), () {
        if (mounted) setState(() => _shakeId = null);
      });
      return;
    }

    _answerTap.handleCorrectAnswer(
      setState: setState,
      applyImmediateUi: () {
        _score++;
        _celebrateId = kana.id;
        _correct = true;
        _feedback = 'Giỏi lắm!';
      },
      // One sequence: the caught letter, the praise, then the next letter to
      // find. Played separately, each clip cut the one before it.
      playSound: () {
        if (_score >= _goal) return playWinningAnswer(audio, leadIds: [_clipFor(kana)]);
        _upcoming = _generate();
        unawaited(audio.playRandomSuccess(
          leadIds: [_clipFor(kana)],
          trailIds: [if (_upcoming != null) _clipFor(_upcoming!.target)],
        ));
      },
      sideEffects: recordMastery,
      isMounted: () => mounted,
      advanceOrFinish: () {
        _feedback = null;
        _correct = null;
        _celebrateId = null;
        if (_score >= _goal) {
          _finished = true;
          _ticker?.stop();
        } else {
          _nextRound(say: false);
        }
      },
    );
  }

  void _restart() {
    _ticker?.stop();
    _answerTap.reset();
    setState(() {
      _score = 0;
      _wrong = 0;
      _finished = false;
      _feedback = null;
      _correct = null;
      _shakeId = null;
      _celebrateId = null;
      _upcoming = null;
      _recent.clear();
      _nextRound();
    });
    _lastTick = Duration.zero;
    _ticker?.start();
  }

  void _sayTarget() {
    unawaited(ref.read(audioServiceProvider).speak(const [], trailIds: [_clipFor(_round.target)]));
  }

  @override
  Widget build(BuildContext context) {
    final color = _accent;
    return GamePlayScaffold(
      title: _title,
      scene: GameScene.sky,
      finished: _finished,
      correct: _correct,
      complete: GameCompletePanel(score: _score, wrong: _wrong, total: _goal, onRetry: _restart),
      instruction: GameTargetBanner(
        label: 'Tìm chữ',
        glyph: _round.target.character,
        color: color,
        onTap: _sayTarget,
      ),
      progress: GameProgressBar(current: _score, total: _goal, color: color),
      feedback: GameFeedbackToast(correct: _correct, message: _feedback),
      playArea: GameBoard(
        key: const ValueKey('catch-kana-board'),
        onSize: _onBoardSize,
        child: Stack(
          children: [
            for (var i = 0; i < _items.length; i++)
              Positioned(
                left: _items[i].left,
                top: _items[i].top,
                child: GameLetterToken(
                  key: ValueKey('letter-token-${_items[i].kana.id}'),
                  character: _items[i].kana.character,
                  size: _items[i].size,
                  color: gamePalette[i % gamePalette.length],
                  shake: _shakeId == _items[i].kana.id,
                  celebrate: _celebrateId == _items[i].kana.id,
                  onTap: () => _tap(_items[i].kana),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Falling {
  _Falling({required this.kana, required this.left, required this.top, required this.size});
  final KanaItem kana;
  double left;
  double top;
  double size;
}
