import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Robust return to the main kids Home screen.
///
/// After [GoRouter.go] (or a broken stack), [Navigator.pop] alone can no-op.
/// Prefer popping to the first route, then ensure `/home` is active.
void navigateBackToHome(BuildContext context) {
  if (!context.mounted) return;
  final navigator = Navigator.maybeOf(context);
  if (navigator != null && navigator.canPop()) {
    navigator.popUntil((route) => route.isFirst);
  }
  if (!context.mounted) return;
  final loc = GoRouterState.of(context).matchedLocation;
  if (loc != '/home') {
    context.go('/home');
  }
}

/// Leave a lesson / mini-game / detail screen by popping — never push a hub.
///
/// Falls back to [navigateBackToHome] when the stack was replaced and cannot pop.
void popLearningScreen(BuildContext context) {
  if (!context.mounted) return;
  if (context.canPop()) {
    context.pop();
    return;
  }
  navigateBackToHome(context);
}
