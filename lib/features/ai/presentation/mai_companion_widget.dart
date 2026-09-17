import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/mai_action.dart';
import '../../../core/ai/mai_context.dart';
import '../../../core/ai/mai_response.dart';
import '../../../core/providers.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/models/child_profile.dart';
import '../../shared/widgets/vimai_mascot.dart';
import 'mai_companion_state.dart';
import 'mai_speech_bubble.dart';

/// Reusable controller to coordinate reactive states and speech across screens.
class MaiCompanionController extends ChangeNotifier {
  MaiState _state = MaiState.idle;
  String? _bubbleText;
  int _hintLevel = 0;
  Timer? _autoDismissTimer;

  MaiState get state => _state;
  String? get bubbleText => _bubbleText;
  int get hintLevel => _hintLevel;
  bool get hasMessage => _bubbleText != null && _bubbleText!.trim().isNotEmpty;

  void setState(MaiState newState, {String? message, int hintLevel = 0, Duration? autoDismiss}) {
    _state = newState;
    _bubbleText = message;
    _hintLevel = hintLevel;
    _autoDismissTimer?.cancel();
    if (autoDismiss != null) {
      _autoDismissTimer = Timer(autoDismiss, dismissBubble);
    }
    notifyListeners();
  }

  void showResponse(MaiResponse response, {Duration? autoDismiss = const Duration(seconds: 7)}) {
    final state = switch (response.action) {
      MaiAction.celebrate => MaiState.celebrating,
      MaiAction.encourage => MaiState.encouraging,
      MaiAction.hint => MaiState.hinting,
      MaiAction.demonstrate => MaiState.hinting,
      MaiAction.speak || MaiAction.ask => MaiState.speaking,
    };
    setState(state, message: response.text, hintLevel: response.hintLevel, autoDismiss: autoDismiss);
  }

  void dismissBubble() {
    _bubbleText = null;
    _state = MaiState.idle;
    _autoDismissTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }
}

/// Reusable UI component representing the Mai AI Learning Companion.
///
/// Features reactive states: IDLE, LISTENING, THINKING, SPEAKING, HINTING,
/// CELEBRATING, ENCOURAGING with subtle animations and speech bubbles.
class MaiCompanionWidget extends ConsumerStatefulWidget {
  final MaiContext? context;
  final MaiCompanionController? controller;
  final double mascotSize;
  final Color? color;
  final bool showHintButton;
  final VoidCallback? onHintRequested;

  const MaiCompanionWidget({
    super.key,
    this.context,
    this.controller,
    this.mascotSize = 80,
    this.color,
    this.showHintButton = true,
    this.onHintRequested,
  });

  @override
  ConsumerState<MaiCompanionWidget> createState() => _MaiCompanionWidgetState();
}

class _MaiCompanionWidgetState extends ConsumerState<MaiCompanionWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  MaiCompanionController? _internalController;

  MaiCompanionController get _effectiveController =>
      widget.controller ?? (_internalController ??= MaiCompanionController());

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _effectiveController.addListener(_onControllerChange);
  }

  @override
  void didUpdateWidget(covariant MaiCompanionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChange);
      widget.controller?.addListener(_onControllerChange);
    }
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onControllerChange);
    _internalController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleTapMai() async {
    final aiService = ref.read(maiAiServiceProvider);
    ChildProfile? profile;
    try {
      profile = ref.read(currentProfileProvider);
    } catch (_) {}
    final aiEnabled = profile?.settings['ai_enabled'] != false && aiService.isAiEnabled;

    if (!aiEnabled) return;

    if (widget.context != null) {
      _effectiveController.setState(MaiState.thinking, message: 'Mai đang suy nghĩ gợi ý cho bé nhé...');
      final resp = await aiService.requestHint(widget.context!);
      if (mounted) {
        _effectiveController.showResponse(resp);
      }
    }
    widget.onHintRequested?.call();
  }

  @override
  Widget build(BuildContext context) {
    ChildProfile? profile;
    try {
      profile = ref.watch(currentProfileProvider);
    } catch (_) {}
    final aiEnabled = profile?.settings['ai_enabled'] != false;
    final state = _effectiveController.state;
    final message = _effectiveController.bubbleText;
    final mascotColor = widget.color ?? mascotColorForAvatar(profile?.avatar ?? 'mint');

    return Semantics(
      label: 'Mai AI đồng hành. Trạng thái: ${state.labelVi}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speech bubble on top of mascot when message is available
          if (message != null && message.isNotEmpty && aiEnabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 250),
                child: MaiSpeechBubble(
                  text: message,
                  tailPosition: BubbleTailPosition.bottomCenter,
                  backgroundColor: _bubbleBackgroundForState(state),
                  borderColor: _bubbleBorderForState(state),
                  onDismiss: () => _effectiveController.dismissBubble(),
                  trailingAction: state == MaiState.hinting && _effectiveController.hintLevel > 0
                      ? Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Gợi ý mức ${_effectiveController.hintLevel}/4',
                              style: VimaiType.caption.copyWith(
                                color: VimaiColor.inkSoft,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.context != null && _effectiveController.hintLevel < 4)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _handleTapMai,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Gợi ý thêm →',
                                    style: VimaiType.caption.copyWith(
                                      color: VimaiColor.sky,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : null,
                ),
              ),
            ),

          // Animated Mascot with reactive state
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: aiEnabled ? _handleTapMai : null,
            child: ScaleTransition(
              scale: state == MaiState.thinking || state == MaiState.celebrating
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Subtle glow halo in celebrating / hinting states
                  if (state == MaiState.celebrating || state == MaiState.hinting)
                    Container(
                      width: widget.mascotSize * 1.15,
                      height: widget.mascotSize * 1.15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (state == MaiState.celebrating ? VimaiColor.honey : VimaiColor.mint)
                            .withValues(alpha: 0.22),
                      ),
                    ),
                  VimaiMascot(
                    mood: state.mascotMood,
                    size: widget.mascotSize,
                    color: mascotColor,
                  ),
                ],
              ),
            ),
          ),

          // Friendly Hint Button when idle in quiz
          if (aiEnabled && widget.showHintButton && message == null && widget.context != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleTapMai,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: VimaiColor.honeySoft.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VimaiColor.honey.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lightbulb_rounded, size: 14, color: VimaiColor.honey),
                      const SizedBox(width: 4),
                      Text(
                        'Mai gợi ý nhé!',
                        style: VimaiType.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: VimaiColor.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _bubbleBackgroundForState(MaiState state) {
    switch (state) {
      case MaiState.celebrating:
        return VimaiColor.honeySoft;
      case MaiState.hinting:
      case MaiState.thinking:
        return VimaiColor.mintSoft;
      case MaiState.encouraging:
        return VimaiColor.coralSoft;
      default:
        return Colors.white;
    }
  }

  Color _bubbleBorderForState(MaiState state) {
    switch (state) {
      case MaiState.celebrating:
        return VimaiColor.honey;
      case MaiState.hinting:
      case MaiState.thinking:
        return VimaiColor.mint;
      case MaiState.encouraging:
        return VimaiColor.coral;
      default:
        return VimaiColor.sky;
    }
  }
}
