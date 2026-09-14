import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/ai/mai_context.dart';
import '../../../core/audio/vietnamese_phonics_guide.dart';
import '../../../core/audio/vietnamese_phonics_view.dart';
import '../../../core/audio/vietnamese_speech_catalog.dart';
import '../../../core/game/webkit_answer_tap.dart';
import '../../../core/gamification/gamification_service.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/session/session_binder.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/content/content_item.dart';
import '../../japanese/writing/presentation/widgets/writing_canvas.dart';
import '../../shared/widgets/choice_grid.dart';
import '../../shared/widgets/kids_lesson.dart';
import '../../shared/widgets/kids_living_canopy.dart';
import '../../shared/widgets/kids_scene.dart';
import '../../shared/widgets/learning_pager.dart';
import '../../shared/widgets/lesson_journey.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_ui.dart';

/// Decoupled modules: look-only, write-only, or recognize-only (locked by [startMode]).
class VietnameseLetterLessonScreen extends ConsumerStatefulWidget {
  final String? startId;
  final String? startMode;

  const VietnameseLetterLessonScreen({super.key, this.startId, this.startMode});

  @override
  ConsumerState<VietnameseLetterLessonScreen> createState() => _VietnameseLetterLessonScreenState();
}

class _VietnameseLetterLessonScreenState extends ConsumerState<VietnameseLetterLessonScreen> {
  late final PageController _controller;
  final _answerTap = WebKitAnswerTap(holdDuration: const Duration(milliseconds: 400));
  late List<ContentItem> _letters;
  int _index = 0;
  bool _completed = false;
  String _mode = 'look';
  String? _feedback;
  String? _lastChoice;
  bool? _lastCorrect;
  String? _aiHint;
  List<String> _recognizeChoices = const [];
  String? _pendingMode;
  /// Ignore PageView callbacks until the first post-frame play has run.
  bool _pageAudioEnabled = false;

  @override
  void initState() {
    super.initState();
    _letters = ref.read(contentRepositoryProvider).getVietnameseAlphabet();
    _index = _letters.indexWhere((e) => e.id == widget.startId);
    if (_index < 0) _index = 0;
    final mode = widget.startMode;
    if (mode == 'recognize' || mode == 'write' || mode == 'look') {
      _mode = mode!;
    }
    _rebuildRecognizeChoices();
    _controller = PageController(initialPage: _index.clamp(0, (_letters.length - 1).clamp(0, 999)));
    // Initial audio ONCE after first frame — never from initState body.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _letters.isEmpty) return;
      unawaited(_playAt(_index));
      _pageAudioEnabled = true;
    });
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

  ContentItem get _current => _letters[_index];

  Future<void> _playAt(int index) async {
    if (!mounted || _letters.isEmpty) return;
    if (index < 0 || index >= _letters.length) return;
    final letter = _letters[index];
    final audioId = VietnamesePhonicsGuide.primaryAudioId(letter);
    final result = audioId.isNotEmpty
        ? await ref.read(audioServiceProvider).playAsset(audioId)
        : await VietnamesePhonicsGuide.playPrimary(ref.read(audioServiceProvider), letter);
    if (mounted && index == _index) AudioService.notify(context, result);
  }

  void _rebuildRecognizeChoices() {
    if (_letters.isEmpty) return;
    final letter = _current;
    final others = _letters.where((e) => e.question != letter.question).map((e) => e.question!).toList()..shuffle();
    _recognizeChoices = <String>{letter.question ?? '', ...others.take(3)}.toList()..shuffle();
  }

  /// Next: page animation ONLY — audio via [onPageChanged].
  void _onNext() {
    if (_index >= _letters.length - 1) {
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

  /// Previous: page animation ONLY — audio via [onPageChanged].
  void _onPrevious() {
    if (_index <= 0) {
      context.pop();
      return;
    }
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
    if (index >= _letters.length) {
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

  String _speechFor(ContentItem letter, AppStrings copy) {
    if (_aiHint != null && _lastCorrect == false) {
      return _aiHint!;
    }
    final phonics = VietnamesePhonicsView.fromItem(letter);
    final glyph = phonics.letter;
    switch (_mode) {
      case 'write':
        return 'Con hãy viết theo mẫu';
      case 'recognize':
        return copy.findLetterForMai(glyph);
      default:
        if (phonics.phonics.isNotEmpty) {
          return phonics.exampleWord.isNotEmpty
              ? 'Chữ $glyph — ${phonics.phonics}! Ví dụ: ${phonics.exampleWord}'
              : 'Chữ $glyph — ${phonics.phonics}!';
        }
        return copy.letterIntro(glyph);
    }
  }

  MascotMood _moodFor() {
    if (_lastCorrect == true) return MascotMood.celebrating;
    if (_lastCorrect == false) return MascotMood.encouraging;
    switch (_mode) {
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
    if (_letters.isEmpty) {
      return SessionBinder(
        subject: 'vietnamese',
        child: Scaffold(
          appBar: AppBar(title: const Text('Tiếng Việt')),
          body: const Center(child: Text('Chưa có bảng chữ cái')),
        ),
      );
    }

    if (_completed) {
      return SessionBinder(
        subject: 'vietnamese',
        child: Scaffold(
          appBar: AppBar(title: const Text('Tiếng Việt')),
          body: LessonCompleteCard(
            onReview: () => _jumpToPage(0),
            onOther: () => context.pop(),
            onBack: () => context.go('/vietnamese'),
          ),
        ),
      );
    }

    final copy = AppStrings.of(ref.watch(currentProfileProvider), context);
    final continueLabel = _continueLabel(copy);

    return SessionBinder(
      subject: 'vietnamese',
      child: Scaffold(
        backgroundColor: VimaiColor.skyTop,
        body: PageView.builder(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _letters.length,
          onPageChanged: (index) {
            // Single source of truth during navigation.
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
            final letter = _letters[i];
            final phonics = VietnamesePhonicsView.fromItem(letter);
            final active = i == _index;
            final mode = active ? _mode : 'look';
            return LessonJourneyShell(
              backgroundAsset: VimaiArt.gardenLesson,
              title: 'Học âm chữ: ${phonics.letter}',
              speech: active ? _speechFor(letter, copy) : copy.letterIntro(phonics.letter),
              accent: AppTheme.primaryColor,
              mascotMood: active ? _moodFor() : MascotMood.happy,
              onBack: () => context.pop(),
              feedback: active && _feedback != null
                  ? LessonFeedback(correct: _lastCorrect, message: _feedback)
                  : null,
              hero: _LetterHero(
                letter: letter,
                phonics: phonics,
                mode: mode,
                copy: copy,
                recognizeChoices: active ? _recognizeChoices : const [],
                lastChoice: active ? _lastChoice : null,
                lastCorrect: active ? _lastCorrect : null,
                onPlayPhoneme: () async {
                  final audioId = AudioService.getAudioIdForLetter(phonics.letter);
                  final result = await ref.read(audioServiceProvider).playAsset(
                        audioId.isNotEmpty
                            ? audioId
                            : VietnamesePhonicsGuide.primaryAudioId(letter),
                      );
                  if (context.mounted) AudioService.notify(context, result);
                },
                onPlayWord: (word) async {
                  // Prefer production wordAudioId / exampleWordAudioId (v_word_*), then word-text id.
                  final letterWordId = letter.exampleWordAudioId.isNotEmpty
                      ? letter.exampleWordAudioId
                      : letter.wordAudioId;
                  final textWordId = VietnameseSpeechCatalog.getAudioIdForWord(word);
                  final audioId = letterWordId.isNotEmpty ? letterWordId : textWordId;
                  final result = await ref.read(audioServiceProvider).playAsset(audioId);
                  if (context.mounted) AudioService.notify(context, result);
                },
                onRecognize: (value, ok) {
                  if (_answerTap.locked) return;
                  final profile = ref.read(currentProfileProvider);
                  final audio = ref.read(audioServiceProvider);
                  final letterId = letter.id;
                  final phonicsRule = phonics.phonics;
                  final letterGlyph = phonics.letter;

                  void sideEffects() {
                    if (profile != null) {
                      unawaited(
                        ref.read(masteryRepositoryProvider).record(
                              childId: profile.id,
                              itemId: letterId,
                              skill: 'vietnamese.alphabet',
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
                        currentModule: 'vietnamese',
                        currentLesson: letterId,
                        currentActivity: _mode,
                        currentQuestion: 'Tìm chữ $letterGlyph',
                        learningObjective: 'Nhận biết chữ cái $letterGlyph',
                        expectedAnswer: letterGlyph,
                        childAge: profile?.age ?? 5,
                        phoneticRule: phonicsRule,
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
                        _feedback = 'Thử lại nhé!';
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
                      _feedback = 'Giỏi lắm!';
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
                      canPrevious: true,
                    )
                  : const SizedBox(height: 8),
            );
          },
        ),
      ),
    );
  }
}

class _LetterHero extends StatelessWidget {
  const _LetterHero({
    required this.letter,
    required this.phonics,
    required this.mode,
    required this.copy,
    required this.recognizeChoices,
    required this.lastChoice,
    required this.lastCorrect,
    required this.onPlayPhoneme,
    required this.onPlayWord,
    required this.onRecognize,
  });

  final ContentItem letter;
  final VietnamesePhonicsView phonics;
  final String mode;
  final AppStrings copy;
  final List<String> recognizeChoices;
  final String? lastChoice;
  final bool? lastCorrect;
  final VoidCallback onPlayPhoneme;
  final ValueChanged<String> onPlayWord;
  final void Function(String value, bool ok) onRecognize;

  @override
  Widget build(BuildContext context) {
    final glyph = phonics.letter;
    if (mode == 'write') {
      return _VietnameseWriteHero(glyph: glyph, color: AppTheme.primaryColor);
    }
    if (mode == 'recognize') {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KidsAudioButton(label: 'Nghe nào!', color: VimaiColor.mint, onPressed: onPlayPhoneme),
              const SizedBox(height: 12),
              ChoiceGrid(
                choices: recognizeChoices,
                lastChoice: lastChoice,
                lastCorrect: lastCorrect,
                onSelected: (value) => onRecognize(value, value == letter.question),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PearlLetterHero(
              letter: glyph,
              lowercase: phonics.lowercase,
              phonics: phonics.phonics,
              color: AppTheme.primaryColor,
              listenLabel: 'Nghe nào!',
              onListen: onPlayPhoneme,
            ),
            if (phonics.exampleWord.isNotEmpty) ...[
              const SizedBox(height: 14),
              WordExampleWidget(
                word: phonics.exampleWord,
                onTap: () => onPlayWord(phonics.exampleWord),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Example word cue — always speaks the word, never the letter phoneme.
class WordExampleWidget extends StatelessWidget {
  const WordExampleWidget({super.key, required this.word, required this.onTap});

  final String word;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: word,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WordSceneCue(word: word, color: VimaiColor.sky, size: 72),
          Text(
            word,
            style: VimaiType.title.copyWith(color: VimaiColor.sky, fontSize: 22),
          ),
        ],
      ),
    );
  }
}

class _VietnameseWriteHero extends StatefulWidget {
  const _VietnameseWriteHero({required this.glyph, required this.color});

  final String glyph;
  final Color color;

  @override
  State<_VietnameseWriteHero> createState() => _VietnameseWriteHeroState();
}

class _VietnameseWriteHeroState extends State<_VietnameseWriteHero> {
  final GlobalKey<WritingCanvasState> _canvasKey = GlobalKey<WritingCanvasState>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: KidsWritingStage(
            letter: widget.glyph,
            color: widget.color,
            child: WritingCanvas(
              key: _canvasKey,
              strokeColor: widget.color,
              boardFill: Colors.transparent,
              showClearButton: false,
              onCleared: () {},
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 8,
          child: TactileNode(
            key: const Key('write-clear'),
            semanticLabel: 'Xóa',
            minSize: VimaiSize.touchKid,
            onTap: () => _canvasKey.currentState?.clear(),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color.lerp(widget.color, Colors.white, 0.85)!],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(color: widget.color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Icon(Icons.auto_fix_off_rounded, size: 30, color: widget.color),
            ),
          ),
        ),
      ],
    );
  }
}
