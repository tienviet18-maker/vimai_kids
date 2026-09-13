import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/kana/hiragana_data.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/models/kana_item.dart';
import '../../shared/widgets/vimai_ui.dart';
import 'widgets/game_play_scaffold.dart';

class MatchKanaGame extends ConsumerStatefulWidget {
  const MatchKanaGame({super.key});

  @override
  ConsumerState<MatchKanaGame> createState() => _MatchKanaGameState();
}

class _MatchKanaGameState extends ConsumerState<MatchKanaGame> {
  late List<String> _cards;
  final _flipped = <int>{};
  int? _first;
  int? _second;
  int _matches = 0;
  bool _lock = false;
  bool _finished = false;
  Timer? _flipTimer;
  AudioService? _audio;

  static const _pairs = 6;

  @override
  void dispose() {
    _flipTimer?.cancel();
    _audio?.stopGameBgm();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _deal();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audio = ref.read(audioServiceProvider);
      final profile = ref.read(currentProfileProvider);
      _audio?.soundEnabled = profile?.soundEnabled ?? true;
      _audio?.bgmEnabled = profile?.bgmEnabled ?? true;
      _audio?.startGameBgm();
      _audio?.playIntro('sys_thinking_match');
    });
  }

  void _deal() {
    final pool = hiraganaData.where((e) => e.kanaType == KanaType.basic).toList()..shuffle();
    final selected = pool.take(_pairs).map((e) => e.character).toList();
    _cards = [...selected, ...selected]..shuffle();
    _flipped.clear();
    _first = null;
    _second = null;
    _matches = 0;
    _lock = false;
    _finished = false;
  }

  void _tap(int index) {
    if (_lock || _flipped.contains(index) || _first == index || _finished) return;
    setState(() {
      if (_first == null) {
        _first = index;
        return;
      }
      _second = index;
      _lock = true;
    });
    final a = _first!;
    final b = index;
    final match = _cards[a] == _cards[b];
    _flipTimer?.cancel();
    _flipTimer = Timer(Duration(milliseconds: match ? 280 : 520), () {
      if (!mounted) return;
      setState(() {
        if (match) {
          _flipped.addAll([a, b]);
          _matches++;
          if (_matches == _pairs) _finished = true;
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
      title: 'Ghép đôi chữ',
      finished: _finished,
      complete: GameCompletePanel(score: _matches, wrong: 0, total: _pairs, onRetry: () => setState(_deal)),
      instruction: const GameTargetBanner(label: 'Tìm hai chữ giống nhau', glyph: 'あ', color: AppTheme.hiraganaColor),
      progress: GameProgressBar(current: _matches, total: _pairs, color: AppTheme.hiraganaColor),
      playArea: GameCardGrid(
        itemCount: _cards.length,
        builder: (context, index) {
          final open = _flipped.contains(index) || _first == index || _second == index;
          return Pressable(
            semanticLabel: open ? _cards[index] : 'Úp',
            onTap: () => _tap(index),
            child: Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              decoration: BoxDecoration(
                color: VimaiColor.surface,
                borderRadius: BorderRadius.circular(VimaiRadius.md),
                border: Border.all(color: AppTheme.hiraganaColor.withValues(alpha: 0.35), width: 2),
                boxShadow: VimaiShadow.soft,
              ),
              child: Text(
                open ? _cards[index] : '?',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.hiraganaColor),
              ),
            ),
          );
        },
      ),
    );
  }
}
