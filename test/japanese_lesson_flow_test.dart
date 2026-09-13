import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/content/content_repository.dart';
import 'package:mai_an_learning/data/repositories/kana_repository_impl.dart';
import 'package:mai_an_learning/data/repositories/mastery_repository.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/domain/models/kana_item.dart';
import 'package:mai_an_learning/features/japanese/handwriting/stroke_order_catalog.dart';
import 'package:mai_an_learning/features/japanese/handwriting/stroke_order_player.dart';
import 'package:mai_an_learning/features/japanese/handwriting/write_practice_board.dart';
import 'package:mai_an_learning/features/japanese/presentation/japanese_home_screen.dart';
import 'package:mai_an_learning/features/japanese/presentation/kana_lesson_screen.dart';
import 'package:mai_an_learning/features/japanese/writing/presentation/widgets/writing_canvas.dart';

class _SilentAudio extends AudioService {
  @override
  Future<AudioPlayResult> playJapaneseAsset(String audioId) async => const AudioPlayResult.ok('ja-JP');

  @override
  Future<AudioPlayResult> playVietnameseAsset(String audioId) async => const AudioPlayResult.ok('vi-VN');

  @override
  Future<void> stop() async {}
}

Widget _app({
  required Size size,
  required Widget home,
  required ChildProfile profile,
}) {
  final notifier = CurrentProfileNotifier(ProfileRepository())..state = profile;
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(_SilentAudio()),
      kanaRepositoryProvider.overrideWithValue(KanaRepositoryImpl()),
      contentRepositoryProvider.overrideWithValue(ContentRepository()),
      masteryRepositoryProvider.overrideWithValue(MasteryRepository()),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: home,
      ),
    ),
  );
}

ChildProfile _profile() {
  return ChildProfile(
    id: 'test',
    name: 'Lan',
    age: 5,
    avatar: '🐱',
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final raw = File('assets/content/japanese/strokes/catalog.json').readAsStringSync();
    StrokeOrderCatalog.loadJson(raw);
    expect(jsonDecode(raw)['source'], 'KanjiVG');
  });

  testWidgets('Japanese home removes redundant separate stroke tiles', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(size: const Size(390, 844), home: const JapaneseHomeScreen(), profile: _profile()));
    await tester.pump();
    expect(find.text('Thứ tự nét Hiragana'), findsNothing);
    expect(find.text('Thứ tự nét Katakana'), findsNothing);
    expect(find.text('Học Hiragana'), findsOneWidget);
    expect(find.text('Viết Hiragana'), findsOneWidget);
    expect(find.text('Học Katakana'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Japanese look module advances to next letter only', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        size: const Size(390, 844),
        home: const KanaLessonScreen(script: KanaScript.hiragana, typeName: 'basic', startMode: 'look'),
        profile: _profile(),
      ),
    );
    await tester.pump();
    expect(find.text('あ'), findsWidgets);
    expect(find.textContaining('Học chữ:'), findsWidgets);
    expect(find.text('Hãy nghe nhé!'), findsOneWidget);
    expect(find.byType(StrokeOrderPlayer), findsNothing);
    expect(find.byType(WritePracticeBoard), findsNothing);
    expect(find.byKey(const Key('continue-flow')), findsOneWidget);

    await tester.tap(find.byKey(const Key('continue-flow')));
    await tester.pump();
    expect(find.byType(StrokeOrderPlayer), findsNothing);
    expect(find.byType(WritePracticeBoard), findsNothing);
    expect(find.textContaining('Học chữ:'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('write mode deep link is not a blank dead tab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        size: const Size(390, 844),
        home: const KanaLessonScreen(script: KanaScript.hiragana, typeName: 'basic', startMode: 'write'),
        profile: _profile(),
      ),
    );
    await tester.pump();
    expect(find.byType(WritePracticeBoard), findsOneWidget);
    expect(find.text('Con hãy viết theo mẫu'), findsWidgets);
    expect(find.byType(WritingCanvas), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('extended kana stroke mode is honestly unavailable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        size: const Size(390, 844),
        home: const KanaLessonScreen(script: KanaScript.hiragana, typeName: 'dakuten', startMode: 'strokes'),
        profile: _profile(),
      ),
    );
    await tester.pump();
    expect(find.text('Chưa có dữ liệu thứ tự nét'), findsOneWidget);
    expect(find.textContaining('Nét 1/'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Japanese lesson screens fit required sizes', (tester) async {
    const sizes = [
      Size(360, 640),
      Size(390, 844),
      Size(412, 915),
      Size(768, 1024),
      Size(1366, 768),
    ];
    const modes = ['look', 'listen', 'strokes', 'write'];
    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      for (final mode in modes) {
        await tester.pumpWidget(
          _app(
            size: size,
            home: KanaLessonScreen(script: KanaScript.hiragana, typeName: 'basic', startMode: mode),
            profile: _profile(),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'overflow $mode $size');
        expect(find.text('あ'), findsWidgets, reason: 'character $mode $size');
        if (mode == 'strokes') {
          expect(StrokeOrderCatalog().hasPaths('h_a'), isTrue);
          expect(find.byType(StrokeOrderPlayer), findsOneWidget, reason: 'player $size');
          expect(find.textContaining('Nét', skipOffstage: false), findsWidgets, reason: 'stroke number $size');
        }
        if (mode == 'write') {
          expect(find.byType(WritingCanvas), findsOneWidget, reason: 'canvas $size');
          expect(find.byKey(const Key('write-clear'), skipOffstage: false), findsOneWidget);
        }
      }
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
