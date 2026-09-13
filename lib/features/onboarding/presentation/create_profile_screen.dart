import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/vimai_tokens.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../shared/widgets/vimai_mascot.dart';
import '../../shared/widgets/vimai_ui.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _nameController = TextEditingController();
  int _selectedAge = 5;
  String _selectedAvatar = 'peach';

  final List<int> _ages = [3, 4, 5, 6, 7];
  final List<String> _avatars = ['peach', 'mint', 'sky', 'grape', 'honey', 'coral'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Con hãy nhập tên nhé')),
      );
      return;
    }

    await ref.read(currentProfileProvider.notifier).createProfile(name, _selectedAge, _selectedAvatar);
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;

    return PageScaffold(
      title: 'Hồ sơ của con',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gap = (constraints.maxHeight * 0.012).clamp(4.0, 12.0);
          final mascotSize = (constraints.maxHeight * 0.11).clamp(48.0, 80.0);

          return Padding(
            padding: EdgeInsets.fromLTRB(20, gap, 20, gap),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  flex: 2,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: VimaiMascot(mood: MascotMood.happy, size: mascotSize),
                    ),
                  ),
                ),
                SizedBox(height: gap),
                Text('Con tên là gì?', style: VimaiType.title.copyWith(fontSize: 18)),
                SizedBox(height: gap * 0.6),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Tên của con',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(VimaiRadius.md)),
                    filled: true,
                    fillColor: VimaiColor.surface,
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                SizedBox(height: gap),
                Text('Con bao nhiêu tuổi?', style: VimaiType.title.copyWith(fontSize: 18)),
                SizedBox(height: gap * 0.6),
                Flexible(
                  flex: 2,
                  child: LayoutBuilder(
                    builder: (context, chipConstraints) {
                      final chipH = chipConstraints.maxHeight.clamp(40.0, 64.0);
                      return Row(
                        children: [
                          for (var i = 0; i < _ages.length; i++) ...[
                            if (i > 0) SizedBox(width: gap * 0.7),
                            Expanded(
                              child: Pressable(
                                semanticLabel: '${_ages[i]} tuổi',
                                onTap: () => setState(() => _selectedAge = _ages[i]),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  height: chipH,
                                  decoration: BoxDecoration(
                                    color: _selectedAge == _ages[i] ? VimaiColor.coral : VimaiColor.surface,
                                    borderRadius: BorderRadius.circular(VimaiRadius.md),
                                    border: Border.all(
                                      color: _selectedAge == _ages[i] ? VimaiColor.coral : VimaiColor.line,
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${_ages[i]}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: _selectedAge == _ages[i] ? Colors.white : VimaiColor.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: gap),
                Text(
                  'Chọn màu bạn đồng hành',
                  style: VimaiType.title.copyWith(fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: gap * 0.6),
                Flexible(
                  flex: 4,
                  child: LayoutBuilder(
                    builder: (context, gridConstraints) {
                      final cell = (gridConstraints.maxHeight / 2).clamp(44.0, 88.0);
                      final mascot = (cell * 0.55).clamp(28.0, 48.0);
                      return Column(
                        children: [
                          for (var row = 0; row < 2; row++) ...[
                            if (row > 0) SizedBox(height: gap),
                            Expanded(
                              child: Row(
                                children: [
                                  for (var col = 0; col < 3; col++) ...[
                                    if (col > 0) SizedBox(width: gap),
                                    Expanded(
                                      child: Builder(
                                        builder: (context) {
                                          final avatar = _avatars[row * 3 + col];
                                          final isSelected = _selectedAvatar == avatar;
                                          return Pressable(
                                            semanticLabel: avatar,
                                            onTap: () => setState(() => _selectedAvatar = avatar),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 160),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? mascotColorForAvatar(avatar).withValues(alpha: 0.18)
                                                    : VimaiColor.surface,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? mascotColorForAvatar(avatar)
                                                      : VimaiColor.line,
                                                  width: 3,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: VimaiMascot(
                                                mood: MascotMood.happy,
                                                size: mascot,
                                                color: mascotColorForAvatar(avatar),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: (h * 0.012).clamp(6.0, 12.0)),
                SafeArea(
                  top: false,
                  minimum: EdgeInsets.zero,
                  child: KidButton(label: 'Xong rồi!', onPressed: _createProfile),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
