import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/routing/nav_utils.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/listen_prompt.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_ui.dart';
import '../data/explore_catalog.dart';
import '../explore_guide.dart';
import 'explore_widgets.dart';

const _hubColor = Color(0xFF3B9BE8);

/// "Khám phá thế giới": a shelf of big, colourful topic tiles.
class ExploreHubScreen extends ConsumerWidget {
  const ExploreHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(exploreCatalogProvider);
    final avatar = ref.watch(currentProfileProvider)?.avatar ?? '';
    void greet() => unawaited(ref.read(audioServiceProvider).speak([ExploreGuide.hub]));

    return SpeakOnOpen(
      lines: const [ExploreGuide.hub],
      child: Scaffold(
        backgroundColor: VimaiColor.bgWarmCream,
        body: ExploreBackdrop(
          color: _hubColor,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                ExploreTopBar(
                  title: 'Khám phá thế giới',
                  emoji: '🌍',
                  color: _hubColor,
                  onBack: () => popLearningScreen(context),
                ),
                Expanded(
                  child: catalog.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Chưa mở được thế giới, bé thử lại nhé.', style: VimaiType.title)),
                    data: (data) => _HubBody(
                      categories: data.categories,
                      mascotColor: mascotColorForAvatar(avatar),
                      onGreet: greet,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubBody extends StatelessWidget {
  const _HubBody({required this.categories, required this.mascotColor, required this.onGreet});

  final List<ExploreCategory> categories;
  final Color mascotColor;
  final VoidCallback onGreet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final columns = w < 520 ? 2 : (w < 820 ? 3 : 4);
        final gap = w < 520 ? 12.0 : 18.0;
        final side = w < 520 ? 14.0 : 24.0;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: VimaiSpace.maxHero),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 8, side, 14),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: MaiSays(
                          text: 'Bé muốn khám phá điều gì nào?',
                          mood: MascotMood.excited,
                          color: mascotColor,
                          mascotSize: w < 520 ? 76 : 96,
                          onTap: onGreet,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 0, side, 32),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: gap,
                      crossAxisSpacing: gap,
                      childAspectRatio: 0.92,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => ExplorePopIn(
                        index: i,
                        child: _CategoryTile(
                          category: categories[i],
                          onTap: () => context.push('/explore/${categories[i].id}'),
                        ),
                      ),
                      childCount: categories.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final ExploreCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = category.color;
    final deep = Color.lerp(c, Colors.black, 0.18)!;
    return Pressable(
      semanticLabel: category.title,
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(c, Colors.white, 0.18)!, deep],
          ),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(color: c.withValues(alpha: 0.38), blurRadius: 18, offset: const Offset(0, 9)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: LayoutBuilder(
            builder: (context, box) {
              final s = box.maxWidth;
              final hero = s * 0.4;
              final small = s * 0.17;
              final cover = category.cover;
              const spots = [Alignment(-0.78, -0.82), Alignment(0.8, -0.7), Alignment(0.82, 0.18)];
              return Stack(
                children: [
                  // Glossy light at the top-left, a soft hill at the bottom.
                  Positioned(
                    left: -s * 0.25,
                    top: -s * 0.3,
                    child: Container(
                      width: s * 0.9,
                      height: s * 0.9,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.16)),
                    ),
                  ),
                  Positioned(
                    left: -s * 0.2,
                    right: -s * 0.2,
                    bottom: -s * 0.55,
                    height: s * 0.9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.18)),
                    ),
                  ),
                  Positioned.fill(
                    bottom: box.maxHeight * 0.3,
                    child: Stack(
                      children: [
                        for (var i = 0; i < cover.length && i < spots.length; i++)
                          Align(
                            alignment: spots[i],
                            child: Transform.rotate(
                              angle: (i.isEven ? -0.18 : 0.16),
                              child: ExploreEmoji(cover[i], size: small),
                            ),
                          ),
                        Align(
                          alignment: const Alignment(-0.12, 0.35),
                          child: Container(
                            width: hero * 1.45,
                            height: hero * 1.45,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.9),
                              boxShadow: [
                                BoxShadow(
                                    color: deep.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))
                              ],
                            ),
                            child: ExploreEmoji(category.emoji, size: hero),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    height: box.maxHeight * 0.26,
                    child: Center(
                      child: Text(
                        category.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: VimaiType.title.copyWith(
                          color: Colors.white,
                          fontSize: (s * 0.1).clamp(15.0, 24.0),
                          height: 1.08,
                          shadows: [
                            Shadow(color: deep.withValues(alpha: 0.7), blurRadius: 6, offset: const Offset(0, 2))
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
