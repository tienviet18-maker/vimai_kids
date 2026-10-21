import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/kana/hiragana_data.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/models/kana_item.dart';
import '../../shared/widgets/chunky_button.dart';
import 'widgets/game_play_scaffold.dart';
import '../../../core/audio/kid_guide.dart';

class MatchKanaGame extends ConsumerStatefulWidget {
  const MatchKanaGame({super.key});

  @override
  ConsumerState<MatchKanaGame> createState() => _MatchKanaGameState();
}

class _MatchKanaGameState extends ConsumerState<MatchKanaGame> {
  late List<KanaItem> _cards;
  final _flipped = <int>{};
  int? _first;
  int? _second;
  int _matches = 0;
  int _wrong = 0;
  bool _lock = false;
  bool _finished = false;
  Timer? _flipTimer;
  AudioService? _audio;

  /// Fewer cards for the youngest: 8 cards at 3–4, 12 at 5–6, 16 at 7.
  int _pairs = 6;

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
      unawaited(_audio?.speak([KidGuide.gameMatchKana], fallbackId: 'sys_thinking_match'));
    });
  }

  void _deal() {
    _pairs = GameCatalog.pairCount(ref.read(currentProfileProvider)?.age ?? 5);
    final pool = hiraganaData.where((e) => e.kanaType == KanaType.basic).toList()..shuffle();
    final selected = pool.take(_pairs).toList();
    _cards = [...selected, ...selected]..shuffle();
    _flipped.clear();
    _first = null;
    _second = null;
    _matches = 0;
    _wrong = 0;
    _lock = false;
    _finished = false;
  }

  void _tap(int index) {
    if (_lock || _flipped.contains(index) || _first == index || _finished) return;
    final audio = ref.read(audioServiceProvider);
    audio.sfx(Sfx.flip);
    final a = _first;
    final b = index;
    final match = a != null && _cards[a].id == _cards[b].id;
    // Every card says its sound when it turns over, so the child also
    // remembers by ear. On a pair the praise follows that sound instead of
    // cutting it off.
    if (match) {
      unawaited(audio.playRandomSuccess(leadIds: [_cards[b].audioId]));
    } else {
      unawaited(audio.playJapaneseAsset(_cards[b].audioId));
    }
    if (a == null) {
      setState(() => _first = index);
      return;
    }
    setState(() {
      _second = b;
      _lock = true;
      if (!match) _wrong++;
    });
    _flipTimer?.cancel();
    // A miss stays open long enough to remember both cards, then turns back.
    _flipTimer = Timer(Duration(milliseconds: match ? 700 : 1400), () {
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
      if (!match) audio.sfx(Sfx.flip);
    });
  }

  void _sayHowTo() => unawaited(ref.read(audioServiceProvider).speak([KidGuide.gameMatchKana]));

  @override
  Widget build(BuildContext context) {
    final a = _first;
    final b = _second;
    final miss = a != null && b != null && _cards[a].id != _cards[b].id;
    return GamePlayScaffold(
      title: 'Ghép đôi chữ',
      scene: GameScene.table,
      finished: _finished,
      correct: miss ? false : null,
      complete: GameCompletePanel(score: _matches, wrong: (_wrong - _pairs).clamp(0, 99), total: _pairs, onRetry: () => setState(_deal)),
      instruction: GameTargetBanner(
        label: 'Tìm hai chữ giống nhau',
        glyph: 'あ',
        color: AppTheme.hiraganaColor,
        onTap: _sayHowTo,
      ),
      progress: GameProgressBar(current: _matches, total: _pairs, color: AppTheme.hiraganaColor),
      feedback: miss ? const GameFeedbackToast(correct: false, message: 'Thử lại nhé!') : null,
      playArea: GameCardGrid(
        itemCount: _cards.length,
        builder: (context, index) {
          final matched = _flipped.contains(index);
          final open = matched || _first == index || _second == index;
          return ShakeOnChange(
            trigger: miss && (index == a || index == b) ? 'miss-$a-$b' : null,
            child: GameFlipCard(
              open: open,
              matched: matched,
              color: AppTheme.hiraganaColor,
              semanticLabel: open ? _cards[index].character : 'Úp',
              onTap: () => _tap(index),
              face: Text(
                _cards[index].character,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.hiraganaColor, height: 1.1),
              ),
            ),
          );
        },
      ),
    );
  }
}
