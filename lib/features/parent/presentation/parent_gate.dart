import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/routing/nav_utils.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/repositories/profile_repository.dart';

/// One adult-only challenge: a randomized single-digit multiplication whose
/// answer is a two-digit number (12..81). Children aged 3–7 cannot solve it,
/// and blind guessing has roughly a 1-in-90 chance per attempt.
class ParentGateChallenge {
  final int a;
  final int b;
  const ParentGateChallenge(this.a, this.b);

  factory ParentGateChallenge.random(Random random) {
    // 3..9 × 4..9, never the trivially guessable ×1/×2 tables.
    return ParentGateChallenge(3 + random.nextInt(7), 4 + random.nextInt(6));
  }

  int get answer => a * b;

  bool check(String input) => int.tryParse(input.trim()) == answer;

  String get prompt => '$a × $b = ?';
}

/// Parental gate required by App Store Review Guideline 1.3 before the parent
/// area, external links, mail, purchases or anything else that leaves the
/// child experience. After [maxAttempts] wrong answers it gives up and calls
/// [onCancel].
class ParentGatePanel extends ConsumerStatefulWidget {
  const ParentGatePanel({
    super.key,
    required this.onPassed,
    required this.onCancel,
    this.random,
    this.maxAttempts = 3,
  });

  final VoidCallback onPassed;
  final VoidCallback onCancel;
  final Random? random;
  final int maxAttempts;

  @override
  ConsumerState<ParentGatePanel> createState() => _ParentGatePanelState();
}

class _ParentGatePanelState extends ConsumerState<ParentGatePanel> {
  late final Random _random = widget.random ?? Random.secure();
  late ParentGateChallenge _challenge = ParentGateChallenge.random(_random);
  String _input = '';
  int _wrong = 0;
  bool _showWrong = false;

  void _tapDigit(int d) {
    if (_input.length >= 3) return;
    setState(() {
      _input += '$d';
      _showWrong = false;
    });
  }

  void _backspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _submit() {
    if (_input.isEmpty) return;
    if (_challenge.check(_input)) {
      widget.onPassed();
      return;
    }
    _wrong++;
    if (_wrong >= widget.maxAttempts) {
      widget.onCancel();
      return;
    }
    setState(() {
      _challenge = ParentGateChallenge.random(_random);
      _input = '';
      _showWrong = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppStrings.of(ref.watch(currentProfileProvider), context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 40, color: VimaiColor.inkSoft),
              const SizedBox(height: 8),
              Text(copy.parentGateTitle, style: VimaiType.title, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(copy.parentGateBody, style: VimaiType.cardBody, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                _challenge.prompt,
                key: const Key('parent_gate_question'),
                style: VimaiType.display.copyWith(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Container(
                key: const Key('parent_gate_input'),
                width: 140,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VimaiColor.line, width: 2),
                ),
                child: Text(_input, style: VimaiType.title.copyWith(fontSize: 30)),
              ),
              SizedBox(
                height: 28,
                child: _showWrong
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          copy.parentGateWrong,
                          style: VimaiType.caption.copyWith(color: VimaiColor.retry),
                        ),
                      )
                    : null,
              ),
              _Keypad(
                onDigit: _tapDigit,
                onBackspace: _backspace,
                onSubmit: _submit,
                clearLabel: copy.parentGateClear,
                submitLabel: copy.parentGateSubmit,
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('parent_gate_cancel'),
                onPressed: widget.onCancel,
                child: Text(copy.parentGateCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    required this.clearLabel,
    required this.submitLabel,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final String clearLabel;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    Widget key(Widget child, VoidCallback onTap, {required Key k, String? tooltip, Color? color}) {
      final button = SizedBox(
        width: 72,
        height: 56,
        child: FilledButton.tonal(
          key: k,
          style: FilledButton.styleFrom(
            backgroundColor: color ?? VimaiColor.skySoft,
            foregroundColor: VimaiColor.ink,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onTap,
          child: child,
        ),
      );
      return Padding(
        padding: const EdgeInsets.all(5),
        child: tooltip == null ? button : Tooltip(message: tooltip, child: button),
      );
    }

    Widget digit(int d) => key(
          Text('$d', style: VimaiType.title.copyWith(fontSize: 24)),
          () => onDigit(d),
          k: Key('parent_gate_key_$d'),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) digit(d)]),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            key(
              const Icon(Icons.backspace_outlined),
              onBackspace,
              k: const Key('parent_gate_backspace'),
              tooltip: clearLabel,
              color: VimaiColor.honeySoft,
            ),
            digit(0),
            key(
              const Icon(Icons.check_rounded),
              onSubmit,
              k: const Key('parent_gate_submit'),
              tooltip: submitLabel,
              color: VimaiColor.mintSoft,
            ),
          ],
        ),
      ],
    );
  }
}

/// Shows the parental gate as a modal dialog. Resolves to true only when an
/// adult answered correctly. Use before any link-out, mail, share, rating
/// prompt or purchase.
Future<bool> showParentGate(BuildContext context, {Random? random}) async {
  final passed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: VimaiColor.surface,
      child: ParentGatePanel(
        random: random,
        onPassed: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    ),
  );
  return passed == true;
}

/// Route-level guard: shows the gate full-screen and reveals [child] only
/// after it is passed. Every visit to the parent area asks again, including
/// direct URLs on the web build.
class ParentGateGuard extends StatefulWidget {
  const ParentGateGuard({super.key, required this.child, this.random});

  final Widget child;
  final Random? random;

  @override
  State<ParentGateGuard> createState() => _ParentGateGuardState();
}

class _ParentGateGuardState extends State<ParentGateGuard> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    return Scaffold(
      backgroundColor: VimaiColor.surface,
      body: SafeArea(
        child: ParentGatePanel(
          random: widget.random,
          onPassed: () => setState(() => _unlocked = true),
          onCancel: () => popLearningScreen(context),
        ),
      ),
    );
  }
}
