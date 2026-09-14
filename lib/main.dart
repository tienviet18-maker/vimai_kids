import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/audio/audio_service.dart';
import 'core/branding/config.dart';
import 'core/data_driven/data_driven_content_service.dart';
import 'core/providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/japanese/handwriting/stroke_order_catalog.dart';
import 'data/content/content_repository.dart';
import 'data/repositories/kana_repository_impl.dart';
import 'data/repositories/mastery_repository.dart';
import 'data/repositories/profile_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final kanaRepo = KanaRepositoryImpl();
  await kanaRepo.init();

  final contentRepo = ContentRepository();
  await contentRepo.loadAllContent();

  final profileRepo = ProfileRepository();
  await profileRepo.init();

  final masteryRepo = MasteryRepository();
  await masteryRepo.init();

  final audioService = AudioService();
  await audioService.init();
  await StrokeOrderCatalog.ensureLoaded();

  final dataDrivenService = DataDrivenContentService();
  await dataDrivenService.init();

  runApp(
    ProviderScope(
      overrides: [
        kanaRepositoryProvider.overrideWithValue(kanaRepo),
        contentRepositoryProvider.overrideWithValue(contentRepo),
        profileRepositoryProvider.overrideWithValue(profileRepo),
        masteryRepositoryProvider.overrideWithValue(masteryRepo),
        audioServiceProvider.overrideWithValue(audioService),
        dataDrivenContentServiceProvider.overrideWithValue(dataDrivenService),
      ],
        child: const ViMaiKidsApp(),
    ),
  );
}

class ViMaiKidsApp extends ConsumerWidget {
  const ViMaiKidsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        // Safari/iOS: unlock Web Audio on first user gesture.
        unawaited(ref.read(audioServiceProvider).unlockWebAudioContext());
      },
      child: MaterialApp.router(
        title: AppBrand.productDisplayName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        routerConfig: goRouter,
      ),
    );
  }
}

/// Backward-compatible names for existing tests.
typedef MaiAnApp = ViMaiKidsApp;
typedef HocVuiApp = ViMaiKidsApp;
