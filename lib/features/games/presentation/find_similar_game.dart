import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/providers.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/chunky_button.dart';
import 'widgets/game_fx.dart';
import 'widgets/game_play_scaffold.dart';
import '../../../core/audio/kid_guide.dart';

class FindSimilarGame extends ConsumerStatefulWidget {
  const FindSimilarGame({super.key});

  @override
  ConsumerState<FindSimilarGame> createState() => _FindSimilarGameState();
}

class _FindSimilarGameState extends ConsumerState<FindSimilarGame> {
  List<String> _cards = const [];
  List<bool> _isFlipped = const [];
  List<bool> _isMatched = const [];
  int? _first;
  int? _second;
  int _matches = 0;
  int _rounds = 0;
  int _pairCount = 4;
  bool _lock = false;
  bool _handDone = false;
  Timer? _flipTimer;
  AudioService? _audio;

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
      unawaited(_audio?.speak([KidGuide.gameFindSimilar], fallbackId: 'sys_thinking_memory') ?? Future.value());
      setState(_deal);
    });
  }

  @override
  void dispose() {
    _flipTimer?.cancel();
    _audio?.stopGameBgm();
    super.dispose();
  }

  void _deal() {
    final age = ref.read(currentProfileProvider)?.age ?? 5;
    _pairCount = GameCatalog.pairCount(age);
    _cards = GameCatalog.similarDeal(age, Random());
    _isFlipped = List<bool>.filled(_cards.length, false);
    _isMatched = List<bool>.filled(_cards.length, false);
    _first = null;
    _second = null;
    _matches = 0;
    _lock = false;
    _handDone = false;
  }

  void _tap(int index) {
    if (_lock || _handDone || _isMatched[index] || _isFlipped[index]) return;
    if (_first == index) return;

    setState(() {
      _isFlipped[index] = true;
      if (_first == null) {
        _first = index;
        return;
      }
      _second = index;
      _lock = true;
    });

    if (_second == null) return;

    final a = _first!;
    final b = _second!;
    final match = _cards[a] == _cards[b];
    _flipTimer?.cancel();
    _flipTimer = Timer(Duration(milliseconds: match ? 350 : 1000), () {
      if (!mounted) return;
      final audio = ref.read(audioServiceProvider);
      if (match) {
        unawaited(audio.playRandomSuccess());
      } else {
        unawaited(audio.playRandomTryAgain());
      }
      setState(() {
        if (match) {
          _isMatched[a] = true;
          _isMatched[b] = true;
          _isFlipped[a] = true;
          _isFlipped[b] = true;
          _matches++;
          if (_matches == _pairCount) {
            _handDone = true;
            _rounds++;
            final profile = ref.read(currentProfileProvider);
            if (profile != null) {
              ref.read(masteryRepositoryProvider).record(
                    childId: profile.id,
                    itemId: 'find_similar_$_rounds',
                    skill: 'game.find_similar',
                    correct: true,
                  );
            }
          }
        } else {
          _isFlipped[a] = false;
          _isFlipped[b] = false;
        }
        _first = null;
        _second = null;
        _lock = false;
      });
    });
  }

  void _sayHowTo() => unawaited(ref.read(audioServiceProvider).speak([KidGuide.gameFindSimilar]));

  @override
  Widget build(BuildContext context) {
    final a = _first;
    final b = _second;
    final miss = a != null && b != null && a < _cards.length && b < _cards.length && _cards[a] != _cards[b];
    const color = Color(0xFFFF8A3D);
    return GamePlayScaffold(
      title: 'Tìm hình giống nhau',
      scene: GameScene.table,
      correct: miss ? false : (_handDone ? true : null),
      instruction: GameTargetBanner(
        label: 'Tìm hai hình giống nhau',
        glyph: '◆',
        color: VimaiColor.grape,
        onTap: _sayHowTo,
      ),
      progress: GameProgressBar(current: _matches, total: _pairCount, color: VimaiColor.grape),
      feedback: miss
          ? const GameFeedbackToast(correct: false, message: 'Thử lại nhé!')
          : (_handDone ? const GameFeedbackToast(correct: true, message: 'Giỏi lắm!') : null),
      playArea: Stack(
        children: [
          Positioned.fill(
            child: GameCardGrid(
              itemCount: _cards.length,
              builder: (context, index) {
                final matched = index < _isMatched.length && _isMatched[index];
                final open = index < _isFlipped.length && (_isFlipped[index] || matched);
                return ShakeOnChange(
                  trigger: miss && (index == a || index == b) ? 'miss-$a-$b' : null,
                  child: GameFlipCard(
                    open: open,
                    matched: matched,
                    color: color,
                    semanticLabel: open ? _cards[index] : 'Úp',
                    onTap: () => _tap(index),
                    face: Text(_cards[index], style: const TextStyle(fontSize: 48, height: 1.1)),
                  ),
                );
              },
            ),
          ),
          if (_handDone)
            Positioned.fill(
              child: Stack(
                children: [
                  const ConfettiRain(count: 50),
                  Align(
                    alignment: const Alignment(0, 0.85),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.4, end: 1),
                      duration: VimaiMotion.of(context, const Duration(milliseconds: 600)),
                      curve: Curves.elasticOut,
                      builder: (context, v, child) => Transform.scale(scale: v, child: child),
                      child: SizedBox(
                        width: 260,
                        height: 76,
                        child: ChunkyButton(
                          color: VimaiColor.correct,
                          depth: 7,
                          radius: 28,
                          semanticLabel: 'Ván mới',
                          onTap: () => setState(_deal),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                              const SizedBox(width: 6),
                              Text('Ván mới', style: VimaiType.display.copyWith(color: Colors.white, fontSize: 28, height: 1)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
