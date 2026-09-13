import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_locale_policy.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/audio/vietnamese_phonics_guide.dart';
import 'package:mai_an_learning/core/audio/vietnamese_phonics_view.dart';
import 'package:mai_an_learning/core/audio/vietnamese_speech_catalog.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/data/content/content_repository.dart';
import 'package:mai_an_learning/data/repositories/mastery_repository.dart';
import 'package:mai_an_learning/data/repositories/profile_repository.dart';
import 'package:mai_an_learning/domain/content/content_item.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/features/japanese/writing/presentation/widgets/writing_canvas.dart';
import 'package:mai_an_learning/features/vietnamese/presentation/vietnamese_letter_lesson_screen.dart';

class _SpyAudio extends AudioService {
  final ids = <String>[];

  @override
  Future<AudioPlayResult> playAudio(String id) async {
    ids.add(id);
    return const AudioPlayResult.ok('vi-VN');
  }

  @override
  Future<AudioPlayResult> playAsset(String assetKey) => playAudio(assetKey);

  @override
  Future<AudioPlayResult> playVietnameseAsset(String audioId) => playAudio(audioId);

  @override
  Future<AudioPlayResult> playVietnameseLetterName(String letter, {String? audioAsset}) async {
    ids.add('NAME:$letter');
    return const AudioPlayResult.ok('vi-VN');
  }

  @override
  Future<AudioPlayResult> playVietnameseLetterSound(String letter, {String? audioAsset}) async {
    ids.add('SOUND:$letter');
    return const AudioPlayResult.ok('vi-VN');
  }

  @override
  Future<void> stop() async {}
}

class _AlphabetRepo extends ContentRepository {
  _AlphabetRepo(this._letters);
  final List<ContentItem> _letters;

  @override
  List<ContentItem> getVietnameseAlphabet() => _letters;
}

List<ContentItem> _loadAlphabet() {
  final raw = File('assets/content/vietnamese/alphabet.json').readAsStringSync();
  return (jsonDecode(raw) as List).map((e) => ContentItem.fromJson(e as Map<String, dynamic>)).toList();
}

ChildProfile _profile() {
  return ChildProfile(id: 'test', name: 'Lan', age: 5, avatar: 'peach', createdAt: DateTime(2026, 1, 1));
}

Widget _app({required Widget home, required ContentRepository repo, required AudioService audio}) {
  final notifier = CurrentProfileNotifier(ProfileRepository())..state = _profile();
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(ProfileRepository()),
      currentProfileProvider.overrideWith((ref) => notifier),
      audioServiceProvider.overrideWithValue(audio),
      contentRepositoryProvider.overrideWithValue(repo),
      masteryRepositoryProvider.overrideWithValue(MasteryRepository()),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: home,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<ContentItem> letters;

  setUpAll(() {
    letters = _loadAlphabet();
  });

  test('curriculum has 29 Vietnamese letters and is not rewritten', () {
    expect(letters.length, 29);
    expect(letters.map((e) => e.id).toSet().length, 29);
    final c = letters.firstWhere((e) => e.question == 'C');
    expect(c.letterName, 'xê');
    expect(c.phoneme, 'cờ');
    expect(c.exampleWord, 'cá');
    expect(c.audioNameId, 'vi_letter_c_name');
    expect(c.audioSoundId, 'vi_letter_c_sound');
  });

  test('phonics primary for C is cờ, never letter-name xê', () {
    final c = letters.firstWhere((e) => e.question == 'C');
    expect(VietnamesePhonicsGuide.primarySpoken(c), 'cờ');
    expect(VietnamesePhonicsGuide.letterNameSpoken(c), 'xê');
    expect(VietnamesePhonicsGuide.nameDiffersFromSound(c), isTrue);
    expect(VietnamesePhonicsGuide.primaryAudioId(c), 'v_c');
    expect(VietnamesePhonicsGuide.primaryAudioId(c), isNot('vi_letter_c_name'));
    expect(VietnameseSpeechCatalog.soundSpoken('C'), 'cờ');
    expect(VietnameseSpeechCatalog.nameSpoken('C'), 'xê');
  });

  test('catalog name/sound match curriculum; phonics overlay is explicit', () {
    for (final letter in letters) {
      final glyph = letter.question ?? '';
      expect(VietnameseSpeechCatalog.letters.containsKey(glyph), isTrue, reason: glyph);
      expect(VietnameseSpeechCatalog.nameSpoken(glyph), letter.letterName, reason: glyph);
      expect(VietnameseSpeechCatalog.soundSpoken(glyph), letter.phoneme, reason: glyph);
      expect(VietnamesePhonicsGuide.primarySpoken(letter), VietnameseSpeechCatalog.phonicsSpoken(glyph), reason: glyph);
      if (letter.letterName != letter.phoneme) {
        expect(
          VietnamesePhonicsGuide.primaryAudioId(letter),
          VietnameseSpeechCatalog.getAudioIdForLetter(glyph),
          reason: glyph,
        );
      }
    }
  });

  test('required phonics spoken forms B C D Đ Y', () {
    expect(VietnameseSpeechCatalog.phonicsSpoken('B'), 'bờ');
    expect(VietnameseSpeechCatalog.phonicsSpoken('C'), 'cờ');
    expect(VietnameseSpeechCatalog.phonicsSpoken('D'), 'dờ');
    expect(VietnameseSpeechCatalog.phonicsSpoken('Đ'), 'đờ');
    expect(VietnameseSpeechCatalog.phonicsSpoken('Y'), 'i dài');
    expect(VietnameseSpeechCatalog.nameSpoken('B'), 'bê');
    expect(VietnameseSpeechCatalog.nameSpoken('C'), 'xê');
    expect(VietnameseSpeechCatalog.nameSpoken('Y'), 'i');
    expect(VietnameseSpeechCatalog.soundSpoken('Y'), 'i');
    final y = letters.firstWhere((e) => e.question == 'Y');
    expect(y.phoneme, 'i');
    expect(y.letterName, 'i');
    expect(VietnamesePhonicsGuide.primarySpoken(y), 'i dài');
    expect(VietnamesePhonicsGuide.letterNameSpoken(y), 'i');
    expect(VietnamesePhonicsGuide.nameDiffersFromSound(y), isTrue);
    final i = letters.firstWhere((e) => e.question == 'I');
    expect(i.phoneme, 'i');
    expect(VietnamesePhonicsGuide.primarySpoken(i), 'i');
  });

  test('letter-keyed pedagogy map covers 29 letters and hides names from children', () {
    final raw = jsonDecode(File('tool/audio_generation/vietnamese_pronunciation_map.json').readAsStringSync()) as Map<String, dynamic>;
    expect(raw['curriculumModified'], isFalse);
    expect(raw['childShowsLetterName'], isFalse);
    final map = raw['letters'] as Map<String, dynamic>;
    expect(map.keys, hasLength(29));
    expect(map['B']['spoken'], 'bờ');
    expect(map['C']['spoken'], 'cờ');
    expect(map['D']['spoken'], 'dờ');
    expect(map['Đ']['spoken'], 'đờ');
    expect(map['Y']['spoken'], 'i dài');
    expect(map['C']['letterName'], 'xê');
    expect(map['C']['example'], 'cá');
    for (final letter in letters) {
      final glyph = letter.question ?? '';
      final row = map[glyph] as Map<String, dynamic>;
      expect(row['spoken'], VietnameseSpeechCatalog.phonicsSpoken(glyph), reason: glyph);
      expect(row['example'], letter.exampleWord, reason: glyph);
    }
  });

  test('generation map keeps C phonics spokenText as cờ', () {
    final raw = jsonDecode(File('tool/audio_generation/vimai_kids_pronunciation_map.json').readAsStringSync()) as Map<String, dynamic>;
    expect(raw['curriculumModified'], isFalse);
    expect(raw['scope'], 'AUDIO_GENERATION_ONLY');
    final items = (raw['items'] as List).cast<Map<String, dynamic>>();
    final sound = items.firstWhere((e) => e['id'] == 'vi_letter_c_sound');
    final name = items.firstWhere((e) => e['id'] == 'vi_letter_c_name');
    expect(sound['spokenText'], 'cờ');
    expect(name['spokenText'], 'xê');
    expect(sound['originalCurriculumText'], 'cờ');
    expect(items.firstWhere((e) => e['id'] == 'vi_letter_y_sound')['spokenText'], 'i dài');
    expect(items.firstWhere((e) => e['id'] == 'vi_letter_y_name')['spokenText'], 'i dài');
    expect(items.firstWhere((e) => e['id'] == 'vi_letter_b_sound')['spokenText'], 'bờ');
    expect(items.firstWhere((e) => e['id'] == 'vi_letter_d_sound')['spokenText'], 'dờ');
    expect(items.firstWhere((e) => e['id'] == 'vi_letter_dd_sound')['spokenText'], 'đờ');
  });

  testWidgets('phonics look lesson autoplays sound id, not letter name', (tester) async {
    final spy = _SpyAudio();
    await tester.pumpWidget(
      _app(
        home: const VietnameseLetterLessonScreen(startId: 'v_c'),
        repo: _AlphabetRepo(letters),
        audio: spy,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('C'), findsWidgets);
    expect(find.text('cờ'), findsOneWidget);
    expect(find.text('cá'), findsWidgets);
    expect(find.text('Nghe nào!'), findsOneWidget);
    expect(find.text('xê'), findsNothing);
    expect(find.text('Tên chữ: xê'), findsNothing);
    expect(find.text('Xê'), findsNothing);
    expect(spy.ids, isNotEmpty);
    expect(spy.ids.first, 'v_c');
    expect(spy.ids.where((e) => e == 'vi_letter_c_name' || e.startsWith('NAME:')), isEmpty);
  });

  testWidgets('Y phonics look shows i dài, not a bare short i as the teaching sound', (tester) async {
    final spy = _SpyAudio();
    await tester.pumpWidget(
      _app(
        home: const VietnameseLetterLessonScreen(startId: 'v_y'),
        repo: _AlphabetRepo(letters),
        audio: spy,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Y'), findsWidgets);
    expect(find.text('i dài'), findsOneWidget);
    expect(find.text('Tên chữ: i'), findsNothing);
    expect(find.text('xê'), findsNothing);
    expect(find.textContaining('Học âm chữ'), findsOneWidget);
    expect(spy.ids.first, 'v_y');
  });

  testWidgets('Vietnamese write mode shows a practice canvas immediately', (tester) async {
    await tester.pumpWidget(
      _app(
        home: const VietnameseLetterLessonScreen(startId: 'v_c', startMode: 'write'),
        repo: _AlphabetRepo(letters),
        audio: _SpyAudio(),
      ),
    );
    await tester.pump();
    expect(find.byType(WritingCanvas), findsOneWidget);
    expect(find.text('Con hãy viết theo mẫu'), findsOneWidget);
  });

  test('phonics view-model keeps letter names in data and hides them from child mode', () {
    ContentItem letterOf(String glyph) => letters.firstWhere((e) => e.question == glyph);
    final c = VietnamesePhonicsView.fromItem(letterOf('C'));
    expect(c.letterName, 'xê');
    expect(c.phonics, 'cờ');
    expect(c.ttsText, 'cờ');
    expect(c.exampleWord, 'cá');
    expect(c.audioType, 'sound');
    expect(c.showLetterNameInChildMode, isFalse);
    expect(VietnamesePhonicsView.fromItem(letterOf('B')).phonics, 'bờ');
    expect(VietnamesePhonicsView.fromItem(letterOf('D')).phonics, 'dờ');
    expect(VietnamesePhonicsView.fromItem(letterOf('Đ')).phonics, 'đờ');
    expect(VietnamesePhonicsView.fromItem(letterOf('Y')).phonics, 'i dài');
  });
}
