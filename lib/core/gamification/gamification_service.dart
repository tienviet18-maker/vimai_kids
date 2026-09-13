import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/profile_repository.dart';
import '../../domain/models/child_profile.dart';
import '../audio/audio_service.dart';
import '../providers.dart';
import 'celebration_overlay.dart';

class GamificationState {
  final int totalStars;
  final int todayStars;
  final List<String> stickers;
  final List<String> badges;

  const GamificationState({
    this.totalStars = 0,
    this.todayStars = 0,
    this.stickers = const [],
    this.badges = const [],
  });

  GamificationState copyWith({
    int? totalStars,
    int? todayStars,
    List<String>? stickers,
    List<String>? badges,
  }) {
    return GamificationState(
      totalStars: totalStars ?? this.totalStars,
      todayStars: todayStars ?? this.todayStars,
      stickers: stickers ?? this.stickers,
      badges: badges ?? this.badges,
    );
  }
}

class GamificationService {
  final Ref _ref;

  GamificationService(this._ref);

  AudioService get _audio => _ref.read(audioServiceProvider);

  ChildProfile? get _currentProfile => _ref.read(currentProfileProvider);

  /// Triggered whenever child answers a question or task correctly.
  /// 1. Awards a star.
  /// 2. Spawns non-blocking celebratory particle fireworks / confetti.
  /// 3. Plays random warm Northern Hoài My praise clip ('Tuyệt cú mèo!', etc.).
  Future<void> onCorrectAnswer(
    BuildContext context, {
    bool playSound = true,
    bool showCelebration = true,
  }) async {
    if (showCelebration && context.mounted) {
      CelebrationOverlay.show(context);
    }
    if (playSound) {
      unawaited(_audio.playRandomSuccess());
    }
    await awardStars(1);
  }

  /// Automatically awards stars and updates progress upon completing a lesson/game.
  Future<void> onActivityCompleted({
    required String subject,
    bool perfect = false,
    BuildContext? context,
  }) async {
    final stars = perfect ? 5 : 3;
    await awardStars(stars);

    // Auto-award thematic stickers
    final stickerId = switch (subject.toLowerCase()) {
      'vietnamese' => 'sticker_tieng_viet_sao_sang',
      'japanese' => 'sticker_tieng_nhat_cham_chi',
      'math' => 'sticker_toan_hoc_sieu_dang',
      'thinking' => 'sticker_tu_duy_nhanh_nhen',
      _ => 'sticker_be_ngoan_hoc_gioi',
    };
    await awardSticker(stickerId);

    if (context != null && context.mounted) {
      CelebrationOverlay.show(context);
      unawaited(_audio.playRandomSuccess());
    }
  }

  /// Adds stars to current profile and saves to persistence.
  Future<void> awardStars(int count) async {
    final profile = _currentProfile;
    if (profile == null || count <= 0) return;

    final progress = Map<String, dynamic>.from(profile.progress);
    final currentStars = (progress['stars'] as num?)?.toInt() ?? 0;
    progress['stars'] = currentStars + count;

    final todayDate = profile.todayDateKey;
    final starsByDate = Map<String, dynamic>.from(progress['starsByDate'] as Map? ?? {});
    final todayCount = (starsByDate[todayDate] as num?)?.toInt() ?? 0;
    starsByDate[todayDate] = todayCount + count;
    progress['starsByDate'] = starsByDate;

    await _ref.read(currentProfileProvider.notifier).setProfile(
          profile.copyWith(progress: progress),
        );
  }

  /// Adds a collectible sticker to current profile.
  Future<void> awardSticker(String stickerId) async {
    final profile = _currentProfile;
    if (profile == null) return;

    final progress = Map<String, dynamic>.from(profile.progress);
    final stickers = List<String>.from((progress['stickers'] as List?) ?? []);
    if (!stickers.contains(stickerId)) {
      stickers.add(stickerId);
      progress['stickers'] = stickers;
      await _ref.read(currentProfileProvider.notifier).setProfile(
            profile.copyWith(progress: progress),
          );
    }
  }

  /// Adds an achievement badge to current profile.
  Future<void> awardBadge(String badgeId) async {
    final profile = _currentProfile;
    if (profile == null) return;

    final progress = Map<String, dynamic>.from(profile.progress);
    final badges = List<String>.from((progress['badges'] as List?) ?? []);
    if (!badges.contains(badgeId)) {
      badges.add(badgeId);
      progress['badges'] = badges;
      await _ref.read(currentProfileProvider.notifier).setProfile(
            profile.copyWith(progress: progress),
          );
    }
  }

  int get totalStars {
    final profile = _currentProfile;
    if (profile == null) return 0;
    return (profile.progress['stars'] as num?)?.toInt() ?? 0;
  }

  int get todayStars {
    final profile = _currentProfile;
    if (profile == null) return 0;
    final starsByDate = profile.progress['starsByDate'] as Map? ?? {};
    return (starsByDate[profile.todayDateKey] as num?)?.toInt() ?? 0;
  }

  List<String> get stickers {
    final profile = _currentProfile;
    if (profile == null) return const [];
    return List<String>.from((profile.progress['stickers'] as List?) ?? []);
  }

  List<String> get badges {
    final profile = _currentProfile;
    if (profile == null) return const [];
    return List<String>.from((profile.progress['badges'] as List?) ?? []);
  }
}

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService(ref);
});
