import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/kana/kana_examples.dart';

class LookScreen extends ConsumerWidget {
  final String kanaId;

  const LookScreen({super.key, required this.kanaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(kanaRepositoryProvider);
    final audio = ref.watch(audioServiceProvider);
    final kana = repo.getKanaById(kanaId);

    if (kana == null) {
      return const Scaffold(body: Center(child: Text('Không tìm thấy')));
    }

    final color = kana.script.name == 'hiragana' ? AppTheme.hiraganaColor : AppTheme.katakanaColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pushReplacement('/kana/${kana.id}/listen'),
            child: const Text('Tiếp theo ➡️', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Breakpoints.kanaFontSize(constraints);
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        kana.character,
                        style: TextStyle(fontSize: size, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(kana.romaji, style: const TextStyle(fontSize: 28, color: AppTheme.textLight)),
                    const SizedBox(height: 24),
                    IconButton(
                      iconSize: 72,
                      color: color,
                      icon: const Icon(Icons.volume_up_rounded),
                      onPressed: () => audio.playJapaneseAsset(kana.audioId),
                    ),
                    if ((kana.resolvedExampleWord.isNotEmpty
                            ? kana.resolvedExampleWord
                            : KanaExamples.wordFor(kana.character))
                        .isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Ví dụ: ${kana.resolvedExampleWord.isNotEmpty ? kana.resolvedExampleWord : KanaExamples.wordFor(kana.character)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        kana.resolvedExampleMeaning.isNotEmpty
                            ? kana.resolvedExampleMeaning
                            : KanaExamples.meaningFor(kana.character),
                        style: const TextStyle(fontSize: 16, color: AppTheme.textLight),
                      ),
                      IconButton(
                        iconSize: 48,
                        color: color,
                        icon: const Icon(Icons.record_voice_over_rounded),
                        onPressed: () {
                          final id = kana.exampleWordAudioId?.trim().isNotEmpty == true
                              ? kana.exampleWordAudioId!
                              : KanaExamples.audioIdFor(kana.character);
                          if (id.isNotEmpty) {
                            audio.playAsset(id);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
