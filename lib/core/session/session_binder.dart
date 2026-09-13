import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/profile_repository.dart';

/// Records elapsed time on a learning screen into [ChildProfile.dailyLearningState].
class SessionBinder extends ConsumerStatefulWidget {
  const SessionBinder({super.key, required this.subject, required this.child});

  final String subject;
  final Widget child;

  @override
  ConsumerState<SessionBinder> createState() => _SessionBinderState();
}

class _SessionBinderState extends ConsumerState<SessionBinder> {
  late final DateTime _start;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
  }

  @override
  void dispose() {
    try {
      final seconds = DateTime.now().difference(_start).inSeconds;
      ref.read(currentProfileProvider.notifier).addLearningSeconds(seconds, widget.subject);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
