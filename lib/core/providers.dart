import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content/content_repository.dart';
import '../data/repositories/mastery_repository.dart';
import '../domain/repositories/kana_repository.dart';
import 'audio/audio_service.dart';
import 'ai/mai_ai_service.dart';

final kanaRepositoryProvider = Provider<KanaRepository>((ref) {
  throw UnimplementedError('kanaRepositoryProvider must be overridden in main');
});

final audioServiceProvider = Provider<AudioService>((ref) {
  throw UnimplementedError('audioServiceProvider must be overridden in main');
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  throw UnimplementedError('contentRepositoryProvider must be overridden in main');
});

final masteryRepositoryProvider = Provider<MasteryRepository>((ref) {
  throw UnimplementedError('masteryRepositoryProvider must be overridden in main');
});

final maiAiServiceProvider = Provider<MaiAiService>((ref) {
  return MaiAiService();
});
