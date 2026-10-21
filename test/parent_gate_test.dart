import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/features/parent/presentation/parent_gate.dart';

Widget _wrap(Widget child) {
  final notifier = CurrentProfileNotifier(ProfileRepository())
    ..state = ChildProfile(id: 't', name: 'Lan', age: 5, avatar: '🐱', createdAt: DateTime(2026, 1, 1));
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
    ],
    child: MaterialApp(home: child),
  );
}

int _currentAnswer(WidgetTester tester) {
  final text = tester.widget<Text>(find.byKey(const Key('parent_gate_question'))).data!;
  final m = RegExp(r'(\d+) × (\d+)').firstMatch(text)!;
  return int.parse(m.group(1)!) * int.parse(m.group(2)!);
}

Future<void> _enter(WidgetTester tester, int value) async {
  for (final ch in '$value'.split('')) {
    await tester.tap(find.byKey(Key('parent_gate_key_$ch')));
    await tester.pump();
  }
  await tester.tap(find.byKey(const Key('parent_gate_submit')));
  await tester.pump();
}

void main() {
  // Phone-sized portrait viewport so the whole keypad is on screen.
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1170, 2532);
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  });
  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  group('ParentGateChallenge', () {
    test('always a two-digit product a 3–7 year old cannot work out', () {
      final r = Random(42);
      final seen = <String>{};
      for (var i = 0; i < 500; i++) {
        final c = ParentGateChallenge.random(r);
        expect(c.a, inInclusiveRange(3, 9));
        expect(c.b, inInclusiveRange(4, 9));
        expect(c.answer, inInclusiveRange(12, 81));
        expect(c.check('${c.answer}'), isTrue);
        expect(c.check('${c.answer + 1}'), isFalse);
        expect(c.check(''), isFalse);
        seen.add(c.prompt);
      }
      // Randomized: many distinct questions, not one memorizable code.
      expect(seen.length, greaterThan(30));
    });
  });

  group('ParentGateGuard', () {
    const secret = Text('PARENT AREA');

    testWidgets('hides the parent area until the correct answer is entered', (tester) async {
      await tester.pumpWidget(_wrap(ParentGateGuard(random: Random(7), child: secret)));
      expect(find.text('PARENT AREA'), findsNothing);
      expect(find.byKey(const Key('parent_gate_question')), findsOneWidget);

      await _enter(tester, _currentAnswer(tester));
      expect(find.text('PARENT AREA'), findsOneWidget);
    });

    testWidgets('a simple tap or wrong answer does not unlock and changes the question', (tester) async {
      await tester.pumpWidget(_wrap(ParentGateGuard(random: Random(3), child: secret)));
      // Tapping confirm with nothing entered does nothing.
      await tester.tap(find.byKey(const Key('parent_gate_submit')));
      await tester.pump();
      expect(find.text('PARENT AREA'), findsNothing);

      final answer = _currentAnswer(tester);
      await _enter(tester, answer + 1);
      expect(find.text('PARENT AREA'), findsNothing);
      expect(find.text('Chưa đúng, thử phép tính mới nhé.'), findsOneWidget);

      // Still passable with the new question's answer.
      await _enter(tester, _currentAnswer(tester));
      expect(find.text('PARENT AREA'), findsOneWidget);
    });

    testWidgets('backspace removes the last digit', (tester) async {
      await tester.pumpWidget(_wrap(ParentGateGuard(random: Random(11), child: secret)));
      await tester.tap(find.byKey(const Key('parent_gate_key_9')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('parent_gate_backspace')));
      await tester.pump();
      await _enter(tester, _currentAnswer(tester));
      expect(find.text('PARENT AREA'), findsOneWidget);
    });
  });

  group('showParentGate', () {
    Future<bool?> run(WidgetTester tester, Future<void> Function() act) async {
      bool? result;
      await tester.pumpWidget(_wrap(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await showParentGate(context, random: Random(5)),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await act();
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('resolves true for a correct adult answer', (tester) async {
      final result = await run(tester, () => _enter(tester, _currentAnswer(tester)));
      expect(result, isTrue);
    });

    testWidgets('resolves false on cancel', (tester) async {
      final result = await run(tester, () => tester.tap(find.byKey(const Key('parent_gate_cancel'))));
      expect(result, isFalse);
    });

    testWidgets('gives up after three wrong answers', (tester) async {
      final result = await run(tester, () async {
        for (var i = 0; i < 3; i++) {
          await _enter(tester, _currentAnswer(tester) + 1);
        }
      });
      expect(result, isFalse);
      expect(find.byKey(const Key('parent_gate_question')), findsNothing);
    });
  });

  group('Kids Category wiring', () {
    test('the /parent route is wrapped in the parental gate', () {
      final src = File('lib/core/routing/app_router.dart').readAsStringSync();
      expect(src, contains('ParentGateGuard(child: ParentScreen())'));
      expect(src, isNot(contains("builder: (context, state) => const ParentScreen()")));
    });

    test('external launches only happen inside the gated parent area', () {
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final src = f.readAsStringSync();
        if (src.contains('launchUrl(')) {
          expect(f.path.replaceAll('\\', '/'), contains('features/parent/'), reason: f.path);
        }
      }
    });

    test('release build scripts never inject a Gemini key (Mai stays on-device)', () {
      for (final dir in ['.github/workflows', 'tool', 'tools', 'ios']) {
        final d = Directory(dir);
        if (!d.existsSync()) continue;
        for (final f in d.listSync(recursive: true).whereType<File>()) {
          if (!RegExp(r'\.(ya?ml|sh|py|xcconfig|pbxproj|plist)$').hasMatch(f.path)) continue;
          expect(f.readAsStringSync().contains('GEMINI_API_KEY'), isFalse, reason: f.path);
        }
      }
    });

    test('fonts are bundled and never fetched at runtime', () {
      expect(File('lib/main.dart').readAsStringSync(), contains('GoogleFonts.config.allowRuntimeFetching = false'));
      for (final name in ['Baloo2-Regular', 'Baloo2-Medium', 'Baloo2-SemiBold', 'Baloo2-Bold', 'Baloo2-ExtraBold', 'Poppins-ExtraBold']) {
        expect(File('assets/google_fonts/$name.ttf').existsSync(), isTrue, reason: name);
      }
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/google_fonts/'));
    });
  });
}
