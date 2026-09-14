import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/providers.dart';
import '../../../core/routing/vimai_route_observer.dart';
import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/continue_learning.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/models/child_profile.dart';
import '../../shared/widgets/kids_living_canopy.dart';
import '../../shared/widgets/kids_storybook.dart';
import '../../shared/widgets/vimai_mascot.dart';

/// Vibrant storybook Home + ambient BGM (stops when leaving for lessons).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  bool _subscribed = false;
  AudioService? _audio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio ??= ref.read(audioServiceProvider);
    final route = ModalRoute.of(context);
    if (!_subscribed && route is PageRoute) {
      vimaiRouteObserver.subscribe(this, route);
      _subscribed = true;
    }
  }

  @override
  void dispose() {
    if (_subscribed) {
      vimaiRouteObserver.unsubscribe(this);
      _subscribed = false;
    }
    _audio?.stopHomeBgm();
    super.dispose();
  }

  @override
  void didPush() => _resumeBgm();

  @override
  void didPopNext() => _resumeBgm();

  @override
  void didPushNext() => _pauseBgm();

  @override
  void didPop() => _pauseBgm();

  void _resumeBgm() {
    final profile = ref.read(currentProfileProvider);
    final audio = ref.read(audioServiceProvider);
    audio.soundEnabled = profile?.soundEnabled ?? true;
    audio.bgmEnabled = profile?.bgmEnabled ?? true;
    audio.voiceVolume = profile?.voiceVolume ?? AudioService.defaultVoiceVolume;
    audio.bgmVolume = profile?.bgmVolume ?? AudioService.defaultBgmVolume;
    audio.startHomeBgm();
  }

  void _pauseBgm() {
    ref.read(audioServiceProvider).stopHomeBgm();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    if (profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/welcome');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final audio = ref.read(audioServiceProvider);
    audio.soundEnabled = profile.soundEnabled;
    audio.bgmEnabled = profile.bgmEnabled;
    audio.voiceVolume = profile.voiceVolume;
    audio.bgmVolume = profile.bgmVolume;

    final items = ref.watch(masteryRepositoryProvider).allForChild(profile.id);
    final copy = AppStrings.of(profile, context);
    final suggestion = ref.watch(continueLearningProvider);
    final mood = suggestion.isReview
        ? MascotMood.encouraging
        : (items.isEmpty ? MascotMood.excited : MascotMood.happy);
    final userName = profile.name.trim().isEmpty ? 'An' : profile.name.trim();

    final destinations = <CanopyDestination>[
      CanopyDestination(
        title: copy.vietnamese,
        subtitle: 'Bến Sông Tiếng Việt',
        color: const Color(0xFF3B9BDB),
        glyph: '🌊',
        artAsset: VimaiArt.vietnameseGarden,
        onTap: () async {
          await ref.read(currentProfileProvider.notifier).setLastWorld(LearningWorld.vietnamese.name);
          if (context.mounted) context.push('/vietnamese');
        },
      ),
      CanopyDestination(
        title: copy.japanese,
        subtitle: 'Vườn Anh Đào Kana',
        color: const Color(0xFFE86BA0),
        glyph: '🌸',
        artAsset: VimaiArt.japaneseVillage,
        onTap: () async {
          await ref.read(currentProfileProvider.notifier).setLastWorld(LearningWorld.japanese.name);
          if (context.mounted) context.push('/japanese');
        },
      ),
      CanopyDestination(
        title: copy.math,
        subtitle: 'Xưởng Số Vui Nhộn',
        color: const Color(0xFFFF7E40),
        glyph: '🔢',
        artAsset: VimaiArt.mathValley,
        onTap: () async {
          await ref.read(currentProfileProvider.notifier).setLastWorld(LearningWorld.math.name);
          if (context.mounted) context.push('/math');
        },
      ),
      CanopyDestination(
        title: '${copy.thinking} & ${copy.creativity}',
        subtitle: 'Hang Mộng Mơ',
        color: const Color(0xFF8B6CF0),
        glyph: '✨',
        artAsset: VimaiArt.thinkingCave,
        onTap: () async {
          await ref.read(currentProfileProvider.notifier).setLastWorld(LearningWorld.thinking.name);
          if (context.mounted) context.push('/thinking');
        },
      ),
      CanopyDestination(
        title: copy.games,
        subtitle: 'Hội Chợ Trò Chơi',
        color: const Color(0xFFF0A010),
        glyph: '🎪',
        artAsset: VimaiArt.gamesPlayground,
        onTap: () async {
          await ref.read(currentProfileProvider.notifier).setLastWorld(LearningWorld.games.name);
          if (context.mounted) context.push('/games');
        },
      ),
    ];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Immersive nature backdrop (not used for button coordinates).
          Image.asset(
            VimaiArt.homeWorld,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            cacheWidth: 1400,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFB8DCF5)),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66FFFFFF),
                  Color(0x33FDFBF4),
                  Color(0xAAF3F8E8),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: VimaiSpace.maxHome),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final short = constraints.maxHeight < 680;
                    final gap = (constraints.maxHeight * 0.012).clamp(4.0, 10.0);
                    final logoH = short
                        ? 34.0
                        : (MediaQuery.sizeOf(context).width >= 600 ? 48.0 : 40.0);

                    return Padding(
                      padding: EdgeInsets.fromLTRB(16, gap * 0.5, 16, gap),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              children: [
                                CanopyBgmToggle(
                                  enabled: profile.bgmEnabled,
                                  onChanged: (enabled) async {
                                    final settings = Map<String, dynamic>.from(profile.settings)..['bgm'] = enabled;
                                    await ref.read(currentProfileProvider.notifier).setProfile(
                                          profile.copyWith(settings: settings),
                                        );
                                    await ref.read(audioServiceProvider).setBgmEnabled(enabled);
                                  },
                                ),
                                Expanded(
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: short ? 4 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.88),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x221B3B2B),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: VimaiKidsLogo(height: logoH),
                                    ),
                                  ),
                                ),
                                ParentOakGate(
                                  label: copy.parent,
                                  onUnlocked: () {
                                    if (context.mounted) context.push('/parent');
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: gap),
                          Flexible(
                            flex: short ? 2 : 3,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: constraints.maxWidth - 32,
                                child: DiscoveryNest(
                                  mood: mood,
                                  mascotColor: mascotColorForAvatar(profile.avatar),
                                  greeting: 'Chào $userName! Hôm nay cùng khám phá nhé',
                                  trailing: _buildMaiAiToggle(context, profile),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: gap),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Thế giới khám phá',
                              textAlign: TextAlign.center,
                              style: VimaiType.title.copyWith(
                                color: VimaiColor.ink,
                                fontSize: short ? 18 : 22,
                                shadows: const [Shadow(color: Colors.white, blurRadius: 8)],
                              ),
                            ),
                          ),
                          SizedBox(height: gap * 0.8),
                          Expanded(
                            flex: short ? 10 : 12,
                            child: CanopyPathTrail(
                              destinations: destinations,
                              compact: short,
                            ),
                          ),
                          SizedBox(height: gap * 0.8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: short ? 4 : 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: VimaiCopyrightLine(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaiAiToggle(BuildContext context, ChildProfile profile) {
    final aiEnabled = profile.aiEnabled;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMaiAiModal(context, profile),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: aiEnabled ? const Color(0xFFFFF3E0) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: aiEnabled ? const Color(0xFFFFB74D) : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (aiEnabled ? const Color(0xFFFFB74D) : Colors.black).withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: aiEnabled ? const Color(0xFFFF6F00) : const Color(0xFF9E9E9E),
              ),
              const SizedBox(width: 4),
              Text(
                'Mai AI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: aiEnabled ? const Color(0xFFE65100) : const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMaiAiModal(BuildContext context, ChildProfile profile) {
    final suggestion = ref.read(continueLearningProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentProfile = ref.watch(currentProfileProvider) ?? profile;
            final enabled = currentProfile.aiEnabled;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFDF9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Color(0xFFFF6F00), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bạn Mai AI Trợ Lý',
                                style: VimaiType.title.copyWith(fontSize: 18, color: VimaiColor.ink),
                              ),
                              Text(
                                enabled ? 'Đang bật trợ lý học tập' : 'Trợ lý học tập đang tắt',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: enabled ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: enabled,
                          activeThumbColor: const Color(0xFFFF7E40),
                          onChanged: (val) async {
                            final settings = Map<String, dynamic>.from(currentProfile.settings)..['ai_enabled'] = val;
                            await ref.read(currentProfileProvider.notifier).setProfile(
                                  currentProfile.copyWith(settings: settings),
                                );
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFE0B2), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x10FF7E40), blurRadius: 10, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFA000), size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Gợi ý học tập hôm nay',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            suggestion.prompt.isNotEmpty
                                ? '${suggestion.glyph} ${suggestion.prompt}'
                                : 'Cùng khám phá các bài học thú vị hôm nay nhé!',
                            style: VimaiType.cardTitle.copyWith(fontSize: 15, color: VimaiColor.ink),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF7E40),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                context.push(suggestion.route);
                              },
                              icon: const Icon(Icons.play_arrow_rounded, size: 20),
                              label: const Text('Bắt đầu khám phá', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _quickTopicChip(
                          sheetContext,
                          emoji: '🌊',
                          label: 'Tiếng Việt',
                          route: '/vietnamese',
                        ),
                        _quickTopicChip(
                          sheetContext,
                          emoji: '🌸',
                          label: 'Tiếng Nhật',
                          route: '/japanese',
                        ),
                        _quickTopicChip(
                          sheetContext,
                          emoji: '🔢',
                          label: 'Toán học',
                          route: '/math',
                        ),
                        _quickTopicChip(
                          sheetContext,
                          emoji: '🎨',
                          label: 'Vẽ tranh',
                          route: '/creativity',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickTopicChip(
    BuildContext context, {
    required String emoji,
    required String label,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        this.context.push(route);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
