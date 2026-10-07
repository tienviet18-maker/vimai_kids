import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/vimai_tokens.dart';
import 'vimai_ui.dart';

/// A question card a child can hear: a big speaker button beside the text.
/// Tapping anywhere on the card says [lines] (defaults to [text]) again.
class ListenPrompt extends ConsumerWidget {
  const ListenPrompt({
    super.key,
    required this.text,
    this.lines,
    this.color = VimaiColor.grape,
    this.style,
    this.child,
    this.onTap,
  });

  /// Replaces the default "say [lines]" when the card should replay
  /// something else (a word clip, a blend).
  final VoidCallback? onTap;

  final String text;
  final List<String?>? lines;
  final Color color;
  final TextStyle? style;

  /// Optional content under the text (an emoji row, an equation).
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void say() => onTap != null ? onTap!() : unawaited(ref.read(audioServiceProvider).speak(lines ?? [text]));
    return Pressable(
      semanticLabel: 'Nghe lại: $text',
      borderRadius: BorderRadius.circular(VimaiRadius.lg),
      onTap: say,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        decoration: BoxDecoration(
          color: Color.alphaBlend(color.withValues(alpha: 0.12), Colors.white),
          borderRadius: BorderRadius.circular(VimaiRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.32), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: VimaiShadow.lift),
              child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text, textAlign: TextAlign.center, style: style ?? VimaiType.title),
                  if (child != null) ...[const SizedBox(height: 8), child!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Says [lines] once when a screen opens (after its first frame), so every
/// screen greets the child with what to do. Wrap a screen body with it.
class SpeakOnOpen extends ConsumerStatefulWidget {
  const SpeakOnOpen(
      {super.key, required this.lines, required this.child, this.delay = const Duration(milliseconds: 350)});

  final List<String?> lines;
  final Widget child;
  final Duration delay;

  @override
  ConsumerState<SpeakOnOpen> createState() => _SpeakOnOpenState();
}

class _SpeakOnOpenState extends ConsumerState<SpeakOnOpen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) unawaited(ref.read(audioServiceProvider).speak(widget.lines));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
