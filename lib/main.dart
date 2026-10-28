import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/audio/audio_service.dart';
import 'core/branding/config.dart';
import 'core/data_driven/data_driven_content_service.dart';
import 'core/in_app_browser/in_app_browser_banner.dart';
import 'core/providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'features/japanese/handwriting/stroke_order_catalog.dart';
import 'data/content/content_repository.dart';
import 'data/repositories/kana_repository_impl.dart';
import 'data/repositories/mastery_repository.dart';
import 'data/repositories/profile_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Kids Category (App Store 1.3 / 5.1.4): fonts are bundled in
  // assets/google_fonts/, so never contact fonts.gstatic.com at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
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
  // Critical feedback / system clips must be warm before first gesture on Safari.
  await audioService.preloadFeedbackAndSystemClips();
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
        // Safari/iOS: unlock Web Audio on first user gesture (same frame).
        unawaited(ref.read(audioServiceProvider).unlockWebAudioContext());
      },
      child: MaterialApp.router(
        title: AppBrand.productDisplayName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        scrollBehavior: const AppScrollBehavior(),
        routerConfig: goRouter,
        // Inside Messenger / Zalo...: open in Safari / Chrome.
        builder: (context, child) => Stack(
          children: [
            if (child != null) child,
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: InAppBrowserBanner(languageCode: 'vi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Backward-compatible names for existing tests.
typedef MaiAnApp = ViMaiKidsApp;
typedef HocVuiApp = ViMaiKidsApp;
