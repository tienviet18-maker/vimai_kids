import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../domain/models/kana_item.dart';
import 'stroke_order_player.dart';

export 'stroke_order_catalog.dart';
export 'stroke_order_player.dart';

/// Compatibility wrapper. Stroke teaching lives in [StrokeOrderPlayer].
class StrokeOrderBoard extends StatelessWidget {
  const StrokeOrderBoard({
    super.key,
    required this.kana,
    required this.color,
    required this.copy,
    this.onPlayAudio,
  });

  final KanaItem kana;
  final Color color;
  final AppStrings copy;
  final VoidCallback? onPlayAudio;

  @override
  Widget build(BuildContext context) {
    return StrokeOrderPlayer(
      kana: kana,
      color: color,
      copy: copy,
      onPlayAudio: onPlayAudio,
    );
  }
}
