import 'dart:async';
import 'dart:math' as math;

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

String _heroTag(ExploreCategory c, ExploreItem i) => 'explore-${c.id}-${i.id}';

/// One topic: a wall of big picture cards. Tapping a card zooms it into a
/// story card where Mai says its name and a fun fact.
class ExploreCategoryScreen extends ConsumerWidget {
  const ExploreCategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(exploreCatalogProvider);
    return catalog.when(
      loading: () =>
          const Scaffold(backgroundColor: VimaiColor.bgWarmCream, body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const _Missing(),
      data: (data) {
        final category = data.byId(categoryId);
        if (category == null) return const _Missing();
        return SpeakOnOpen(
          lines: [category.title, ExploreGuide.category],
          child: _CategoryView(category: category),
        );
      },
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VimaiColor.bgWarmCream,
      body: SafeArea(
        child: Column(
          children: [
            ExploreTopBar(
                title: 'Khám phá', emoji: '🌍', color: VimaiColor.sky, onBack: () => popLearningScreen(context)),
            const Expanded(child: Center(child: ExploreEmoji('🧭', size: 96))),
          ],
        ),
      ),
    );
  }
}

class _CategoryView extends ConsumerWidget {
  const _CategoryView({required this.category});

  final ExploreCategory category;

  void _open(BuildContext context, int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: false,
        transitionDuration: VimaiMotion.of(context, const Duration(milliseconds: 460)),
        reverseTransitionDuration: VimaiMotion.of(context, VimaiMotion.page),
        pageBuilder: (context, animation, _) => ExploreCardViewer(category: category, initialIndex: index),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = category.color;
    return Scaffold(
      backgroundColor: VimaiColor.bgWarmCream,
      body: ExploreBackdrop(
        color: color,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  ExploreTopBar(
                    title: category.title,
                    emoji: category.emoji,
                    color: color,
                    onBack: () => popLearningScreen(context),
                    trailing: ExploreRoundButton(
                      icon: Icons.volume_up_rounded,
                      semanticLabel: 'Nghe lại',
                      color: Colors.white,
                      background: color,
                      onTap: () => unawaited(
                        ref.read(audioServiceProvider).speak([category.title, ExploreGuide.category]),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final columns = w < 480 ? 2 : (w < 760 ? 3 : (w < 1100 ? 4 : 5));
                        final gap = w < 480 ? 12.0 : 18.0;
                        final side = w < 480 ? 14.0 : 24.0;
                        return Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: VimaiSpace.maxHero),
                            child: CustomScrollView(
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding: EdgeInsets.fromLTRB(side, 6, side, 12),
                                  sliver: SliverToBoxAdapter(
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 620),
                                        child: MaiSays(
                                          text: ExploreGuide.category,
                                          color: mascotColorForAvatar(ref.watch(currentProfileProvider)?.avatar ?? ''),
                                          mascotSize: w < 480 ? 64 : 84,
                                          onTap: () => unawaited(
                                            ref
                                                .read(audioServiceProvider)
                                                .speak([category.title, ExploreGuide.category]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: EdgeInsets.fromLTRB(side, 0, side, 120),
                                  sliver: SliverGrid(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      mainAxisSpacing: gap,
                                      crossAxisSpacing: gap,
                                      childAspectRatio: 0.86,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, i) => ExplorePopIn(
                                        index: i,
                                        child: _ItemCard(
                                          category: category,
                                          item: category.items[i],
                                          onTap: () => _open(context, i),
                                        ),
                                      ),
                                      childCount: category.items.length,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 18 + MediaQuery.paddingOf(context).bottom,
                child: Center(
                  child: _QuizLaunchButton(
                    color: color,
                    onTap: () => context.push('/explore/${category.id}/quiz'),
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

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.category, required this.item, required this.onTap});

  final ExploreCategory category;
  final ExploreItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = category.color;
    return Pressable(
      semanticLabel: item.name,
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final s = box.maxWidth;
            final circle = s * 0.74;
            return Column(
              children: [
                SizedBox(height: s * 0.07),
                Hero(
                  tag: _heroTag(category, item),
                  child: _EmojiDisc(emoji: item.emoji, color: c, size: circle),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: VimaiType.cardTitle.copyWith(
                          fontSize: (s * 0.1).clamp(14.0, 20.0),
                          color: Color.lerp(c, VimaiColor.ink, 0.55),
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A soft coloured disc with a big emoji: the picture on every card.
class _EmojiDisc extends StatelessWidget {
  const _EmojiDisc({required this.emoji, required this.color, required this.size});

  final String emoji;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [Color.lerp(color, Colors.white, 0.92)!, Color.lerp(color, Colors.white, 0.68)!],
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ExploreEmoji(emoji, size: size * 0.56),
      ),
    );
  }
}

class _QuizLaunchButton extends StatelessWidget {
  const _QuizLaunchButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Đố bé',
      borderRadius: BorderRadius.circular(VimaiRadius.pill),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.fromLTRB(8, 8, 26, 8),
        decoration: BoxDecoration(
          gradient: VimaiColor.candyGradient,
          borderRadius: BorderRadius.circular(VimaiRadius.pill),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [BoxShadow(color: Color(0x55FF2A6D), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const ExploreEmoji('🎯', size: 30),
            ),
            const SizedBox(width: 12),
            Text('Đố bé', style: VimaiType.button.copyWith(color: Colors.white, fontSize: 24)),
            const SizedBox(width: 10),
            const ExploreEmoji('⭐', size: 26),
          ],
        ),
      ),
    );
  }
}

/// Full-screen story card: the picture zooms in (Hero), Mai says the name
/// and the fact. Swipe or tap the arrows for the next card.
class ExploreCardViewer extends ConsumerStatefulWidget {
  const ExploreCardViewer({super.key, required this.category, required this.initialIndex});

  final ExploreCategory category;
  final int initialIndex;

  @override
  ConsumerState<ExploreCardViewer> createState() => _ExploreCardViewerState();
}

class _ExploreCardViewerState extends ConsumerState<ExploreCardViewer> {
  late final PageController _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  Timer? _sayTimer;
  int _talkKey = 0;
  static bool _swipeHinted = false;

  List<ExploreItem> get _items => widget.category.items;

  @override
  void initState() {
    super.initState();
    // Let the zoom land before Mai speaks.
    _sayTimer = Timer(const Duration(milliseconds: 480), _say);
  }

  @override
  void dispose() {
    _sayTimer?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _say() {
    if (!mounted) return;
    final item = _items[_index];
    setState(() => _talkKey++);
    // The first card of the session also teaches how to move on.
    final hint = !_swipeHinted;
    _swipeHinted = true;
    unawaited(ref.read(audioServiceProvider).speak([item.name, item.fact, if (hint) ExploreGuide.swipe]));
  }

  void _onPage(int i) {
    setState(() => _index = i);
    _sayTimer?.cancel();
    _sayTimer = Timer(const Duration(milliseconds: 260), _say);
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= _items.length) return;
    final d = VimaiMotion.of(context, const Duration(milliseconds: 380));
    if (d == Duration.zero) {
      _pages.jumpToPage(next);
    } else {
      _pages.animateToPage(next, duration: d, curve: Curves.easeOutCubic);
    }
  }

  void _close() {
    unawaited(ref.read(audioServiceProvider).stop());
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.category.color;
    final last = _index == _items.length - 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Tinted veil over the card wall.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(c, Colors.black, 0.1)!.withValues(alpha: 0.94),
                  Color.lerp(c, Colors.black, 0.35)!.withValues(alpha: 0.96),
                ],
              ),
            ),
          ),
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _RaysPainter()))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      ExploreRoundButton(icon: Icons.close_rounded, semanticLabel: 'Đóng', color: c, onTap: _close),
                      Expanded(child: Center(child: _Dots(count: _items.length, index: _index))),
                      const SizedBox(width: 64),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _items.length,
                    onPageChanged: _onPage,
                    itemBuilder: (context, i) => _StoryCard(
                      key: ValueKey('story-$i'),
                      category: widget.category,
                      item: _items[i],
                      active: i == _index,
                      flipIn: i != widget.initialIndex,
                      talkKey: i == _index ? _talkKey : -1,
                      onSay: _say,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ExploreRoundButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: 'Hình trước',
                        color: c,
                        size: 68,
                        onTap: _index > 0 ? () => _go(-1) : null,
                      ),
                      const SizedBox(width: 18),
                      ExploreRoundButton(
                        icon: Icons.volume_up_rounded,
                        semanticLabel: 'Nghe lại',
                        color: Colors.white,
                        background: VimaiColor.primaryPink,
                        size: 80,
                        onTap: _say,
                      ),
                      const SizedBox(width: 18),
                      if (last)
                        ExploreRoundButton(
                          icon: Icons.emoji_events_rounded,
                          semanticLabel: 'Đố bé',
                          color: Colors.white,
                          background: VimaiColor.honey,
                          size: 68,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push('/explore/${widget.category.id}/quiz');
                          },
                        )
                      else
                        ExploreRoundButton(
                          icon: Icons.arrow_forward_rounded,
                          semanticLabel: 'Hình tiếp theo',
                          color: c,
                          size: 68,
                          onTap: () => _go(1),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(VimaiRadius.pill),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: VimaiMotion.of(context, VimaiMotion.feedback),
              width: i == index ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    super.key,
    required this.category,
    required this.item,
    required this.active,
    required this.flipIn,
    required this.talkKey,
    required this.onSay,
  });

  final ExploreCategory category;
  final ExploreItem item;
  final bool active;
  final bool flipIn;
  final int talkKey;
  final VoidCallback onSay;

  @override
  Widget build(BuildContext context) {
    final c = category.color;
    return LayoutBuilder(
      builder: (context, box) {
        final cardW = math.min(box.maxWidth - 40, 540.0);
        final disc = math.min(cardW * 0.62, box.maxHeight * 0.4).clamp(120.0, 320.0);
        final nameSize = (cardW * 0.085).clamp(26.0, 40.0);
        final card = Container(
          width: cardW,
          padding: EdgeInsets.fromLTRB(20, disc * 0.12, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Color.lerp(c, Colors.white, 0.6)!, width: 5),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 14))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: _heroTag(category, item),
                child: _BreathingDisc(emoji: item.emoji, color: c, size: disc, active: active),
              ),
              SizedBox(height: disc * 0.08),
              Text(
                item.name,
                textAlign: TextAlign.center,
                style: VimaiType.display.copyWith(fontSize: nameSize, color: Color.lerp(c, VimaiColor.ink, 0.45)),
              ),
              const SizedBox(height: 10),
              Pressable(
                semanticLabel: item.fact,
                borderRadius: BorderRadius.circular(VimaiRadius.lg),
                onTap: onSay,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                  decoration: BoxDecoration(
                    color: Color.lerp(c, Colors.white, 0.88),
                    borderRadius: BorderRadius.circular(VimaiRadius.lg),
                  ),
                  child: Row(
                    children: [
                      _TalkingMai(talkKey: talkKey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.fact,
                          style: VimaiType.title.copyWith(fontSize: 18, fontWeight: FontWeight.w700, height: 1.25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        final animated = flipIn && active ? _FlipIn(child: card) : card;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            physics: const ClampingScrollPhysics(),
            child: animated,
          ),
        );
      },
    );
  }
}

/// Flips a card in around its vertical axis (like turning a picture card).
class _FlipIn extends StatelessWidget {
  const _FlipIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final d = VimaiMotion.of(context, const Duration(milliseconds: 520));
    if (d == Duration.zero) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: d,
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, t, child) {
        final angle = (1 - t) * math.pi / 2.2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
    );
  }
}

/// The emoji disc gently bobs while its card is on screen.
class _BreathingDisc extends StatefulWidget {
  const _BreathingDisc({required this.emoji, required this.color, required this.size, required this.active});

  final String emoji;
  final Color color;
  final double size;
  final bool active;

  @override
  State<_BreathingDisc> createState() => _BreathingDiscState();
}

class _BreathingDiscState extends State<_BreathingDisc> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _BreathingDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final still = MediaQuery.disableAnimationsOf(context);
    if (widget.active && !still) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, -6 * t),
          child: Transform.rotate(angle: (t - 0.5) * 0.06, child: child),
        );
      },
      child: _EmojiDisc(emoji: widget.emoji, color: widget.color, size: widget.size),
    );
  }
}

/// Mai's face beside the fact; she pops each time she starts talking.
class _TalkingMai extends StatelessWidget {
  const _TalkingMai({required this.talkKey});

  final int talkKey;

  @override
  Widget build(BuildContext context) {
    final mai = Stack(
      clipBehavior: Clip.none,
      children: [
        const VimaiMascot(mood: MascotMood.excited, size: 60),
        Positioned(
          right: -4,
          bottom: 0,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(color: VimaiColor.primaryPink, shape: BoxShape.circle),
            child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
    final d = VimaiMotion.of(context, const Duration(milliseconds: 600));
    if (d == Duration.zero) return mai;
    return TweenAnimationBuilder<double>(
      key: ValueKey(talkKey),
      tween: Tween(begin: 0.7, end: 1),
      duration: d,
      curve: Curves.elasticOut,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: mai,
    );
  }
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final r = size.longestSide;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + r * math.cos(a - 0.09), center.dy + r * math.sin(a - 0.09))
        ..lineTo(center.dx + r * math.cos(a + 0.09), center.dy + r * math.sin(a + 0.09))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
