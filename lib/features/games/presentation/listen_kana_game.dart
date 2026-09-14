import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/kana/hiragana_data.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/choice_grid.dart';
import '../../shared/widgets/vimai_ui.dart';
import '../logic/catch_kana_round.dart';
import 'widgets/game_play_scaffold.dart';

class ListenKanaGame extends ConsumerStatefulWidget {
  const ListenKanaGame({super.key});

  @override
  ConsumerState<ListenKanaGame> createState() => _ListenKanaGameState();
}

class _ListenKanaGameState extends ConsumerState<ListenKanaGame> {
  final _random = Random();
  late CatchKanaRound _round;
  String? _feedback;
  bool? _correct;
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;
  bool _busy = false;
  final _recent = <String>[];

  int get _goal => GameCatalog.roundsForAge(ref.read(currentProfileProvider)?.age ?? 5);

  @override
  void initState() {
    super.initState();
    _round = CatchKanaRound.generate(pool: hiraganaData, random: _random);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playPrompt());
  }

  Future<void> _playPrompt() async {
    unawaited(ref.read(audioServiceProvider).playJapaneseAsset(_round.target.audioId));
  }

  Future<void> _next() async {
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
    setState(() {});
    await _playPrompt();
  }

  Future<void> _onChoice(String value) async {
    if (_busy || _finished) return;
    final tapped = _round.items.firstWhere((e) => e.character == value, orElse: () => _round.target);
    final ok = _round.isCorrect(tapped);
    final profile = ref.read(currentProfileProvider);
    if (profile != null) {
      await ref.read(masteryRepositoryProvider).record(
            childId: profile.id,
            itemId: _round.target.id,
            skill: 'game.listen_kana',
            correct: ok,
          );
    }
    if (!mounted) return;
    setState(() {
      _feedback = ok ? 'Giỏi lắm!' : 'Thử lại nhé!';
      _correct = ok;
      if (ok) {
        _score++;
        _busy = true;
      } else {
        _wrong++;
      }
    });
    if (!ok) return;
    final audio = ref.read(audioServiceProvider);
    unawaited(audio.playJapaneseAsset(tapped.audioId));
    unawaited(audio.playRandomSuccess());
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (_score >= _goal) {
        _finished = true;
      } else {
        _next();
      }
    });
  }

  void _restart() {
    setState(() {
      _score = 0;
      _wrong = 0;
      _finished = false;
      _busy = false;
      _recent.clear();
    });
    _next();
  }

  @override
  Widget build(BuildContext context) {
    return GamePlayScaffold(
      title: 'Nghe và bắt chữ',
      finished: _finished,
      complete: GameCompletePanel(score: _score, wrong: _wrong, total: _goal, onRetry: _restart),
      instruction: const GameTargetBanner(label: 'Chữ nào đúng?', glyph: '♪', color: AppTheme.katakanaColor),
      progress: GameProgressBar(current: _score, total: _goal, color: AppTheme.katakanaColor),
      feedback: LessonFeedback(correct: _correct, message: _feedback),
      playArea: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight, maxWidth: 440),
              child: Center(
                child: ChoiceGrid(
                  choices: _round.items.map((e) => e.character).toList(),
                  color: AppTheme.katakanaColor,
                  onSelected: _onChoice,
                ),
              ),
            ),
          );
        },
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            iconSize: 48,
            tooltip: 'Nghe lại',
            onPressed: _playPrompt,
            icon: const Icon(Icons.volume_up_rounded, color: AppTheme.katakanaColor),
          ),
          Text('Điểm $_score   •   Sai $_wrong', style: VimaiType.caption),
        ],
      ),
    );
  }
}
