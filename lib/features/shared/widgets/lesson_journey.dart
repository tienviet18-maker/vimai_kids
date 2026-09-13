import 'package:flutter/material.dart';

import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import 'kids_lesson.dart';
import 'kids_living_canopy.dart';
import 'vimai_mascot.dart';
import 'vimai_world.dart';

/// Shared warm lesson stage: Mai hearth → centered pearl hero → single bottom action.
class LessonJourneyShell extends StatelessWidget {
  const LessonJourneyShell({
    super.key,
    required this.title,
    required this.speech,
    required this.hero,
    required this.bottomDeck,
    this.backgroundAsset,
    this.accent = VimaiColor.primaryPink,
    this.mascotMood = MascotMood.happy,
    this.mascotColor = VimaiColor.mascot,
    this.onBack,
    this.feedback,
  });

  final String title;
  final String speech;
  final Widget hero;
  final Widget bottomDeck;
  final String? backgroundAsset;
  final Color accent;
  final MascotMood mascotMood;
  final Color mascotColor;
  final VoidCallback? onBack;
  final Widget? feedback;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundAsset ?? VimaiArt.gardenLesson;
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: Image.asset(
            bg,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            cacheWidth: 1100,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE7F4FF)),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x88FFF8EC),
                Color(0x55FDFBF4),
                Color(0xAAF3F8E8),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 14, 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (onBack != null) ...[
                      LessonBackButton(onTap: onBack!),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: MaiDialogueHearth(
                        title: title,
                        speech: speech,
                        mood: mascotMood,
                        mascotColor: mascotColor,
                        accent: accent,
                      ),
                    ),
                  ],
                ),
                if (feedback != null) ...[
                  const SizedBox(height: 8),
                  feedback!,
                ],
                Expanded(child: hero),
                bottomDeck,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Soft circular back / exit control — top-left, ≥60dp touch.
class LessonBackButton extends StatelessWidget {
  const LessonBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TactileNode(
      key: const Key('lesson-back'),
      semanticLabel: 'Quay lại',
      minSize: 60,
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x281B3B2B), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.arrow_back_rounded, size: 30, color: VimaiColor.ink),
      ),
    );
  }
}

/// Cloud dialogue with Mai beside a big Baloo title.
class MaiDialogueHearth extends StatelessWidget {
  const MaiDialogueHearth({
    super.key,
    required this.title,
    required this.speech,
    required this.mood,
    required this.mascotColor,
    required this.accent,
  });

  final String title;
  final String speech;
  final MascotMood mood;
  final Color mascotColor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IdleMascot(mood: mood, color: mascotColor, size: 68),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x221B3B2B), blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: VimaiType.title.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  speech,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: VimaiType.subtitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: VimaiColor.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Claymorphic pearl / wood board for the focus letter (≥160dp).
class PearlLetterHero extends StatelessWidget {
  const PearlLetterHero({
    super.key,
    required this.letter,
    required this.color,
    required this.onListen,
    this.phonics,
    this.lowercase,
    this.listenLabel = 'Nghe nào!',
    this.size = 168,
  });

  final String letter;
  final Color color;
  final VoidCallback onListen;
  final String? phonics;
  final String? lowercase;
  final String listenLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final board = size.clamp(160.0, 220.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TactileNode(
          semanticLabel: letter,
          minSize: board,
          onTap: onListen,
          child: Container(
            width: board,
            height: board,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color.lerp(color, Colors.white, 0.82)!,
                  Color.lerp(color, const Color(0xFFFFF4E8), 0.55)!,
                ],
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 12)),
                const BoxShadow(color: Color(0x221B3B2B), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  child: Text(
                    letter,
                    style: VimaiType.display.copyWith(
                      fontSize: board * 0.46,
                      color: color,
                      height: 1,
                    ),
                  ),
                ),
                if (lowercase != null && lowercase!.isNotEmpty && lowercase != letter)
                  Text(
                    lowercase!,
                    style: VimaiType.label.copyWith(color: color.withValues(alpha: 0.55), fontSize: 22),
                  ),
                if (phonics != null && phonics!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      phonics!,
                      style: VimaiType.label.copyWith(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        KidsAudioButton(label: listenLabel, color: color, onPressed: onListen),
      ],
    );
  }
}

/// Primary dual-navigation CTA for the linear lesson journey: [Quay lại] and [Tiếp tục].
class LessonContinuePill extends StatelessWidget {
  const LessonContinuePill({
    super.key,
    required this.label,
    required this.onTap,
    this.previousLabel = 'Quay lại',
    this.onPrevious,
    this.canPrevious = false,
  });

  final String label;
  final VoidCallback onTap;
  final String previousLabel;
  final VoidCallback? onPrevious;
  final bool canPrevious;

  @override
  Widget build(BuildContext context) {
    final nextBtn = TactileNode(
      key: const Key('continue-flow'),
      semanticLabel: label,
      minSize: VimaiSize.touchKid,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: VimaiColor.candyGradient,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x40FF2A6D), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: VimaiType.button.copyWith(color: Colors.white, fontSize: 20),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
          ],
        ),
      ),
    );

    if (onPrevious == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: nextBtn,
      );
    }

    final prevBtn = Opacity(
      opacity: canPrevious ? 1.0 : 0.35,
      child: IgnorePointer(
        ignoring: !canPrevious,
        child: TactileNode(
          key: const Key('lesson-back-flow'),
          semanticLabel: previousLabel,
          minSize: VimaiSize.touchKid,
          onTap: (canPrevious && onPrevious != null) ? onPrevious! : () {},
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x221B3B2B), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back_rounded, color: VimaiColor.ink, size: 24),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    previousLabel,
                    overflow: TextOverflow.ellipsis,
                    style: VimaiType.button.copyWith(
                      color: VimaiColor.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: [
          Expanded(flex: 2, child: prevBtn),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: nextBtn),
        ],
      ),
    );
  }
}
