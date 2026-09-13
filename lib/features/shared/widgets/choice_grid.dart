import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_tokens.dart';
import 'vimai_ui.dart';

class ChoiceGrid extends StatelessWidget {
  final List<String> choices;
  final String? highlighted;
  final String? lastChoice;
  final bool? lastCorrect;
  final Color color;
  final ValueChanged<String> onSelected;

  const ChoiceGrid({
    super.key,
    required this.choices,
    required this.onSelected,
    this.highlighted,
    this.lastChoice,
    this.lastCorrect,
    this.color = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 16,
      children: [
        for (var i = 0; i < choices.length; i++)
          Transform.translate(
            offset: Offset(i.isOdd ? 10 : -6, i < 2 ? 0 : 8),
            child: _ChoiceBubble(
              choice: choices[i],
              color: color,
              selected: highlighted == choices[i] || lastChoice == choices[i],
              isRight: lastChoice == choices[i] && lastCorrect == true,
              isWrong: lastChoice == choices[i] && lastCorrect == false,
              onTap: () => onSelected(choices[i]),
            ),
          ),
      ],
    );
  }
}

class _ChoiceBubble extends StatelessWidget {
  const _ChoiceBubble({
    required this.choice,
    required this.color,
    required this.selected,
    required this.isRight,
    required this.isWrong,
    required this.onTap,
  });

  final String choice;
  final Color color;
  final bool selected;
  final bool isRight;
  final bool isWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = isRight
        ? VimaiColor.correct
        : isWrong
            ? VimaiColor.retry
            : (selected ? color : color.withValues(alpha: 0.88));
    return Pressable(
      semanticLabel: choice,
      borderRadius: BorderRadius.circular(VimaiRadius.pill),
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.06 : 1,
        duration: VimaiMotion.of(context, VimaiMotion.feedback),
        child: Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            boxShadow: VimaiShadow.lift,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                choice,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
