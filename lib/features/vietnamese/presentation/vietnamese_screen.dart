import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/vimai_art.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/kids_storybook.dart';

class VietnameseScreen extends ConsumerWidget {
  const VietnameseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final age = profile?.age ?? 5;
    final copy = AppStrings.of(profile, context);
    final items = [
      const (title: 'Học chữ', subtitle: 'Vuốt A → Ă → Â cùng Mai', route: '/vietnamese/learn', glyph: 'A'),
      const (title: 'Viết chữ', subtitle: 'Tập viết theo mẫu', route: '/vietnamese/learn?mode=write', glyph: 'A'),
      const (title: 'Bảng chữ cái', subtitle: '29 chữ a ă â… y', route: '/vietnamese/alphabet', glyph: 'Ă'),
      const (title: 'Chọn chữ', subtitle: 'Nghe rồi chọn chữ đúng', route: '/vietnamese/learn?mode=recognize', glyph: '?'),
      const (title: 'Ghép âm', subtitle: 'b + a → ba', route: '/vietnamese/blend', glyph: 'ba'),
      if (age >= 5) const (title: 'Ghép vần', subtitle: 'an, ang, anh…', route: '/vietnamese/rimes', glyph: 'an'),
      const (title: 'Từ đơn giản', subtitle: 'ba, mẹ, cá…', route: '/vietnamese/words', glyph: 'từ'),
      const (title: 'Từ vựng', subtitle: 'Từ theo chủ đề', route: '/vietnamese/vocabulary', glyph: 'từ'),
      if (age >= 4) const (title: 'Câu ngắn', subtitle: 'Đọc câu ngắn', route: '/vietnamese/sentences', glyph: 'câu'),
      const (title: 'Nhiều dạng bài', subtitle: 'Chọn chữ theo gợi ý', route: '/vietnamese/choose', glyph: 'A'),
      const (title: 'Trò chơi tiếng Việt', subtitle: 'Nghe và chọn chữ', route: '/vietnamese/game', glyph: '▶'),
    ];

    return KidsHubShell(
      title: copy.vietnamese,
      subtitle: copy.vietnameseSub,
      accent: VimaiColor.sky,
      artAsset: VimaiArt.vietnameseGarden,
      onBack: () => context.pop(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final tablet = constraints.maxWidth >= 600;
          if (!tablet) {
            return ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                for (var i = 0; i < items.length; i++)
                  KidsChapterBanner(
                    title: items[i].title,
                    subtitle: items[i].subtitle,
                    color: VimaiColor.sky,
                    glyph: items[i].glyph,
                    artAsset: i == 0 ? VimaiArt.vietnameseGarden : null,
                    featured: i == 0,
                    onTap: () => context.push(items[i].route),
                  ),
              ],
            );
          }

          // iPad / tablet: interactive book-page 2-column grid.
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 118,
              crossAxisSpacing: 4,
              mainAxisSpacing: 2,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              return KidsChapterBanner(
                title: items[i].title,
                subtitle: items[i].subtitle,
                color: VimaiColor.sky,
                glyph: items[i].glyph,
                artAsset: i == 0 ? VimaiArt.vietnameseGarden : null,
                featured: i == 0,
                onTap: () => context.push(items[i].route),
              );
            },
          );
        },
      ),
    );
  }
}
