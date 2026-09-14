import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_locale_policy.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/vietnamese_phonics_guide.dart';
import '../../../core/providers.dart';
import '../../../core/session/session_binder.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/content/content_item.dart';
import '../../shared/widgets/choice_grid.dart';
import '../../shared/widgets/vimai_ui.dart';

class VietnameseAlphabetGridScreen extends ConsumerWidget {
  const VietnameseAlphabetGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final letters = ref.watch(contentRepositoryProvider).getVietnameseAlphabet();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
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
  int _index = 0;
  String? _feedback;

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

  @override
  Widget build(BuildContext context) {
    final items = widget.loader(ref);
    if (items.isEmpty) {
      return SessionBinder(
        subject: 'vietnamese',
        child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('Chưa có dữ liệu')),
      ),
      );
    }
    if (_index >= items.length) {
      return SessionBinder(
        subject: 'vietnamese',
        child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Con đã học hết phần này rồi! 🎉', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => setState(() => _index = 0), child: const Text('Ôn lại')),
              TextButton(onPressed: () => context.go('/vietnamese'), child: const Text('Về trang Tiếng Việt')),
            ],
          ),
        ),
      ),
      );
    }
    final item = items[_index];
    final isBlend = widget.skill.contains('blend') || widget.skill.contains('phonics');
    return SessionBinder(
      subject: 'vietnamese',
      child: Scaffold(
      appBar: AppBar(title: Text('${widget.title}  ${_index + 1}/${items.length}')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(item.instruction, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              if (item.question != null && item.question != item.instruction)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Pressable(
                    semanticLabel: item.question!,
                    onTap: () => isBlend ? _playBlendParts(item) : _playItem(item),
                    child: Text(item.question!, style: const TextStyle(fontSize: 32)),
                  ),
                ),
              const SizedBox(height: 16),
              IconButton(
                iconSize: 64,
                color: AppTheme.primaryColor,
                onPressed: () => isBlend ? _playBlendParts(item) : _playItem(item),
                icon: const Icon(Icons.volume_up_rounded),
              ),
              if (isBlend && (item.onset.isNotEmpty || item.rime.isNotEmpty || item.syllable.isNotEmpty)) ...[
                const SizedBox(height: 8),
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
                      _BlendChip(
                        label: item.syllable,
                        emphasized: true,
                        onTap: () => _playItem(item),
                      ),
                  ],
                ),
              ],
              ChoiceGrid(
                choices: item.choices ?? [item.answer ?? ''],
                onSelected: (value) async {
                  final ok = value == item.answer;
                  final profile = ref.read(currentProfileProvider);
                  if (profile != null) {
                    await ref.read(masteryRepositoryProvider).record(
                          childId: profile.id,
                          itemId: item.id,
                          skill: widget.skill,
                          correct: ok,
                        );
                  }
                  setState(() => _feedback = ok ? 'Đúng rồi! ⭐' : 'Thử lại nhé! 💪');
                  if (ok) {
                    await Future<void>.delayed(const Duration(milliseconds: 600));
                    if (mounted) {
                      setState(() {
                        _index++;
                        _feedback = null;
                      });
                    }
                  }
                },
              ),
              if (_feedback != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_feedback!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
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
    setState(() => _feedback = null);
    final audio = ref.read(audioServiceProvider);
    final result = await VietnamesePhonicsGuide.playPrimary(audio, _target!);
    if (mounted) AudioService.notify(context, result);
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
              const Text('Nghe rồi chọn chữ đúng', style: TextStyle(fontSize: 22)),
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
                onSelected: (value) async {
                  final target = _target;
                  if (target == null) return;
                  final ok = value == target.question;
                  final profile = ref.read(currentProfileProvider);
                  if (profile != null) {
                    await ref.read(masteryRepositoryProvider).record(
                          childId: profile.id,
                          itemId: target.id,
                          skill: 'game.vietnamese_listen',
                          correct: ok,
                        );
                  }
                  setState(() {
                    _feedback = ok ? 'Đúng rồi! ⭐' : 'Thử lại nhé! 💪';
                    if (ok) {
                      _score++;
                    } else {
                      _wrong++;
                    }
                  });
                  if (ok) {
                    await Future<void>.delayed(const Duration(milliseconds: 500));
                    if (mounted) _next();
                  }
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
                  onSelected: (value) async {
                    final ok = value == _answer;
                    final target = _target;
                    final profile = ref.read(currentProfileProvider);
                    if (profile != null && target != null) {
                      await ref.read(masteryRepositoryProvider).record(
                            childId: profile.id,
                            itemId: target.id,
                            skill: 'vietnamese.choose_letter',
                            correct: ok,
                          );
                    }
                    setState(() {
                      _feedback = ok ? 'Đúng rồi! ⭐' : 'Thử lại nhé! 💪';
                      if (ok) {
                        _score++;
                      } else {
                        _wrong++;
                      }
                    });
                    if (ok) {
                      await Future<void>.delayed(const Duration(milliseconds: 450));
                      if (mounted) _next();
                    }
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
