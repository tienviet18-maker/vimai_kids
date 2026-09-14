import 'dart:async';

import 'package:flutter/foundation.dart';

/// Safari / iOS WebKit-safe answer progression for Flutter Web.
///
/// Critical rule: never `await` audio, AI, persistence, or animation on the
/// gesture → feedback → score → unlock path. Those side effects must be
/// fire-and-forget. UI mutation happens in a synchronous [setState], and the
/// next-question transition is scheduled with a cancellable [Timer].
class WebKitAnswerTap {
  WebKitAnswerTap({
    this.holdDuration = const Duration(milliseconds: 500),
  });

  final Duration holdDuration;

  bool locked = false;
  Timer? _advanceTimer;

  void dispose() {
    cancelScheduledAdvance();
    locked = false;
  }

  /// Clear lock/timers between rounds without tearing down the host State.
  void reset() => dispose();

  /// Returns `false` when another answer is already in flight.
  bool tryLock() {
    if (locked) return false;
    locked = true;
    return true;
  }

  void unlock() {
    locked = false;
  }

  void cancelScheduledAdvance() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
  }

  /// Schedule next-question / unlock work without awaiting anything.
  void scheduleAdvance({
    required bool Function() isMounted,
    required VoidCallback onAdvance,
    Duration? delay,
  }) {
    cancelScheduledAdvance();
    _advanceTimer = Timer(delay ?? holdDuration, () {
      _advanceTimer = null;
      if (!isMounted()) return;
      locked = false;
      onAdvance();
    });
  }

  /// Full correct-answer pipeline used by mini-games.
  ///
  /// [applyImmediateUi] must increment score / show feedback / set busy flags.
  /// It is invoked inside the caller's [setState] synchronously before any
  /// side effects are kicked off.
  void handleCorrectAnswer({
    required void Function(VoidCallback fn) setState,
    required VoidCallback applyImmediateUi,
    required VoidCallback playSound,
    required bool Function() isMounted,
    required VoidCallback advanceOrFinish,
    VoidCallback? sideEffects,
    Duration? hold,
  }) {
    if (!tryLock()) return;
    setState(applyImmediateUi);
    _safeRun(playSound);
    if (sideEffects != null) _safeRun(sideEffects);
    scheduleAdvance(
      isMounted: isMounted,
      delay: hold,
      onAdvance: () {
        setState(advanceOrFinish);
      },
    );
  }

  /// Wrong-answer path: feedback immediately, never keep the lock.
  void handleWrongAnswer({
    required void Function(VoidCallback fn) setState,
    required VoidCallback applyImmediateUi,
    required VoidCallback playSound,
    VoidCallback? sideEffects,
  }) {
    cancelScheduledAdvance();
    locked = false;
    setState(applyImmediateUi);
    _safeRun(playSound);
    if (sideEffects != null) _safeRun(sideEffects);
  }

  static void _safeRun(VoidCallback fn) {
    try {
      fn();
    } catch (e, st) {
      debugPrint('[WebKitAnswerTap] side-effect ignored: $e\n$st');
    }
  }
}
