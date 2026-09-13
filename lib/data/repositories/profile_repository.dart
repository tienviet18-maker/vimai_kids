import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/child_profile.dart';

class ProfileRepository {
  static const String _boxName = 'profiles_box';
  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  List<ChildProfile> getAllProfiles() {
    final box = _box;
    if (box == null) return [];
    final profiles = <ChildProfile>[];
    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        profiles.add(ChildProfile.fromJson(jsonDecode(data) as Map<String, dynamic>));
      }
    }
    return profiles;
  }

  Future<void> saveProfile(ChildProfile profile) async {
    await _box?.put(profile.id, jsonEncode(profile.toJson()));
  }

  Future<void> deleteProfile(String id) async {
    await _box?.delete(id);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  throw UnimplementedError();
});

class CurrentProfileNotifier extends StateNotifier<ChildProfile?> {
  final ProfileRepository _repo;

  CurrentProfileNotifier(this._repo) : super(null) {
    _loadInitial();
  }

  void _loadInitial() {
    final profiles = _repo.getAllProfiles();
    if (profiles.isNotEmpty) {
      profiles.sort((a, b) {
        final aTime = a.lastActiveAt ?? a.createdAt;
        final bTime = b.lastActiveAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
      state = profiles.first;
    }
  }

  Future<void> setProfile(ChildProfile profile) async {
    final updated = profile.copyWith(lastActiveAt: DateTime.now());
    await _repo.saveProfile(updated);
    state = updated;
  }

  Future<void> setLastWorld(String world) async {
    final profile = state;
    if (profile == null) return;
    final settings = Map<String, dynamic>.from(profile.settings)..['lastWorld'] = world;
    await setProfile(profile.copyWith(settings: settings));
  }

  Future<void> addLearningSeconds(int seconds, String subject) async {
    final profile = state;
    if (profile == null || seconds <= 0) return;
    final now = DateTime.now();
    final key =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final prev = Map<String, dynamic>.from(profile.dailyLearningState);
    if (prev['date'] != key) {
      prev
        ..clear()
        ..['date'] = key
        ..['seconds'] = 0
        ..['bySubject'] = <String, dynamic>{};
    }
    prev['seconds'] = ((prev['seconds'] as num?)?.toInt() ?? 0) + seconds;
    final by = Map<String, dynamic>.from(prev['bySubject'] as Map? ?? {});
    by[subject] = ((by[subject] as num?)?.toInt() ?? 0) + seconds;
    prev['bySubject'] = by;
    await setProfile(profile.copyWith(dailyLearningState: prev));
  }

  Future<void> createProfile(String name, int age, String avatar) async {
    final profile = ChildProfile(
      id: const Uuid().v4(),
      name: name,
      age: ChildProfile.clampAge(age),
      avatar: avatar,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );
    await _repo.saveProfile(profile);
    state = profile;
  }

  void clear() {
    state = null;
  }
}

final currentProfileProvider = StateNotifierProvider<CurrentProfileNotifier, ChildProfile?>((ref) {
  return CurrentProfileNotifier(ref.watch(profileRepositoryProvider));
});
