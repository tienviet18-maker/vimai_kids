import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/vimai_tokens.dart';
import 'kids_lesson.dart';
import 'vimai_mascot.dart';
import 'vimai_ui.dart';
import 'vimai_world.dart';

/// Chunky tactile CTA. Not a Material filled button with a new color.
class KidsPlayButton extends StatefulWidget {
  const KidsPlayButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = VimaiColor.coral,
    this.icon = Icons.play_arrow_rounded,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final bool expanded;

  @override
  State<KidsPlayButton> createState() => _KidsPlayButtonState();
}

class _KidsPlayButtonState extends State<KidsPlayButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final duration = VimaiMotion.of(context, VimaiMotion.tap);
    final face = Color.lerp(widget.color, Colors.white, 0.08)!;
    final base = Color.lerp(widget.color, Colors.black, 0.18)!;
    final label = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: VimaiType.button.copyWith(color: Colors.white, fontSize: 18),
    );
    final child = AnimatedScale(
      scale: _down ? 0.96 : 1,
      duration: duration,
      curve: VimaiMotion.curve,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56, minWidth: 88),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(22)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: face,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 24),
                        const SizedBox(width: 6),
                      ],
                      if (widget.expanded) Expanded(child: label) else label,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      label: widget.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onHighlightChanged: (v) => setState(() => _down = v),
          onTap: widget.onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  widget.onPressed!();
                },
          child: child,
        ),
      ),
    );
  }
}

/// Speech that belongs to Mai, not a dashboard subtitle.
class KidsSpeechBubble extends StatelessWidget {
  const KidsSpeechBubble({super.key, required this.children, this.color = VimaiColor.cream});

  final List<Widget> children;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(color: color),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  _BubbleTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(18, size.height - 4)
      ..lineTo(4, size.height + 14)
      ..lineTo(34, size.height - 4)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) => oldDelegate.color != color;
}

/// Gentle bob for living objects. Background motion stays smaller than this.
class KidsFloat extends StatefulWidget {
  const KidsFloat({
    super.key,
    required this.child,
    this.dy = 6,
    this.duration = const Duration(milliseconds: 2200),
    this.delay = Duration.zero,
  });

  final Widget child;
  final double dy;
  final Duration duration;
  final Duration delay;

  @override
  State<KidsFloat> createState() => _KidsFloatState();
}

class _KidsFloatState extends State<KidsFloat> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    if (widget.duration.inMilliseconds > 0) {
      _c.value = (widget.delay.inMilliseconds % widget.duration.inMilliseconds) / widget.duration.inMilliseconds;
    }
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -widget.dy * math.sin(_c.value * math.pi)),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// A full-bleed lesson scene: background, Mai, speech, interactive stage.
class KidsLearningScene extends StatelessWidget {
  const KidsLearningScene({
    super.key,
    required this.backgroundAsset,
    required this.speech,
    required this.stage,
    this.speechEyebrow,
    this.mascotMood = MascotMood.happy,
    this.mascotColor = VimaiColor.mascot,
    this.footer,
    this.topRight,
  });

  final String backgroundAsset;
  final String? speechEyebrow;
  final String speech;
  final Widget stage;
  final MascotMood mascotMood;
  final Color mascotColor;
  final Widget? footer;
  final Widget? topRight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: Image.asset(
            backgroundAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            cacheWidth: 900,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stack) => const ColoredBox(color: VimaiColor.skyTop),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IdleMascot(mood: mascotMood, color: mascotColor, size: 72),
                    const SizedBox(width: 8),
                    Expanded(
                      child: KidsSpeechBubble(
                        children: [
                          if (speechEyebrow != null && speechEyebrow!.isNotEmpty)
                            Text(speechEyebrow!, style: VimaiType.caption.copyWith(fontWeight: FontWeight.w800, color: VimaiColor.mint)),
                          Text(speech, style: VimaiType.title.copyWith(fontSize: 18)),
                        ],
                      ),
                    ),
                    if (topRight != null) topRight!,
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(child: stage),
                if (footer != null) ...[const SizedBox(height: 8), footer!],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Letter as a toy in the scene, not a hero headline on a blank page.
class KidsLetterObject extends StatelessWidget {
  const KidsLetterObject({
    super.key,
    required this.letter,
    required this.color,
    this.phonics,
    this.lowercase,
    this.size = 148,
    this.onTap,
  });

  final String letter;
  final Color color;
  final String? phonics;
  final String? lowercase;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 6,
            child: Container(
              width: size * 0.72,
              height: 16,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(99)),
            ),
          ),
          Container(
            width: size * 0.86,
            height: size * 0.86,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: VimaiColor.cream,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  child: Text(
                    letter,
                    style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w800, color: color, height: 1),
                  ),
                ),
                if (lowercase != null && lowercase!.isNotEmpty && lowercase != letter)
                  Text(lowercase!, style: TextStyle(fontSize: size * 0.16, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.55))),
              ],
            ),
          ),
          if (phonics != null && phonics!.isNotEmpty)
            Positioned(
              right: 0,
              bottom: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(phonics!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return KidsFloat(child: body);
    return KidsFloat(
      child: Pressable(semanticLabel: letter, borderRadius: BorderRadius.circular(99), onTap: onTap, child: body),
    );
  }
}

class KidsChoiceObject extends StatelessWidget {
  const KidsChoiceObject({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.correct,
    this.size = 84,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool? correct;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fill = correct == true
        ? VimaiColor.correct
        : correct == false
            ? VimaiColor.retry
            : color;
    return Pressable(
      semanticLabel: label,
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: AnimatedScale(
        scale: correct != null ? 1.08 : 1,
        duration: VimaiMotion.of(context, VimaiMotion.feedback),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 30)),
        ),
      ),
    );
  }
}

/// Wooden writing board sitting in the scene.
class KidsWritingStage extends StatelessWidget {
  const KidsWritingStage({super.key, required this.letter, required this.color, required this.child});

  final String letter;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFC9844A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF8A5A2B), width: 4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: DecoratedBox(
          decoration: BoxDecoration(color: VimaiColor.cream, borderRadius: BorderRadius.circular(20)),
          child: GuidedWritePad(letter: letter, color: color, child: child),
        ),
      ),
    );
  }
}

class KidsStarSticker extends StatelessWidget {
  const KidsStarSticker({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: label,
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: VimaiColor.honey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 3),
        ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VimaiType.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
      ),
    );
  }
}

class KidsHouseButton extends StatelessWidget {
  const KidsHouseButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: label,
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: VimaiColor.peach,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.home_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

/// Hub destinations as toys in a room, not a trail of list rows.
class ActivityGarden extends StatelessWidget {
  const ActivityGarden({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 14,
      children: [
        for (var i = 0; i < children.length; i++)
          Transform.translate(
            offset: Offset(i.isOdd ? 8 : -8, (i % 3) * 4.0),
            child: children[i],
          ),
      ],
    );
  }
}
