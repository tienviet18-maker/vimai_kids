import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_tokens.dart';
import 'chunky_button.dart';

/// Big, chunky answer buttons laid out on a clean responsive grid.
///
/// Every button is a fixed square cell (no offsets), so what the child sees
/// is exactly what they can tap. Four answers sit in a 2×2 block on phones
/// and a single row on wider screens.
class ChoiceGrid extends StatefulWidget {
  final List<String> choices;
  final String? highlighted;
  final String? lastChoice;
  final bool? lastCorrect;
  final Color color;
  final ValueChanged<String> onSelected;

  /// Optional per-button colours (cycled). Defaults to [color] for all.
  final List<Color>? palette;

  /// Largest button edge; buttons shrink to fit narrow screens.
  final double maxItemSize;

  const ChoiceGrid({
    super.key,
    required this.choices,
    required this.onSelected,
    this.highlighted,
    this.lastChoice,
    this.lastCorrect,
    this.color = AppTheme.primaryColor,
    this.palette,
    this.maxItemSize = 116,
  });

  @override
  State<ChoiceGrid> createState() => _ChoiceGridState();
}

class _ChoiceGridState extends State<ChoiceGrid> {
  String? _tapped;
  int _taps = 0;

  void _onTap(String choice) {
    setState(() {
      _tapped = choice;
      _taps++;
    });
    widget.onSelected(choice);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 14.0;
        final n = widget.choices.length;
        if (n == 0) return const SizedBox.shrink();
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
        final maxSize = widget.maxItemSize;
        int columns;
        if (n <= 3) {
          columns = n;
        } else if (n == 4) {
          columns = width >= 4 * maxSize + 3 * gap ? 4 : 2;
        } else {
          columns = width >= 4 * maxSize + 3 * gap ? 4 : 3;
        }
        final size =
            ((width - gap * (columns - 1)) / columns).clamp(64.0, maxSize);
        final effectiveLast = widget.lastChoice ?? _tapped;
        // Exact width for [columns] cells so the Wrap never packs an extra
        // button into a row (keeps 2×2 a real 2×2).
        final rowWidth = columns * size + (columns - 1) * gap;
        final grid = Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < n; i++)
              SizedBox(
                key: ValueKey('choice-$i-${widget.choices[i]}'),
                width: size,
                height: size,
                child: _ChoiceBubble(
                  choice: widget.choices[i],
                  color: widget.palette == null || widget.palette!.isEmpty
                      ? widget.color
                      : widget.palette![i % widget.palette!.length],
                  size: size,
                  selected: widget.highlighted == widget.choices[i],
                  isRight: effectiveLast == widget.choices[i] &&
                      widget.lastCorrect == true,
                  isWrong: effectiveLast == widget.choices[i] &&
                      widget.lastCorrect == false,
                  shakeKey: effectiveLast == widget.choices[i] &&
                          widget.lastCorrect == false
                      ? _taps
                      : null,
                  onTap: () => _onTap(widget.choices[i]),
                ),
              ),
          ],
        );
        return Align(
          alignment: Alignment.topCenter,
          widthFactor: 1,
          heightFactor: 1,
          child:
              SizedBox(width: rowWidth < width ? rowWidth : width, child: grid),
        );
      },
    );
  }
}

class _ChoiceBubble extends StatelessWidget {
  const _ChoiceBubble({
    required this.choice,
    required this.color,
    required this.size,
    required this.selected,
    required this.isRight,
    required this.isWrong,
    required this.shakeKey,
    required this.onTap,
  });

  final String choice;
  final Color color;
  final double size;
  final bool selected;
  final bool isRight;
  final bool isWrong;
  final Object? shakeKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = isRight
        ? VimaiColor.correct
        : isWrong
            ? VimaiColor.retry
            : color;
    final long = choice.runes.length > 3;
    return ShakeOnChange(
      trigger: shakeKey,
      child: AnimatedScale(
        scale: isRight ? 1.08 : (selected ? 1.05 : 1),
        duration: VimaiMotion.of(context, VimaiMotion.feedback),
        curve: VimaiMotion.bounceOut,
        child: ChunkyButton(
          semanticLabel: choice,
          color: fill,
          radius: size * 0.3,
          depth: 7,
          outlineWidth: 4,
          glow: isRight ? VimaiColor.correct : null,
          onTap: onTap,
          child: SizedBox.expand(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: size * 0.1, vertical: size * 0.08),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  choice,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: long ? size * 0.26 : size * 0.42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    shadows: const [
                      Shadow(
                          color: Color(0x40000000),
                          offset: Offset(0, 2),
                          blurRadius: 2)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
