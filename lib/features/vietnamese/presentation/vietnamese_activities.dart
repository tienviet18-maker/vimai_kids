import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_locale_policy.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/kid_guide.dart';
import '../../../core/audio/speech_id.dart';
import '../../../core/audio/vietnamese_speech_catalog.dart';
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

/// The vi_say_* clip for [line], as a list (empty when it has none).
List<String> _lineClip(String line) {
  final id = SpeechId.idForLine(line);
  return id == null ? const [] : [id];
}

class _VietnameseQuizListScreenState extends ConsumerState<VietnameseQuizListScreen> {
  final _answerTap = WebKitAnswerTap(holdDuration: kPraiseHold);
  int _index = 0;

  /// Questions answered right on the first try this round: what the stars
  /// count. Counting after retries made every round 10/10.
  int _stars = 0;

  /// The child already tapped a wrong answer on the current question.
  bool _missed = false;

  /// Lessons run in rounds of [_roundSize] so a 3–7 year old finishes one.
  static const _roundSize = 10;
  int _roundStart = 0;
  int _roundEnd(int total) => min(_roundStart + _roundSize, total);
  String? _feedback;
  String? _lastChoice;
  bool? _lastCorrect;

  bool get _isBlend => widget.skill.contains('blend') || widget.skill.contains('phonics');
  bool get _isRime => widget.skill.contains('rime');
  bool get _isSentence => widget.skill.contains('sentence');

  /// Word and sentence tasks are listening tasks: the written answer stays
  /// hidden until found, with or without a picture.
  bool get _hidesAnswer => !_isBlend && !_isRime;

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

  /// The lesson's items. Ghép âm only keeps real blends (onset + rime): the
  /// whole words mixed into the phonics file showed their own answer.
  List<ContentItem> _items() {
    final items = widget.loader(ref);
    if (!_isBlend) return items;
    return items.where((e) => e.onset.trim().isNotEmpty && e.rime.trim().isNotEmpty).toList();
  }

  String get _howTo {
    if (_isBlend) return KidGuide.blendHowTo;
    if (_isRime) return KidGuide.rimeHowTo;
    if (_isSentence) return KidGuide.sentencePick;
    return KidGuide.wordHowTo;
  }

  /// What Mai says before the item: the full how-to on a round's first
  /// question (and when the child taps the prompt), then a short ask.
  String _spokenPrompt({required bool full}) {
    if (full) return _howTo;
    return _isSentence ? KidGuide.whichSentence : KidGuide.listenPickWord;
  }

  /// The clip that says this item (blend, rime, word or sentence).
  String _itemClipId(ContentItem item) {
    if (_isBlend) {
      return item.exampleWordAudioId.isNotEmpty
          ? item.exampleWordAudioId
          : (item.blendAudioId.isNotEmpty ? item.blendAudioId : item.audioId);
    }
    if (_isRime) return item.audioId.isNotEmpty ? item.audioId : 'v_rime_${item.rime}';
    if (item.exampleWordAudioId.isNotEmpty) return item.exampleWordAudioId;
    if (item.audioId.isNotEmpty) return item.audioId;
    return item.wordAudioId;
  }

  /// Clips for "short ask + item" of question [index], or the closing line.
  List<String> _promptClips(List<ContentItem> items, int index) {
    if (index >= _roundEnd(items.length)) return _lineClip(KidGuide.sessionDone);
    return [..._lineClip(_spokenPrompt(full: false)), _itemClipId(items[index])];
  }

  /// Mai says what to do, then the item itself ("Nghe và chọn từ đúng… mèo").
  void _present({bool first = false}) {
    if (!mounted) return;
    final items = _items();
    if (_index >= _roundEnd(items.length)) return;
    final item = items[_index];
    unawaited(
      ref.read(audioServiceProvider).speak([_spokenPrompt(full: first)], trailIds: [_itemClipId(item)]),
    );
  }

  /// The clip that says what the child tapped, when it is short enough to
  /// say before the praise or the nudge (a word, a syllable).
  List<String> _choiceClips(List<ContentItem> items, ContentItem item, String value) {
    if (_isSentence) return const [];
    if (value == item.answer) {
      // Ghép âm has just spelled the whole blend; a word's own clip says it best.
      if (_isBlend) return const [];
      if (!_isRime) return [_itemClipId(item)];
    }
    if (!_isBlend && !_isRime) {
      for (final other in items) {
        if (other.answer == value) return [_itemClipId(other)];
      }
    }
    return _lineClip(value);
  }

  Future<void> _playItem(ContentItem item) async {
    final audio = ref.read(audioServiceProvider);
    AudioPlayResult result;
    if (_isBlend) {
      final id = item.exampleWordAudioId.isNotEmpty
          ? item.exampleWordAudioId
          : (item.blendAudioId.isNotEmpty ? item.blendAudioId : item.audioId);
      result = await audio.playAsset(id);
    } else if (_isRime) {
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
      result = widget.skill.contains('word') || _isSentence
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
      }
    }
    await _playItem(item);
  }

  final _choiceCache = <int, List<String>>{};

  /// Choices for [index]; items without their own (or whose own include a
  /// second fitting answer) get other answers from the same list (stable
  /// per question). A blend with a tone ("b + a" → bà) never also offers
  /// the toneless syllable (ba), which reads "b + a" too.
  List<String> _choicesFor(List<ContentItem> items, int index) {
    return _choiceCache.putIfAbsent(index, () {
      final item = items[index];
      final answer = item.answer ?? item.question ?? '';
      final plain = _isBlend ? '${item.onset}${item.rime}'.trim().toLowerCase() : null;
      // A word with the same picture (👨 bố / ba) would fit the question too.
      final picture = item.metadata?['image'] as String?;
      final samePicture = {
        if (picture != null && picture.isNotEmpty)
          for (final e in items)
            if (e.metadata?['image'] == picture) e.answer ?? '',
      };
      bool fits(String a) =>
          a.isNotEmpty &&
          a != answer &&
          !samePicture.contains(a) &&
          (plain == null || answer.toLowerCase() == plain || a.toLowerCase() != plain);
      final own = item.choices ?? const <String>[];
      if (own.length >= 2 && own.where((c) => c != answer).every(fits)) return own;
      final others = items.map((e) => e.answer ?? '').where(fits).toSet().toList()
        ..shuffle(Random(index * 7919 + items.length));
      return [answer, ...others.take(_isSentence ? 2 : 3)]..shuffle(Random(index));
    });
  }

  void _onChoice(List<ContentItem> items, ContentItem item, String value) {
    if (_answerTap.locked) return;
    final ok = value == item.answer;
    final profile = ref.read(currentProfileProvider);
    final audio = ref.read(audioServiceProvider);
    final said = _choiceClips(items, item, value);

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
          _missed = true;
        },
        // What the child tapped, then the gentle nudge.
        playSound: () => unawaited(audio.playRandomTryAgain(leadIds: said)),
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
        if (!_missed) _stars++;
      },
      // One sequence: the word, the praise, then the next ask and item (or
      // the closing line). A prompt started on the advance timer cut the
      // praise off.
      playSound: () => unawaited(audio.playRandomSuccess(
            leadIds: said,
            trailIds: _promptClips(items, _index + 1),
          )),
      sideEffects: sideEffects,
      isMounted: () => mounted,
      advanceOrFinish: () {
        _index++;
        _feedback = null;
        _lastChoice = null;
        _lastCorrect = null;
        _missed = false;
        if (_index >= _roundEnd(items.length)) audio.sfx(Sfx.win);
      },
    );
  }

  void _restartRound({required int start}) {
    _answerTap.reset();
    setState(() {
      _roundStart = start;
      _index = start;
      _stars = 0;
      _missed = false;
      _feedback = null;
      _lastChoice = null;
      _lastCorrect = null;
      _choiceCache.clear();
    });
    _present(first: true);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items();
    final Widget body;
    String subtitle = '';
    if (items.isEmpty) {
      body = const Center(child: Text('Chưa có dữ liệu'));
    } else if (_index >= _roundEnd(items.length)) {
      final hasMore = _index < items.length;
      body = _FinishedPanel(
        stars: _stars,
        total: _roundEnd(items.length) - _roundStart,
        onContinue: hasMore ? () => _restartRound(start: _index) : null,
        onReplay: () => _restartRound(start: hasMore ? _roundStart : 0),
        onHome: () => popLearningScreen(context),
      );
    } else {
      final item = items[_index];
      subtitle = '${_index - _roundStart + 1} / ${_roundEnd(items.length) - _roundStart}';
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
    final picture = item.metadata?['image'] as String?;
    final choices = _choicesFor(items, _index);
    void hear() => unawaited(_isBlend ? _playBlendParts(item) : _playItem(item));
    void hearAll() => unawaited(
          ref.read(audioServiceProvider).speak([_spokenPrompt(full: true)], trailIds: [_itemClipId(item)]),
        );
    final tone = _isBlend ? _toneName(item) : null;
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
                  value: ((_index - _roundStart) / (_roundEnd(items.length) - _roundStart)).clamp(0, 1),
                  minHeight: 10,
                  color: VimaiColor.sky,
                  backgroundColor: VimaiColor.sky.withValues(alpha: 0.14),
                ),
              ),
              const SizedBox(height: 14),
              _HeroCard(
                picture: picture,
                // The child listens (and looks at the picture) and finds the
                // written word/sentence; the text appears once they get it.
                text: (_hidesAnswer && _lastCorrect != true) ? null : item.question ?? item.answer ?? '',
                large: !_isSentence,
                onTap: hear,
              ),
              const SizedBox(height: 12),
              ListenPrompt(
                text: _howTo,
                color: VimaiColor.sky,
                style: VimaiType.subtitle,
                onTap: hearAll,
              ),
              if (_isBlend && (item.onset.isNotEmpty || item.rime.isNotEmpty || item.syllable.isNotEmpty)) ...[
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
                    // "b + a" alone also reads "ba": show the tone that makes "bà".
                    if (tone != null) _BlendChip(label: 'dấu $tone', onTap: () => _playItem(item)),
                    // The joined syllable is the answer: show it only once found.
                    if (item.syllable.isNotEmpty && _lastCorrect == true)
                      _BlendChip(label: item.syllable, emphasized: true, onTap: () => _playItem(item)),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              if (_isSentence)
                Column(
                  children: [
                    for (final c in choices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SentenceChoice(
                          text: c,
                          state: _lastChoice == c ? _lastCorrect : null,
                          onTap: () => _onChoice(items, item, c),
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
                  onSelected: (value) => _onChoice(items, item, value),
                ),
              LessonFeedback(correct: _lastCorrect, message: _feedback),
            ],
          ),
        ),
      ),
    );
  }

  /// The tone a blend adds ("bờ - a - ba - huyền - bà" → huyền), or null.
  static String? _toneName(ContentItem item) {
    const tones = {'huyền', 'sắc', 'hỏi', 'ngã', 'nặng'};
    for (final p in item.audioText.split(' - ')) {
      if (tones.contains(p.trim())) return p.trim();
    }
    return null;
  }
}

/// Big picture + word the child is learning; tap to hear it again.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.picture, required this.text, required this.large, required this.onTap});

  final String? picture;
  final String? text;
  final bool large;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Nghe lại',
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
            if (text != null && picture != null && picture!.isNotEmpty) const SizedBox(height: 12),
            if (text != null)
              Text(
                text!,
                textAlign: TextAlign.center,
                style: (large ? VimaiType.display : VimaiType.title).copyWith(color: VimaiColor.ink),
              )
            else
              const Icon(Icons.hearing_rounded, color: VimaiColor.sky, size: 34),
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
  const _FinishedPanel({
    required this.stars,
    required this.total,
    required this.onReplay,
    required this.onHome,
    this.onContinue,
    this.message,
    this.replayLabel = 'Ôn lại',
  });

  final VoidCallback? onContinue;
  final String? message;
  final String replayLabel;
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
            Text(
              message ?? (onContinue != null ? 'Bé giỏi quá! Xong một chặng rồi! 🎉' : 'Con đã học hết phần này rồi! 🎉'),
              textAlign: TextAlign.center,
              style: VimaiType.title,
            ),
            const SizedBox(height: 8),
            Text('⭐ $stars / $total', style: VimaiType.greeting.copyWith(color: VimaiColor.honey)),
            const SizedBox(height: 20),
            if (onContinue != null) ...[
              KidsPlayButton(label: 'Học tiếp', color: VimaiColor.coral, onPressed: onContinue),
              const SizedBox(height: 10),
            ],
            KidsPlayButton(label: replayLabel, color: VimaiColor.sky, icon: Icons.replay_rounded, onPressed: onReplay),
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

/// Trò chơi tiếng Việt: hear a letter's sound, tap the letter. Ten in a row.
class VietnameseLetterGameScreen extends StatelessWidget {
  const VietnameseLetterGameScreen({super.key});

  @override
  Widget build(BuildContext context) => const VietnameseChooseLetterScreen(
        title: 'Nghe chữ',
        modes: [VietnameseChooseMode.hearSound],
        skill: 'game.vietnamese_listen',
      );
}

/// Question types of "Nhiều dạng bài". There is no letter-name mode: the
/// bundled letter clips say the sound ("bờ"), not the name ("bê"), so a
/// "hear the name" mode played the same clip as [hearSound].
enum VietnameseChooseMode { hearSound, letterToSound, letterToWord }

/// One question, built before it is shown so its prompt can be chained
/// after the praise for the previous one.
class _ChooseRound {
  _ChooseRound({
    required this.target,
    required this.mode,
    required this.choices,
    required this.clips,
    required this.answer,
    required this.prompt,
    required this.spoken,
  });

  final ContentItem target;
  final VietnameseChooseMode mode;
  final List<String> choices;

  /// The clip that says each choice (letter sound, sound, word).
  final Map<String, String> clips;
  final String answer;

  /// On screen / said by Mai (never names the letter to find).
  final String prompt;
  final String spoken;

  String get letterClip => AudioService.getAudioIdForLetter(target.question ?? target.letterName);

  /// The letter is on screen in these modes; in [VietnameseChooseMode.hearSound]
  /// the child only hears it.
  bool get showsLetter => mode != VietnameseChooseMode.hearSound;
}

/// Letters whose bundled clip says the same sound (C/K "cờ", I/Y "i") can
/// never be offered together: both would be right.
bool vietnameseLettersSoundAlike(ContentItem a, ContentItem b) =>
    VietnameseSpeechCatalog.soundSpoken(a.question ?? '') == VietnameseSpeechCatalog.soundSpoken(b.question ?? '');

class VietnameseChooseLetterScreen extends ConsumerStatefulWidget {
  const VietnameseChooseLetterScreen({
    super.key,
    this.title = 'Nhiều dạng bài',
    this.modes = VietnameseChooseMode.values,
    this.skill = 'vietnamese.choose_letter',
    this.random,
  });

  final String title;
  final List<VietnameseChooseMode> modes;
  final String skill;
  final Random? random;

  @override
  ConsumerState<VietnameseChooseLetterScreen> createState() => _VietnameseChooseLetterScreenState();
}

class _VietnameseChooseLetterScreenState extends ConsumerState<VietnameseChooseLetterScreen> {
  static const _goal = 10;

  final _answerTap = WebKitAnswerTap(holdDuration: kPraiseHold);
  final _recent = <String>[];
  late final Random _random = widget.random ?? Random();
  _ChooseRound? _round;
  String? _feedback;
  String? _lastChoice;
  bool? _lastCorrect;

  /// Questions done this set, and how many of them were right first try.
  int _done = 0;
  int _stars = 0;
  bool _missed = false;
  int _asked = 0;
  bool _speakerHintSaid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _round = _build());
      _playPrompt(first: true);
    });
  }

  @override
  void dispose() {
    _answerTap.dispose();
    try {
      ref.read(audioServiceProvider).stop();
    } catch (_) {}
    super.dispose();
  }

  _ChooseRound? _build() {
    final letters = List<ContentItem>.from(ref.read(contentRepositoryProvider).getVietnameseAlphabet());
    if (letters.isEmpty) return null;
    letters.shuffle(_random);
    final mode = widget.modes[_asked % widget.modes.length];
    _asked++;
    // "Chữ này đọc âm nào?" only for letters whose sound is not just the
    // letter itself (Ô → "ô" would be matching two identical marks).
    final pool = mode == VietnameseChooseMode.letterToSound
        ? letters.where((e) => VietnamesePhonicsGuide.primarySpoken(e) != e.lowercase).toList()
        : letters;
    final pick = pool.firstWhere((e) => !_recent.contains(e.id), orElse: () => pool.first);
    _recent.add(pick.id);
    if (_recent.length > 8) _recent.removeAt(0);
    final others = letters.where((e) => e.id != pick.id && !vietnameseLettersSoundAlike(e, pick)).toList();
    final clips = <String, String>{};
    switch (mode) {
      case VietnameseChooseMode.hearSound:
        final picked = [pick, ...others.take(3)];
        for (final l in picked) {
          clips[l.question ?? ''] = AudioService.getAudioIdForLetter(l.question ?? '');
        }
        return _ChooseRound(
          target: pick,
          mode: mode,
          choices: clips.keys.toList()..shuffle(_random),
          clips: clips,
          answer: pick.question ?? '',
          prompt: KidGuide.hearLetterSound,
          spoken: KidGuide.hearLetterSound,
        );
      case VietnameseChooseMode.letterToSound:
        // One letter per sound, so each written sound says one clip.
        final bySound = <String, ContentItem>{VietnamesePhonicsGuide.primarySpoken(pick): pick};
        for (final l in others) {
          if (bySound.length >= 4) break;
          final sound = VietnamesePhonicsGuide.primarySpoken(l);
          if (bySound.values.any((e) => vietnameseLettersSoundAlike(e, l))) continue;
          bySound.putIfAbsent(sound, () => l);
        }
        for (final e in bySound.entries) {
          clips[e.key] = AudioService.getAudioIdForLetter(e.value.question ?? '');
        }
        return _ChooseRound(
          target: pick,
          mode: mode,
          choices: clips.keys.toList()..shuffle(_random),
          clips: clips,
          answer: VietnamesePhonicsGuide.primarySpoken(pick),
          prompt: KidGuide.letterWhichSound,
          spoken: KidGuide.letterWhichSound,
        );
      case VietnameseChooseMode.letterToWord:
        clips[pick.exampleWord] = _wordClip(pick);
        // Distractors must not contain the letter too ("áo" and "cá" both have
        // a), nor a letter that sounds the same: heard aloud, "cá" also
        // starts with the K sound.
        final alike = [
          pick.lowercase,
          for (final l in letters)
            if (l.id != pick.id && vietnameseLettersSoundAlike(l, pick)) l.lowercase,
        ];
        for (final l in others) {
          if (clips.length >= 4) break;
          final w = l.exampleWord;
          if (w.isEmpty || clips.containsKey(w) || alike.any((x) => vietnameseWordHasLetter(w, x))) continue;
          clips[w] = _wordClip(l);
        }
        return _ChooseRound(
          target: pick,
          mode: mode,
          choices: clips.keys.toList()..shuffle(_random),
          clips: clips,
          answer: pick.exampleWord,
          prompt: KidGuide.letterInWord,
          spoken: KidGuide.letterInWord,
        );
    }
  }

  static String _wordClip(ContentItem letter) => letter.exampleWordAudioId.isNotEmpty
      ? letter.exampleWordAudioId
      : VietnameseSpeechCatalog.getAudioIdForWord(letter.exampleWord);

  /// Ask line (on the first question, or always when the type changes),
  /// then the letter's sound when the child has to find it by ear.
  List<String> _promptClips(_ChooseRound round, {required bool first}) {
    // The first question with written answers says how to hear them.
    final hint = round.showsLetter && !_speakerHintSaid;
    if (hint) _speakerHintSaid = true;
    return [
      if (first || widget.modes.length > 1) ..._lineClip(round.spoken),
      if (hint) ..._lineClip(KidGuide.tapSmallSpeaker),
      if (!round.showsLetter && round.letterClip.isNotEmpty) round.letterClip,
    ];
  }

  void _playPrompt({bool first = false}) {
    final round = _round;
    if (round == null) return;
    unawaited(ref.read(audioServiceProvider).speak(const [], leadIds: _promptClips(round, first: first)));
  }

  /// The speaker button: the ask, then the letter's sound again.
  void _replay() {
    final round = _round;
    if (round == null) return;
    unawaited(ref.read(audioServiceProvider).speak(const [], leadIds: [
      ..._lineClip(round.spoken),
      if (!round.showsLetter && round.letterClip.isNotEmpty) round.letterClip,
    ]));
  }

  void _onChoice(String value) {
    final round = _round;
    if (round == null || _answerTap.locked) return;
    final ok = value == round.answer;
    final profile = ref.read(currentProfileProvider);
    final audio = ref.read(audioServiceProvider);
    final said = [if (round.clips[value]?.isNotEmpty ?? false) round.clips[value]!];

    void sideEffects() {
      if (profile == null) return;
      unawaited(
        ref.read(masteryRepositoryProvider).record(
              childId: profile.id,
              itemId: round.target.id,
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
          _missed = true;
        },
        // What the child tapped, the nudge, then the sound to find again.
        playSound: () => unawaited(audio.playRandomTryAgain(
              leadIds: said,
              trailIds: [if (!round.showsLetter && round.letterClip.isNotEmpty) round.letterClip],
            )),
        sideEffects: sideEffects,
      );
      return;
    }

    final last = _done + 1 >= _goal;
    final upcoming = last ? null : _build();
    _answerTap.handleCorrectAnswer(
      setState: setState,
      applyImmediateUi: () {
        _feedback = 'Đúng rồi! ⭐';
        _lastChoice = value;
        _lastCorrect = true;
        if (!_missed) _stars++;
      },
      // One sequence: what was tapped, the praise, then the next question.
      playSound: () => unawaited(audio.playRandomSuccess(
            leadIds: said,
            trailIds: upcoming == null ? _lineClip(KidGuide.sessionDone) : _promptClips(upcoming, first: false),
          )),
      sideEffects: sideEffects,
      isMounted: () => mounted,
      advanceOrFinish: () {
        _done++;
        _feedback = null;
        _lastChoice = null;
        _lastCorrect = null;
        _missed = false;
        if (upcoming == null) {
          audio.sfx(Sfx.win);
        } else {
          _round = upcoming;
        }
      },
    );
  }

  void _restart() {
    _answerTap.reset();
    setState(() {
      _done = 0;
      _stars = 0;
      _asked = 0;
      _missed = false;
      _feedback = null;
      _lastChoice = null;
      _lastCorrect = null;
      _recent.clear();
      _round = _build();
    });
    _playPrompt(first: true);
  }

  @override
  Widget build(BuildContext context) {
    final round = _round;
    final finished = _done >= _goal;
    return SessionBinder(
      subject: 'vietnamese',
      child: KidsHubShell(
        title: widget.title,
        subtitle: finished || round == null ? '' : '${_done + 1} / $_goal',
        accent: VimaiColor.sky,
        onBack: () => popLearningScreen(context),
        body: finished
            ? _FinishedPanel(
                stars: _stars,
                total: _goal,
                message: 'Bé làm xong $_goal câu rồi! 🎉',
                replayLabel: 'Chơi tiếp',
                onReplay: _restart,
                onHome: () => popLearningScreen(context),
              )
            : round == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: _done / _goal,
                                minHeight: 10,
                                color: VimaiColor.sky,
                                backgroundColor: VimaiColor.sky.withValues(alpha: 0.14),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ListenPrompt(
                              text: round.prompt,
                              color: VimaiColor.sky,
                              onTap: _replay,
                              // "Chữ này…": the letter itself, big enough to read.
                              child: round.showsLetter
                                  ? Text(
                                      '${round.target.question}  ${round.target.lowercase}',
                                      style: VimaiType.display.copyWith(color: VimaiColor.ink, fontSize: 56),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            ChoiceGrid(
                              choices: round.choices,
                              color: VimaiColor.sky,
                              lastChoice: _lastChoice,
                              lastCorrect: _lastCorrect,
                              // Written sounds and words can be heard before
                              // choosing; letters to find by ear cannot (the
                              // badge would say the answer).
                              onHear: round.showsLetter
                                  ? (value) {
                                      final id = round.clips[value];
                                      if (id != null && id.isNotEmpty) {
                                        unawaited(ref.read(audioServiceProvider).speak(const [], leadIds: [id]));
                                      }
                                    }
                                  : null,
                              onSelected: _onChoice,
                            ),
                            LessonFeedback(correct: _lastCorrect, message: _feedback),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}

const _tonedVowels = {
  'a': 'àáảãạ', 'ă': 'ằắẳẵặ', 'â': 'ầấẩẫậ', 'e': 'èéẻẽẹ', 'ê': 'ềếểễệ', 'i': 'ìíỉĩị',
  'o': 'òóỏõọ', 'ô': 'ồốổỗộ', 'ơ': 'ờớởỡợ', 'u': 'ùúủũụ', 'ư': 'ừứửữự', 'y': 'ỳýỷỹỵ',
};

/// True when [word] contains the alphabet [letter], ignoring tone marks
/// ("cá" has a, "cờ" has ơ) but not hats/breves (ă and â are other letters).
bool vietnameseWordHasLetter(String word, String letter) {
  final l = letter.toLowerCase();
  if (l.isEmpty) return false;
  final toned = _tonedVowels[l] ?? '';
  for (final ch in word.toLowerCase().split('')) {
    if (ch == l || toned.contains(ch)) return true;
  }
  return false;
}
