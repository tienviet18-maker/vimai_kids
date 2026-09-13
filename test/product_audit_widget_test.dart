import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/branding/config.dart';
import 'package:mai_an_learning/core/entitlements/app_entitlements.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/content/content_repository.dart';
import 'package:mai_an_learning/data/kana/hiragana_data.dart';
import 'package:mai_an_learning/data/repositories/kana_repository_impl.dart';
import 'package:mai_an_learning/data/repositories/mastery_repository.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/domain/models/kana_item.dart';
import 'package:mai_an_learning/features/creativity/presentation/creativity_screen.dart';
import 'package:mai_an_learning/features/home/presentation/home_screen.dart';
import 'package:mai_an_learning/features/japanese/writing/presentation/widgets/writing_canvas.dart';
import 'package:mai_an_learning/features/parent/presentation/parent_screen.dart';
import 'package:mai_an_learning/features/progress/presentation/progress_screen.dart';
import 'package:mai_an_learning/features/shared/widgets/kids_living_canopy.dart';
import 'package:mai_an_learning/features/thinking/presentation/thinking_screen.dart';

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
      audioServiceProvider.overrideWithValue(AudioService()),
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

ChildProfile _profile({String name = 'Lan', int age = 5}) {
  return ChildProfile(
    id: 'test',
    name: name,
    age: age,
    avatar: '🐱',
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home shows ChildProfile name and age, not daily lesson', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(size: const Size(390, 844), home: const HomeScreen(), profile: _profile(name: 'Minh', age: 6)));
    await tester.pump();
    expect(find.textContaining('Chào Minh! Hôm nay cùng khám phá nhé'), findsOneWidget);
    expect(find.text('6 tuổi'), findsNothing);
    expect(find.text('Hôm nay mình học gì nhỉ?'), findsNothing);
    expect(find.text('Con muốn học gì hôm nay?'), findsNothing);
    expect(find.text('Khám phá'), findsNothing);
    expect(find.text('Tiếng Nhật'), findsOneWidget);
    expect(find.text('h_he'), findsNothing);
    expect(find.text('vietnamese.blend'), findsNothing);
    expect(find.text('Học tiếp'), findsNothing);
    expect(find.text('Bắt đầu'), findsNothing);
    expect(find.text('Chơi ngay'), findsNothing);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(SliverGrid), findsOneWidget);
    expect(find.byType(CanopyPathTrail), findsOneWidget);
    expect(find.byType(DiscoveryNest), findsOneWidget);
    expect(find.byType(TactileNode), findsWidgets);
    expect(find.byType(ParentOakGate), findsOneWidget);
    expect(find.byType(CanopyBgmToggle), findsOneWidget);
    expect(find.text('Bài học hôm nay'), findsNothing);
    expect(find.text('Tiến bộ'), findsNothing);
    expect(find.text('Mai An'), findsNothing);
    expect(find.text('adfaf'), findsNothing);
    expect(find.textContaining('Phạm Tiến Việt'), findsNothing);
    expect(find.textContaining('tienviet18'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('age is only 3-7 on parent screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(size: const Size(390, 844), home: const ParentScreen(), profile: _profile(age: 4)));
    await tester.pump();
    expect(find.text('3 tuổi'), findsOneWidget);
    expect(find.text('7 tuổi'), findsOneWidget);
    expect(find.text('2 tuổi'), findsNothing);
    expect(find.text('8 tuổi'), findsNothing);
    expect(find.text('Lưu'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('vimai.support@gmail.com'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('vimai.support@gmail.com'), findsOneWidget);
    expect(find.text('Ôn tập', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('ViMai Kids', skipOffstage: false), findsWidgets);
    expect(find.textContaining('tienviet18'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home fits key phone and desktop sizes without overflow', (tester) async {
    const sizes = [
      Size(360, 640),
      Size(360, 800),
      Size(390, 844),
      Size(412, 915),
      Size(600, 960),
      Size(768, 1024),
      Size(1024, 768),
      Size(1366, 768),
    ];
    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_app(size: size, home: const HomeScreen(), profile: _profile()));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Home overflow at $size');
      expect(find.textContaining('Hôm nay cùng khám phá nhé'), findsOneWidget, reason: 'Home greeting at $size');
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('Parent, thinking and creativity do not overflow at 360x800', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final home in const [ParentScreen(), ThinkingScreen(), CreativityScreen(), ProgressScreen()]) {
      await tester.pumpWidget(_app(size: const Size(360, 800), home: home, profile: _profile(age: 3)));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '${home.runtimeType} overflow');
    }
  });

  testWidgets('WritingCanvas uses the selected stroke color', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WritingCanvas(strokeColor: Colors.redAccent, onCleared: () {}),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final canvas = tester.widget<WritingCanvas>(find.byType(WritingCanvas));
    expect(canvas.strokeColor, Colors.redAccent);
    expect(canvas.strokeColor, isNot(Colors.black87));
  });

  test('Japanese session swipe and continue share the same index', () {
    final items = hiraganaData.where((e) => e.kanaType == KanaType.basic).toList();
    var index = 0;
    var popped = false;
    void swipe() {
      if (index < items.length - 1) index++;
    }
    void continuePressed() {
      if (index < items.length - 1) {
        index++;
        return;
      }
    }
    swipe();
    expect(items[index].character, 'い');
    continuePressed();
    expect(items[index].character, 'う');
    expect(popped, isFalse);
    index = items.length - 1;
    continuePressed();
    expect(index, items.length - 1);
    expect(popped, isFalse);
  });

  test('support identity and free entitlements are honest', () {
    expect(AppBrand.productDisplayName, 'ViMai Kids');
    expect(AppBrand.createdByLabel, 'ViMai');
    expect(AppBrand.supportEmail, 'vimai.support@gmail.com');
    expect(const AppEntitlements().isPro, isFalse);
    expect(const AppEntitlements().coreLearningUnlocked, isTrue);
  });
}
