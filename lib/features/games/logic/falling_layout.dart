import 'dart:math';

import 'game_board_metrics.dart';

/// Axis-aligned token in **board coordinates** (origin = top-left of GameBoard).
class TokenBox {
  TokenBox({required this.left, required this.top, required this.size});

  final double left;
  final double top;
  final double size;

  double get right => left + size;
  double get bottom => top + size;

  TokenBox copyWith({double? left, double? top, double? size}) {
    return TokenBox(left: left ?? this.left, top: top ?? this.top, size: size ?? this.size);
  }

  bool isInside(double width, double height, {double epsilon = 0.75}) {
    return left >= -epsilon && top >= -epsilon && right <= width + epsilon && bottom <= height + epsilon;
  }

  bool overlaps(TokenBox other, double gap) {
    return !(right + gap <= other.left || other.right + gap <= left || bottom + gap <= other.top || other.bottom + gap <= top);
  }
}

/// Lane placement so falling letters fill the real board and never stack.
class FallingLayout {
  FallingLayout._();

  /// One vertical lane per letter. Tokens stay fully inside the board.
  static List<TokenBox> placeLanes({
    required double width,
    required double height,
    required int count,
    required Random random,
  }) {
    if (count <= 0 || width < 8 || height < 8) return const [];
    final n = count;
    var size = GameBoardMetrics.tokenSize(width, height);
    final pad = GameBoardMetrics.padding(size);
    final innerW = max(size, width - pad * 2);
    final laneW = innerW / n;
    size = min(size, max(8.0, laneW - GameBoardMetrics.minGap));
    final innerH = max(size, height - pad * 2);
    final maxTop = pad + innerH - size;

    final boxes = <TokenBox>[];
    for (var i = 0; i < n; i++) {
      final slackX = max(0.0, laneW - size - GameBoardMetrics.minGap);
      final left = pad + i * laneW + (slackX == 0 ? 0 : random.nextDouble() * slackX);
      final span = max(0.0, maxTop - pad);
      final top = pad + (span == 0 ? 0 : random.nextDouble() * span);
      boxes.add(
        TokenBox(
          left: left.clamp(0, max(0, width - size)),
          top: top.clamp(pad, max(pad, maxTop)),
          size: size,
        ),
      );
    }
    return boxes;
  }

  /// Advance downward; wrap to the top padding while staying fully visible.
  static double advanceY({
    required double top,
    required double size,
    required double boardHeight,
    required double pixels,
  }) {
    final pad = GameBoardMetrics.padding(size);
    final maxTop = max(pad, boardHeight - size - pad);
    var y = top + pixels;
    if (y > maxTop) return pad;
    return y;
  }

  static bool allInside(List<TokenBox> boxes, double width, double height) {
    return boxes.every((b) => b.isInside(width, height));
  }

  static bool noneOverlap(List<TokenBox> boxes) {
    for (var i = 0; i < boxes.length; i++) {
      for (var j = i + 1; j < boxes.length; j++) {
        if (boxes[i].overlaps(boxes[j], GameBoardMetrics.minGap)) return false;
      }
    }
    return true;
  }
}
