import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import 'kids_scene.dart';
import 'vimai_mascot.dart';
import 'vimai_world.dart';

String _artFor(WorldKind kind) {
  switch (kind) {
    case WorldKind.japanese:
      return VimaiArt.japaneseVillage;
    case WorldKind.vietnamese:
      return VimaiArt.vietnameseGarden;
    case WorldKind.math:
      return VimaiArt.mathValley;
    case WorldKind.thinking:
      return VimaiArt.thinkingCave;
    case WorldKind.creativity:
      return VimaiArt.creativeStudio;
    case WorldKind.games:
      return VimaiArt.gamesPlayground;
  }
}

/// One tappable object inside Mai's play room — distinct art + scale, not a card.
class KidsRoomObject extends StatefulWidget {
  const KidsRoomObject({
    super.key,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.look,
    required this.onTap,
    this.progress = 0,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final WorldKind kind;
  final SubjectLook look;
  final VoidCallback onTap;
  final double progress;
  final bool highlighted;

  @override
  State<KidsRoomObject> createState() => _KidsRoomObjectState();
}

class _KidsRoomObjectState extends State<KidsRoomObject> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.subtitle}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _down = true),
            onTapUp: (_) => setState(() => _down = false),
            onTapCancel: () => setState(() => _down = false),
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTap();
            },
            child: AnimatedScale(
              scale: _down ? 0.92 : (widget.highlighted ? 1.04 : 1),
              duration: VimaiMotion.of(context, VimaiMotion.tap),
              curve: VimaiMotion.curve,
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      left: w * 0.08,
                      right: w * 0.08,
                      bottom: h * 0.06,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: widget.look.color.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const SizedBox(height: 14),
                      ),
                    ),
                    Positioned.fill(
                      bottom: h * 0.14,
                      child: Image.asset(
                        _artFor(widget.kind),
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        cacheWidth: 420,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => ColoredBox(color: widget.look.soft),
                      ),
                    ),
                    Positioned(
                      left: 4,
                      right: 4,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: widget.look.color,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                              ),
                              Text(
                                widget.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w700, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (widget.progress >= 0.4)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: VimaiColor.honey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(3),
                            child: Text('★', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Full-bleed play room: backdrop + asymmetric objects filling the viewport.
class KidsRoomScene extends StatelessWidget {
  const KidsRoomScene({
    super.key,
    required this.objects,
    this.quest,
    this.topBar,
  });

  final List<Widget> objects;
  final Widget? quest;
  final Widget? topBar;

  /// Asymmetric slots: left, top, width, height — different scales on purpose.
  static const phoneSlots = <(double, double, double, double)>[
    (0.00, 0.06, 0.46, 0.34), // JP large
    (0.50, 0.04, 0.48, 0.36), // VI large
    (0.00, 0.36, 0.40, 0.30), // Math med
    (0.52, 0.36, 0.44, 0.32), // Thinking med
    (0.02, 0.60, 0.38, 0.28), // Creativity smaller
    (0.48, 0.58, 0.48, 0.32), // Games med-large
  ];

  static const desktopSlots = <(double, double, double, double)>[
    (0.02, 0.04, 0.30, 0.42),
    (0.34, 0.02, 0.32, 0.44),
    (0.68, 0.06, 0.28, 0.38),
    (0.04, 0.42, 0.28, 0.36),
    (0.36, 0.44, 0.28, 0.34),
    (0.66, 0.42, 0.30, 0.38),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final slots = wide ? desktopSlots : phoneSlots;
        final questH = wide ? 128.0 : 118.0;
        final roomH = (constraints.maxHeight - questH).clamp(420.0, 1200.0);

        return Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(child: _RoomBackdrop()),
                  if (topBar != null)
                    Positioned(left: 10, right: 10, top: 4, child: topBar!),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 44,
                    bottom: 0,
                    child: LayoutBuilder(
                      builder: (context, room) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (var i = 0; i < objects.length && i < slots.length; i++)
                              Positioned(
                                left: room.maxWidth * slots[i].$1,
                                top: room.maxHeight * slots[i].$2,
                                width: room.maxWidth * slots[i].$3,
                                height: room.maxHeight * slots[i].$4,
                                child: objects[i],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (quest != null)
              SizedBox(
                height: questH,
                width: double.infinity,
                child: quest,
              ),
            // Ensure layout uses roomH intent on very tall screens without dead air above quest.
            if (constraints.maxHeight > roomH + questH + 80) const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}

class _RoomBackdrop extends StatelessWidget {
  const _RoomBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          VimaiArt.homeWorld,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          cacheWidth: 1200,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => const ColoredBox(color: VimaiColor.skyTop),
        ),
        // Soft vignette so labels stay readable without flattening the room.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.transparent,
                VimaiColor.ink.withValues(alpha: 0.12),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact quest strip — Mai participates; not an oversized isolated mascot.
class KidsQuestBanner extends StatelessWidget {
  const KidsQuestBanner({
    super.key,
    required this.mood,
    required this.mascotColor,
    required this.greeting,
    required this.adventure,
    required this.ctaLabel,
    required this.onPlay,
  });

  final MascotMood mood;
  final Color mascotColor;
  final String greeting;
  final String adventure;
  final String ctaLabel;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: VimaiColor.surface.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.9), width: 3)),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IdleMascot(mood: mood, color: mascotColor, size: 64),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting, maxLines: 1, overflow: TextOverflow.ellipsis, style: VimaiType.title.copyWith(fontSize: 17)),
                  const SizedBox(height: 2),
                  Text(adventure, maxLines: 2, overflow: TextOverflow.ellipsis, style: VimaiType.subtitle.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: VimaiColor.ink)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: KidsPlayButton(label: ctaLabel, color: VimaiColor.coral, onPressed: onPlay),
            ),
          ],
        ),
      ),
    );
  }
}

/// Test/back-compat aliases for prior Home widget names.
typedef KidsActivitySticker = KidsRoomObject;
typedef KidsPlayRoomHero = KidsQuestBanner;
