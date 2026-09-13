import 'package:flutter/material.dart';

import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import 'vimai_mascot.dart';
import 'vimai_ui.dart';

/// Shared child-learning stage. Alias of [LessonStage] for lesson screens.
class KidsLessonScaffold extends StatelessWidget {
  const KidsLessonScaffold({
    super.key,
    required this.color,
    required this.child,
    this.companion,
  });

  final Color color;
  final Widget child;
  final Widget? companion;

  @override
  Widget build(BuildContext context) {
    return LessonStage(color: color, companion: companion, child: child);
  }
}

class KidsLetterHero extends StatelessWidget {
  const KidsLetterHero({
    super.key,
    required this.letter,
    required this.color,
    this.fontSize = 96,
    this.subtitle,
  });

  final String letter;
  final Color color;
  final double fontSize;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final duration = VimaiMotion.of(context, VimaiMotion.enter);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: duration == Duration.zero ? 1 : 0.88, end: 1),
      duration: duration,
      curve: VimaiMotion.curve,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: CustomPaint(
        painter: _LetterCloudPainter(color: color),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  letter,
                  style: VimaiType.display.copyWith(fontSize: fontSize, color: color, height: 1),
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: VimaiType.title.copyWith(fontSize: 28, color: color.withValues(alpha: 0.55)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class KidsAudioButton extends StatefulWidget {
  const KidsAudioButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = VimaiColor.mint,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  State<KidsAudioButton> createState() => _KidsAudioButtonState();
}

class _KidsAudioButtonState extends State<KidsAudioButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (!reduced) {
      await _pulse.forward(from: 0);
      if (mounted) _pulse.reverse();
    }
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = 1 + (_pulse.value * 0.08);
        return Transform.scale(scale: scale, child: child);
      },
      child: Semantics(
        button: true,
        label: widget.label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Pressable(
              semanticLabel: widget.label,
              borderRadius: BorderRadius.circular(VimaiRadius.pill),
              onTap: _tap,
              child: Container(
                width: VimaiSize.touchKid + 10,
                height: VimaiSize.touchKid + 10,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, Color.lerp(widget.color, VimaiColor.accentOrange, 0.35)!],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: VimaiShadow.lift,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.label, style: VimaiType.button.copyWith(color: widget.color, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class KidsStepStrip extends StatelessWidget {
  const KidsStepStrip({super.key, required this.steps, this.active = 0, this.color = VimaiColor.mint});

  final List<String> steps;
  final int active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < steps.length; i++)
          DecoratedBox(
            decoration: BoxDecoration(
              color: i == active ? color : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(VimaiRadius.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                '${i + 1}. ${steps[i]}',
                style: VimaiType.caption.copyWith(
                  color: i == active ? Colors.white : color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class KidsExampleCard extends StatelessWidget {
  const KidsExampleCard({
    super.key,
    required this.word,
    required this.color,
    this.spoken,
    this.onListen,
    this.listenLabel = 'Nghe từ ví dụ',
    this.size = 88,
  });

  final String word;
  final Color color;
  final String? spoken;
  final VoidCallback? onListen;
  final String listenLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (word.isEmpty) return const SizedBox.shrink();
    return SoftSurface(
      color: color.withValues(alpha: 0.10),
      borderColor: color.withValues(alpha: 0.28),
      child: Column(
        children: [
          WordSceneCue(word: word, color: color, size: size),
          const SizedBox(height: 8),
          Text(word.toUpperCase(), style: VimaiType.display.copyWith(color: color, fontSize: 32)),
          Text(word, style: VimaiType.subtitle.copyWith(fontSize: 18)),
          if (spoken != null && spoken!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('$spoken — $word', style: VimaiType.cardTitle.copyWith(color: color, fontSize: 20)),
          ],
          if (onListen != null)
            TextButton.icon(
              onPressed: onListen,
              icon: const Icon(Icons.volume_up_rounded),
              label: Text(listenLabel),
            ),
        ],
      ),
    );
  }
}

class KidsCharacterBanner extends StatelessWidget {
  const KidsCharacterBanner({
    super.key,
    required this.mood,
    required this.color,
    this.size = VimaiSize.mascotCard,
  });

  final MascotMood mood;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return VimaiMascot(mood: mood, size: size, color: color);
  }
}

/// One reusable illustration placeholder. Never emoji spam, never invented curriculum.
class WordSceneCue extends StatelessWidget {
  const WordSceneCue({super.key, required this.word, required this.color, this.size = 88});

  final String word;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final art = VimaiArt.objectForWord(word);
    if (art != null) {
      return Semantics(
        label: word,
        button: true,
        image: true,
        child: Image.asset(
          art,
          height: size * 1.35,
          cacheWidth: 240,
          filterQuality: FilterQuality.medium,
        ),
      );
    }
    return Semantics(
      label: word,
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _WordScenePainter(word: word, color: color),
      ),
    );
  }
}

class _WordScenePainter extends CustomPainter {
  _WordScenePainter({required this.word, required this.color});

  final String word;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final soft = Paint()..color = color.withValues(alpha: 0.22);
    final w = size.width;
    canvas.drawCircle(Offset(w * 0.5, w * 0.5), w * 0.46, soft);
    switch (word) {
      case 'cá':
        canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.46, w * 0.5), width: w * 0.52, height: w * 0.32), fill);
        final tail = Path()
          ..moveTo(w * 0.7, w * 0.5)
          ..lineTo(w * 0.88, w * 0.34)
          ..lineTo(w * 0.88, w * 0.66)
          ..close();
        canvas.drawPath(tail, fill);
        canvas.drawCircle(Offset(w * 0.34, w * 0.46), w * 0.045, Paint()..color = Colors.white);
        break;
      case 'hoa':
        final petals = <Offset>[
          Offset(w * 0.5, w * 0.28),
          Offset(w * 0.72, w * 0.42),
          Offset(w * 0.64, w * 0.68),
          Offset(w * 0.36, w * 0.68),
          Offset(w * 0.28, w * 0.42),
        ];
        for (final p in petals) {
          canvas.drawCircle(p, w * 0.12, fill);
        }
        canvas.drawCircle(Offset(w * 0.5, w * 0.5), w * 0.11, Paint()..color = VimaiColor.honey);
        break;
      case 'gà':
      case 'voi':
      case 'rùa':
        canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, w * 0.54), width: w * 0.55, height: w * 0.38), fill);
        canvas.drawCircle(Offset(w * 0.32, w * 0.4), w * 0.14, fill);
        break;
      case 'táo':
      case 'quả':
      case 'ớt':
        canvas.drawCircle(Offset(w * 0.5, w * 0.54), w * 0.28, fill);
        canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.5, w * 0.28), width: w * 0.08, height: w * 0.16), Paint()..color = VimaiColor.mint);
        break;
      case 'lá':
        canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, w * 0.5), width: w * 0.28, height: w * 0.5), fill);
        break;
      case 'xe':
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, w * 0.38, w * 0.64, w * 0.28), const Radius.circular(10)), fill);
        canvas.drawCircle(Offset(w * 0.34, w * 0.72), w * 0.08, Paint()..color = VimaiColor.ink);
        canvas.drawCircle(Offset(w * 0.66, w * 0.72), w * 0.08, Paint()..color = VimaiColor.ink);
        break;
      default:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.5, w * 0.5), width: w * 0.42, height: w * 0.42), const Radius.circular(16)),
          fill,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _WordScenePainter oldDelegate) => oldDelegate.word != word || oldDelegate.color != color;
}

class _LetterCloudPainter extends CustomPainter {
  _LetterCloudPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.58), width: size.width * 0.92, height: size.height * 0.7), cloud);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.28, size.height * 0.48), width: size.width * 0.42, height: size.height * 0.42), cloud);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.72, size.height * 0.48), width: size.width * 0.4, height: size.height * 0.4), cloud);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.92), width: size.width * 0.5, height: 16),
      Paint()..color = color.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _LetterCloudPainter oldDelegate) => oldDelegate.color != color;
}

class GuidedWritePad extends StatelessWidget {
  const GuidedWritePad({
    super.key,
    required this.letter,
    required this.color,
    required this.child,
  });

  final String letter;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
