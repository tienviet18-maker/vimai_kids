import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Web / Safari-first scroll physics: clamp (no rubber-band jank) and accept
/// both touch and mouse/trackpad so Flutter owns all drag gestures.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Always clamp on web — iOS Safari bounce fights Flutter PageView / back swipe.
    if (kIsWeb) {
      return const ClampingScrollPhysics();
    }
    return super.getScrollPhysics(context);
  }
}
