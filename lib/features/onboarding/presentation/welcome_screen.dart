import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../shared/widgets/kids_scene.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_world.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VimaiColor.skyTop,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            VimaiArt.homeWorld,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            cacheWidth: 1000,
            errorBuilder: (_, __, ___) => const WorldSky(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  VimaiColor.ink.withValues(alpha: 0.28),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: VimaiSpace.maxContent),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      const IdleMascot(mood: MascotMood.excited, color: VimaiColor.mascot, size: 140),
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: VimaiColor.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                          child: Column(
                            children: [
                              Text('ViMai Kids', style: VimaiType.greeting, textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              Text('Chào mừng con!', style: VimaiType.title, textAlign: TextAlign.center),
                              const SizedBox(height: 6),
                              Text('Cùng Mai học vui mỗi ngày nhé', style: VimaiType.subtitle, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
                      SizedBox(
                        width: double.infinity,
                        child: KidsPlayButton(
                          label: 'Bắt đầu nào!',
                          color: VimaiColor.coral,
                          expanded: true,
                          onPressed: () => context.push('/onboarding/create_profile'),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
