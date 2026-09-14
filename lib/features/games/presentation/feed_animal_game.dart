import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
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
  late var _item = _generator.generateCounting(5);
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;
  bool _busy = false;
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
    _audio?.stopGameBgm();
    super.dispose();
  }

  ContentItem _nextItem() {
    final age = ref.read(currentProfileProvider)?.age ?? 5;
    return _generator.generateBySkill('counting', age: age);
  }

  Future<void> _onChoice(String value) async {
    if (_busy || _finished) return;
    final ok = value == _item.answer;
    final profile = ref.read(currentProfileProvider);
    if (profile != null) {
      await ref.read(masteryRepositoryProvider).record(
            childId: profile.id,
            itemId: _item.id,
            skill: 'game.feed_animal',
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
    if (!ok) {
      await ref.read(audioServiceProvider).playRandomTryAgain();
      return;
    }
    await ref.read(audioServiceProvider).playRandomSuccess();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _feedback = null;
      _correct = null;
      if (_score >= _goal) {
        _finished = true;
      } else {
        _item = _nextItem();
      }
    });
  }

  void _restart() {
    setState(() {
      _score = 0;
      _wrong = 0;
      _finished = false;
      _busy = false;
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
