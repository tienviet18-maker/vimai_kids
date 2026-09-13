import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/repositories/profile_repository.dart';
import 'widgets/writing_canvas.dart';

class WritingScreen extends ConsumerWidget {
  final String kanaId;

  const WritingScreen({super.key, required this.kanaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(kanaRepositoryProvider);
    final kana = repo.getKanaById(kanaId);

    if (kana == null) {
      return const Scaffold(body: Center(child: Text('Không tìm thấy')));
    }

    final color = kana.script.name == 'hiragana' ? AppTheme.hiraganaColor : AppTheme.katakanaColor;

    Future<void> finish(bool good) async {
      final profile = ref.read(currentProfileProvider);
      if (profile != null) {
        await ref.read(masteryRepositoryProvider).record(
              childId: profile.id,
              itemId: kana.id,
              skill: 'japanese.writing',
              correct: good,
            );
      }
      if (context.mounted) context.pop();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: const Text('Cùng tập viết nào'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(kana.character, style: TextStyle(fontSize: 72, color: color, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
              WritingCanvas(key: ValueKey(kana.character), strokeColor: color, onCleared: () {}),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => finish(false),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    child: const Text('Chưa đẹp'),
                  ),
                  ElevatedButton(
                    onPressed: () => finish(true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Rất đẹp!'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
