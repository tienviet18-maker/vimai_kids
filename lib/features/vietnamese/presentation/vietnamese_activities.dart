import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_locale_policy.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/kid_guide.dart';
import '../../../core/audio/vietnamese_phonics_guide.dart';
import '../../../core/game/webkit_answer_tap.dart';
import '../../../core/providers.dart';
import '../../../core/routing/nav_utils.dart';
import '../../../core/session/session_binder.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/content/content_item.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../shared/widgets/choice_grid.dart';
import '../../shared/widgets/kids_scene.dart';
import '../../shared/widgets/kids_storybook.dart';
import '../../shared/widgets/listen_prompt.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_world.dart';
import '../../shared/widgets/vimai_ui.dart';

class VietnameseAlphabetGridScreen extends ConsumerWidget {
  const VietnameseAlphabetGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final letters = ref.watch(contentRepositoryProvider).getVietnameseAlphabet();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => popLearningScreen(context)),
        title: const Text('Bảng chữ cái'),
      ),
      body: SafeArea(
        child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 90,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: letters.length,
        itemBuilder: (context, index) {
          final letter = letters[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/vietnamese/learn?id=${letter.id}'),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4), width: 2),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        letter.question ?? '',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        iconSize: 22,
                        color: AppTheme.primaryColor,
                        onPressed: () async {
                          final audioId = AudioService.getAudioIdForLetter(letter.question ?? '');
                          final result = audioId.isNotEmpty
                              ? await ref.read(audioServiceProvider).playAudio(audioId)
                              : await VietnamesePhonicsGuide.playPrimary(ref.read(audioServiceProvider), letter);
                          if (context.mounted) AudioService.notify(context, result);
                        },
                        icon: const Icon(Icons.volume_up_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}

class VietnameseQuizListScreen extends ConsumerStatefulWidget {
  final String title;
  final List<ContentItem> Function(WidgetRef ref) loader;
  final String skill;

  const VietnameseQuizListScreen({
    super.key,
    required this.title,
    required this.loader,
    required this.skill,
  });

  @override
  ConsumerState<VietnameseQuizListScreen> createState() => _VietnameseQuizListScreenState();
}

class _VietnameseQuizListScreenState extends ConsumerState<VietnameseQuizListScreen> {
  final _answerTap = WebKitAnswerTap(holdDuration: const Duration(milliseconds: 500));
  int _index = 0;
  int _stars = 0;
  String? _feedback;
  String? _lastChoice;
  bool? _lastCorrect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _present(first: true));
  }

  @override
  void dispose() {
    _answerTap.dispose();
    super.dispose();
  }

  String get _howTo {
    final s = widget.skill;
    if (s.contains('blend') || s.contains('phonics')) return KidGuide.blendHowTo;
    if (s.contains('rime')) return KidGuide.rimeHowTo;
    if (s.contains('sentence')) return KidGuide.sentenceHowTo;
    return KidGuide.wordHowTo;
  }

  /// The clip that says this item (blend, rime, word or sentence).
  String _itemClipId(ContentItem item) {
    final s = widget.skill;
    if (s.contains('blend') || s.contains('phonics')) {
      return item.exampleWordAudioId.isNotEmpty
          ? item.exampleWordAudioId
          : (item.blendAudioId.isNotEmpty ? item.blendAudioId : item.audioId);
    }
    if (s.contains('rime')) return item.audioId.isNotEmpty ? item.audioId : 'v_rime_${item.rime}';
    if (item.exampleWordAudioId.isNotEmpty) return item.exampleWordAudioId;
    if (item.audioId.isNotEmpty) return item.audioId;
    return item.wordAudioId;
  }

  /// Mai says what to do, then the item itself ("Đọc từ này… mèo").
  void _present({bool first = false}) {
    if (!mounted) return;
    final items = widget.loader(ref);
    if (_index >= items.length) {
      unawaited(ref.read(audioServiceProvider).speakLine(KidGuide.sessionDone));
      return;
    }
    final item = items[_index];
    unawaited(
      ref.read(audioServiceProvider).speak(
        [if (first) _howTo, item.instruction],
        trailIds: [_itemClipId(item)],
      ),
    );
  }

  Future<void> _playItem(ContentItem item) async {
    final audio = ref.read(audioServiceProvider);
    AudioPlayResult result;
    if (widget.skill.contains('blend') || widget.skill.contains('phonics')) {
      final id = item.exampleWordAudioId.isNotEmpty
          ? item.exampleWordAudioId
          : (item.blendAudioId.isNotEmpty ? item.blendAudioId : item.audioId);
      result = await audio.playAsset(id);
    } else if (widget.skill.contains('rime')) {
      final id = item.audioId.isNotEmpty ? item.audioId : 'v_rime_${item.rime}';
      result = await audio.playAsset(id);
    } else if (item.exampleWordAudioId.isNotEmpty) {
      result = await audio.playAsset(item.exampleWordAudioId);
    } else if (item.audioId.isNotEmpty) {
      result = await audio.playAsset(item.audioId);
    } else if (item.wordAudioId.isNotEmpty) {
      result = await audio.playAsset(item.wordAudioId);
    } else {
      final text = item.audioText.isNotEmpty ? item.audioText : item.syllable;
      result = widget.skill.contains('word') || widget.skill.contains('sentence')
          ? await audio.playVietnameseWord(text)
          : await audio.playVietnamesePhonics(text);
    }
    if (mounted) AudioService.notify(context, result);
  }

  Future<void> _playBlendParts(ContentItem item) async {
    final audio = ref.read(audioServiceProvider);
    final onset = item.onset.trim();
    final rime = item.rime.trim();
    if (onset.isNotEmpty) {
      final onsetId = AudioService.getAudioIdForLetter(onset);
      if (onsetId.isNotEmpty) {
        await audio.playAsset(onsetId, waitForComplete: true);
        await Future<void>.delayed(const Duration(milliseconds: 280));
      }
    }
    if (rime.isNotEmpty) {
      final rimeId = AudioService.getAudioIdForLetter(rime);
      if (rimeId.isNotEmpty) {
        await audio.playAsset(rimeId, waitForComplete: true);
        await Future<void>.delayed(const Duration(milliseconds: 280));
      } else if (item.audioId.isNotEmpty || item.blendAudioId.isNotEmpty) {
        // vowel rime may be multi-letter — play full blend after onset
      }
    }
    await _playItem(item);
  }

  final _choiceCache = <int, List<String>>{};

  /// Choices for [index]; sentence/word items without their own get two
  /// other answers from the same list (stable per question).
  List<String> _choicesFor(List<ContentItem> items, int index) {
    return _choiceCache.putIfAbsent(index, () {
      final item = items[index];
      final own = item.choices ?? const <String>[];
      if (own.length >= 2) return own;
      final answer = item.answer ?? item.question ?? '';
      final others = items.map((e) => e.answer ?? '').where((a) => a.isNotEmpty && a != answer).toSet().toList()
        ..shuffle(Random(index * 7919 + items.length));
      return [answer, ...others.take(2)]..shuffle(Random(index));
    });
  }

  void _onChoice(ContentItem item, String value) {
    if (_answerTap.locked) return;
    final ok = value == item.answer;
    final profile = ref.read(currentProfileProvider);

    void sideEffects() {
      if (profile == null) return;
      unawaited(
        ref.read(masteryRepositoryProvider).record(
              childId: profile.id,
              itemId: item.id,
              skill: widget.skill,
              correct: ok,
            ),
      );
    }

    if (!ok) {
      _answerTap.handleWrongAnswer(
        setState: setState,
        applyImmediateUi: () {
          _feedback = 'Thử lại nhé! 💪';
          _lastChoice = value;
          _lastCorrect = false;
        },
        playSound: () => unawaited(ref.read(audioServiceProvider).playRandomTryAgain()),
        sideEffects: sideEffects,
      );
      return;
    }

    _answerTap.handleCorrectAnswer(
      setState: setState,
      applyImmediateUi: () {
        _feedback = 'Đúng rồi! ⭐';
        _lastChoice = value;
        _lastCorrect = true;
        _stars++;
      },
      playSound: () => unawaited(ref.read(audioServiceProvider).playRandomSuccess()),
      sideEffects: sideEffects,
      isMounted: () => mounted,
      advanceOrFinish: () {
        _index++;
        _feedback = null;
        _lastChoice = null;
        _lastCorrect = null;
        _present();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.loader(ref);
    final Widget body;
    String subtitle = '';
    if (items.isEmpty) {
      body = const Center(child: Text('Chưa có dữ liệu'));
    } else if (_index >= items.length) {
      body = _FinishedPanel(
        stars: _stars,
        total: items.length,
        onReplay: () {
          setState(() {
            _index = 0;
            _stars = 0;
            _choiceCache.clear();
          });
          _present(first: true);
        },
        onHome: () => popLearningScreen(context),
      );
    } else {
      final item = items[_index];
      subtitle = '${_index + 1} / ${items.length}';
      body = _question(context, items, item);
    }
    return SessionBinder(
      subject: 'vietnamese',
      child: KidsHubShell(
        title: widget.title,
        subtitle: subtitle,
        accent: VimaiColor.sky,
        onBack: () => popLearningScreen(context),
        body: body,
      ),
    );
  }

  Widget _question(BuildContext context, List<ContentItem> items, ContentItem item) {
    final isBlend = widget.skill.contains('blend') || widget.skill.contains('phonics');
    final isSentence = widget.skill.contains('sentence');
    final picture = item.metadata?['image'] as String?;
    final choices = _choicesFor(items, _index);
    void hear() => unawaited(isBlend ? _playBlendParts(item) : _playItem(item));
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (_index / items.length).clamp(0, 1),
                  minHeight: 10,
                  color: VimaiColor.sky,
                  backgroundColor: VimaiColor.sky.withValues(alpha: 0.14),
                ),
              ),
              const SizedBox(height: 14),
              _HeroCard(
                picture: picture,
                text: item.question ?? item.answer ?? '',
                large: !isSentence,
                onTap: hear,
              ),
              const SizedBox(height: 12),
              ListenPrompt(
                // Formulas ("b + a = ?") already show on the card; say the how-to instead.
                text: item.instruction.contains('+') ? _howTo : item.instruction,
                lines: [item.instruction.contains('+') ? _howTo : item.instruction],
                color: VimaiColor.sky,
                style: VimaiType.subtitle,
                onTap: hear,
              ),
              if (isBlend && (item.onset.isNotEmpty || item.rime.isNotEmpty || item.syllable.isNotEmpty)) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (item.onset.isNotEmpty)
                      _BlendChip(
                        label: item.onset,
                        onTap: () async {
                          final id = AudioService.getAudioIdForLetter(item.onset);
                          final result = await ref.read(audioServiceProvider).playAsset(
                                id.isNotEmpty ? id : 'v_${item.onset.toLowerCase()}',
                              );
                          if (!context.mounted) return;
                          AudioService.notify(context, result);
                        },
                      ),
                    if (item.rime.isNotEmpty)
                      _BlendChip(
                        label: item.rime,
                        onTap: () async {
                          final id = AudioService.getAudioIdForLetter(item.rime);
                          final result = await ref.read(audioServiceProvider).playAsset(
                                id.isNotEmpty ? id : 'v_${item.rime.toLowerCase()}',
                              );
                          if (!context.mounted) return;
                          AudioService.notify(context, result);
                        },
                      ),
                    if (item.syllable.isNotEmpty)
                      _BlendChip(label: item.syllable, emphasized: true, onTap: () => _playItem(item)),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              if (isSentence)
                Column(
                  children: [
                    for (final c in choices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SentenceChoice(
                          text: c,
                          state: _lastChoice == c ? _lastCorrect : null,
                          onTap: () => _onChoice(item, c),
                        ),
                      ),
                  ],
                )
              else
                ChoiceGrid(
                  choices: choices,
                  color: VimaiColor.sky,
                  lastChoice: _lastChoice,
                  lastCorrect: _lastCorrect,
                  onSelected: (value) => _onChoice(item, value),
                ),
              LessonFeedback(correct: _lastCorrect, message: _feedback),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big picture + word the child is learning; tap to hear it again.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.picture, required this.text, required this.large, required this.onTap});

  final String? picture;
  final String text;
  final bool large;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Nghe: $text',
      borderRadius: BorderRadius.circular(VimaiRadius.xl),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE6F4FF), Color(0xFFFFF4E0)],
          ),
          borderRadius: BorderRadius.circular(VimaiRadius.xl),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: VimaiShadow.lift,
        ),
        child: Column(
          children: [
            if (picture != null && picture!.isNotEmpty)
              Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Text(picture!, style: const TextStyle(fontSize: 72)),
              ),
            if (picture != null && picture!.isNotEmpty) const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: (large ? VimaiType.display : VimaiType.title).copyWith(color: VimaiColor.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentenceChoice extends StatelessWidget {
  const _SentenceChoice({required this.text, required this.state, required this.onTap});

  final String text;
  final bool? state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = state == true
        ? VimaiColor.correct
        : state == false
            ? VimaiColor.retry
            : VimaiColor.sky;
    return Pressable(
      semanticLabel: text,
      borderRadius: BorderRadius.circular(VimaiRadius.pill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: VimaiMotion.of(context, VimaiMotion.feedback),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(VimaiRadius.pill),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: VimaiShadow.lift,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: VimaiType.cardTitle.copyWith(color: Colors.white, fontSize: 22),
        ),
      ),
    );
  }
}

class _FinishedPanel extends StatelessWidget {
  const _FinishedPanel({required this.stars, required this.total, required this.onReplay, required this.onHome});

  final int stars;
  final int total;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IdleMascot(mood: MascotMood.celebrating, color: VimaiColor.mascot, size: 110),
            const SizedBox(height: 12),
            Text('Con đã học hết phần này rồi! 🎉', textAlign: TextAlign.center, style: VimaiType.title),
            const SizedBox(height: 8),
            Text('⭐ $stars / $total', style: VimaiType.greeting.copyWith(color: VimaiColor.honey)),
            const SizedBox(height: 20),
            KidsPlayButton(label: 'Ôn lại', color: VimaiColor.sky, icon: Icons.replay_rounded, onPressed: onReplay),
            const SizedBox(height: 8),
            TextButton(onPressed: onHome, child: const Text('Về trang Tiếng Việt')),
          ],
        ),
      ),
    );
  }
}

class _BlendChip extends StatelessWidget {
  const _BlendChip({
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: emphasized ? AppTheme.primaryColor : const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: emphasized ? AppTheme.primaryColor : const Color(0xFF7DD3FC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: emphasized ? Colors.white : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}

class VietnameseLetterGameScreen extends ConsumerStatefulWidget {
  const VietnameseLetterGameScreen({super.key});

  @override
  ConsumerState<VietnameseLetterGameScreen> createState() => _VietnameseLetterGameScreenState();
}

class _VietnameseLetterGameScreenState extends ConsumerState<VietnameseLetterGameScreen> {
  final _answerTap = WebKitAnswerTap(holdDuration: const Duration(milliseconds: 500));
  ContentItem? _target;
  List<String> _choices = const [];
  String? _feedback;
  int _score = 0;
  int _wrong = 0;
  final _recent = <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _next());
  }

  @override
  void dispose() {
    _answerTap.dispose();
    try {
      ref.read(audioServiceProvider).stop();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _next() async {
    final letters = List<ContentItem>.from(ref.read(contentRepositoryProvider).getVietnameseAlphabet());
    if (letters.isEmpty) return;
    letters.shuffle();
    _target = letters.firstWhere((e) => !_recent.contains(e.id), orElse: () => letters.first);
    _recent.add(_target!.id);
    if (_recent.length > 6) _recent.removeAt(0);
    _choices = letters.take(4).map((e) => e.question ?? '').toList()..shuffle();
    if (!_choices.contains(_target!.question)) {
      _choices[0] = _target!.question ?? '';
      _choices.shuffle();
    }
    final first = _score == 0 && _wrong == 0 && _recent.length == 1;
    setState(() => _feedback = null);
    final audio = ref.read(audioServiceProvider);
    final letterId = AudioService.getAudioIdForLetter(_target!.question ?? _target!.letterName);
    if (letterId.isEmpty) {
      final result = await VietnamesePhonicsGuide.playPrimary(audio, _target!);
      if (mounted) AudioService.notify(context, result);
      return;
    }
    unawaited(audio.speak([if (first) KidGuide.listenPickLetter], trailIds: [letterId]));
  }

  @override
  Widget build(BuildContext context) {
    return SessionBinder(
      subject: 'vietnamese',
      child: Scaffold(
      appBar: AppBar(title: Text('Nghe chữ  •  $_score đúng / $_wrong sai')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(KidGuide.listenPickLetter, style: TextStyle(fontSize: 22)),
              IconButton(
                iconSize: 72,
                color: AppTheme.primaryColor,
                onPressed: _target == null
                    ? null
                    : () async {
                        final result = await VietnamesePhonicsGuide.playPrimary(ref.read(audioServiceProvider), _target!);
                        if (context.mounted) AudioService.notify(context, result);
                      },
                icon: const Icon(Icons.volume_up_rounded),
              ),
              if (_choices.isNotEmpty)
              ChoiceGrid(
                choices: _choices,
                onSelected: (value) {
                  if (_answerTap.locked) return;
                  final target = _target;
                  if (target == null) return;
                  final ok = value == target.question;
                  final profile = ref.read(currentProfileProvider);
                  final audio = ref.read(audioServiceProvider);

                  void sideEffects() {
                    if (profile == null) return;
                    unawaited(
                      ref.read(masteryRepositoryProvider).record(
                            childId: profile.id,
                            itemId: target.id,
                            skill: 'game.vietnamese_listen',
                            correct: ok,
                          ),
                    );
                  }

                  if (!ok) {
                    _answerTap.handleWrongAnswer(
                      setState: setState,
                      applyImmediateUi: () {
                        _feedback = 'Thử lại nhé! 💪';
                        _wrong++;
                      },
                      playSound: () => unawaited(audio.playRandomTryAgain()),
                      sideEffects: sideEffects,
                    );
                    return;
                  }

                  _answerTap.handleCorrectAnswer(
                    setState: setState,
                    applyImmediateUi: () {
                      _feedback = 'Đúng rồi! ⭐';
                      _score++;
                    },
                    playSound: () => unawaited(audio.playRandomSuccess()),
                    sideEffects: sideEffects,
                    isMounted: () => mounted,
                    advanceOrFinish: () {
                      // _next owns its own setState / audio prompt.
                      unawaited(_next());
                    },
                  );
                },
              ),
              if (_feedback != null) Text(_feedback!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _score = 0;
                    _wrong = 0;
                  });
                  _next();
                },
                child: const Text('Chơi lại'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

enum _ChooseMode { hearName, hearSound, letterToSound, letterToWord, recognize }

class VietnameseChooseLetterScreen extends ConsumerStatefulWidget {
  const VietnameseChooseLetterScreen({super.key});

  @override
  ConsumerState<VietnameseChooseLetterScreen> createState() => _VietnameseChooseLetterScreenState();
}

class _VietnameseChooseLetterScreenState extends ConsumerState<VietnameseChooseLetterScreen> {
  final _answerTap = WebKitAnswerTap(holdDuration: const Duration(milliseconds: 450));
  final _recent = <String>[];
  ContentItem? _target;
  List<String> _choices = const [];
  String? _prompt;
  String? _feedback;
  int _score = 0;
  int _wrong = 0;
  int _round = 0;
  _ChooseMode _mode = _ChooseMode.hearName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _next());
  }

  @override
  void dispose() {
    _answerTap.dispose();
    try {
      ref.read(audioServiceProvider).stop();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _next() async {
    final letters = List<ContentItem>.from(ref.read(contentRepositoryProvider).getVietnameseAlphabet());
    if (letters.isEmpty) return;
    letters.shuffle();
    var pick = letters.firstWhere((e) => !_recent.contains(e.id), orElse: () => letters.first);
    _recent.add(pick.id);
    if (_recent.length > 8) _recent.removeAt(0);
    _target = pick;
    _mode = _ChooseMode.values[_round % _ChooseMode.values.length];
    _round++;
    switch (_mode) {
      case _ChooseMode.hearName:
        _prompt = 'Nghe tên chữ, chọn chữ đúng';
        _choices = _letterChoices(letters, pick);
        break;
      case _ChooseMode.hearSound:
        _prompt = 'Nghe âm chữ, chọn chữ đúng';
        _choices = _letterChoices(letters, pick);
        break;
      case _ChooseMode.letterToSound:
        _prompt = 'Chữ ${pick.question} đọc âm nào?';
        final sounds = letters.map(VietnamesePhonicsGuide.primarySpoken).toSet().toList()..shuffle();
        _choices = <String>{VietnamesePhonicsGuide.primarySpoken(pick), ...sounds.take(3)}.toList()..shuffle();
        break;
      case _ChooseMode.letterToWord:
        _prompt = 'Chữ ${pick.question} có trong từ nào?';
        final words = letters.map((e) => e.exampleWord).where((e) => e.isNotEmpty).toSet().toList()..shuffle();
        _choices = <String>{pick.exampleWord, ...words.take(3)}.toList()..shuffle();
        break;
      case _ChooseMode.recognize:
        _prompt = 'Đâu là chữ ${pick.letterName}?';
        _choices = _letterChoices(letters, pick);
        break;
    }
    setState(() => _feedback = null);
    await _playPrompt();
  }

  List<String> _letterChoices(List<ContentItem> letters, ContentItem pick) {
    final others = letters.where((e) => e.id != pick.id).map((e) => e.question ?? '').toList()..shuffle();
    return <String>{pick.question ?? '', ...others.take(3)}.toList()..shuffle();
  }

  Future<void> _playPrompt() async {
    final target = _target;
    if (target == null) return;
    final audio = ref.read(audioServiceProvider);
    final letterId = AudioService.getAudioIdForLetter(target.question ?? target.letterName);
    if (letterId.isNotEmpty) {
      // Spoken prompt never names the letter, so it never gives the answer away.
      final spoken = switch (_mode) {
        _ChooseMode.hearName => KidGuide.hearLetterName,
        _ChooseMode.hearSound => KidGuide.hearLetterSound,
        _ChooseMode.letterToSound => KidGuide.letterWhichSound,
        _ChooseMode.letterToWord => KidGuide.letterInWord,
        _ChooseMode.recognize => KidGuide.findLetter,
      };
      final showsLetter = _mode == _ChooseMode.letterToSound || _mode == _ChooseMode.letterToWord;
      unawaited(audio.speak([spoken], trailIds: [if (!showsLetter) letterId]));
      return;
    }
    final AudioPlayResult result;
    switch (_mode) {
      case _ChooseMode.hearName:
      case _ChooseMode.recognize:
      case _ChooseMode.letterToSound:
      case _ChooseMode.letterToWord:
        result = letterId.isNotEmpty
            ? await audio.playAudio(letterId)
            : await audio.playVietnameseLetterName(target.question ?? target.letterName);
        break;
      case _ChooseMode.hearSound:
        result = letterId.isNotEmpty
            ? await audio.playAudio(letterId)
            : await audio.playVietnameseLetterSound(target.question ?? target.phoneme);
        break;
    }
    if (mounted) AudioService.notify(context, result);
  }

  String get _answer {
    final target = _target;
    if (target == null) return '';
    switch (_mode) {
      case _ChooseMode.hearName:
      case _ChooseMode.hearSound:
      case _ChooseMode.recognize:
        return target.question ?? '';
      case _ChooseMode.letterToSound:
        return VietnamesePhonicsGuide.primarySpoken(target);
      case _ChooseMode.letterToWord:
        return target.exampleWord;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SessionBinder(
      subject: 'vietnamese',
      child: Scaffold(
      appBar: AppBar(title: Text('Chọn chữ  •  $_score đúng / $_wrong sai')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(_prompt ?? 'Chọn chữ', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              IconButton(
                iconSize: 64,
                color: AppTheme.primaryColor,
                onPressed: _playPrompt,
                icon: const Icon(Icons.volume_up_rounded),
              ),
              if (_choices.isNotEmpty)
                ChoiceGrid(
                  choices: _choices,
                  onSelected: (value) {
                    if (_answerTap.locked) return;
                    final ok = value == _answer;
                    final target = _target;
                    final profile = ref.read(currentProfileProvider);
                    final audio = ref.read(audioServiceProvider);

                    void sideEffects() {
                      if (profile == null || target == null) return;
                      unawaited(
                        ref.read(masteryRepositoryProvider).record(
                              childId: profile.id,
                              itemId: target.id,
                              skill: 'vietnamese.choose_letter',
                              correct: ok,
                            ),
                      );
                    }

                    if (!ok) {
                      _answerTap.handleWrongAnswer(
                        setState: setState,
                        applyImmediateUi: () {
                          _feedback = 'Thử lại nhé! 💪';
                          _wrong++;
                        },
                        playSound: () => unawaited(audio.playRandomTryAgain()),
                        sideEffects: sideEffects,
                      );
                      return;
                    }

                    _answerTap.handleCorrectAnswer(
                      setState: setState,
                      applyImmediateUi: () {
                        _feedback = 'Đúng rồi! ⭐';
                        _score++;
                      },
                      playSound: () => unawaited(audio.playRandomSuccess()),
                      sideEffects: sideEffects,
                      isMounted: () => mounted,
                      advanceOrFinish: () {
                        unawaited(_next());
                      },
                    );
                  },
                ),
              if (_feedback != null) Text(_feedback!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _score = 0;
                    _wrong = 0;
                    _round = 0;
                    _recent.clear();
                  });
                  _next();
                },
                child: const Text('Chơi lại'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
