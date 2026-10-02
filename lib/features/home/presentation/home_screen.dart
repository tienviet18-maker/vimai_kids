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
import 'discovery_islands.dart';

/// Home: Mai guides the child across an archipelago of six learning worlds.
/// Ambient BGM plays here and stops when a world opens.
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
  void didPush() => _onVisible();

  @override
  void didPopNext() => _onVisible();

  void _onVisible() {
    // Mastery changes while a world is open; refresh Mai's suggestion on return.
    ref.invalidate(continueLearningProvider);
    _resumeBgm();
  }

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

  MascotMood? _maiReaction;

  void _onMaiTap() {
    ref.read(audioServiceProvider).playFireAndForget('sys_welcome_back');
    setState(() => _maiReaction = MascotMood.excited);
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _maiReaction = null);
    });
  }

  Future<void> _openWorld(LearningWorld world, String route) async {
    await ref.read(currentProfileProvider.notifier).setLastWorld(world.name);
    if (mounted) context.push(route);
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
    final mood = _maiReaction ??
        (suggestion.isReview ? MascotMood.encouraging : (items.isEmpty ? MascotMood.excited : MascotMood.happy));
    final userName = profile.name.trim().isEmpty ? 'An' : profile.name.trim();
    final visited = {
      for (final m in items)
        if (m.attempts > 0) ContinueLearningRecommender.worldNameFor(m),
    };
    final suggested = suggestion.needsChoice ? null : suggestion.world;

    IslandSpec island(LearningWorld world, String title, String glyph, Color color, String art, String route) {
      return IslandSpec(
        id: world.name,
        title: title,
        glyph: glyph,
        color: color,
        art: art,
        visited: visited.contains(world.name),
        suggested: suggested == world,
        onTap: () => _openWorld(world, route),
      );
    }

    // Order is the stepping-stone trail: language → numbers → mind → making → play.
    final islands = <IslandSpec>[
      island(LearningWorld.vietnamese, copy.vietnamese, 'A', const Color(0xFF2F8FD8), VimaiArt.islandVietnamese, '/vietnamese'),
      island(LearningWorld.japanese, copy.japanese, 'あ', const Color(0xFFE2558F), VimaiArt.islandJapanese, '/japanese'),
      island(LearningWorld.math, copy.math, '123', const Color(0xFFF07A2E), VimaiArt.islandMath, '/math'),
      island(LearningWorld.thinking, copy.thinking, '?', const Color(0xFF7B5CE6), VimaiArt.islandThinking, '/thinking'),
      island(LearningWorld.creativity, copy.creativity, '✎', const Color(0xFF18A57A), VimaiArt.islandCreativity, '/creativity'),
      island(LearningWorld.games, copy.games, '★', const Color(0xFFE39B1A), VimaiArt.islandGames, '/games'),
    ];

    final greeting = 'Chào $userName! Hôm nay cùng khám phá nhé';
    final hasNext = !suggestion.needsChoice && suggestion.route != '/home';
    final hint = hasNext ? null : 'Chạm vào một hòn đảo nào!';

    Widget guide({required bool vertical, required double mascot}) => MaiGuide(
          vertical: vertical,
          mascotSize: mascot,
          mood: mood,
          mascotColor: mascotColorForAvatar(profile.avatar),
          greeting: greeting,
          hint: hint,
          actionLabel: hasNext ? suggestion.prompt : null,
          actionGlyph: hasNext ? suggestion.glyph : null,
          actionColor: islands.firstWhere((e) => e.id == suggestion.world.name, orElse: () => islands.first).color,
          onAction: hasNext ? () => _openWorld(suggestion.world, suggestion.route) : null,
          onMaiTap: _onMaiTap,
          trailing: _buildMaiAiToggle(context, profile),
        );

    return Scaffold(
      backgroundColor: const Color(0xFF9AD8FF),
      body: LayoutBuilder(
        builder: (context, outer) {
          final wide = outer.maxWidth > outer.maxHeight * 1.15 && outer.maxWidth >= 700;
          return Stack(
            fit: StackFit.expand,
            children: [
              DiscoverySeaBackground(horizon: wide ? 0.3 : 0.22),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: VimaiSpace.maxHome),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final short = constraints.maxHeight < 680;
                        final logoH = short ? 40.0 : (wide ? 56.0 : 48.0);
                        final topBar = _TopBar(
                          logoHeight: logoH,
                          profile: profile,
                          parentLabel: copy.parent,
                          onBgmChanged: (enabled) async {
                            final settings = Map<String, dynamic>.from(profile.settings)..['bgm'] = enabled;
                            await ref.read(currentProfileProvider.notifier).setProfile(
                                  profile.copyWith(settings: settings),
                                );
                            await ref.read(audioServiceProvider).setBgmEnabled(enabled);
                          },
                          onParent: () {
                            if (context.mounted) context.push('/parent');
                          },
                        );

                        if (wide) {
                          final guideW = (constraints.maxWidth * 0.3).clamp(260.0, 380.0);
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                            child: Column(
                              children: [
                                topBar,
                                Expanded(
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: guideW,
                                        child: Center(
                                          child: SingleChildScrollView(
                                            child: guide(vertical: true, mascot: short ? 96 : 124),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: DiscoveryArchipelago(islands: islands),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const _Footer(),
                              ],
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              topBar,
                              SizedBox(height: short ? 4 : 10),
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 560),
                                  child: guide(vertical: false, mascot: short ? 64 : (constraints.maxWidth >= 600 ? 112 : 84)),
                                ),
                              ),
                              SizedBox(height: short ? 2 : 8),
                              Expanded(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 620),
                                    child: DiscoveryArchipelago(islands: islands),
                                  ),
                                ),
                              ),
                              const _Footer(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMaiAiToggle(BuildContext context, ChildProfile profile) {
    final aiEnabled = profile.aiEnabled;
    return TactileNode(
      semanticLabel: 'Mai AI',
      minSize: 44,
      onTap: () => _showMaiAiModal(context, profile),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: aiEnabled ? const Color(0xFFFFF3E0) : const Color(0xFFF5F5F5),
          shape: BoxShape.circle,
          border: Border.all(color: aiEnabled ? const Color(0xFFFFB74D) : const Color(0xFFE0E0E0), width: 1.5),
        ),
        child: Icon(
          Icons.auto_awesome,
          size: 20,
          color: aiEnabled ? const Color(0xFFFF6F00) : const Color(0xFF9E9E9E),
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
          builder: (context, _) {
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
                                enabled ? 'Đang bật trợ lý học tập' : 'Bố mẹ có thể bật trong mục Phụ huynh',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: enabled ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.logoHeight,
    required this.profile,
    required this.parentLabel,
    required this.onBgmChanged,
    required this.onParent,
  });

  final double logoHeight;
  final ChildProfile profile;
  final String parentLabel;
  final ValueChanged<bool> onBgmChanged;
  final VoidCallback onParent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CanopyBgmToggle(enabled: profile.bgmEnabled, onChanged: onBgmChanged),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(VimaiRadius.pill),
                boxShadow: const [BoxShadow(color: Color(0x261B3B5B), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: VimaiKidsLogo(height: logoHeight),
            ),
          ),
        ),
        ParentOakGate(label: parentLabel, onUnlocked: onParent),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(VimaiRadius.pill),
        ),
        child: const FittedBox(fit: BoxFit.scaleDown, child: VimaiCopyrightLine()),
      ),
    );
  }
}
