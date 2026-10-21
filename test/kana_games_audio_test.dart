import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/audio/kid_guide.dart';
import 'package:mai_an_learning/data/content/game_catalog.dart';
import 'package:mai_an_learning/domain/models/kana_item.dart';
import 'package:mai_an_learning/features/games/logic/catch_kana_round.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/kana/hiragana_data.dart';
import 'package:mai_an_learning/data/repositories/mastery_repository.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/features/games/presentation/catch_kana_game.dart';
import 'package:mai_an_learning/features/games/presentation/find_similar_game.dart';
import 'package:mai_an_learning/features/games/presentation/listen_kana_game.dart';
import 'package:mai_an_learning/features/games/presentation/match_kana_game.dart';
import 'package:mai_an_learning/features/games/presentation/widgets/game_play_scaffold.dart';
import 'package:mai_an_learning/features/shared/widgets/chunky_button.dart';

class _Said {
  _Said(this.lines, this.lead, this.trail);
  final List<String> lines;
  final List<String> lead;
  final List<String> trail;
  @override
  String toString() => 'lead=$lead lines=$lines trail=$trail';
}

/// Records what Mai would say and play instead of touching the audio plugin.
class _FakeAudio extends AudioService {
  final said = <_Said>[];
  final clips = <String>[];

  @override
  Future<AudioPlayResult> speak(
    List<String?> lines, {
    String? fallbackId,
    List<String> leadIds = const [],
    List<String> trailIds = const [],
  }) async {
    said.add(_Said(lines.whereType<String>().toList(), leadIds, trailIds));
    return const AudioPlayResult.unavailable('test');
  }

  @override
  Future<AudioPlayResult> playAudio(String id, {bool waitForComplete = false}) async {
    clips.add(id);
    return const AudioPlayResult.unavailable('test');
  }

  @override
  void sfx(Sfx effect) {}

  @override
  Future<void> startGameBgm() async {}

  @override
  Future<void> stopGameBgm() async {}

  @override
  Future<void> stop() async {}
}

Widget _app(Widget home, _FakeAudio audio, {int age = 5}) {
  final notifier = CurrentProfileNotifier(ProfileRepository())
    ..state = ChildProfile(id: 't', name: 'Lan', age: age, avatar: 'peach', createdAt: DateTime(2026, 1, 1));
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(audio),
      masteryRepositoryProvider.overrideWithValue(MasteryRepository()),
    ],
    child: MaterialApp(home: home),
  );
}

Future<void> _pumpFor(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

String _bannerGlyph(WidgetTester tester) => tester.widget<GameTargetBanner>(find.byType(GameTargetBanner)).glyph;

Finder _button(String label) => find.byWidgetPredicate((w) => w is ChunkyButton && w.semanticLabel == label);

Finder _token(String glyph) => find.byWidgetPredicate((w) => w is GameLetterToken && w.character == glyph);

void main() {
  testWidgets('Vietnamese catch says the letter to find, and the next one after the praise', (tester) async {
    _phone(tester);
    final audio = _FakeAudio();
    await tester.pumpWidget(_app(const CatchKanaGame(alphabet: CatchAlphabet.vietnamese), audio));
    await _pumpFor(tester, 600);

    final first = _bannerGlyph(tester);
    final firstClip = AudioService.getAudioIdForLetter(first);
    expect(firstClip, startsWith('v_'));
    // Intro ends with the letter itself (it used to ask for a ja_vi_catch_* clip
    // that does not exist, so Vietnamese children never heard the target).
    expect(audio.said.first.trail, [firstClip]);

    // The replay button says the same letter.
    audio.said.clear();
    await tester.tap(find.text('Tìm chữ'));
    await tester.pump();
    expect(audio.said.single.trail, [firstClip]);

    // A wrong letter: "try again", then the letter once more.
    audio.said.clear();
    final wrong = tester
        .widgetList<GameLetterToken>(find.byType(GameLetterToken))
        .firstWhere((t) => t.character != first)
        .character;
    await tester.tap(_token(wrong), warnIfMissed: false);
    await tester.pump();
    expect(audio.said.single.trail, [firstClip]);
    await _pumpFor(tester, 500);

    // The right letter: one sequence of caught letter → praise → next letter.
    audio.said.clear();
    await tester.tap(_token(first), warnIfMissed: false);
    await tester.pump();
    final cheer = audio.said.single;
    expect(cheer.lead, [firstClip]);
    expect(cheer.lines, hasLength(1));
    expect(cheer.trail, hasLength(1));
    await _pumpFor(tester, 1000);
    final next = _bannerGlyph(tester);
    expect(cheer.trail.single, AudioService.getAudioIdForLetter(next));
    // Nothing else talks over that sequence when the round changes.
    expect(audio.said, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Switching alphabet on the same catch screen deals that alphabet', (tester) async {
    _phone(tester);
    final alphabet = ValueNotifier(CatchAlphabet.katakana);
    await tester.pumpWidget(_app(
      ValueListenableBuilder<CatchAlphabet>(
        valueListenable: alphabet,
        builder: (context, value, _) => CatchKanaGame(alphabet: value),
      ),
      _FakeAudio(),
    ));
    await _pumpFor(tester, 400);
    alphabet.value = CatchAlphabet.hiragana;
    await _pumpFor(tester, 400);
    final glyph = _bannerGlyph(tester);
    expect(hiraganaData.any((k) => k.character == glyph), isTrue, reason: 'banner still shows $glyph');
    for (final t in tester.widgetList<GameLetterToken>(find.byType(GameLetterToken))) {
      expect(hiraganaData.any((k) => k.character == t.character), isTrue, reason: 'token ${t.character}');
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Listen: praise follows the chosen sound and leads into the next sound', (tester) async {
    _phone(tester);
    final audio = _FakeAudio();
    await tester.pumpWidget(_app(const ListenKanaGame(), audio));
    await _pumpFor(tester, 300);

    final firstClip = audio.said.first.trail.single;
    final target = hiraganaData.firstWhere((k) => k.audioId == firstClip);
    final choices = tester
        .widgetList<ChunkyButton>(find.byType(ChunkyButton))
        .map((b) => b.semanticLabel)
        .whereType<String>()
        .where((l) => hiraganaData.any((k) => k.character == l))
        .toList();
    expect(choices, contains(target.character));

    // Wrong: "try again", then the same sound again.
    audio.said.clear();
    await tester.tap(_button(choices.firstWhere((c) => c != target.character)));
    await tester.pump();
    expect(audio.said.single.trail, [firstClip]);

    audio.said.clear();
    await tester.tap(_button(target.character));
    await tester.pump();
    final cheer = audio.said.single;
    expect(cheer.lead, [firstClip]);
    expect(cheer.trail, hasLength(1));
    await _pumpFor(tester, 1000);
    expect(audio.said, hasLength(1), reason: 'the next prompt must not cut the praise');

    // The speaker button replays exactly the sound that was announced.
    audio.said.clear();
    await tester.tap(_button('Nghe lại'));
    await tester.pump();
    expect(audio.said.single.trail, cheer.trail);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Match: each card says its own kana clip; youngest get 8 cards', (tester) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final audio = _FakeAudio();
    await tester.pumpWidget(_app(const MatchKanaGame(), audio, age: 3));
    await _pumpFor(tester, 300);
    expect(find.byType(GameFlipCard), findsNWidgets(8));

    await tester.tap(find.byType(GameFlipCard).first);
    await tester.pump();
    final face = (tester.widget<GameFlipCard>(find.byType(GameFlipCard).first).face as Text).data!;
    final kana = hiraganaData.firstWhere((k) => k.character == face);
    // It used to ask for "ja_<glyph>", which has no clip, so cards were silent.
    expect(audio.clips.last, kana.audioId);
    await _pumpFor(tester, 2000);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Match keeps 12 cards at age 5', (tester) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const MatchKanaGame(), _FakeAudio()));
    await _pumpFor(tester, 300);
    expect(find.byType(GameFlipCard), findsNWidgets(12));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Listen, age 3: no look-alikes on screen; the winning answer leaves the praise to the win panel',
      (tester) async {
    _phone(tester);
    final audio = _FakeAudio();
    await tester.pumpWidget(_app(const ListenKanaGame(), audio, age: 3));
    await _pumpFor(tester, 300);
    final goal = GameCatalog.sessionRounds(GameKind.listenKana, 3);
    expect(goal, 6);
    var clip = audio.said.first.trail.single;
    for (var round = 1; round <= goal; round++) {
      final shown = tester
          .widgetList<ChunkyButton>(find.byType(ChunkyButton))
          .map((b) => b.semanticLabel)
          .whereType<String>()
          .map((l) => hiraganaData.where((k) => k.character == l).firstOrNull)
          .whereType<KanaItem>()
          .toList();
      expect(shown, hasLength(4));
      for (final a in shown) {
        for (final b in shown) {
          if (a.id != b.id) expect(CatchKanaRound.confusable(a, b), isFalse, reason: '${a.character}/${b.character}');
        }
      }
      final target = hiraganaData.firstWhere((k) => k.audioId == clip);
      audio.said.clear();
      await tester.tap(_button(target.character));
      await tester.pump();
      final cheer = audio.said.single;
      expect(cheer.lead, [clip]);
      if (round < goal) {
        expect(cheer.lines, hasLength(1), reason: 'praise');
        clip = cheer.trail.single;
        await _pumpFor(tester, 1000);
      } else {
        // Last one: just the sound, no praise line for the win line to cut.
        expect(cheer.lines, isEmpty);
        expect(cheer.trail, isEmpty);
      }
    }
    await _pumpFor(tester, 4500);
    expect(find.byType(GameCompletePanel), findsOneWidget);
    expect(audio.said.last.lines, [KidGuide.gameWin]);
    expect(audio.said.where((s) => s.lines.any(KidGuide.praise.contains)), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Find similar ends on the win panel with Mai\'s win line, and "Chơi tiếp" deals again', (tester) async {
    _phone(tester);
    final audio = _FakeAudio();
    await tester.pumpWidget(_app(const FindSimilarGame(), audio, age: 3));
    await _pumpFor(tester, 300);
    String face(int i) => (tester.widget<GameFlipCard>(find.byType(GameFlipCard).at(i)).face as Text).data!;
    final n = tester.widgetList(find.byType(GameFlipCard)).length;
    expect(n, 8);
    final faces = [for (var i = 0; i < n; i++) face(i)];
    // One wrong pair first.
    final other = faces.indexWhere((f) => f != faces[0]);
    await tester.tap(find.byType(GameFlipCard).at(0));
    await tester.pump();
    await tester.tap(find.byType(GameFlipCard).at(other));
    await _pumpFor(tester, 1500);
    final done = <int>{};
    for (var i = 0; i < n; i++) {
      if (done.contains(i)) continue;
      final j = [for (var k = i + 1; k < n; k++) k].firstWhere((k) => faces[k] == faces[i]);
      done.addAll([i, j]);
      await tester.tap(find.byType(GameFlipCard).at(i));
      await tester.pump();
      await tester.tap(find.byType(GameFlipCard).at(j));
      await _pumpFor(tester, 800);
    }
    final panel = tester.widget<GameCompletePanel>(find.byType(GameCompletePanel));
    expect(panel.score, 4);
    expect(panel.wrong, 0, reason: 'early misses are free, as in Ghép đôi chữ');
    expect(find.text('Ván mới'), findsNothing);
    await _pumpFor(tester, 3600);
    expect(audio.said.last.lines, [KidGuide.gameWin]);
    await tester.tap(find.text('Chơi tiếp'));
    await _pumpFor(tester, 600);
    expect(find.byType(GameCompletePanel), findsNothing);
    expect(tester.widget<GameProgressBar>(find.byType(GameProgressBar)).current, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
