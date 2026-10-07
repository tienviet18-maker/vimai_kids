import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/kid_guide.dart';
import '../../../core/routing/nav_utils.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/listen_prompt.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_world.dart';
import 'widgets/game_art.dart';
import 'widgets/game_scene.dart';

export 'catch_kana_game.dart';
export 'feed_animal_game.dart';
export 'find_similar_game.dart';
export 'listen_kana_game.dart';
export 'match_kana_game.dart';
export 'math_rocket_game.dart';
export 'number_train_game.dart';

enum _Art { bubbles, speaker, cards, rocket, train, panda }

class _GameEntry {
  const _GameEntry(
      this.title, this.route, this.color, this.scene, this.art, this.glyphs);
  final String title;
  final String route;
  final Color color;
  final GameScene scene;
  final _Art art;
  final List<String> glyphs;
}

const _games = [
  _GameEntry('Bắt chữ Hiragana', '/games/catch-kana?alphabet=hiragana',
      Color(0xFFFF4F86), GameScene.sky, _Art.bubbles, ['あ', 'い', 'う']),
  _GameEntry('Tên lửa toán', '/games/math-rocket', Color(0xFF6D4BD8),
      GameScene.space, _Art.rocket, ['+']),
  _GameEntry('Cho thú ăn', '/games/feed-animal', Color(0xFF22B45A),
      GameScene.meadow, _Art.panda, ['🍎']),
  _GameEntry('Tàu số', '/games/number-train', Color(0xFF2F86E0),
      GameScene.railway, _Art.train, ['1', '2', '3']),
  _GameEntry('Tìm hình giống nhau', '/games/find-similar', Color(0xFFFF8A3D),
      GameScene.table, _Art.cards, ['🐱', '🐱']),
  _GameEntry('Ghép đôi chữ', '/games/match-kana', Color(0xFFE5397A),
      GameScene.table, _Art.cards, ['あ', 'あ']),
  _GameEntry('Nghe và bắt chữ', '/games/listen-kana', Color(0xFFB0306A),
      GameScene.stage, _Art.speaker, ['あ']),
  _GameEntry('Bắt chữ Katakana', '/games/catch-kana?alphabet=katakana',
      Color(0xFF3F7FD6), GameScene.sky, _Art.bubbles, ['ア', 'イ', 'ウ']),
  _GameEntry('Bắt chữ Tiếng Việt', '/games/catch-kana?alphabet=vietnamese',
      Color(0xFF14A3B8), GameScene.sky, _Art.bubbles, ['A', 'B', 'C']),
  _GameEntry('Nghe và chọn chữ tiếng Việt', '/vietnamese/game',
      Color(0xFFE0A100), GameScene.stage, _Art.speaker, ['A']),
];

/// The games shelf: big painted tiles, one per game, each previewing the
/// world the game is played in.
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SpeakOnOpen(
      lines: const [KidGuide.gamesHub],
      child: Scaffold(
        backgroundColor: GameScene.arcade.base,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const GameSceneBackdrop(scene: GameScene.arcade),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 30, 10, 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: ChunkyButton(
                            circle: true,
                            depth: 4,
                            color: Colors.white,
                            outlineWidth: 0,
                            semanticLabel: 'Quay lại',
                            onTap: () => navigateBackToHome(context),
                            child: const Center(
                                child: Icon(Icons.arrow_back_rounded,
                                    size: 30, color: VimaiColor.ink)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Khu vui chơi',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: VimaiType.display.copyWith(
                                  color: Colors.white,
                                  fontSize: 30,
                                  height: 1.05,
                                  shadows: const [
                                    Shadow(
                                        color: Color(0xFFC77700),
                                        offset: Offset(0, 3)),
                                    Shadow(
                                        color: Color(0x55000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 4)),
                                  ],
                                ),
                              ),
                              Text(
                                'Chạm vào một trò để chơi nhé!',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: VimaiType.label.copyWith(
                                    color: const Color(0xFF8A4B00),
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const IdleMascot(
                            mood: MascotMood.excited,
                            color: VimaiColor.mascot,
                            size: 66),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final columns = w < 560 ? 2 : (w < 860 ? 3 : 4);
                            return GridView.builder(
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.84,
                              ),
                              itemCount: _games.length,
                              itemBuilder: (context, i) => _GameTile(
                                  entry: _games[i],
                                  onTap: () => context.push(_games[i].route)),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.entry, required this.onTap});

  final _GameEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      color: entry.color,
      radius: 28,
      depth: 8,
      outlineWidth: 4,
      semanticLabel: entry.title,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                        painter: GameScenePainter(
                            scene: entry.scene,
                            time: const AlwaysStoppedAnimation(0.18))),
                    _TileArt(entry: entry),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 6,
                                offset: Offset(0, 3))
                          ],
                        ),
                        child: Icon(Icons.play_arrow_rounded,
                            color: entry.color, size: 26),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 42,
              child: Center(
                child: Text(
                  entry.title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: VimaiType.cardTitle.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.1,
                    shadows: const [
                      Shadow(
                          color: Color(0x40000000),
                          offset: Offset(0, 1.5),
                          blurRadius: 2)
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileArt extends StatelessWidget {
  const _TileArt({required this.entry});
  final _GameEntry entry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final s = math.min(c.maxWidth, c.maxHeight);
        switch (entry.art) {
          case _Art.bubbles:
            const colors = [
              Color(0xFFFF4F86),
              Color(0xFFFFA726),
              Color(0xFF8B5CF6)
            ];
            return Stack(
              children: [
                for (var i = 0; i < entry.glyphs.length; i++)
                  Positioned(
                    left: c.maxWidth * (0.08 + i * 0.3),
                    top: c.maxHeight * (i.isOdd ? 0.12 : 0.36),
                    child: _MiniBubble(
                        letter: entry.glyphs[i],
                        color: colors[i % colors.length],
                        size: s * 0.4),
                  ),
              ],
            );
          case _Art.rocket:
            return Center(
              child: Transform.rotate(
                angle: 0.35,
                child: SizedBox(
                    width: s * 0.42,
                    height: s * 0.76,
                    child: CustomPaint(
                        painter: RocketPainter(flame: 0.2, boost: 0.6))),
              ),
            );
          case _Art.panda:
            return Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -0.2),
                  child: SizedBox(
                      width: s * 0.78,
                      height: s * 0.72,
                      child: CustomPaint(
                          painter: PandaPainter(mouth: 0.7, happy: true))),
                ),
                Positioned(
                  left: c.maxWidth * 0.06,
                  bottom: c.maxHeight * 0.06,
                  child: Text(entry.glyphs.first,
                      style: TextStyle(fontSize: s * 0.24, height: 1)),
                ),
              ],
            );
          case _Art.train:
            return Align(
              alignment: const Alignment(0, 0.35),
              child: SizedBox(
                  width: s * 0.86,
                  height: s * 0.69,
                  child: CustomPaint(painter: TrainEnginePainter(puff: 0.35))),
            );
          case _Art.cards:
            return Center(
              child: SizedBox(
                width: s * 0.9,
                height: s * 0.7,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = 0; i < 2; i++)
                      Transform.translate(
                        offset: Offset((i == 0 ? -1 : 1) * s * 0.17, 0),
                        child: Transform.rotate(
                          angle: (i == 0 ? -1 : 1) * 0.16,
                          child: Container(
                            width: s * 0.38,
                            height: s * 0.5,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(s * 0.06),
                              border: Border.all(color: entry.color, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x40000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 4))
                              ],
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  entry.glyphs[i],
                                  style: TextStyle(
                                      fontSize: s * 0.26,
                                      fontWeight: FontWeight.w900,
                                      color: entry.color,
                                      height: 1.1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          case _Art.speaker:
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: s * 0.5,
                  height: s * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF4F86),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFFFE680).withValues(alpha: 0.6),
                          blurRadius: 18,
                          spreadRadius: 4)
                    ],
                  ),
                  child: Icon(Icons.volume_up_rounded,
                      color: Colors.white, size: s * 0.28),
                ),
                Positioned(
                  right: c.maxWidth * 0.08,
                  top: c.maxHeight * 0.14,
                  child: _MiniBubble(
                      letter: entry.glyphs.first,
                      color: const Color(0xFF4C8DDB),
                      size: s * 0.3),
                ),
                Positioned(
                  left: c.maxWidth * 0.12,
                  top: c.maxHeight * 0.2,
                  child: Icon(Icons.music_note_rounded,
                      color: const Color(0xFFFFE680), size: s * 0.2),
                ),
              ],
            );
        }
      },
    );
  }
}

class _MiniBubble extends StatelessWidget {
  const _MiniBubble(
      {required this.letter, required this.color, required this.size});
  final String letter;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [Color.lerp(color, Colors.white, 0.45)!, color],
        ),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Text(
        letter,
        style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1),
      ),
    );
  }
}
