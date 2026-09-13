import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/content/math_generator.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/choice_grid.dart';
import '../../shared/widgets/vimai_ui.dart';
import 'widgets/game_play_scaffold.dart';

class MathRocketGame extends ConsumerStatefulWidget {
  const MathRocketGame({super.key});

  @override
  ConsumerState<MathRocketGame> createState() => _MathRocketGameState();
}

class _MathRocketGameState extends ConsumerState<MathRocketGame> {
  final _generator = MathQuestionGenerator();
  late var _item = _generator.generateAddition(10);
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;
  bool _busy = false;
  String? _feedback;
  bool? _correct;

  int get _goal => GameCatalog.roundsForAge(ref.read(currentProfileProvider)?.age ?? 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final age = ref.read(currentProfileProvider)?.age ?? 5;
      final skill = MathQuestionGenerator.skillForAge(age, addition: true);
      setState(() => _item = _generator.generateBySkill(skill, age: age));
      final audio = ref.read(audioServiceProvider);
      final profile = ref.read(currentProfileProvider);
      audio.soundEnabled = profile?.soundEnabled ?? true;
      audio.bgmEnabled = profile?.bgmEnabled ?? true;
      audio.startGameBgm();
      audio.playIntro('sys_math_calc_add');
    });
  }

  void _nextItem() {
    final age = ref.read(currentProfileProvider)?.age ?? 5;
    final skill = MathQuestionGenerator.skillForAge(age, addition: true);
    _item = _generator.generateBySkill(skill, age: age);
  }

  Future<void> _onChoice(String value) async {
    if (_busy || _finished) return;
    final ok = value == _item.answer;
    final profile = ref.read(currentProfileProvider);
    if (profile != null) {
      await ref.read(masteryRepositoryProvider).record(
            childId: profile.id,
            itemId: _item.id,
            skill: 'game.math_rocket',
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
        _nextItem();
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
      _nextItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GamePlayScaffold(
      title: 'Tên lửa toán',
      finished: _finished,
      complete: GameCompletePanel(score: _score, wrong: _wrong, total: _goal, onRetry: _restart),
      instruction: const GameTargetBanner(label: 'Chọn đáp án đúng', glyph: '🚀', color: AppTheme.mathColor),
      progress: GameProgressBar(current: _score, total: _goal, color: AppTheme.mathColor),
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
                    Text(_item.question ?? '', style: VimaiType.greeting.copyWith(fontSize: 36, color: AppTheme.mathColor)),
                    const SizedBox(height: 20),
                    ChoiceGrid(choices: _item.choices ?? [], color: AppTheme.mathColor, onSelected: _onChoice),
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
