import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/vimai_ui.dart';
import 'widgets/game_play_scaffold.dart';

class NumberTrainGame extends ConsumerStatefulWidget {
  const NumberTrainGame({super.key});

  @override
  ConsumerState<NumberTrainGame> createState() => _NumberTrainGameState();
}

class _NumberTrainGameState extends ConsumerState<NumberTrainGame> {
  late List<int> _numbers;
  final _selected = <int>[];
  int _score = 0;
  int _wrong = 0;
  bool _finished = false;
  String? _feedback;
  bool? _correct;

  int get _goal => GameCatalog.roundsForAge(ref.read(currentProfileProvider)?.age ?? 5);

  @override
  void initState() {
    super.initState();
    _numbers = [1, 2, 3, 4, 5]..shuffle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(_reset);
        ref.read(audioServiceProvider).playIntro('sys_math_order');
      }
    });
  }

  void _reset() {
    final age = ref.read(currentProfileProvider)?.age ?? 5;
    _numbers = GameCatalog.numberTrain(age, Random());
    _selected.clear();
    _feedback = null;
    _correct = null;
  }

  void _pick(int n) {
    if (_finished || _selected.contains(n)) return;
    setState(() => _selected.add(n));
    final expected = List<int>.from(_numbers)..sort();
    if (_selected.length != expected.length) return;
    final ok = _selected.join() == expected.join();
    if (ok) {
      unawaited(ref.read(audioServiceProvider).playRandomSuccess());
      setState(() {
        _score++;
        _correct = true;
        _feedback = 'Giỏi lắm!';
        if (_score >= _goal) {
          _finished = true;
        }
      });
      if (!_finished) {
        Future<void>.delayed(const Duration(milliseconds: 650), () {
          if (!mounted || _finished) return;
          setState(_reset);
        });
      }
    } else {
      unawaited(ref.read(audioServiceProvider).playRandomTryAgain());
      setState(() {
        _wrong++;
        _correct = false;
        _feedback = 'Thử lại nhé!';
        _selected.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GamePlayScaffold(
      title: 'Tàu số',
      finished: _finished,
      complete: GameCompletePanel(
        score: _score,
        wrong: _wrong,
        total: _goal,
        onRetry: () => setState(() {
          _score = 0;
          _wrong = 0;
          _finished = false;
          _reset();
        }),
      ),
      instruction: const GameTargetBanner(label: 'Xếp số từ nhỏ đến lớn', glyph: '12', color: VimaiColor.sky),
      progress: GameProgressBar(current: _score, total: _goal, color: VimaiColor.sky),
      feedback: LessonFeedback(correct: _correct, message: _feedback),
      playArea: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _selected.isEmpty ? '…' : _selected.join(' → '),
                style: VimaiType.greeting.copyWith(fontSize: 28, color: AppTheme.mathColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _numbers.map((n) {
                  final used = _selected.contains(n);
                  return SizedBox(
                    width: 72,
                    height: 72,
                    child: Pressable(
                      semanticLabel: '$n',
                      onTap: used ? null : () => _pick(n),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: used ? VimaiColor.skySoft : VimaiColor.surface,
                          borderRadius: BorderRadius.circular(VimaiRadius.md),
                          border: Border.all(color: VimaiColor.sky.withValues(alpha: 0.4), width: 2.5),
                        ),
                        child: Text(
                          '$n',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: used ? VimaiColor.inkSoft : VimaiColor.sky,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      footer: TextButton(onPressed: () => setState(_reset), child: const Text('Làm lại')),
    );
  }
}
