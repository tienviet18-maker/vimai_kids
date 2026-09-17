import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/session_binder.dart';
import '../../../../core/theme/vimai_tokens.dart';
import '../../../shared/widgets/vimai_mascot.dart';
import '../../../shared/widgets/vimai_ui.dart';
import '../../logic/game_board_metrics.dart';

/// Shared kid-game chrome: header outside the board, constrained playfield.
class GamePlayScaffold extends StatelessWidget {
  const GamePlayScaffold({
    super.key,
    required this.title,
    required this.playArea,
    this.instruction,
    this.progress,
    this.feedback,
    this.footer,
    this.complete,
    this.finished = false,
  });

  final String title;
  final Widget? instruction;
  final Widget? progress;
  final Widget? feedback;
  final Widget playArea;
  final Widget? footer;
  final Widget? complete;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    return SessionBinder(
      subject: 'games',
      child: PageScaffold(
      title: title,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        tooltip: 'Quay lại',
        onPressed: () => context.pop(),
      ),
      body: finished && complete != null
          ? complete!
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (instruction != null) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: instruction),
                if (progress != null) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: progress),
                if (feedback != null) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 4), child: feedback),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: playArea,
                  ),
                ),
                if (footer != null) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: footer),
              ],
            ),
      ),
    );
  }
}

class GameTargetBanner extends StatelessWidget {
  const GameTargetBanner({
    super.key,
    required this.label,
    required this.glyph,
    required this.color,
  });

  final String label;
  final String glyph;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: VimaiColor.surface,
        borderRadius: BorderRadius.circular(VimaiRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
        boxShadow: VimaiShadow.soft,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: VimaiType.cardTitle.copyWith(color: VimaiColor.ink))),
          Container(
            constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(VimaiRadius.md),
            ),
            child: Text(
              glyph,
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class GameProgressBar extends StatelessWidget {
  const GameProgressBar({
    super.key,
    required this.current,
    required this.total,
    required this.color,
  });

  final int current;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = total <= 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
    return Row(
      children: [
        Text('$current / $total', style: VimaiType.cardTitle.copyWith(fontSize: 15, color: color)),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class GameCompletePanel extends StatelessWidget {
  const GameCompletePanel({
    super.key,
    required this.score,
    required this.wrong,
    required this.total,
    required this.onRetry,
    this.onContinue,
  });

  final int score;
  final int wrong;
  final int total;
  final VoidCallback onRetry;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const VimaiMascot(mood: MascotMood.celebrating, size: 96),
              const SizedBox(height: 16),
              Text('Giỏi lắm!', style: VimaiType.greeting.copyWith(color: VimaiColor.correct)),
              const SizedBox(height: 8),
              Text('$score đúng / $wrong sai  •  $total vòng', textAlign: TextAlign.center, style: VimaiType.subtitle),
              const SizedBox(height: 24),
              KidButton(label: 'Chơi lại', onPressed: onRetry, color: VimaiColor.coral),
              const SizedBox(height: 12),
              KidButton(
                label: 'Tiếp tục',
                onPressed: onContinue ?? () => context.pop(),
                color: VimaiColor.sky,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameBoard extends StatefulWidget {
  const GameBoard({
    super.key,
    required this.child,
    required this.onSize,
    this.color = VimaiColor.skySoft,
  });

  final Widget child;
  final ValueChanged<Size> onSize;
  final Color color;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  Size? _reported;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitted = GameBoardMetrics.fit(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox(
            key: const ValueKey('game-playfield'),
            width: fitted.width,
            height: fitted.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(VimaiRadius.lg),
                border: Border.all(color: VimaiColor.sky.withValues(alpha: 0.28), width: 2),
                boxShadow: VimaiShadow.card,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(VimaiRadius.lg),
                child: LayoutBuilder(
                  builder: (context, board) {
                    final size = Size(board.maxWidth, board.maxHeight);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || size.width < 8 || size.height < 8) return;
                      final last = _reported;
                      if (last != null && (last.width - size.width).abs() < 0.5 && (last.height - size.height).abs() < 0.5) {
                        return;
                      }
                      _reported = size;
                      widget.onSize(size);
                    });
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        const _BoardDecor(),
                        widget.child,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardDecor extends StatelessWidget {
  const _BoardDecor();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CloudPainter(), size: Size.infinite);
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    void cloud(double x, double y, double r) {
      canvas.drawCircle(Offset(x, y), r, paint);
      canvas.drawCircle(Offset(x + r * 0.9, y + r * 0.1), r * 0.75, paint);
      canvas.drawCircle(Offset(x - r * 0.7, y + r * 0.15), r * 0.6, paint);
    }

    cloud(size.width * 0.18, size.height * 0.16, size.shortestSide * 0.08);
    cloud(size.width * 0.72, size.height * 0.28, size.shortestSide * 0.07);
    cloud(size.width * 0.55, size.height * 0.72, size.shortestSide * 0.09);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GameLetterToken extends StatelessWidget {
  const GameLetterToken({
    super.key,
    required this.character,
    required this.size,
    required this.color,
    required this.onTap,
    this.shake = false,
    this.celebrate = false,
    this.semanticLabel,
  });

  final String character;
  final double size;
  final Color color;
  final VoidCallback onTap;
  final bool shake;
  final bool celebrate;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final duration = VimaiMotion.of(context, VimaiMotion.feedback);
    return AnimatedScale(
      scale: celebrate ? 1.12 : 1,
      duration: duration,
      child: AnimatedRotation(
        turns: shake ? 0.03 : 0,
        duration: duration,
        child: Pressable(
          semanticLabel: semanticLabel ?? character,
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: VimaiColor.surface,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: VimaiShadow.soft,
            ),
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  character,
                  style: TextStyle(fontSize: size * 0.46, fontWeight: FontWeight.w800, color: color, height: 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GameCardGrid extends StatelessWidget {
  const GameCardGrid({
    super.key,
    required this.itemCount,
    required this.builder,
  });

  final int itemCount;
  final IndexedWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitted = GameBoardMetrics.fit(constraints.maxWidth, constraints.maxHeight);
        final columns = fitted.width < 360 ? 3 : 4;
        return Center(
          child: SizedBox(
            width: fitted.width,
            height: fitted.height,
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              physics: const ClampingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: itemCount,
              itemBuilder: builder,
            ),
          ),
        );
      },
    );
  }
}
