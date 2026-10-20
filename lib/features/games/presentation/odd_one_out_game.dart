import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/audio/kid_guide.dart';
import '../../../core/game/webkit_answer_tap.dart';
import '../../../core/providers.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/game_catalog.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../explore/data/explore_catalog.dart';
import '../../shared/widgets/chunky_button.dart';
import '../logic/odd_one_out_round.dart';
import 'widgets/game_play_scaffold.dart';

const _accent = Color(0xFF7B63E0);

/// "Cái nào khác nhóm?": Mai asks which picture does not belong
/// ("Bạn nào không phải là con vật nuôi?"), the child taps it and Mai says
/// why. Three very different pictures at first; four close ones (pets vs
/// wild animals, fruit vs vegetables) once the child is on a roll.
class OddOneOutGame extends ConsumerWidget {
  const OddOneOutGame({super.key, this.random});

  /// Fixed seed for tests.
  final math.Random? random;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(exploreCatalogProvider);
    return catalog.when(
      loading: () => const _Waiting(),
      error: (e, _) => const _Waiting(),
      data: (data) => _OddOneOutPlay(catalog: data, random: random ?? math.Random()),
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) => const GamePlayScaffold(
        title: 'Cái nào khác nhóm?',
        scene: GameScene.meadow,
        playArea: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
}

class _OddOneOutPlay extends ConsumerStatefulWidget {
  const _OddOneOutPlay({required this.catalog, required this.random});

  final ExploreCatalog catalog;
  final math.Random random;

  @override
  ConsumerState<_OddOneOutPlay> createState() => _OddOneOutPlayState();
}

class _OddOneOutPlayState extends ConsumerState<_OddOneOutPlay> {
  /// Long enough for the chime, Mai's praise and her "why" before the next round.
  static const _solvedHold = Duration(milliseconds: 4600);

  /// Mai's praise/retry voice plays first; her own line follows after it.
  static const _afterFeedbackVoice = Duration(milliseconds: 1500);

  final _answerTap = WebKitAnswerTap();
  late OddOneOutRound _round;
  int _roundNo = 0;
  int _level = 0;
  int _streak = 0;
  int _misses = 0;
  int _roundMisses = 0;
  int _score = 0;
  int _wrong = 0;
  bool _solved = false;
  bool _finished = false;
  bool? _correct;
  String? _feedback;
  final _wrongIds = <String>{};
  final _shakes = <String, int>{};
  Timer? _sayTimer;
  AudioService? _audio;

  int get _age => ref.read(currentProfileProvider)?.age ?? 5;
  int get _goal => math.min(GameCatalog.roundsForAge(_age), 10);

  @override
  void initState() {
    super.initState();
    _level = OddOneOutRound.startLevel(ref.read(currentProfileProvider)?.age ?? 5);
    _round = OddOneOutRound.generate(widget.catalog, level: _level, random: widget.random);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _audio = ref.read(audioServiceProvider);
      final profile = ref.read(currentProfileProvider);
      _audio?.soundEnabled = profile?.soundEnabled ?? true;
      _audio?.bgmEnabled = profile?.bgmEnabled ?? true;
      _audio?.startGameBgm();
      unawaited(_audio?.speak([KidGuide.gameOddOneOut, _round.question], fallbackId: 'sys_thinking_memory'));
    });
  }

  @override
  void dispose() {
    _sayTimer?.cancel();
    _answerTap.dispose();
    _audio?.stopGameBgm();
    super.dispose();
  }

  AudioService get _voice => ref.read(audioServiceProvider);

  void _sayLater(String line) {
    _sayTimer?.cancel();
    _sayTimer = Timer(_afterFeedbackVoice, () {
      if (mounted) unawaited(_voice.speak([line]));
    });
  }

  void _sayQuestion() {
    _sayTimer?.cancel();
    unawaited(_voice.speak([_round.question]));
  }

  void _sayName(ExploreItem item) {
    _voice.sfx(Sfx.pop);
    unawaited(_voice.speak([item.name]));
  }

  void _nextRound() {
    _roundNo++;
    _round = OddOneOutRound.generate(widget.catalog,
        level: _level, random: widget.random, avoidMajority: _round.majority.id);
    _solved = false;
    _correct = null;
    _feedback = null;
    _roundMisses = 0;
    _wrongIds.clear();
    _voice.sfx(Sfx.whoosh);
    unawaited(_voice.speak([_round.question]));
  }

  void _recordMastery(ExploreItem tapped, bool ok) {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    unawaited(
      ref.read(masteryRepositoryProvider).record(
            childId: profile.id,
            itemId: 'odd_one_out_${_round.majority.id}_${tapped.id}',
            skill: 'game.odd_one_out',
            correct: ok,
          ),
    );
  }

  void _onTap(ExploreItem item) {
    if (_finished || _solved || _answerTap.locked) return;
    if (_wrongIds.contains(item.id)) {
      // Already ruled out: just say its name again, no penalty.
      _sayName(item);
      return;
    }
    final audio = _voice;
    if (!_round.isOdd(item)) {
      _answerTap.handleWrongAnswer(
        setState: setState,
        applyImmediateUi: () {
          _wrongIds.add(item.id);
          _shakes[item.id] = (_shakes[item.id] ?? 0) + 1;
          _wrong++;
          _roundMisses++;
          _streak = 0;
          _misses++;
          if (_misses >= 2) {
            _misses = 0;
            _level = math.max(0, _level - 1);
          }
          _correct = false;
          _feedback = 'Thử lại nhé!';
        },
        playSound: () {
          audio.playWrongSound();
          _sayLater(item.name);
        },
        sideEffects: () => _recordMastery(item, false),
      );
      return;
    }

    final explanation = _round.explanation;
    _answerTap.handleCorrectAnswer(
      setState: setState,
      hold: _solvedHold,
      applyImmediateUi: () {
        _solved = true;
        _correct = true;
        _feedback = 'Đúng rồi!';
        _score++;
        if (_roundMisses == 0) {
          _misses = 0;
          _streak++;
          if (_streak >= 2 && _level < OddOneOutRound.maxLevel) {
            _streak = 0;
            _level++;
          }
        }
      },
      playSound: () {
        audio.playCorrectSound();
        _sayLater(explanation);
      },
      sideEffects: () => _recordMastery(item, true),
      isMounted: () => mounted,
      advanceOrFinish: () {
        if (_score >= _goal) {
          _finished = true;
          _sayTimer?.cancel();
        } else {
          _nextRound();
        }
      },
    );
  }

  void _restart() {
    _answerTap.reset();
    _sayTimer?.cancel();
    setState(() {
      _score = 0;
      _wrong = 0;
      _streak = 0;
      _misses = 0;
      _finished = false;
      _level = OddOneOutRound.startLevel(_age);
      _nextRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    return GamePlayScaffold(
      title: 'Cái nào khác nhóm?',
      scene: GameScene.meadow,
      finished: _finished,
      correct: _correct,
      complete: GameCompletePanel(
        score: _score,
        wrong: _wrong,
        total: _goal,
        onRetry: _restart,
        hero: const Text('🔍', style: TextStyle(fontSize: 96, height: 1.1)),
      ),
      instruction: GameTargetBanner(
        label: round.question,
        glyph: round.majority.emoji,
        color: _accent,
        onTap: _sayQuestion,
      ),
      progress: GameProgressBar(current: _score, total: _goal, color: _accent),
      feedback: GameFeedbackToast(correct: _correct, message: _feedback),
      playArea: GameCardGrid(
        itemCount: round.cards.length,
        aspect: 0.86,
        builder: (context, index) {
          final item = round.cards[index];
          return OddOneOutCard(
            key: ValueKey('odd-card-$_roundNo-${item.id}'),
            item: item,
            odd: round.isOdd(item),
            index: index,
            ruledOut: _wrongIds.contains(item.id),
            solved: _solved,
            shake: _shakes[item.id],
            badge: _solved ? (round.isOdd(item) ? round.oddCategory.emoji : round.majority.emoji) : null,
            onTap: () => _onTap(item),
            onLongPress: () => _sayName(item),
          );
        },
      ),
    );
  }
}

/// One big picture. Springs in when a round starts, wobbles when it is not the
/// answer, glows green when it is; once solved, each card shows its group's
/// emoji so the child sees which ones belonged together.
class OddOneOutCard extends StatelessWidget {
  const OddOneOutCard({
    super.key,
    required this.item,
    required this.odd,
    required this.index,
    required this.ruledOut,
    required this.solved,
    required this.onTap,
    required this.onLongPress,
    this.shake,
    this.badge,
  });

  final ExploreItem item;

  /// True for the picture that does not belong (used by tests and semantics).
  final bool odd;
  final int index;
  final bool ruledOut;
  final bool solved;
  final int? shake;
  final String? badge;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final winner = solved && odd;
    final faded = ruledOut || (solved && !odd);
    final enter = VimaiMotion.of(context, Duration(milliseconds: 520 + index * 110));
    final fade = VimaiMotion.of(context, const Duration(milliseconds: 250));
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1),
      duration: enter,
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: ShakeOnChange(
        trigger: shake,
        distance: 12,
        child: PopOnChange(
          trigger: winner,
          amount: 0.16,
          child: AnimatedOpacity(
            duration: fade,
            opacity: faded ? 0.5 : 1,
            child: GestureDetector(
              onLongPress: onLongPress,
              child: ChunkyButton(
                color: winner ? const Color(0xFFE9FFF0) : Colors.white,
                outline: winner ? VimaiColor.correct : (ruledOut ? VimaiColor.retry : const Color(0xFFE6E0FA)),
                outlineWidth: winner || ruledOut ? 5 : 3,
                glow: winner ? VimaiColor.correct : null,
                radius: 28,
                depth: 7,
                semanticLabel: item.name,
                onTap: onTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                      child: Column(
                        children: [
                          Expanded(
                            child: FittedBox(
                              child: Text(item.emoji, style: const TextStyle(fontSize: 96, height: 1.15)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 22,
                            child: FittedBox(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                style: VimaiType.cardTitle.copyWith(color: VimaiColor.inkSoft, fontSize: 18, height: 1.1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (badge != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: _Badge(glyph: badge!, color: winner ? VimaiColor.correct : _accent),
                      ),
                    if (ruledOut)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: _Badge(icon: Icons.close_rounded, color: VimaiColor.retry),
                      ),
                    if (winner)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: _Badge(icon: Icons.check_rounded, color: VimaiColor.correct),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({this.glyph, this.icon, required this.color});

  final String? glyph;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PopOnChange(
      trigger: glyph ?? icon,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: glyph != null ? Colors.white : color,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2.5),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: glyph != null
            ? Text(glyph!, style: const TextStyle(fontSize: 18, height: 1.1))
            : Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
