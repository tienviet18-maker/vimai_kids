import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/vimai_mascot.dart';

/// Interactive, friendly floating or embedded Mai AI Assistant mascot and speech bubble.
///
/// Designed to confirm visible integration of the Mai AI companion on the home screen
/// and provide child-friendly interactive encouragement.
class MaiAssistantBubble extends ConsumerStatefulWidget {
  final bool embedded;
  final String? initialMessage;
  final VoidCallback? onTap;

  const MaiAssistantBubble({
    super.key,
    this.embedded = false,
    this.initialMessage,
    this.onTap,
  });

  @override
  ConsumerState<MaiAssistantBubble> createState() => _MaiAssistantBubbleState();
}

class _MaiAssistantBubbleState extends ConsumerState<MaiAssistantBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  bool _expanded = true;
  int _messageIndex = 0;

  static const List<String> _greetings = [
    'Chào bé! Bạn Mai sẵn sàng cùng bé học chữ và số nhé! 🌟',
    'Hôm nay bé muốn học chữ Tiếng Việt hay số Toán học nào? 🎈',
    'Bé nhớ phát âm rõ các âm "a...", "á...", "ớ..." cùng Mai nhé! ✨',
    'Cố gắng lên nào, Mai rất tự hào về bé! 🚀',
    'Bạn Mai luôn ở đây giúp bé khám phá mọi bài học vui! 🌸',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _expanded = true;
      _messageIndex = (_messageIndex + 1) % _greetings.length;
    });

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    Color avatarColor = VimaiColor.mint;
    try {
      final profile = ref.watch(currentProfileProvider);
      avatarColor = mascotColorForAvatar(profile?.avatar ?? 'mai');
    } catch (_) {}
    final currentText = widget.initialMessage ?? _greetings[_messageIndex];

    final avatarWidget = GestureDetector(
      key: const Key('mai-assistant-avatar'),
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF9E79), Color(0xFFFF5252)],
            ),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40FF5252),
                blurRadius: 14,
                spreadRadius: 2,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: VimaiMascot(
                  mood: MascotMood.happy,
                  color: avatarColor,
                  size: 40,
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!_expanded) {
      return Semantics(
        label: 'Mở trợ lý Mai AI',
        button: true,
        child: avatarWidget,
      );
    }

    final bubbleContent = GestureDetector(
      key: const Key('mai-assistant-bubble'),
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD54F), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFFF5252)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                      SizedBox(width: 3),
                      Text(
                        'Mai AI Companion',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _expanded = false),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              currentText,
              style: VimaiType.cardTitle.copyWith(
                color: VimaiColor.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD54F), width: 2),
        ),
        child: Row(
          children: [
            avatarWidget,
            const SizedBox(width: 8),
            Expanded(child: bubbleContent),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: bubbleContent,
          ),
        ),
        const SizedBox(width: 8),
        avatarWidget,
      ],
    );
  }
}
