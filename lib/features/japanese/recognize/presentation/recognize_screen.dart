import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../domain/models/kana_item.dart';

class RecognizeScreen extends ConsumerStatefulWidget {
  final String kanaId;

  const RecognizeScreen({super.key, required this.kanaId});

  @override
  ConsumerState<RecognizeScreen> createState() => _RecognizeScreenState();
}

class _RecognizeScreenState extends ConsumerState<RecognizeScreen> {
  List<KanaItem> _choices = [];
  bool _answered = false;
  bool _correct = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateChoices();
    });
  }

  void _generateChoices() {
    final repo = ref.read(kanaRepositoryProvider);
    final targetKana = repo.getKanaById(widget.kanaId);
    if (targetKana == null) return;

    final allKana = targetKana.script.name == 'hiragana' ? repo.getAllHiragana() : repo.getAllKatakana();
    final random = Random();
    
    final choices = <KanaItem>{targetKana};
    
    // Add confusion group if any
    if (targetKana.confusionGroup != null) {
      for (var char in targetKana.confusionGroup!) {
        final confKana = allKana.firstWhere((k) => k.character == char, orElse: () => allKana.first);
        if (confKana.id != targetKana.id) {
          choices.add(confKana);
        }
      }
    }

    // Fill the rest with random kana
    while (choices.length < 4) {
      choices.add(allKana[random.nextInt(allKana.length)]);
    }

    setState(() {
      _choices = choices.toList()..shuffle();
    });
    
    ref.read(audioServiceProvider).playJapaneseAsset(targetKana.audioId);
  }

  void _onChoiceSelected(KanaItem choice) {
    if (_answered) return;
    
    final targetKana = ref.read(kanaRepositoryProvider).getKanaById(widget.kanaId);
    final isCorrect = choice.id == targetKana?.id;
    
    setState(() {
      _answered = true;
      _correct = isCorrect;
    });

    final profile = ref.read(currentProfileProvider);
    if (profile != null && targetKana != null) {
      ref.read(masteryRepositoryProvider).record(
            childId: profile.id,
            itemId: targetKana.id,
            skill: 'japanese.recognize',
            correct: isCorrect,
          );
    }

    if (isCorrect) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.pushReplacement('/kana/${widget.kanaId}/write');
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _answered = false;
            _correct = false;
          });
          ref.read(audioServiceProvider).playJapaneseAsset(targetKana!.audioId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(kanaRepositoryProvider);
    final targetKana = repo.getKanaById(widget.kanaId);

    if (targetKana == null || _choices.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final color = targetKana.script.name == 'hiragana' ? AppTheme.hiraganaColor : AppTheme.katakanaColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Chữ nào đúng nhỉ?',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 32),
              IconButton(
                iconSize: 80,
                color: color,
                icon: const Icon(Icons.volume_up_rounded),
                onPressed: () => ref.read(audioServiceProvider).playJapaneseAsset(targetKana.audioId),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  children: _choices.map((choice) {
                    final isTarget = choice.id == targetKana.id;
                    Color cardColor = Colors.white;
                    if (_answered) {
                      if (isTarget) {
                        cardColor = Colors.green.shade100;
                      } else if (!isTarget && _correct == false) {
                        cardColor = Colors.red.shade100;
                      }
                    }

                    return GestureDetector(
                      onTap: () => _onChoiceSelected(choice),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: color.withValues(alpha: 0.3), width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          choice.character,
                          style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
