import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/providers.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/vimai_ui.dart';
import 'widgets/game_play_scaffold.dart';

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
      unawaited(_audio?.playIntro('sys_thinking_memory') ?? Future.value());
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

  @override
  Widget build(BuildContext context) {
    return GamePlayScaffold(
      title: 'Tìm hình giống nhau',
      instruction: const GameTargetBanner(label: 'Tìm hai hình giống nhau', glyph: '◆', color: VimaiColor.grape),
      progress: GameProgressBar(current: _matches, total: _pairCount, color: VimaiColor.grape),
      playArea: GameCardGrid(
        itemCount: _cards.length,
        builder: (context, index) {
          final open = index < _isFlipped.length && (_isFlipped[index] || _isMatched[index]);
          return Pressable(
            semanticLabel: open ? _cards[index] : 'Úp',
            onTap: () => _tap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              decoration: BoxDecoration(
                color: open ? VimaiColor.surface : VimaiColor.grape.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(VimaiRadius.md),
                border: Border.all(color: VimaiColor.grape.withValues(alpha: 0.35), width: 2),
                boxShadow: VimaiShadow.soft,
              ),
              child: Text(
                open ? _cards[index] : '?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: open ? VimaiColor.ink : VimaiColor.grape,
                ),
              ),
            ),
          );
        },
      ),
      footer: _handDone
          ? KidButton(label: 'Ván mới', onPressed: () => setState(_deal), color: VimaiColor.grape)
          : Text('Ván $_rounds', textAlign: TextAlign.center, style: VimaiType.caption),
    );
  }
}
