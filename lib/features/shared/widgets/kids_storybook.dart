import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import 'kids_living_canopy.dart';
import 'vimai_mascot.dart';
import 'vimai_world.dart';

String artForWorld(WorldKind kind) {
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

/// Official ViMai Kids wordmark.
class VimaiKidsLogo extends StatelessWidget {
  const VimaiKidsLogo({super.key, this.height = 52});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ViMai Kids',
      image: true,
      child: SvgPicture.asset(
        VimaiBrandAssets.kidsLogo,
        height: height,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Image.asset(
          VimaiBrandAssets.companyLogo,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Text('ViMai Kids', style: VimaiType.brand),
        ),
      ),
    );
  }
}

class VimaiCopyrightLine extends StatelessWidget {
  const VimaiCopyrightLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      VimaiBrandAssets.copyright,
      textAlign: TextAlign.center,
      style: VimaiType.caption.copyWith(fontSize: 11, height: 1.35),
    );
  }
}

/// Today's adventure stage — Mai guides; not a dashboard header.
class KidsQuestStage extends StatelessWidget {
  const KidsQuestStage({
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
    return DiscoveryNest(
      mood: mood,
      mascotColor: mascotColor,
      greeting: greeting,
      adventure: adventure,
      ctaLabel: ctaLabel,
      onPlay: onPlay,
    );
  }
}

/// Commercial lesson list row — glyph box never overlaps title.
class KidsChapterBanner extends StatelessWidget {
  const KidsChapterBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.artAsset,
    this.glyph,
    this.progress = 0,
    this.featured = false,
    this.look,
    this.kind,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final String? artAsset;
  final String? glyph;
  final double progress;
  final bool featured;
  final SubjectLook? look;
  final WorldKind? kind;

  @override
  Widget build(BuildContext context) {
    final accent = look?.color ?? color;
    final art = artAsset ?? (kind != null ? artForWorld(kind!) : null);
    final glyphText = glyph ?? look?.glyph ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: TactileNode(
        semanticLabel: '$title. $subtitle',
        minSize: VimaiSize.touchKid,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          constraints: BoxConstraints(minHeight: featured ? 96 : 84),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Color.lerp(accent, Colors.white, 0.88),
            borderRadius: BorderRadius.circular(VimaiRadius.lg),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: VimaiShadow.soft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: VimaiSize.glyphTile + (featured ? 8 : 0),
                height: VimaiSize.glyphTile + (featured ? 8 : 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: art != null && featured
                        ? Image.asset(
                            art,
                            fit: BoxFit.cover,
                            cacheWidth: 160,
                            errorBuilder: (_, __, ___) => _GlyphFace(glyph: glyphText),
                          )
                        : _GlyphFace(glyph: glyphText),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VimaiType.lessonTitle.copyWith(color: accent, fontSize: featured ? 20 : 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VimaiType.subtitle.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: VimaiSize.touchKid,
                height: VimaiSize.touchKid,
                decoration: BoxDecoration(
                  gradient: VimaiColor.candyGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: VimaiShadow.soft,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
              ),
              if (progress >= 0.4)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('★', style: TextStyle(fontSize: 16, color: VimaiColor.honey)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlyphFace extends StatelessWidget {
  const _GlyphFace({required this.glyph});
  final String glyph;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            glyph,
            style: VimaiType.title.copyWith(color: Colors.white, fontSize: 26, height: 1),
          ),
        ),
      ),
    );
  }
}

/// Soft illustrated hub shell for subject rooms.
class KidsHubShell extends StatelessWidget {
  const KidsHubShell({
    super.key,
    required this.title,
    required this.accent,
    required this.body,
    this.subtitle,
    this.artAsset,
    this.onBack,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Color accent;
  final String? artAsset;
  final Widget body;
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VimaiColor.bgWarmCream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(accent, VimaiColor.bgWarmCream, 0.72)!,
                  VimaiColor.bgWarmCream,
                ],
              ),
            ),
          ),
          if (artAsset != null)
            Positioned(
              right: -40,
              top: -20,
              width: 220,
              height: 220,
              child: Opacity(
                opacity: 0.28,
                child: Image.asset(artAsset!, fit: BoxFit.contain, cacheWidth: 320),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: VimaiColor.ink,
                        onPressed: onBack,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(title, textAlign: TextAlign.center, style: VimaiType.title.copyWith(color: accent)),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                textAlign: TextAlign.center,
                                style: VimaiType.caption.copyWith(fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
                      ),
                      if (action != null)
                        action!
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: VimaiSpace.maxWide),
                      child: body,
                    ),
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

/// Section label for hub chapter groups.
class KidsHubLabel extends StatelessWidget {
  const KidsHubLabel(this.text, {super.key, this.color = VimaiColor.ink});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
      child: Text(text, style: VimaiType.label.copyWith(color: color, fontSize: 15)),
    );
  }
}

typedef KidsQuestBanner = KidsQuestStage;
typedef KidsRoomObject = KidsChapterBanner;
