import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/ai/mai_context.dart';
import '../../../core/game/webkit_answer_tap.dart';
import '../../../core/gamification/gamification_service.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/session/session_binder.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/kana/kana_examples.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/models/kana_item.dart';
import '../../shared/widgets/choice_grid.dart';
import '../../shared/widgets/kids_lesson.dart';
import '../../shared/widgets/learning_pager.dart';
import '../../shared/widgets/lesson_journey.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_ui.dart';
import '../handwriting/stroke_order_player.dart';
import '../handwriting/write_practice_board.dart';

/// Decoupled modules: look-only, write-only, or recognize-only (locked by [startMode]).
class KanaLessonScreen extends ConsumerStatefulWidget {
  final KanaScript script;
  final String? startId;
  final String? typeName;
  final String? startMode;

  const KanaLessonScreen({
    super.key,
    required this.script,
    this.startId,
    this.typeName,
    this.startMode,
  });

  @override
  ConsumerState<KanaLessonScreen> createState() => _KanaLessonScreenState();
}

class _KanaLessonScreenState extends ConsumerState<KanaLessonScreen> {
  late final PageController _controller;
  final _answerTap = WebKitAnswerTap(holdDuration: const Duration(milliseconds: 500));
  late List<KanaItem> _items;
  int _index = 0;
  bool _completed = false;
  String _mode = 'look';
  String? _feedback;
  String? _lastChoice;
  bool? _lastCorrect;
  String? _aiHint;
  List<String> _recognizeChoices = const [];
  String? _pendingMode;
  bool _pageAudioEnabled = false;

  static const _modes = {'look', 'listen', 'strokes', 'write', 'recognize'};

  @override
  void initState() {
    super.initState();
    final repo = ref.read(kanaRepositoryProvider);
    final all = widget.script == KanaScript.hiragana ? repo.getAllHiragana() : repo.getAllKatakana();
    _items = all.where((e) {
      if (widget.typeName == null || widget.typeName!.isEmpty) {
        return e.kanaType == KanaType.basic;
      }
      return e.kanaType.name == widget.typeName;
    }).toList();
    if (_items.isEmpty) _items = all;
    _index = _items.indexWhere((e) => e.id == widget.startId);
    if (_index < 0) _index = 0;
    _applyStartMode(widget.startMode);
    _rebuildRecognizeChoices();
    _controller = PageController(initialPage: _index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _items.isEmpty) return;
      unawaited(_playAt(_index));
      _pageAudioEnabled = true;
    });
  }

  @override
  void didUpdateWidget(covariant KanaLessonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startMode != widget.startMode) {
      _applyStartMode(widget.startMode);
    }
  }

  void _applyStartMode(String? mode) {
    if (mode == null || mode.isEmpty) {
      _mode = 'look';
      return;
    }
    if (mode == 'listen') {
      _mode = 'look';
      return;
    }
    if (_modes.contains(mode)) {
      _mode = mode;
    }
  }

  @override
  void dispose() {
    _answerTap.dispose();
    try {
      ref.read(audioServiceProvider).stop();
    } catch (_) {}
    _controller.dispose();
    super.dispose();
  }

  KanaItem get _current => _items[_index];

  Future<void> _playAt(int index) async {
    if (!mounted || _items.isEmpty) return;
    if (index < 0 || index >= _items.length) return;
    final kana = _items[index];
    final result = await ref.read(audioServiceProvider).playAsset(kana.audioId);
    if (mounted && index == _index) AudioService.notify(context, result);
  }

  Future<void> _playCurrent() => _playAt(_index);

  Future<void> _playExample() async {
    if (!mounted || _items.isEmpty) return;
    final index = _index;
    final kana = _items[index];
    // Production pack: ja_word_* via exampleWordAudioId (no .mp3).
    final audioKey = kana.exampleWordAudioId?.trim().isNotEmpty == true
        ? kana.exampleWordAudioId!
        : kana.wordAudioId;
    final result = await ref.read(audioServiceProvider).playAsset(audioKey);
    if (mounted && index == _index) AudioService.notify(context, result);
  }

  void _rebuildRecognizeChoices() {
    if (_items.isEmpty) return;
    final kana = _current;
    final repo = ref.read(kanaRepositoryProvider);
    final pool = kana.script == KanaScript.hiragana ? repo.getAllHiragana() : repo.getAllKatakana();
    final choices = <String>{kana.character, ...?kana.confusionGroup};
    for (final item in pool) {
      if (choices.length >= 4) break;
      if (item.kanaType == kana.kanaType) choices.add(item.character);
    }
    for (final item in pool) {
      if (choices.length >= 4) break;
      choices.add(item.character);
    }
    _recognizeChoices = choices.take(4).toList()..shuffle();
  }

  void _onNext() {
    if (_index >= _items.length - 1) {
      setState(() => _completed = true);
      return;
    }
    if (!_controller.hasClients) return;
    _pendingMode = _mode;
    unawaited(
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      ),
    );
  }

  void _onPrevious() {
    if (_index <= 0) return;
    if (!_controller.hasClients) return;
    _pendingMode = _mode;
    unawaited(
      _controller.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      ),
    );
  }

  void _jumpToPage(int index, {String? keepMode}) {
    if (index < 0) return;
    if (index >= _items.length) {
      setState(() => _completed = true);
      return;
    }
    _pendingMode = keepMode ?? _mode;
    if (!_controller.hasClients) return;
    if ((_controller.page?.round() ?? _index) == index) {
      setState(() {
        _index = index;
        _mode = _pendingMode ?? _mode;
        _pendingMode = null;
        _completed = false;
        _feedback = null;
        _lastChoice = null;
        _lastCorrect = null;
        _aiHint = null;
        if (_mode == 'recognize') _rebuildRecognizeChoices();
      });
      unawaited(_playAt(index));
      return;
    }
    unawaited(
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      ),
    );
  }

  String _speechFor(AppStrings copy) {
    if (_aiHint != null && _lastCorrect == false) {
      return _aiHint!;
    }
    switch (_mode) {
      case 'strokes':
        return 'Hãy xem cách viết nét này.';
      case 'write':
        return 'Con hãy viết theo mẫu';
      case 'recognize':
        return copy.whichLetter;
      default:
        return copy.listenHint;
    }
  }

  MascotMood _moodFor() {
    if (_lastCorrect == true) return MascotMood.celebrating;
    if (_lastCorrect == false) return MascotMood.encouraging;
    switch (_mode) {
      case 'strokes':
        return MascotMood.thinking;
      case 'write':
        return MascotMood.thinking;
      case 'recognize':
        return MascotMood.excited;
      default:
        return MascotMood.happy;
    }
  }

  String _continueLabel(AppStrings copy) {
    return copy.keepGoing;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.script == KanaScript.hiragana ? AppTheme.hiraganaColor : AppTheme.katakanaColor;
    final title = widget.script == KanaScript.hiragana ? 'Hiragana' : 'Katakana';
    final copy = AppStrings.of(ref.watch(currentProfileProvider), context);

    if (_completed) {
      return SessionBinder(
        subject: 'japanese',
        child: Scaffold(
          appBar: AppBar(title: Text(title)),
          body: LessonCompleteCard(
            onReview: () => _jumpToPage(0),
            onOther: () => context.pop(),
            onBack: () => context.go('/japanese'),
          ),
        ),
      );
    }

    final continueLabel = _continueLabel(copy);

    return SessionBinder(
      subject: 'japanese',
      child: Scaffold(
        backgroundColor: VimaiColor.skyTop,
        body: PageView.builder(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          onPageChanged: (index) {
            if (!_pageAudioEnabled) return;
            setState(() {
              _index = index;
              if (_pendingMode != null) {
                _mode = _pendingMode!;
                _pendingMode = null;
              }
              _completed = false;
              _feedback = null;
              _lastChoice = null;
              _lastCorrect = null;
              _aiHint = null;
              if (_mode == 'recognize') _rebuildRecognizeChoices();
            });
            unawaited(_playAt(index));
          },
          itemBuilder: (context, i) {
            final kana = _items[i];
            final active = i == _index;
            final mode = active ? _mode : 'look';
            return LessonJourneyShell(
              backgroundAsset: VimaiArt.japanLesson,
              title: 'Học chữ: ${kana.character}',
              speech: active ? _speechFor(copy) : copy.listenHint,
              accent: color,
              mascotMood: active ? _moodFor() : MascotMood.happy,
              mascotColor: color,
              onBack: () => context.pop(),
              feedback: active && _feedback != null
                  ? LessonFeedback(correct: _lastCorrect, message: _feedback)
                  : null,
              hero: _KanaHero(
                kana: kana,
                color: color,
                mode: mode,
                copy: copy,
                recognizeChoices: active ? _recognizeChoices : const [],
                lastChoice: active ? _lastChoice : null,
                lastCorrect: active ? _lastCorrect : null,
                onPlay: _playCurrent,
                onPlayExample: _playExample,
                onRecognize: (value, ok) {
                  if (_answerTap.locked) return;
                  final profile = ref.read(currentProfileProvider);
                  final audio = ref.read(audioServiceProvider);
                  final kanaId = kana.id;
                  final kanaChar = kana.character;

                  void sideEffects() {
                    if (profile != null) {
                      unawaited(
                        ref.read(masteryRepositoryProvider).record(
                              childId: profile.id,
                              itemId: kanaId,
                              skill: 'japanese.recognize',
                              correct: ok,
                            ),
                      );
                    }
                    if (ok) {
                      unawaited(
                        ref.read(gamificationServiceProvider).onCorrectAnswer(this.context),
                      );
                    } else {
                      final aiCtx = MaiContext(
                        currentModule: 'japanese',
                        currentLesson: kanaId,
                        currentActivity: _mode,
                        currentQuestion: 'Chọn chữ $kanaChar',
                        learningObjective: 'Nhận biết chữ Kana $kanaChar',
                        expectedAnswer: kanaChar,
                        targetLanguage: 'ja',
                        childAge: profile?.age ?? 5,
                      );
                      unawaited(() async {
                        try {
                          final hintResp = await ref.read(maiAiServiceProvider).onIncorrectAnswer(aiCtx);
                          if (!mounted) return;
                          setState(() => _aiHint = hintResp.text);
                        } catch (_) {}
                      }());
                    }
                  }

                  if (!ok) {
                    _answerTap.handleWrongAnswer(
                      setState: setState,
                      applyImmediateUi: () {
                        _lastChoice = value;
                        _lastCorrect = false;
                        _feedback = copy.tryAgain;
                      },
                      playSound: () => unawaited(audio.playRandomTryAgain()),
                      sideEffects: sideEffects,
                    );
                    return;
                  }

                  _answerTap.handleCorrectAnswer(
                    setState: setState,
                    applyImmediateUi: () {
                      _lastChoice = value;
                      _lastCorrect = true;
                      _feedback = copy.correct;
                    },
                    playSound: () => unawaited(audio.playRandomSuccess()),
                    sideEffects: sideEffects,
                    isMounted: () => mounted,
                    advanceOrFinish: () => _jumpToPage(_index + 1, keepMode: 'recognize'),
                  );
                },
              ),
              bottomDeck: active
                  ? LessonContinuePill(
                      label: continueLabel,
                      onTap: _onNext,
                      previousLabel: copy.back,
                      onPrevious: _onPrevious,
                      canPrevious: _index > 0,
                    )
                  : const SizedBox(height: 8),
            );
          },
        ),
      ),
    );
  }
}

class _KanaHero extends StatelessWidget {
  const _KanaHero({
    required this.kana,
    required this.color,
    required this.mode,
    required this.copy,
    required this.recognizeChoices,
    required this.lastChoice,
    required this.lastCorrect,
    required this.onPlay,
    required this.onPlayExample,
    required this.onRecognize,
  });

  final KanaItem kana;
  final Color color;
  final String mode;
  final AppStrings copy;
  final List<String> recognizeChoices;
  final String? lastChoice;
  final bool? lastCorrect;
  final VoidCallback onPlay;
  final VoidCallback onPlayExample;
  final void Function(String value, bool ok) onRecognize;

  @override
  Widget build(BuildContext context) {
    if (mode == 'strokes') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: StrokeOrderPlayer(kana: kana, color: color, copy: copy, onPlayAudio: onPlay),
      );
    }
    if (mode == 'write') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: WritePracticeBoard(
          kana: kana,
          color: color,
          copy: copy,
        ),
      );
    }
    if (mode == 'recognize') {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KidsAudioButton(label: copy.listenNow, color: color, onPressed: onPlay),
              const SizedBox(height: 12),
              ChoiceGrid(
                choices: recognizeChoices,
                color: color,
                lastChoice: lastChoice,
                lastCorrect: lastCorrect,
                onSelected: (value) => onRecognize(value, value == kana.character),
              ),
            ],
          ),
        ),
      );
    }

    final example = kana.resolvedExampleWord.isNotEmpty
        ? kana.resolvedExampleWord
        : KanaExamples.wordFor(kana.character);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PearlLetterHero(
              letter: kana.character,
              color: color,
              phonics: kana.romaji,
              listenLabel: copy.listenNow,
              onListen: onPlay,
            ),
            if (example.isNotEmpty) ...[
              const SizedBox(height: 12),
              Pressable(
                semanticLabel: example,
                onTap: onPlayExample,
                child: Text(example, style: VimaiType.title.copyWith(color: color, fontSize: 22)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
