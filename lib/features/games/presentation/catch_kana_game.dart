import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/kana/hiragana_data.dart';
import '../../../data/kana/katakana_data.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/models/kana_item.dart';
import '../../shared/widgets/vimai_ui.dart';
import '../logic/catch_kana_round.dart';
import '../logic/falling_layout.dart';
import 'widgets/game_play_scaffold.dart';

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
  late CatchKanaRound _round;
  List<_Falling> _items = [];
  Size _board = Size.zero;
  Ticker? _ticker;
  Timer? _shakeTimer;
  Duration _lastTick = Duration.zero;
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;
  bool _busy = false;
  String? _feedback;
  bool? _correct;
  String? _shakeId;
  String? _celebrateId;
  AudioService? _audio;

  /// Fall speed multiplier — 0.5 ≈ 2× slower than the original pace.
  static const _fallSlowdown = 0.5;

  int get _goal {
    return GameCatalog.roundsForAge(ref.read(currentProfileProvider)?.age ?? 5);
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

  List<KanaItem> _pool() {
    switch (widget.alphabet) {
      case CatchAlphabet.katakana:
        return katakanaData;
      case CatchAlphabet.vietnamese:
        return CatchKanaRound.vietnamesePool();
      case CatchAlphabet.hiragana:
        return hiraganaData;
    }
  }

  @override
  void initState() {
    super.initState();
    _round = CatchKanaRound.generate(pool: _pool(), random: _random);
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audio = ref.read(audioServiceProvider);
      final profile = ref.read(currentProfileProvider);
      _audio?.soundEnabled = profile?.soundEnabled ?? true;
      _audio?.bgmEnabled = profile?.bgmEnabled ?? true;
      _audio?.startGameBgm();
      unawaited(_audio?.playIntro('sys_game_catch') ?? Future.value());
    });
  }

  @override
  void dispose() {
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
    final age = ref.read(currentProfileProvider)?.age ?? 5;
    final pixels = GameCatalog.catchSpeed(age) * _fallSlowdown * (dtMs / 40.0);
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

  void _nextRound() {
    _round = CatchKanaRound.generate(pool: _pool(), random: _random);
    _shakeId = null;
    _celebrateId = null;
    _layoutLetters();
  }

  Future<void> _tap(KanaItem kana) async {
    if (_busy || _finished) return;
    final ok = _round.isCorrect(kana);
    final profile = ref.read(currentProfileProvider);
    if (profile != null) {
      await ref.read(masteryRepositoryProvider).record(
            childId: profile.id,
            itemId: _round.target.id,
            skill: 'game.catch_kana',
            correct: ok,
          );
    }
    if (!mounted) return;
    if (ok) {
      setState(() {
        _busy = true;
        _score++;
        _celebrateId = kana.id;
        _correct = true;
        _feedback = 'Giỏi lắm!';
      });
      final audio = ref.read(audioServiceProvider);
      // Never await clip/feedback audio — Safari can hang on Web Audio promises.
      if (widget.alphabet == CatchAlphabet.vietnamese) {
        unawaited(audio.playVietnameseLetterSound(kana.character));
      } else {
        unawaited(audio.playJapaneseAsset(kana.audioId));
      }
      unawaited(audio.playRandomSuccess());
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedback = null;
        _correct = null;
        _celebrateId = null;
        if (_score >= _goal) {
          _finished = true;
          _ticker?.stop();
        } else {
          _nextRound();
        }
      });
    } else {
      setState(() {
        _wrong++;
        _shakeId = kana.id;
        _correct = false;
        _feedback = 'Thử lại nhé!';
      });
      unawaited(ref.read(audioServiceProvider).playRandomTryAgain());
      _shakeTimer?.cancel();
      _shakeTimer = Timer(const Duration(milliseconds: 420), () {
        if (mounted) setState(() => _shakeId = null);
      });
    }
  }

  void _restart() {
    _ticker?.stop();
    setState(() {
      _score = 0;
      _wrong = 0;
      _finished = false;
      _busy = false;
      _feedback = null;
      _correct = null;
      _shakeId = null;
      _celebrateId = null;
      _nextRound();
    });
    _lastTick = Duration.zero;
    _ticker?.start();
  }

  @override
  Widget build(BuildContext context) {
    final color = _accent;
    return GamePlayScaffold(
      title: _title,
      finished: _finished,
      complete: GameCompletePanel(score: _score, wrong: _wrong, total: _goal, onRetry: _restart),
      instruction: GameTargetBanner(
        label: 'Tìm chữ',
        glyph: _round.target.character,
        color: color,
      ),
      progress: GameProgressBar(current: _score, total: _goal, color: color),
      feedback: LessonFeedback(correct: _correct, message: _feedback),
      playArea: GameBoard(
        key: const ValueKey('catch-kana-board'),
        onSize: _onBoardSize,
        child: Stack(
          children: [
            for (final item in _items)
              Positioned(
                left: item.left,
                top: item.top,
                child: GameLetterToken(
                  key: ValueKey('letter-token-${item.kana.id}'),
                  character: item.kana.character,
                  size: item.size,
                  color: color,
                  shake: _shakeId == item.kana.id,
                  celebrate: _celebrateId == item.kana.id,
                  onTap: () => _tap(item.kana),
                ),
              ),
          ],
        ),
      ),
      footer: Text(
        'Điểm $_score   •   Sai $_wrong',
        textAlign: TextAlign.center,
        style: VimaiType.caption,
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
