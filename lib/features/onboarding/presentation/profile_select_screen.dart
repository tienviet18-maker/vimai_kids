import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/vimai_tokens.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_ui.dart';

class ProfileSelectScreen extends ConsumerWidget {
  const ProfileSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profileRepositoryProvider).getAllProfiles();
    return PageScaffold(
      title: 'Chọn bé',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: profiles.isEmpty
                  ? Center(child: Text('Chưa có hồ sơ', style: VimaiType.subtitle))
                  : ListView(
                      children: profiles.map((profile) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Pressable(
                            semanticLabel: profile.name,
                            onTap: () async {
                              await ref.read(currentProfileProvider.notifier).setProfile(profile);
                              if (context.mounted) context.go('/home');
                            },
                            child: Ink(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: VimaiColor.surface,
                                borderRadius: BorderRadius.circular(VimaiRadius.lg),
                                boxShadow: VimaiShadow.soft,
                              ),
                              child: Row(
                                children: [
                                  VimaiMascot(
                                    mood: MascotMood.happy,
                                    size: 56,
                                    color: mascotColorForAvatar(profile.avatar),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(profile.name, style: VimaiType.cardTitle.copyWith(fontSize: 20)),
                                        Text('${profile.age} tuổi', style: VimaiType.caption),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            KidButton(
              label: 'Thêm bé mới',
              onPressed: () => context.push('/onboarding/create_profile'),
            ),
          ],
        ),
      ),
    );
  }
}
