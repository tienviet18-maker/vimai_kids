import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_theme.dart';

class ReadScreen extends ConsumerWidget {
  final String kanaId;

  const ReadScreen({super.key, required this.kanaId});

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
            onPressed: () => context.pushReplacement('/kana/${kana.id}/recognize'),
            child: const Text('Tiếp theo ➡️', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🗣 Hãy đọc to lên nào!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 48),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  kana.character,
                  style: TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'Nhấn để nghe lại',
                style: TextStyle(fontSize: 24, color: AppTheme.textLight),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => audio.playJapaneseAsset(kana.audioId),
                icon: const Icon(Icons.volume_up),
                label: const Text('Nghe lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
