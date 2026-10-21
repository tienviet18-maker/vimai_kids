import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/features/games/presentation/match_kana_game.dart';
import 'package:mai_an_learning/features/games/presentation/widgets/game_play_scaffold.dart';

Widget _app() {
  final notifier = CurrentProfileNotifier(ProfileRepository())
    ..state = ChildProfile(id: 't', name: 'Lan', age: 5, avatar: 'peach', createdAt: DateTime(2026, 1, 1), settings: const {'sound': false});
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(AudioService()..soundEnabled = false),
    ],
    child: const MaterialApp(home: MatchKanaGame()),
  );
}

List<GameFlipCard> _cards(WidgetTester tester) =>
    tester.widgetList<GameFlipCard>(find.byType(GameFlipCard)).toList();

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

String _faceOf(GameFlipCard card) => (card.face as Text).data!;

void main() {
  testWidgets('one card alone never counts as a pair; a miss turns back over', (tester) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await _settle(tester);

    final faces = _cards(tester).map(_faceOf).toList();
    const first = 0;
    final other = faces.indexWhere((f) => f != faces[first]);
    final partner = faces.lastIndexOf(faces[first]);

    // Tap one card and wait: it stays open, unmatched, with no progress.
    await tester.tap(find.byType(GameFlipCard).at(first));
    await _settle(tester);
    expect(_cards(tester)[first].open, isTrue);
    expect(_cards(tester).where((c) => c.matched), isEmpty);

    // Second card is different: both show, then both turn back face down.
    await tester.tap(find.byType(GameFlipCard).at(other));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_cards(tester)[other].open, isTrue);
    await _settle(tester);
    expect(_cards(tester)[first].open, isFalse);
    expect(_cards(tester)[other].open, isFalse);
    expect(_cards(tester).where((c) => c.matched), isEmpty);

    // A real pair stays open as matched.
    await tester.tap(find.byType(GameFlipCard).at(first));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(GameFlipCard).at(partner));
    await _settle(tester);
    final matched = [for (var i = 0; i < faces.length; i++) if (_cards(tester)[i].matched) i];
    expect(matched, unorderedEquals([first, partner]));
    // Let queued voice clips time out before the tree is torn down.
    await tester.pump(const Duration(seconds: 12));
  });
}
