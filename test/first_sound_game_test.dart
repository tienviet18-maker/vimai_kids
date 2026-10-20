import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/audio/kid_guide.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/repositories/mastery_repository.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/features/games/logic/first_sound_round.dart';
import 'package:mai_an_learning/features/games/presentation/first_sound_game.dart';
import 'package:mai_an_learning/features/games/presentation/widgets/game_play_scaffold.dart';
import 'package:mai_an_learning/features/shared/widgets/chunky_button.dart';

/// Records what Mai would say and play instead of touching the audio plugin.
class _FakeAudio extends AudioService {
  final said = <String>[];
  final clips = <String>[];

  @override
  Future<AudioPlayResult> speak(
    List<String?> lines, {
    String? fallbackId,
    List<String> leadIds = const [],
    List<String> trailIds = const [],
  }) async {
    said.addAll(lines.whereType<String>());
    clips.addAll([...leadIds, ...trailIds]);
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

Widget _app({required Size size, required _FakeAudio audio, int age = 5}) {
  final notifier = CurrentProfileNotifier(ProfileRepository())
    ..state = ChildProfile(id: 't', name: 'Lan', age: age, avatar: 'peach', createdAt: DateTime(2026, 1, 1));
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(audio),
      masteryRepositoryProvider.overrideWithValue(MasteryRepository()),
    ],
    child: MaterialApp(
      home: MediaQuery(data: MediaQueryData(size: size), child: const FirstSoundGame()),
    ),
  );
}

void main() {
  group('onset rules', () {
    test('clusters before single consonants, vowels have none', () {
      expect(FirstSound.onsetOf('nghé'), 'ngh');
      expect(FirstSound.onsetOf('ngựa'), 'ng');
      expect(FirstSound.onsetOf('nhà'), 'nh');
      expect(FirstSound.onsetOf('chó'), 'ch');
      expect(FirstSound.onsetOf('trăng'), 'tr');
      expect(FirstSound.onsetOf('thỏ'), 'th');
      expect(FirstSound.onsetOf('khóc'), 'kh');
      expect(FirstSound.onsetOf('phở'), 'ph');
      expect(FirstSound.onsetOf('ghế'), 'gh');
      expect(FirstSound.onsetOf('giấy'), 'gi');
      expect(FirstSound.onsetOf('quả'), 'qu');
      expect(FirstSound.onsetOf('đèn'), 'đ');
      expect(FirstSound.onsetOf('bò'), 'b');
      expect(FirstSound.onsetOf('áo'), isNull);
      expect(FirstSound.onsetOf('ông'), isNull);
      expect(FirstSound.soundOf('k'), 'c');
      expect(FirstSound.soundOf('gh'), 'g');
      expect(FirstSound.soundOf('ngh'), 'ng');
    });

    test('every curated word is in words.json with its picture and clips', () {
      final data = jsonDecode(File('assets/data/vietnamese/words.json').readAsStringSync()) as List;
      final byWord = {
        for (final raw in data.cast<Map<String, dynamic>>()) raw['answer'] as String: raw['metadata'] as Map<String, dynamic>,
      };
      final emojis = <String>{};
      for (final w in FirstSound.words) {
        expect(byWord[w.word], isNotNull, reason: w.word);
        expect(byWord[w.word]!['image'], w.emoji, reason: w.word);
        expect(byWord[w.word]!['audioId'], w.audioId, reason: w.word);
        expect(File('assets/audio/${w.audioId}.mp3').existsSync(), isTrue, reason: w.audioId);
        expect(w.onset, isNotNull, reason: w.word);
        expect(File('assets/audio/${FirstSound.clipFor(w.sound)}.mp3').existsSync(), isTrue, reason: w.sound);
        expect(emojis.add(w.emoji), isTrue, reason: 'duplicate picture ${w.emoji}');
      }
    });
  });

  group('rounds', () {
    test('exactly one card has the sound, distractors never sound alike', () {
      for (var level = 0; level <= FirstSound.maxLevel; level++) {
        final random = Random(level);
        for (var i = 0; i < 300; i++) {
          final round = FirstSoundRound.generate(level: level, random: random);
          expect(round.cards.length, FirstSound.cardsFor(level));
          expect(round.cards.where(round.isCorrect).length, 1);
          expect(round.cards.map((c) => c.emoji).toSet().length, round.cards.length);
          final sounds = round.cards.map((c) => c.sound).toList();
          for (var a = 0; a < sounds.length; a++) {
            for (var b = a + 1; b < sounds.length; b++) {
              expect(FirstSound.sameSound(sounds[a], sounds[b]), isFalse, reason: '$sounds');
              if (level < 2) expect(FirstSound.isNear(sounds[a], sounds[b]), isFalse, reason: '$sounds');
            }
          }
          if (level == 0) expect(FirstSound.easySounds, containsAll(sounds));
          if (level == 2) {
            expect(sounds.where((s) => FirstSound.isNear(s, round.sound)), isNotEmpty, reason: '$sounds');
          }
        }
      }
    });
  });

  group('FirstSoundGame', () {
    for (final size in const [Size(360, 640), Size(1024, 768)]) {
      testWidgets('plays one correct answer at ${size.width.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final audio = _FakeAudio();
        await tester.pumpWidget(_app(size: size, audio: audio));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);

        // Intro, then the ask, then the consonant SOUND clip (never a letter name).
        expect(audio.said, containsAllInOrder([KidGuide.gameFirstSound, KidGuide.firstSoundAsk]));
        final banner = tester.widget<GameTargetBanner>(find.byType(GameTargetBanner));
        final sound = FirstSound.soundOf(banner.glyph.toLowerCase());
        expect(audio.clips, contains(FirstSound.clipFor(sound)));

        final cards = FirstSound.words.where((w) => find.text(w.word).evaluate().isNotEmpty).toList();
        expect(cards.length, 3);
        final answer = cards.singleWhere((w) => w.sound == sound);
        for (final w in cards) {
          final rect = tester.getRect(find.ancestor(of: find.text(w.emoji), matching: find.byType(ChunkyButton)).first);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
          expect(rect.width, greaterThanOrEqualTo(64), reason: 'touch target ${w.word} at $size');
        }

        await tester.tap(find.text(answer.emoji));
        await tester.pump();
        expect(find.text('Giỏi lắm!'), findsOneWidget);
        expect(audio.clips.last, answer.audioId);

        await tester.pump(const Duration(seconds: 3));
        // Mai models the blend: onset sound, then the word.
        final blendAt = audio.clips.lastIndexOf(answer.audioId);
        expect(audio.clips[blendAt - 1], FirstSound.clipFor(sound));

        await tester.pump(const Duration(seconds: 2));
        final progress = tester.widget<GameProgressBar>(find.byType(GameProgressBar));
        expect(progress.current, 1);
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('wrong card shakes and keeps the round', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final audio = _FakeAudio();
      await tester.pumpWidget(_app(size: const Size(390, 844), audio: audio));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final banner = tester.widget<GameTargetBanner>(find.byType(GameTargetBanner));
      final sound = FirstSound.soundOf(banner.glyph.toLowerCase());
      final wrong = FirstSound.words.firstWhere((w) => find.text(w.word).evaluate().isNotEmpty && w.sound != sound);
      await tester.tap(find.text(wrong.emoji));
      await tester.pump();
      expect(find.text('Thử lại nhé!'), findsOneWidget);
      expect(audio.clips.last, wrong.audioId);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(tester.widget<GameProgressBar>(find.byType(GameProgressBar)).current, 0);
      expect(tester.takeException(), isNull);
    });
  });
}
