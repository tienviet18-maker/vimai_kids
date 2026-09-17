import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/continue_learning.dart';
import '../../../data/content/progress_labels.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/models/skill_mastery.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_ui.dart';
import '../../shared/widgets/vimai_world.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final copy = AppStrings.of(profile, context);
    final List<SkillMastery> items =
        profile == null ? const [] : ref.watch(masteryRepositoryProvider).allForChild(profile.id);

    int countPrefix(String prefix) => items.where((e) => e.skill.startsWith(prefix) && e.attempts > 0).length;

    final today = items.where((e) {
      final reviewed = e.lastReviewed;
      if (reviewed == null) return false;
      final now = DateTime.now();
      return reviewed.year == now.year && reviewed.month == now.month && reviewed.day == now.day;
    }).length;
    final review = items.where((e) => e.needsReview || e.incorrect > e.correct).take(6).toList();
    final remembered = ProgressLabels.rememberedCount(items);
    final practicing = items.where((e) => e.attempts > 0 && !e.isMastered).length;
    final active = items.where((e) => e.attempts > 0).length;

    return IllustratedScaffold(
      title: copy.progress,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        tooltip: copy.back,
        onPressed: () => context.pop(),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VimaiMascot(mood: MascotMood.encouraging, size: 96, color: mascotColorForAvatar(profile?.avatar ?? 'peach')),
                    const SizedBox(height: 16),
                    Text(copy.noProgressYet, textAlign: TextAlign.center, style: VimaiType.subtitle),
                  ],
                ),
              ),
            )
          : ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Row(
                  children: [
                    VimaiMascot(
                      mood: MascotMood.celebrating,
                      size: VimaiSize.mascotCard,
                      color: mascotColorForAvatar(profile?.avatar ?? 'peach'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile == null ? copy.progress : '${copy.progress} · ${profile.childName}',
                            style: VimaiType.title,
                          ),
                          Text(copy.learnedToday(today), style: VimaiType.subtitle),
                          Text(copy.starsToday(today), style: VimaiType.caption),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatChip(
                      label: '$today',
                      caption: copy.todayTitle,
                      color: VimaiColor.teal,
                      value: profile == null ? 0 : (profile.todayMinutes / profile.dailyMinutes).clamp(0, 1),
                    ),
                    _StatChip(label: '$remembered', caption: copy.remembered, color: VimaiColor.mint, value: active == 0 ? 0 : (remembered / active).clamp(0, 1)),
                    _StatChip(label: '$practicing', caption: copy.practicing, color: VimaiColor.honey, value: active == 0 ? 0 : (practicing / active).clamp(0, 1)),
                    _StatChip(label: ProgressLabels.mostPracticed(items), caption: copy.mostPracticed, color: VimaiColor.coral, value: 0),
                  ],
                ),
                const SizedBox(height: 20),
                Text(copy.subjects, style: VimaiType.title.copyWith(fontSize: 18)),
                const SizedBox(height: 8),
                _line('${copy.japanese}: ${countPrefix('japanese')}', VimaiColor.coral, active == 0 ? 0 : (countPrefix('japanese') / active).clamp(0, 1)),
                _line('${copy.vietnamese}: ${countPrefix('vietnamese')}', VimaiColor.sky, active == 0 ? 0 : (countPrefix('vietnamese') / active).clamp(0, 1)),
                _line('${copy.math}: ${countPrefix('math')}', VimaiColor.mint, active == 0 ? 0 : (countPrefix('math') / active).clamp(0, 1)),
                _line('${copy.thinking}: ${countPrefix('thinking')}', VimaiColor.grape, active == 0 ? 0 : (countPrefix('thinking') / active).clamp(0, 1)),
                _line('${copy.games}: ${countPrefix('game')}', VimaiColor.honey, active == 0 ? 0 : (countPrefix('game') / active).clamp(0, 1)),
                const SizedBox(height: 20),
                Text(copy.needsReviewFriendly, style: VimaiType.title.copyWith(fontSize: 18)),
                const SizedBox(height: 8),
                if (review.isEmpty)
                  Text(copy.noReview, style: VimaiType.subtitle)
                else
                  ...review.map(
                    (e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(ProgressLabels.title(e), style: VimaiType.cardTitle),
                      subtitle: Text(ProgressLabels.subject(e), style: VimaiType.caption),
                      trailing: const Icon(Icons.chevron_right_rounded, size: VimaiSize.iconMd),
                      onTap: () => context.push(ReviewPractice.route(e)),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _line(String text, Color color, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: VimaiType.subtitle.copyWith(color: VimaiColor.ink, fontSize: 16)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.caption, required this.color, this.value = 0});
  final String label;
  final String caption;
  final Color color;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 108, minHeight: VimaiSize.touchKid),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VimaiRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressRing(
            value: value,
            color: color,
            size: 36,
            child: Text(label.length > 3 ? '★' : label, style: VimaiType.caption.copyWith(color: color, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: VimaiType.cardTitle.copyWith(color: color, fontSize: 15)),
              Text(caption, style: VimaiType.caption),
            ],
          ),
        ],
      ),
    );
  }
}
