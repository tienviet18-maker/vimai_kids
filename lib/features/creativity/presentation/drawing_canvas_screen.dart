import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'creativity_screen.dart';

/// Màn hình Canvas Vẽ tranh sáng tạo (Creative Drawing Canvas)
class DrawingCanvasScreen extends ConsumerWidget {
  const DrawingCanvasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CreativityScreen(initialMode: 'draw');
  }
}
