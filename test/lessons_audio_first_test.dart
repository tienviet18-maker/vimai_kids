import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/audio/kid_guide.dart';
import 'package:mai_an_learning/core/audio/speech_id.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/content/content_repository.dart';
import 'package:mai_an_learning/data/content/creativity_catalog.dart';
import 'package:mai_an_learning/data/content/thinking_generator.dart';
import 'package:mai_an_learning/data/repositories/mastery_repository.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/content/content_item.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/domain/models/skill_mastery.dart';
import 'package:mai_an_learning/features/thinking/presentation/thinking_screen.dart';
import 'package:mai_an_learning/features/vietnamese/presentation/vietnamese_activities.dart';
import 'package:mai_an_learning/features/vietnamese/presentation/vietnamese_letter_lesson_screen.dart';

class _Said {
  _Said(this.lines, this.lead, this.trail);
  final List<String> lines;
  final List<String> lead;
  final List<String> trail;
  List<String> get all => [...lead, ...lines, ...trail];
  @override
  String toString() => 'lead=$lead lines=$lines trail=$trail';
}

class _SpyAudio extends AudioService {
  final said = <_Said>[];

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
  Future<AudioPlayResult> playAudio(String id, {bool waitForComplete = false}) async =>
      const AudioPlayResult.unavailable('test');

  @override
  void sfx(Sfx effect) {}

  @override
  Future<void> stop() async {}
}

/// Always asks the given questions, in order.
class _FixedEngine extends ThinkingQuestionEngine {
  _FixedEngine(this.items);
  final List<ContentItem> items;
  int _i = 0;

  @override
  ContentItem next({required int age, List<SkillMastery> mastery = const []}) => items[_i++ % items.length];
}

Widget _app(Widget home, ContentRepository content, AudioService audio) {
  final notifier = CurrentProfileNotifier(ProfileRepository())
    ..state = ChildProfile(id: 't', name: 'Lan', age: 5, avatar: 'peach', createdAt: DateTime(2026, 1, 1));
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      masteryRepositoryProvider.overrideWithValue(MasteryRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(audio),
      contentRepositoryProvider.overrideWithValue(content),
    ],
    child: MaterialApp(home: home),
  );
}

Future<ContentRepository> _content(WidgetTester tester) async {
  final repo = ContentRepository();
  await tester.runAsync(repo.loadAllContent);
  return repo;
}

Future<void> _settle(WidgetTester tester, [int steps = 12]) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

String _clip(String line) => SpeechId.idForLine(line)!;

ContentItem _thinking(String id, String skill, String instruction, String answer, List<String> choices,
        {Map<String, dynamic>? metadata}) =>
    ContentItem(
      id: id,
      subject: ContentSubject.thinking,
      ageMin: 3,
      ageMax: 7,
      level: 1,
      skill: skill,
      difficulty: 1,
      title: 'Test',
      instruction: instruction,
      question: instruction,
      answer: answer,
      choices: choices,
      metadata: metadata,
    );

void main() {
  group('Tư duy', () {
    test('Nhớ vị trí keeps the row out of the question text', () {
      final engine = ThinkingQuestionEngine(random: Random(1));
      final memory = engine.allForAge(7).where((e) => e.skill == 'memory').toList();
      expect(memory, isNotEmpty);
      for (final item in memory) {
        final row = (item.metadata?['sequence'] as List).cast<String>();
        expect(row.length, greaterThanOrEqualTo(3), reason: item.id);
        expect(row, contains(item.answer), reason: item.id);
        for (final e in row) {
          expect(item.instruction.contains(e), isFalse, reason: '${item.id} shows $e while asking');
        }
      }
    });

    testWidgets('Nhớ vị trí shows the row, hides it, then asks with choices', (tester) async {
      await _phone(tester);
      final content = await _content(tester);
      final audio = _SpyAudio();
      final item = _thinking('mem_t', 'memory', 'Hình ở giữa là gì?', '🐶', ['🐱', '🐶', '🐭', '🐰'],
          metadata: {'sequence': ['🐱', '🐶', '🐭']});
      await tester.pumpWidget(_app(ThinkingScreen(engine: _FixedEngine([item])), content, audio));
      await _settle(tester, 4);
      // Looking phase: the row is on screen, nothing to answer yet.
      expect(find.text('🐭'), findsOneWidget);
      expect(find.text('🐰'), findsNothing);
      expect(audio.said.last.all, contains(_clip(KidGuide.memoryLook)));

      await _settle(tester, 24); // 6 s
      // Hidden: covered cards, the question is asked, the choices appear.
      expect(find.text('?'), findsNWidgets(3));
      expect(find.text('🐰'), findsOneWidget);
      expect(audio.said.last.lines, ['Hình ở giữa là gì?']);

      await tester.tap(find.text('Xem lại'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('?'), findsNothing);
      await _settle(tester, 14);
      expect(find.text('?'), findsNWidgets(3));
    });

    testWidgets('written answers have a speaker; tapping says the answer before the praise', (tester) async {
      await _phone(tester);
      final content = await _content(tester);
      final audio = _SpyAudio();
      final q1 = _thinking('l3', 'logic', 'Ban ngày trời sáng. Ban đêm trời?', 'tối', ['sáng', 'tối', 'mưa']);
      final q2 = _thinking('l5', 'logic', 'Chim thì biết gì?', 'bay', ['bơi', 'bay', 'đào']);
      await tester.pumpWidget(_app(ThinkingScreen(engine: _FixedEngine([q1, q2])), content, audio));
      await _settle(tester, 4);
      // First question with words: Mai says how to hear them.
      expect(audio.said.last.all, contains(_clip(KidGuide.tapSmallSpeaker)));

      await tester.tap(find.byKey(const ValueKey('hear-mưa')));
      await tester.pump();
      expect(audio.said.last.lead, [_clip('mưa')]);

      final before = audio.said.length;
      await tester.tap(find.text('tối'));
      await tester.pump();
      await tester.pump();
      final praise = audio.said.last;
      expect(praise.lead, [_clip('tối')]);
      expect(KidGuide.praise, contains(praise.lines.single));
      // The next question rides on the praise instead of cutting it.
      expect(praise.trail, contains(_clip('Chim thì biết gì?')));
      await _settle(tester, 10);
      expect(find.text('Chim thì biết gì?'), findsOneWidget);
      expect(audio.said.length, before + 1, reason: 'nothing spoken over the praise at the advance');
    });

    test('pictures at the end of a question are split off to be shown big', () {
      expect(thinkingPromptParts('Hai hình này giống hay khác? ● ▲'), ('Hai hình này giống hay khác?', '● ▲'));
      expect(thinkingPromptParts('Hai chữ này giống hay khác? A B'), ('Hai chữ này giống hay khác?', 'A B'));
      expect(thinkingPromptParts('Số tiếp theo: 1 2 3 ?'), ('Số tiếp theo:', '1 2 3 ?'));
      expect(thinkingPromptParts('Đâu là con vật?').$2, isNull);
      expect(thinkingPromptParts('Hình đầu tiên: 1️⃣2️⃣3️⃣ — đâu là đầu?').$2, isNull);
    });

    test('no logic or path question says its own answer word', () {
      final engine = ThinkingQuestionEngine(random: Random(2));
      for (final item in engine.allForAge(7)) {
        if (item.skill != 'logic' && item.skill != 'path') continue;
        if (!SpeechId.isSpeakable(item.answer!)) continue; // pictures and arrows are meant to be seen.
        final words = item.instruction.replaceAll('?', ' ').toLowerCase().split(' ');
        expect(words.contains(item.answer!.toLowerCase()), isFalse, reason: '${item.id}: "${item.instruction}"');
      }
    });
  });

  group('Tiếng Việt', () {
    testWidgets('Ghép âm says the how-to once, then only the short ask and the blend', (tester) async {
      await _phone(tester);
      final content = await _content(tester);
      final audio = _SpyAudio();
      await tester.pumpWidget(_app(
        VietnameseQuizListScreen(
          title: 'Ghép âm',
          skill: 'vietnamese.blend',
          loader: (ref) => ref.read(contentRepositoryProvider).getVietnamesePhonics(),
        ),
        content,
        audio,
      ));
      await _settle(tester, 4);
      expect(audio.said.last.lines, [KidGuide.blendHowTo]);
      expect(audio.said.last.trail, ['v_blend_ba']);

      await tester.tap(find.text('ba'));
      await tester.pump();
      await tester.pump();
      final praise = audio.said.last;
      expect(praise.trail.first, _clip(KidGuide.listenPickWord));
      expect(praise.all, isNot(contains(_clip(KidGuide.blendHowTo))));
      final count = audio.said.length;
      await _settle(tester, 10);
      expect(audio.said.length, count, reason: 'the advance does not start a line over the praise');
      expect(find.text('2 / 10'), findsOneWidget);
    });

    testWidgets('stars count first-try answers only', (tester) async {
      await _phone(tester);
      final content = await _content(tester);
      final audio = _SpyAudio();
      final items = content.getVietnameseVocabulary().take(10).toList();
      await tester.pumpWidget(_app(
        VietnameseQuizListScreen(title: 'Từ vựng', skill: 'vietnamese.words', loader: (ref) => items),
        content,
        audio,
      ));
      await _settle(tester, 4);
      for (var i = 0; i < 10; i++) {
        final item = items[i];
        if (i == 0) {
          // One wrong tap first on the first word.
          final grid = find.byWidgetPredicate((w) => w is Text && w.data != item.answer && (item.choices ?? []).contains(w.data));
          await tester.tap(grid.first);
          await tester.pump(const Duration(milliseconds: 200));
        }
        await tester.tap(find.text(item.answer!).last);
        await _settle(tester, 9);
      }
      expect(find.text('⭐ 9 / 10'), findsOneWidget);
    });

    testWidgets('words without a picture keep the answer hidden until found', (tester) async {
      await _phone(tester);
      final content = await _content(tester);
      final item = content.getVietnameseWords().firstWhere((e) => e.id == 'v_vocab_caca');
      expect(item.metadata?['image'], isNull);
      await tester.pumpWidget(_app(
        VietnameseQuizListScreen(title: 'Từ', skill: 'vietnamese.words', loader: (ref) => [item, ...content.getVietnameseWords().take(5)]),
        content,
        _SpyAudio(),
      ));
      await _settle(tester, 4);
      // Only the choice says "ca ca"; the hero card shows the ear icon.
      expect(find.text('ca ca'), findsOneWidget);
      expect(find.byIcon(Icons.hearing_rounded), findsOneWidget);
    });

    test('vocabulary words and example words have pictures where one fits', () {
      final words = jsonDecode(File('assets/data/vietnamese/words.json').readAsStringSync()) as List;
      String? image(String id) => ((words.firstWhere((e) => e['id'] == id) as Map)['metadata'] as Map)['image'] as String?;
      expect(image('v_vocab_baba'), '🐢');
      expect(image('v_vocab_bame'), isNotNull);
      expect(image('v_vocab_dodo'), '🔴');
      final letters = jsonDecode(File('assets/data/vietnamese/alphabet.json').readAsStringSync()) as List;
      final a = (letters.first as Map)['metadata'] as Map;
      expect(a['exampleWord'], 'áo');
      expect(a['exampleImage'], '👕');
    });

    testWidgets('example word "áo" shows its picture, not a blank dot', (tester) async {
      await _phone(tester);
      final content = await _content(tester);
      await tester.pumpWidget(_app(const VietnameseLetterLessonScreen(startId: 'v_a'), content, _SpyAudio()));
      await _settle(tester, 4);
      expect(find.text('👕'), findsOneWidget);
      expect(find.byType(WordExampleWidget), findsOneWidget);
    });

    testWidgets('Nhiều dạng bài: written sounds can be heard, and alike letters never share a question',
        (tester) async {
      await _phone(tester);
      final content = await _content(tester);
      final audio = _SpyAudio();
      await tester.pumpWidget(_app(
        VietnameseChooseLetterScreen(modes: const [VietnameseChooseMode.letterToSound], random: Random(3)),
        content,
        audio,
      ));
      await _settle(tester, 4);
      expect(find.textContaining('đọc âm nào?'), findsOneWidget);
      final badges = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('hear-'));
      expect(badges, findsNWidgets(4));
      await tester.tap(badges.first);
      await tester.pump();
      expect(audio.said.last.lead.single, startsWith('v_'));
    });

    testWidgets('"Chữ này đọc âm nào?" never asks a vowel whose sound is the letter itself', (tester) async {
      await _phone(tester);
      final content = await _content(tester);
      for (var seed = 0; seed < 10; seed++) {
        await tester.pumpWidget(_app(
          VietnameseChooseLetterScreen(key: ValueKey(seed), modes: const [VietnameseChooseMode.letterToSound], random: Random(seed)),
          content,
          _SpyAudio(),
        ));
        await _settle(tester, 2);
        for (final v in ['a', 'e', 'ê', 'i', 'o', 'ô', 'ơ', 'u', 'ư']) {
          expect(find.text('${v.toUpperCase()}  $v'), findsNothing, reason: 'seed $seed asks $v');
        }
      }
    });

    testWidgets('Tìm chữ: one praise, with the next letter after it', (tester) async {
      await _phone(tester);
      final content = await _content(tester);
      final audio = _SpyAudio();
      await tester.pumpWidget(_app(const VietnameseLetterLessonScreen(startId: 'v_a', startMode: 'recognize'), content, audio));
      await _settle(tester, 4);
      final before = audio.said.length;
      await tester.tap(find.text('A'));
      await _settle(tester, 12);
      final praises = audio.said.sublist(before).where((e) => e.lines.any(KidGuide.praise.contains) || e.lines.any((l) => l.contains('liền'))).toList();
      expect(praises, hasLength(1), reason: '${audio.said.sublist(before)}');
      expect(praises.single.lead, ['v_a']);
      expect(praises.single.trail, ['v_aw']);
      // The page change does not say the letter again over the praise.
      expect(audio.said.length, before + 1, reason: '${audio.said.sublist(before)}');
    });

    test('letter-name mode is gone: there are no letter-name clips', () {
      expect(VietnameseChooseMode.values.map((e) => e.name), isNot(contains('hearName')));
    });

    testWidgets('Nghe chữ never offers C with K or I with Y', (tester) async {
      await _phone(tester);
      final content = await _content(tester);
      for (var seed = 0; seed < 12; seed++) {
        await tester.pumpWidget(_app(
          VietnameseChooseLetterScreen(key: ValueKey(seed), modes: const [VietnameseChooseMode.hearSound], random: Random(seed)),
          content,
          _SpyAudio(),
        ));
        await _settle(tester, 2);
        final both = (find.text('C').evaluate().isNotEmpty && find.text('K').evaluate().isNotEmpty) ||
            (find.text('I').evaluate().isNotEmpty && find.text('Y').evaluate().isNotEmpty);
        expect(both, isFalse, reason: 'seed $seed');
      }
      final alphabet = content.getVietnameseAlphabet();
      ContentItem l(String g) => alphabet.firstWhere((e) => e.question == g);
      expect(vietnameseLettersSoundAlike(l('C'), l('K')), isTrue);
      expect(vietnameseLettersSoundAlike(l('I'), l('Y')), isTrue);
      expect(vietnameseLettersSoundAlike(l('B'), l('D')), isFalse);
    });
  });

  group('Sáng tạo', () {
    test('match puzzles: every left picture has one clear partner', () {
      final all = CreativityCatalog.matchPuzzles();
      final baby = all.firstWhere((e) => e.id == 'match_baby');
      expect(baby.right, isNot(contains('🐮')));
      expect(all.firstWhere((e) => e.id == 'match_sports').right, isNot(contains('🏸')));
      expect(all.firstWhere((e) => e.id == 'match_body').right, isNot(contains('👁️')));
    });
  });
}
