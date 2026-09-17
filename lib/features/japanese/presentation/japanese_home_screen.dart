import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/vimai_art.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/kids_storybook.dart';

class JapaneseHomeScreen extends ConsumerWidget {
  const JapaneseHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = AppStrings.of(ref.watch(currentProfileProvider), context);
    const hira = AppTheme.hiraganaColor;
    const kata = AppTheme.katakanaColor;
    return KidsHubShell(
      title: copy.japanese,
      subtitle: copy.japanesePath,
      accent: hira,
      artAsset: VimaiArt.japanLesson,
      onBack: () => context.pop(),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          const KidsHubLabel('Hiragana', color: hira),
          ..._chapters(context, hira, const [
            ('Học Hiragana', 'あ → い → う', '/japanese/learn/hiragana?type=basic', 'あ', true),
            ('Viết Hiragana', 'Tự viết sau khi xem mẫu', '/japanese/learn/hiragana?type=basic&mode=write', 'あ', false),
            ('Chọn chữ Hiragana', 'Nghe rồi chọn chữ đúng', '/japanese/learn/hiragana?type=basic&mode=recognize', 'あ', false),
            ('Bảng Hiragana', 'Tất cả chữ mềm', '/japanese/library/hiragana', 'い', false),
          ], art: VimaiArt.japaneseVillage),
          const KidsHubLabel('Thêm chữ Hiragana', color: hira),
          ..._chapters(context, hira, const [
            ('Hiragana dakuten', 'が ざ だ ば', '/japanese/learn/hiragana?type=dakuten', 'が', false),
            ('Hiragana handakuten', 'ぱ ぴ ぷ ぺ ぽ', '/japanese/learn/hiragana?type=handakuten', 'ぱ', false),
            ('Hiragana yoon', 'きゃ しゃ ちゃ', '/japanese/learn/hiragana?type=yoon', 'き', false),
            ('Chữ nhỏ', 'ぁ ぃ ぅ ぇ ぉ', '/japanese/learn/hiragana?type=small', 'ぁ', false),
            ('Sokuon', 'っ', '/japanese/learn/hiragana?type=sokuon', 'っ', false),
            ('Choon', 'ー', '/japanese/learn/hiragana?type=choon', 'ー', false),
          ]),
          const KidsHubLabel('Katakana', color: kata),
          ..._chapters(context, kata, const [
            ('Học Katakana', 'ア → イ → ウ', '/japanese/learn/katakana?type=basic', 'ア', true),
            ('Viết Katakana', 'Tự viết sau khi xem mẫu', '/japanese/learn/katakana?type=basic&mode=write', 'ア', false),
            ('Chọn chữ Katakana', 'Nghe rồi chọn chữ đúng', '/japanese/learn/katakana?type=basic&mode=recognize', 'ア', false),
            ('Bảng Katakana', 'Tất cả chữ cứng', '/japanese/library/katakana', 'イ', false),
          ], art: VimaiArt.japanLesson),
          const KidsHubLabel('Thêm chữ Katakana', color: kata),
          ..._chapters(context, kata, const [
            ('Katakana dakuten', 'ガ ザ ダ バ', '/japanese/learn/katakana?type=dakuten', 'ガ', false),
            ('Katakana handakuten', 'パ ピ プ ペ ポ', '/japanese/learn/katakana?type=handakuten', 'パ', false),
            ('Katakana yoon', 'キャ シャ チャ', '/japanese/learn/katakana?type=yoon', 'キ', false),
            ('Katakana chữ nhỏ', 'ァ ィ ゥ ェ ォ', '/japanese/learn/katakana?type=small', 'ァ', false),
            ('Katakana sokuon', 'ッ', '/japanese/learn/katakana?type=sokuon', 'ッ', false),
            ('Katakana choon', 'ー', '/japanese/learn/katakana?type=choon', 'ー', false),
            ('Âm ngoại lai', 'ファ ティ ウィ', '/japanese/learn/katakana?type=extended', 'フ', false),
          ]),
          ],
        ),
      ),
    );
  }

  List<Widget> _chapters(
    BuildContext context,
    Color color,
    List<(String, String, String, String, bool)> items, {
    String? art,
  }) {
    return [
      for (var i = 0; i < items.length; i++)
        KidsChapterBanner(
          title: items[i].$1,
          subtitle: items[i].$2,
          color: color,
          glyph: items[i].$4,
          featured: items[i].$5,
          artAsset: items[i].$5 ? art : null,
          onTap: () => context.push(items[i].$3),
        ),
    ];
  }
}
