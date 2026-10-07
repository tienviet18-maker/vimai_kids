import 'package:flutter/material.dart';

import '../../../core/theme/vimai_tokens.dart';
import '../../shared/widgets/vimai_ui.dart';
import 'explore_widgets.dart';

/// The Home doorway into "Khám phá thế giới": a glossy globe pill.
class ExploreEntryButton extends StatelessWidget {
  const ExploreEntryButton({super.key, required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 64.0 : 72.0;
    return LayoutBuilder(builder: (context, box) {
      // The little picture parade only shows when the full title still fits.
      final parade = !compact && box.maxWidth >= 440;
      return Pressable(
        semanticLabel: 'Khám phá thế giới',
        borderRadius: BorderRadius.circular(h),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: h),
          padding: const EdgeInsets.fromLTRB(6, 6, 20, 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2FB7F0), Color(0xFF3B6FE0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(h),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x553B6FE0), blurRadius: 16, offset: Offset(0, 7))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: h - 16,
                height: h - 16,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: ExploreEmoji('🌍', size: (h - 16) * 0.62),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Khám phá thế giới',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VimaiType.button.copyWith(color: Colors.white, fontSize: compact ? 18 : 20),
                ),
              ),
              if (parade) ...[
                const SizedBox(width: 8),
                const ExploreEmoji('🦁', size: 24),
                const ExploreEmoji('🍉', size: 24),
                const ExploreEmoji('🚒', size: 24),
              ],
            ],
          ),
        ),
      );
    });
  }
}
