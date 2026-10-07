import 'dart:async';
import 'dart:math' as math;

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
import '../../shared/widgets/chunky_button.dart';
import 'widgets/game_art.dart';
import 'widgets/game_play_scaffold.dart';
import '../../../core/audio/kid_guide.dart';

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
      unawaited(_audio?.speak([KidGuide.gameFeedAnimal, _item.instruction], fallbackId: 'sys_math_count'));
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
          unawaited(ref.read(audioServiceProvider).speak([_item.instruction]));
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
      unawaited(ref.read(audioServiceProvider).speak([_item.instruction]));
    });
  }

  void _sayInstruction() => unawaited(ref.read(audioServiceProvider).speak([_item.instruction]));

  @override
  Widget build(BuildContext context) {
    final icon = (_item.metadata?['icon'] as String?) ?? '🍎';
    final quantity = (_item.metadata?['quantity'] as int?) ?? int.tryParse(_item.answer ?? '') ?? 0;
    return GamePlayScaffold(
      title: 'Cho thú ăn',
      scene: GameScene.meadow,
      finished: _finished,
      correct: _correct,
      complete: GameCompletePanel(
        score: _score,
        wrong: _wrong,
        total: _goal,
        onRetry: _restart,
        hero: const SizedBox(
          width: 130,
          height: 130,
          child: _HungryPanda(eating: true, size: 130),
        ),
      ),
      instruction: GameTargetBanner(
        label: _item.instruction,
        glyph: icon,
        color: VimaiColor.mint,
        onTap: _sayInstruction,
      ),
      progress: GameProgressBar(current: _score, total: _goal, color: VimaiColor.mint),
      feedback: GameFeedbackToast(correct: _correct, message: _feedback),
      playArea: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 560;
          final pandaSize = (constraints.maxHeight * 0.27).clamp(96.0, 176.0);
          return Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShakeOnChange(
                      trigger: _wrong == 0 ? null : _wrong,
                      child: _HungryPanda(eating: _correct == true, size: pandaSize),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -10),
                      child: _FruitPlate(
                        key: ValueKey(_item.id),
                        icon: icon,
                        count: quantity,
                        eaten: _correct == true,
                        compact: compact,
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 14),
                    ChoiceGrid(
                      choices: _item.choices ?? [],
                      color: VimaiColor.mint,
                      palette: gamePalette,
                      lastCorrect: _correct,
                      maxItemSize: compact ? 72 : 124,
                      onSelected: _onChoice,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The panda: blinks while waiting, chomps happily when fed.
class _HungryPanda extends StatefulWidget {
  const _HungryPanda({required this.eating, required this.size});

  final bool eating;
  final double size;

  @override
  State<_HungryPanda> createState() => _HungryPandaState();
}

class _HungryPandaState extends State<_HungryPanda> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: widget.size * 1.1,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final chomp = widget.eating ? (still ? 0.8 : (0.5 + 0.5 * math.sin(t * math.pi * 2 * 9)).abs()) : 0.0;
          final blink = !widget.eating && (t % 0.5) > 0.47;
          final bob = still ? 0.0 : math.sin(t * math.pi * 4) * 3;
          return Transform.translate(
            offset: Offset(0, bob),
            child: CustomPaint(
              painter: PandaPainter(mouth: chomp, happy: widget.eating, blink: blink),
            ),
          );
        },
      ),
    );
  }
}

/// Picnic plate with the fruit to count. Fruit hops up into the panda's
/// mouth when the child answers right.
class _FruitPlate extends StatelessWidget {
  const _FruitPlate({super.key, required this.icon, required this.count, required this.eaten, required this.compact});

  final String icon;
  final int count;
  final bool eaten;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fruit = compact ? 28.0 : 36.0;
    final duration = VimaiMotion.of(context, const Duration(milliseconds: 450));
    return Container(
      constraints: BoxConstraints(minHeight: fruit + 30, minWidth: 180),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFFF1DE)],
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: const Color(0xFFF2C894), width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD9A066), offset: Offset(0, 6)),
          BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 10)),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: fruit * 5 + 40),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedSlide(
                duration: duration,
                curve: Interval(math.min(0.6, i * 0.06), 1, curve: Curves.easeInBack),
                offset: eaten ? const Offset(0, -2.2) : Offset.zero,
                child: AnimatedScale(
                  duration: duration,
                  scale: eaten ? 0.2 : 1,
                  child: AnimatedOpacity(
                    duration: duration,
                    opacity: eaten ? 0 : 1,
                    child: SizedBox(
                      width: fruit,
                      height: fruit,
                      child: FittedBox(child: Text(icon, style: const TextStyle(fontSize: 40, height: 1))),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
