import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/branding/config.dart';
import '../../../core/contact/feedback_mail.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/continue_learning.dart';
import '../../../data/content/progress_labels.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/models/child_profile.dart';
import '../../../domain/models/skill_mastery.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_ui.dart';

class ParentScreen extends ConsumerStatefulWidget {
  const ParentScreen({super.key});

  @override
  ConsumerState<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends ConsumerState<ParentScreen> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: ref.read(currentProfileProvider)?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _openMail(AppStrings copy, {required String childName, required int age}) async {
    final uri = FeedbackMail.mailto(childName: childName, age: age);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(copy.mailMissing),
            content: Text(copy.mailMissingBody),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(copy.close))],
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(copy.mailMissing),
            content: Text(copy.mailMissingBody),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(copy.close))],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final copy = AppStrings.of(profile, context);
    final List<SkillMastery> items =
        profile == null ? const [] : ref.watch(masteryRepositoryProvider).allForChild(profile.id);
    final weak = items.where((e) => e.needsReview || e.incorrect > e.correct).take(8).toList();

    return PageScaffold(
      title: copy.parent,
      background: VimaiColor.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        tooltip: copy.back,
        onPressed: () => context.pop(),
      ),
      body: profile == null
          ? Center(child: Text(copy.noProfile, style: VimaiType.subtitle))
          : ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _Card(
                  child: Row(
                    children: [
                      VimaiMascot(mood: MascotMood.happy, size: 72, color: mascotColorForAvatar(profile.avatar)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.childName, style: VimaiType.title),
                            Text(copy.doingGreat(profile.childName), style: VimaiType.subtitle),
                            Text(copy.ageLabel(profile.age), style: VimaiType.caption),
                            Text(AppBrand.productDisplayName, style: VimaiType.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHead(icon: Icons.wb_sunny_rounded, title: copy.todayMinutes, color: VimaiColor.honey),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(copy.activitiesToday(_todayCount(items)), style: VimaiType.cardTitle),
                      Text(copy.learnedTodayMinutes(profile.todayMinutes), style: VimaiType.cardBody),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: (profile.todayMinutes / profile.dailyMinutes).clamp(0, 1),
                          minHeight: 10,
                          color: VimaiColor.honey,
                          backgroundColor: VimaiColor.honey.withValues(alpha: 0.15),
                        ),
                      ),
                      Text('${copy.dailyMinutes}: ${copy.minutes(profile.dailyMinutes)}', style: VimaiType.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionHead(icon: Icons.auto_stories_rounded, title: copy.learningSection, color: VimaiColor.mint),
                _Card(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _minTile(copy.japanese, copy.minutes(profile.minutesFor('japanese')), VimaiColor.coral)),
                          const SizedBox(width: 8),
                          Expanded(child: _minTile(copy.vietnamese, copy.minutes(profile.minutesFor('vietnamese')), VimaiColor.sky)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _minTile(copy.math, copy.minutes(profile.minutesFor('math')), VimaiColor.mint)),
                          const SizedBox(width: 8),
                          Expanded(child: _minTile(copy.thinking, copy.minutes(profile.minutesFor('thinking')), VimaiColor.grape)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionHead(icon: Icons.star_rounded, title: copy.strengths, color: VimaiColor.coral),
                _Card(
                  child: Text(
                    items.isEmpty ? copy.noProgressYet : ProgressLabels.mostPracticed(items),
                    style: VimaiType.cardTitle,
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHead(icon: Icons.child_care_rounded, title: copy.childProfile, color: VimaiColor.peach),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(copy.childName, style: VimaiType.caption),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _name,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: VimaiColor.cream,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(VimaiRadius.md)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(copy.howOld, style: VimaiType.caption),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [3, 4, 5, 6, 7].map((age) {
                          final selected = profile.age == age;
                          return ChoiceChip(
                            label: Text(copy.ageLabel(age)),
                            selected: selected,
                            onSelected: (_) async {
                              await ref.read(currentProfileProvider.notifier).setProfile(profile.copyWith(age: age));
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      KidButton(
                        label: copy.save,
                        onPressed: () async {
                          final name = _name.text.trim();
                          if (name.isEmpty) return;
                          await ref.read(currentProfileProvider.notifier).setProfile(profile.copyWith(name: name));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(copy.saved)));
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionHead(icon: Icons.replay_rounded, title: copy.needsPractice, color: VimaiColor.peach),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(copy.review, style: VimaiType.cardTitle),
                      Text(copy.needsReviewFriendly, style: VimaiType.caption),
                      const SizedBox(height: 8),
                      if (weak.isEmpty)
                        Text(copy.noReview, style: VimaiType.cardBody)
                      else
                        ...weak.map(
                          (e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(ReviewPractice.title(e), style: VimaiType.cardTitle.copyWith(fontSize: 15)),
                            subtitle: Text('${e.correct}/${e.attempts}'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.push(ReviewPractice.route(e)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionHead(icon: Icons.tune_rounded, title: copy.settingsSection, color: VimaiColor.sky),
                _Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(copy.sound),
                        value: profile.soundEnabled,
                        onChanged: (value) async {
                          final settings = Map<String, dynamic>.from(profile.settings)..['sound'] = value;
                          await ref.read(currentProfileProvider.notifier).setProfile(profile.copyWith(settings: settings));
                          ref.read(audioServiceProvider).soundEnabled = value;
                        },
                      ),
                      if (profile.soundEnabled) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(copy.voiceVolumeLabel, style: VimaiType.caption),
                                  Text('${(profile.voiceVolume * 100).round()}%', style: VimaiType.caption),
                                ],
                              ),
                              Slider(
                                value: profile.voiceVolume.clamp(0.0, 1.0),
                                min: 0.0,
                                max: 1.0,
                                divisions: 10,
                                onChanged: (val) async {
                                  final settings = Map<String, dynamic>.from(profile.settings)..['voiceVolume'] = val;
                                  await ref.read(currentProfileProvider.notifier).setProfile(profile.copyWith(settings: settings));
                                  await ref.read(audioServiceProvider).setVoiceVolume(val);
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(copy.bgmVolumeLabel, style: VimaiType.caption),
                                  Text('${(profile.bgmVolume * 100).round()}%', style: VimaiType.caption),
                                ],
                              ),
                              Slider(
                                value: profile.bgmVolume.clamp(0.0, 1.0),
                                min: 0.0,
                                max: 1.0,
                                divisions: 10,
                                onChanged: (val) async {
                                  final settings = Map<String, dynamic>.from(profile.settings)..['bgmVolume'] = val;
                                  await ref.read(currentProfileProvider.notifier).setProfile(profile.copyWith(settings: settings));
                                  await ref.read(audioServiceProvider).setBgmVolume(val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(copy.dailyMinutes),
                        subtitle: Text(copy.minutes(profile.dailyMinutes)),
                        trailing: DropdownButton<int>(
                          value: profile.dailyMinutes,
                          items: [10, 15, 20, 30]
                              .map((m) => DropdownMenuItem(value: m, child: Text(copy.minutes(m))))
                              .toList(),
                          onChanged: (value) async {
                            if (value == null) return;
                            final settings = Map<String, dynamic>.from(profile.settings)..['dailyMinutes'] = value;
                            await ref.read(currentProfileProvider.notifier).setProfile(profile.copyWith(settings: settings));
                          },
                        ),
                      ),
                      Align(alignment: Alignment.centerLeft, child: Text(copy.uiLanguage, style: VimaiType.caption)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _langChip(profile, 'vi', 'Tiếng Việt'),
                          _langChip(profile, 'en', 'English'),
                          _langChip(profile, 'ja', '日本語'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(copy.resetProgress),
                        content: Text(copy.confirmReset),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(copy.cancel)),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(copy.confirm)),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await ref.read(masteryRepositoryProvider).clearChild(profile.id);
                      setState(() {});
                    }
                  },
                  child: Text(copy.resetProgress),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(currentProfileProvider.notifier).clear();
                    context.go('/profiles');
                  },
                  child: Text(copy.switchChild),
                ),
                const SizedBox(height: 16),
                _SectionHead(icon: Icons.mail_outline_rounded, title: copy.support, color: VimaiColor.sky),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(copy.needHelp, style: VimaiType.cardTitle),
                      const SizedBox(height: 6),
                      Text(copy.supportBody, style: VimaiType.cardBody),
                      const SizedBox(height: 8),
                      const SelectableText(
                        AppBrand.supportEmail,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: VimaiColor.sky),
                      ),
                      const SizedBox(height: 10),
                      KidButton(
                        label: copy.sendEmail,
                        color: VimaiColor.sky,
                        onPressed: () => _openMail(copy, childName: profile.childName, age: profile.age),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionHead(icon: Icons.chat_bubble_outline_rounded, title: copy.feedbackTitle, color: VimaiColor.peach),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(copy.contact, style: VimaiType.cardTitle),
                      const SizedBox(height: 6),
                      Text(copy.supportBody, style: VimaiType.cardBody),
                      const SizedBox(height: 10),
                      KidButton(
                        label: copy.sendEmail,
                        color: VimaiColor.peach,
                        onPressed: () => _openMail(copy, childName: profile.childName, age: profile.age),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHead(icon: Icons.info_outline_rounded, title: copy.aboutVimai, color: VimaiColor.honey),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppBrand.productDisplayName, style: VimaiType.title.copyWith(fontSize: 20)),
                      const SizedBox(height: 6),
                      Text('${copy.version} ${AppBrand.version}', style: VimaiType.cardBody),
                      Text('${copy.developer}: ${AppBrand.createdByLabel}', style: VimaiType.cardBody),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const _SectionHead(icon: Icons.auto_awesome_rounded, title: 'Mai AI', color: VimaiColor.honey),
                _Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bật Mai AI đồng hành'),
                        subtitle: const Text('Gợi ý sư phạm từng bước'),
                        value: profile.aiEnabled,
                        onChanged: (val) async {
                          final settings = Map<String, dynamic>.from(profile.settings)..['ai_enabled'] = val;
                          await ref.read(currentProfileProvider.notifier).setProfile(profile.copyWith(settings: settings));
                          ref.read(maiAiServiceProvider).isAiEnabled = val;
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tương tác giọng nói'),
                        subtitle: const Text('Mai trò chuyện cùng bé'),
                        value: profile.aiVoiceEnabled,
                        onChanged: (val) async {
                          final settings = Map<String, dynamic>.from(profile.settings)..['ai_voice_enabled'] = val;
                          await ref.read(currentProfileProvider.notifier).setProfile(profile.copyWith(settings: settings));
                          ref.read(maiAiServiceProvider).isVoiceEnabled = val;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(copy.licenses, style: VimaiType.cardTitle),
                      const SizedBox(height: 6),
                      Text(copy.licensesBody, style: VimaiType.caption.copyWith(height: 1.4)),
                      const SizedBox(height: 8),
                      Text(copy.kanjivgCredit, style: VimaiType.caption),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _langChip(ChildProfile profile, String code, String label) {
    final selected = (profile.settings['uiLang'] as String? ?? 'vi') == code;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) async {
        final settings = Map<String, dynamic>.from(profile.settings)..['uiLang'] = code;
        await ref.read(currentProfileProvider.notifier).setProfile(profile.copyWith(settings: settings));
      },
    );
  }

  Widget _minTile(String label, String minutesLabel, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VimaiRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: VimaiType.caption.copyWith(color: color, fontWeight: FontWeight.w800)),
          Text(minutesLabel, style: VimaiType.cardTitle.copyWith(fontSize: 16)),
        ],
      ),
    );
  }

  int _todayCount(List<SkillMastery> items) {
    final now = DateTime.now();
    return items.where((e) {
      final reviewed = e.lastReviewed;
      if (reviewed == null) return false;
      return reviewed.year == now.year && reviewed.month == now.month && reviewed.day == now.day;
    }).length;
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.icon, required this.title, required this.color});
  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: VimaiSize.iconMd),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: VimaiType.cardTitle.copyWith(color: color))),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VimaiRadius.lg),
        boxShadow: VimaiShadow.soft,
      ),
      child: Material(
        color: VimaiColor.surface,
        borderRadius: BorderRadius.circular(VimaiRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}
