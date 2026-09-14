import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/game/webkit_answer_tap.dart';
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

  void _playPrompt() {
    unawaited(ref.read(audioServiceProvider).playJapaneseAsset(_round.target.audioId));
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
