import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/game/webkit_answer_tap.dart';
import '../../../core/providers.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/content/math_generator.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/content/content_item.dart';
import '../../shared/widgets/choice_grid.dart';
import '../../shared/widgets/vimai_ui.dart';
import 'widgets/game_play_scaffold.dart';

class FeedAnimalGame extends ConsumerStatefulWidget {
  const FeedAnimalGame({super.key});

  @override
  ConsumerState<FeedAnimalGame> createState() => _FeedAnimalGameState();
}

class _FeedAnimalGameState extends ConsumerState<FeedAnimalGame> {
  final _generator = MathQuestionGenerator();
  final _answerTap = WebKitAnswerTap(holdDuration: const Duration(milliseconds: 500));
  late var _item = _generator.generateCounting(5);
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;
  String? _feedback;
  bool? _correct;
  AudioService? _audio;

  int get _goal => GameCatalog.roundsForAge(ref.read(currentProfileProvider)?.age ?? 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _item = _nextItem());
      _audio = ref.read(audioServiceProvider);
      final profile = ref.read(currentProfileProvider);
      _audio?.soundEnabled = profile?.soundEnabled ?? true;
      _audio?.bgmEnabled = profile?.bgmEnabled ?? true;
      _audio?.startGameBgm();
      _audio?.playIntro('sys_math_count');
    });
  }

  @override
  void dispose() {
    _answerTap.dispose();
    _audio?.stopGameBgm();
    super.dispose();
  }

  ContentItem _nextItem() {
    final age = ref.read(currentProfileProvider)?.age ?? 5;
    return _generator.generateBySkill('counting', age: age);
  }

  void _recordMastery(bool ok) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    unawaited(
      ref.read(masteryRepositoryProvider).record(
            childId: profile.id,
            itemId: _item.id,
            skill: 'game.feed_animal',
            correct: ok,
          ),
    );
  }

  void _onChoice(String value) {
    if (_finished || _answerTap.locked) return;
    final ok = value == _item.answer;
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
      playSound: () => unawaited(audio.playRandomSuccess()),
      sideEffects: () => _recordMastery(true),
      isMounted: () => mounted,
      advanceOrFinish: () {
        _feedback = null;
        _correct = null;
        if (_score >= _goal) {
          _finished = true;
        } else {
          _item = _nextItem();
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
      _feedback = null;
      _correct = null;
      _item = _nextItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GamePlayScaffold(
      title: 'Cho thú ăn',
      finished: _finished,
      complete: GameCompletePanel(score: _score, wrong: _wrong, total: _goal, onRetry: _restart),
      instruction: GameTargetBanner(label: _item.instruction, glyph: '🐼', color: VimaiColor.mint),
      progress: GameProgressBar(current: _score, total: _goal, color: VimaiColor.mint),
      feedback: LessonFeedback(correct: _correct, message: _feedback),
      playArea: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight, maxWidth: 440),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_item.question ?? '', style: VimaiType.greeting.copyWith(fontSize: 28, color: VimaiColor.mint), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ChoiceGrid(choices: _item.choices ?? [], color: VimaiColor.mint, onSelected: _onChoice),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      footer: Text('Điểm $_score   •   Sai $_wrong', textAlign: TextAlign.center, style: VimaiType.caption),
    );
  }
}
