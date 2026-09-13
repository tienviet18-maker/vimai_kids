import 'dart:math';

import 'dart:ui';

/// Playfield sizing from the *board slot*, never from full-screen MediaQuery.
///
/// Catch-kana used to spawn in a 240×420 phone strip while the Stack filled
/// the window, so desktop/web showed a few letters in a huge empty canvas.
class GameBoardMetrics {
  static const maxWidth = 440.0;
  static const maxHeight = 580.0;
  static const minToken = 56.0;
  static const maxToken = 88.0;
  static const minGap = 8.0;

  /// Compact kid-game rectangle inside [available] space.
  static Size fit(double availableWidth, double availableHeight) {
    var width = min(availableWidth, maxWidth);
    var height = min(availableHeight, maxHeight);
    if (width < 8 || height < 8) {
      return Size(width.clamp(0, maxWidth), height.clamp(0, maxHeight));
    }
    if (height > width * 1.4) height = width * 1.4;
    if (width > height * 1.15) width = height * 1.15;
    return Size(width, height);
  }

  static double tokenSize(double boardWidth, double boardHeight) {
    final shortest = min(boardWidth, boardHeight);
    if (shortest <= 0) return minToken;
    return (shortest * 0.2).clamp(minToken, maxToken);
  }

  static double padding(double token) => max(8.0, token * 0.1);
}
