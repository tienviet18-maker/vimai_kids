import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/audio_service.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/kana_item.dart';

class KanaLibraryScreen extends ConsumerWidget {
  final KanaScript script;

  const KanaLibraryScreen({super.key, required this.script});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(kanaRepositoryProvider);
    final items = script == KanaScript.hiragana ? repo.getAllHiragana() : repo.getAllKatakana();

    final title = script == KanaScript.hiragana ? 'Bảng chữ Hiragana' : 'Bảng chữ Katakana';
    final color = script == KanaScript.hiragana ? AppTheme.hiraganaColor : AppTheme.katakanaColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text(title),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 100,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _KanaLibraryCard(item: item, color: color);
          },
        ),
      ),
    );
  }
}

class _KanaLibraryCard extends ConsumerWidget {
  final KanaItem item;
  final Color color;

  const _KanaLibraryCard({required this.item, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/japanese/learn/${item.script.name}?id=${item.id}&type=${item.kanaType.name}'),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 14),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.character,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color, height: 1.05),
                        ),
                        Text(
                          item.romaji,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textLight, height: 1.1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final result = await ref.read(audioServiceProvider).playAsset(item.audioId);
                    if (context.mounted) AudioService.notify(context, result);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 16,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
