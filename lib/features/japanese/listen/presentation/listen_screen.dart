import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_theme.dart';

class ListenScreen extends ConsumerStatefulWidget {
  final String kanaId;

  const ListenScreen({super.key, required this.kanaId});

  @override
  ConsumerState<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends ConsumerState<ListenScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playAudio();
    });
  }

  void _playAudio() {
    final repo = ref.read(kanaRepositoryProvider);
    final audio = ref.read(audioServiceProvider);
    final kana = repo.getKanaById(widget.kanaId);
    if (kana != null) {
      audio.playJapaneseAsset(kana.audioId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(kanaRepositoryProvider);
    final kana = repo.getKanaById(widget.kanaId);

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
            onPressed: () => context.pushReplacement('/kana/${kana.id}/read'),
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
                'Cùng nghe nhé',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 8),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 12))
                  ],
                ),
                child: IconButton(
                  iconSize: 120,
                  color: color,
                  icon: const Icon(Icons.volume_up_rounded),
                  onPressed: _playAudio,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                kana.character,
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
