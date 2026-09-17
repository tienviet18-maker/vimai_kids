import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../shared/widgets/kids_storybook.dart';

export 'catch_kana_game.dart';
export 'feed_animal_game.dart';
export 'find_similar_game.dart';
export 'listen_kana_game.dart';
export 'match_kana_game.dart';
export 'math_rocket_game.dart';
export 'number_train_game.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Bắt chữ Hiragana', 'Bắt chữ đang rơi', '/games/catch-kana?alphabet=hiragana', 'あ', AppTheme.hiraganaColor),
      ('Bắt chữ Katakana', 'Bắt chữ cứng đang rơi', '/games/catch-kana?alphabet=katakana', 'ア', AppTheme.katakanaColor),
      ('Bắt chữ Tiếng Việt', 'Bắt chữ cái đang rơi', '/games/catch-kana?alphabet=vietnamese', 'A', VimaiColor.sky),
      ('Nghe và bắt chữ', 'Nghe rồi chọn chữ đúng', '/games/listen-kana', 'あ', AppTheme.katakanaColor),
      ('Ghép đôi chữ', 'Tìm hai chữ giống nhau', '/games/match-kana', 'あ', VimaiColor.coral),
      ('Tên lửa toán', 'Chọn đáp án đúng', '/games/math-rocket', '+', AppTheme.mathColor),
      ('Tàu số', 'Xếp số theo thứ tự', '/games/number-train', '12', VimaiColor.sky),
      ('Cho thú ăn', 'Đếm thức ăn', '/games/feed-animal', '3', VimaiColor.mint),
      ('Tìm hình giống nhau', 'Tìm hai hình giống nhau', '/games/find-similar', '◆', VimaiColor.grape),
      ('Nghe và chọn chữ tiếng Việt', 'Nghe rồi chọn chữ', '/vietnamese/game', 'A', VimaiColor.sky),
    ];
    return KidsHubShell(
      title: 'Trò chơi',
      subtitle: 'Học mà chơi — chọn một trò để bắt đầu',
      accent: VimaiColor.honey,
      artAsset: VimaiArt.gamesPlayground,
      onBack: () => context.pop(),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          for (var i = 0; i < items.length; i++)
            KidsChapterBanner(
              title: items[i].$1,
              subtitle: items[i].$2,
              color: items[i].$5,
              glyph: items[i].$4,
              featured: i == 0,
              artAsset: i == 0 ? VimaiArt.gamesPlayground : null,
              onTap: () => context.push(items[i].$3),
            ),
        ],
      ),
    );
  }
}
