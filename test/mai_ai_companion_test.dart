import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mai_an_learning/core/ai/gemini_client.dart';
import 'package:mai_an_learning/core/ai/mai_action.dart';
import 'package:mai_an_learning/core/ai/mai_context.dart';
import 'package:mai_an_learning/core/ai/mai_offline_fallback.dart';
import 'package:mai_an_learning/core/ai/mai_response.dart';
import 'package:mai_an_learning/core/ai/mai_safety.dart';
import 'package:mai_an_learning/core/ai/mai_ai_service.dart';
import 'package:mai_an_learning/core/audio/vietnamese_speech_catalog.dart';
import 'package:mai_an_learning/core/providers.dart';
import 'package:mai_an_learning/domain/models/child_profile.dart';
import 'package:mai_an_learning/features/ai/presentation/mai_assistant_bubble.dart';
import 'package:mai_an_learning/features/ai/presentation/mai_companion_state.dart';
import 'package:mai_an_learning/features/ai/presentation/mai_companion_widget.dart';
import 'package:mai_an_learning/features/shared/widgets/lesson_journey.dart';
import 'package:mai_an_learning/features/shared/widgets/vimai_mascot.dart';

/// Test mock for Gemini API Client
class MockGeminiApiClient implements GeminiApiClient {
  String? mockResponse;
  bool shouldThrow = false;
  int callCount = 0;
  String? lastPrompt;

  @override
  Future<String?> generateContent({
    required String prompt,
    required String apiKey,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    callCount++;
    lastPrompt = prompt;
    if (shouldThrow) {
      throw Exception('Network unreachable or socket closed');
    }
    return mockResponse;
  }
}

void main() {
  group('1. MaiContext & Minimalist Payload Structure', () {
    test('captures all required pedagogical fields and omits raw database state', () {
      const context = MaiContext(
        currentModule: 'math',
        currentLesson: 'addition_under_5',
        currentActivity: 'quiz',
        currentQuestion: '2 + 3 = ?',
        attemptNumber: 2,
        targetLanguage: 'vi',
        learningObjective: 'Phép cộng trong phạm vi 5',
        hintLevel: 1,
        childAge: 5,
        expectedAnswer: '5',
        choices: ['3', '4', '5'],
      );

      expect(context.currentModule, 'math');
      expect(context.currentLesson, 'addition_under_5');
      expect(context.currentActivity, 'quiz');
      expect(context.currentQuestion, '2 + 3 = ?');
      expect(context.attemptNumber, 2);
      expect(context.targetLanguage, 'vi');
      expect(context.learningObjective, 'Phép cộng trong phạm vi 5');
      expect(context.hintLevel, 1);
      expect(context.childAge, 5);

      final payload = context.toMinimalistPayload();

      // Verify payload is minimalist
      expect(payload['currentModule'], 'math');
      expect(payload['currentLesson'], 'addition_under_5');
      expect(payload['currentActivity'], 'quiz');
      expect(payload['currentQuestion'], '2 + 3 = ?');
      expect(payload['attemptNumber'], 2);
      expect(payload['targetLanguage'], 'vi');
      expect(payload['learningObjective'], 'Phép cộng trong phạm vi 5');
      expect(payload['hintLevel'], 1);
      expect(payload['childAge'], 5);
      expect(payload['choices'], ['3', '4', '5']);

      // Ensure no raw internal database IDs or profile paths
      expect(payload.containsKey('childId'), isFalse);
      expect(payload.containsKey('profileId'), isFalse);
      expect(payload.containsKey('rawDatabase'), isFalse);
      expect(payload.containsKey('box'), isFalse);
    });

    test('hintLevel is clamped between 0 and 4 in payload', () {
      const low = MaiContext(
        currentModule: 'math',
        currentLesson: 'count',
        currentActivity: 'quiz',
        currentQuestion: 'Đếm số táo',
        learningObjective: 'Đếm',
        hintLevel: -2,
      );
      expect(low.toMinimalistPayload()['hintLevel'], 0);

      const high = MaiContext(
        currentModule: 'math',
        currentLesson: 'count',
        currentActivity: 'quiz',
        currentQuestion: 'Đếm số táo',
        learningObjective: 'Đếm',
        hintLevel: 9,
      );
      expect(high.toMinimalistPayload()['hintLevel'], 4);
    });
  });

  group('2. Progressive Hint Model (Levels 0 to 4)', () {
    late MaiAiService service;
    late MockGeminiApiClient mockClient;

    setUp(() {
      mockClient = MockGeminiApiClient();
      service = MaiAiService(apiClient: mockClient, apiKey: '');
    });

    test('hints progress sequentially from Level 0 to Level 4 and clamp at 4', () {
      const qKey = 'math_add_2+3';
      expect(service.getHintLevel(qKey), 0);

      expect(service.advanceHintLevel(qKey), 1);
      expect(service.getHintLevel(qKey), 1);

      expect(service.advanceHintLevel(qKey), 2);
      expect(service.getHintLevel(qKey), 2);

      expect(service.advanceHintLevel(qKey), 3);
      expect(service.getHintLevel(qKey), 3);

      expect(service.advanceHintLevel(qKey), 4);
      expect(service.getHintLevel(qKey), 4);

      // Clamp at Level 4 (Demonstration)
      expect(service.advanceHintLevel(qKey), 4);
      expect(service.getHintLevel(qKey), 4);
    });

    test('correct answer resets hint level back to 0', () async {
      const context = MaiContext(
        currentModule: 'math',
        currentLesson: 'addition_under_5',
        currentActivity: 'quiz',
        currentQuestion: '2 + 3 = ?',
        learningObjective: 'Phép cộng',
        hintLevel: 3,
      );

      service.advanceHintLevel('math_addition_under_5_2 + 3 = ?');
      service.advanceHintLevel('math_addition_under_5_2 + 3 = ?');
      expect(service.getHintLevel('math_addition_under_5_2 + 3 = ?'), 2);

      final praise = await service.onCorrectAnswer(context);
      expect(praise.action, MaiAction.celebrate);
      expect(service.getHintLevel('math_addition_under_5_2 + 3 = ?'), 0);
    });

    test('Math progressive hint levels follow pedagogical roles', () {
      const fallback = MaiOfflineFallback();

      // Level 0: Nudge / Attention
      const ctx0 = MaiContext(
        currentModule: 'math',
        currentLesson: 'addition_under_5',
        currentActivity: 'quiz',
        currentQuestion: '2 + 3 = ?',
        learningObjective: 'Cộng trong 5',
        expectedAnswer: '5',
        hintLevel: 0,
      );
      final h0 = fallback.generate(ctx0, requestedAction: MaiAction.hint);
      expect(h0.text, contains('nhìn kỹ lại'));
      expect(h0.action, MaiAction.hint);

      // Level 1: Concept Cue / Guiding question
      final h1 = fallback.generate(ctx0.copyWith(hintLevel: 1), requestedAction: MaiAction.hint);
      expect(h1.text, contains('Dấu cộng (+) nghĩa là'));

      // Level 2: Elimination / Strategy
      final h2 = fallback.generate(ctx0.copyWith(hintLevel: 2), requestedAction: MaiAction.hint);
      expect(h2.text, contains('lớn hơn số ban đầu'));

      // Level 3: Step-by-Step Walkthrough
      final h3 = fallback.generate(ctx0.copyWith(hintLevel: 3), requestedAction: MaiAction.hint);
      expect(h3.text, contains('giữ số đầu tiên trong đầu'));

      // Level 4: Direct Demonstration / Model Solution
      final h4 = fallback.generate(ctx0.copyWith(hintLevel: 4), requestedAction: MaiAction.demonstrate);
      expect(h4.action, MaiAction.demonstrate);
      expect(h4.text, contains('đáp án đúng là 5'));
      expect(h4.suggestedChoice, '5');
    });

    test('Thinking progressive hint levels follow pattern recognition pedagogy', () {
      const fallback = MaiOfflineFallback();
      const ctx = MaiContext(
        currentModule: 'thinking',
        currentLesson: 'pattern',
        currentActivity: 'quiz',
        currentQuestion: 'Tìm hình tiếp theo',
        learningObjective: 'Quy luật hình dạng',
        expectedAnswer: '△',
      );

      final h0 = fallback.generate(ctx.copyWith(hintLevel: 0), requestedAction: MaiAction.hint);
      expect(h0.text, contains('quan sát thật kỹ'));

      final h1 = fallback.generate(ctx.copyWith(hintLevel: 1), requestedAction: MaiAction.hint);
      expect(h1.text, contains('quy luật'));

      final h2 = fallback.generate(ctx.copyWith(hintLevel: 2), requestedAction: MaiAction.hint);
      expect(h2.text, contains('loại trừ'));

      final h4 = fallback.generate(ctx.copyWith(hintLevel: 4), requestedAction: MaiAction.demonstrate);
      expect(h4.action, MaiAction.demonstrate);
      expect(h4.suggestedChoice, '△');
    });
  });

  group('3. Offline Fallback & API Failure Handling', () {
    test('instant offline fallback when API key is empty', () async {
      final mock = MockGeminiApiClient();
      final service = MaiAiService(apiClient: mock, apiKey: '');

      const ctx = MaiContext(
        currentModule: 'vietnamese',
        currentLesson: 'chu_c',
        currentActivity: 'quiz',
        currentQuestion: 'Tìm chữ C',
        learningObjective: 'Nhận biết chữ C',
        expectedAnswer: 'C',
      );

      final resp = await service.requestHint(ctx);
      expect(resp.isOfflineFallback, isTrue);
      expect(mock.callCount, 0); // No network call made
      expect(resp.text, isNotEmpty);
    });

    test('instant offline fallback when network throws an exception', () async {
      final mock = MockGeminiApiClient()
        ..shouldThrow = true;
      final service = MaiAiService(apiClient: mock, apiKey: 'dummy_key');

      const ctx = MaiContext(
        currentModule: 'math',
        currentLesson: 'addition',
        currentActivity: 'quiz',
        currentQuestion: '1 + 1 = ?',
        learningObjective: 'Phép cộng',
        expectedAnswer: '2',
      );

      final resp = await service.requestHint(ctx);
      expect(resp.isOfflineFallback, isTrue);
      expect(resp.text, isNotEmpty);
      // No raw Exception text is presented to child
      expect(resp.text.contains('Exception'), isFalse);
      expect(resp.text.contains('Error:'), isFalse);
    });

    test('MaiResponseParser safely parses JSON in markdown code blocks', () {
      const raw = '''
```json
{
  "action": "HINT",
  "text": "Bé đếm thử xem có bao nhiêu bạn thỏ nhé!",
  "hint_level": 2,
  "mood": "thinking"
}
```
''';
      final parsed = MaiResponseParser.parse(raw);
      expect(parsed.action, MaiAction.hint);
      expect(parsed.text, 'Bé đếm thử xem có bao nhiêu bạn thỏ nhé!');
      expect(parsed.hintLevel, 2);
      expect(parsed.mood, MascotMood.thinking);
    });

    test('MaiResponseParser cleans up raw JSON or stack traces from bad responses', () {
      const rawError = 'InternalServerError: Exception in Gemini backend. StackTrace: line 42 at org...';
      final parsed = MaiResponseParser.parse(rawError);
      expect(parsed.text.contains('Exception'), isFalse);
      expect(parsed.text.contains('StackTrace'), isFalse);
      expect(parsed.text, contains('Mai'));
    });
  });

  group('4. Vietnamese Phonics Source of Truth & Child Safety', () {
    test('curriculum phonics rules are verified: C is cờ, B is bờ, Ă is á', () {
      final cSpeech = VietnameseSpeechCatalog.letters['C'];
      expect(cSpeech, isNotNull);
      expect(cSpeech!.sound, 'cờ');
      expect(cSpeech.name, 'xê');

      final bSpeech = VietnameseSpeechCatalog.letters['B'];
      expect(bSpeech, isNotNull);
      expect(bSpeech!.sound, 'bờ');
      expect(bSpeech.name, 'bê');

      final aSpeech = VietnameseSpeechCatalog.letters['Ă'];
      expect(aSpeech, isNotNull);
      expect(aSpeech!.sound, 'ă');
    });

    test('MaiSafety overrides hallucinated phonetic sounds with catalog truth', () {
      const context = MaiContext(
        currentModule: 'vietnamese',
        currentLesson: 'chu_c',
        currentActivity: 'recognize',
        currentQuestion: 'Tìm chữ C',
        learningObjective: 'Nhận biết chữ C',
      );

      // Model hallucinates foreign English pronunciation "si"
      const badResponse = MaiResponse(
        action: MaiAction.hint,
        text: 'Chữ C phát âm là si nhé bé!',
      );

      final screened = MaiSafety.screen(badResponse, context);
      expect(screened.text, contains('cờ'));
      expect(screened.text.contains('si'), isFalse);
    });

    test('MaiSafety blocks personal identification information (PII)', () {
      const context = MaiContext(
        currentModule: 'vietnamese',
        currentLesson: 'intro',
        currentActivity: 'speak',
        currentQuestion: 'Chào bé',
        learningObjective: 'Chào hỏi',
      );

      const piiResponse = MaiResponse(
        action: MaiAction.speak,
        text: 'Nhà bé ở đâu, cho Mai xin số điện thoại 0987654321 nhé!',
      );

      final screened = MaiSafety.screen(piiResponse, context);
      expect(screened.text.contains('0987654321'), isFalse);
      expect(screened.text.contains('số điện thoại'), isFalse);
      expect(screened.text, contains('Mai ở đây để cùng bé học bài thật vui!'));
    });
  });

  group('5. UI Integration & Reactive Companion Widget', () {
    testWidgets('MaiCompanionWidget renders mascot and reactive speech bubble', (tester) async {
      final controller = MaiCompanionController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MaiCompanionWidget(
                  controller: controller,
                  mascotSize: 80,
                  color: Colors.amber,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(VimaiMascot), findsOneWidget);
      expect(find.text('Mai đang nói'), findsNothing);

      // Trigger speaking state
      controller.setState(MaiState.speaking, message: 'Chào bạn nhỏ!');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Chào bạn nhỏ!'), findsOneWidget);

      // Dismiss bubble
      controller.dismissBubble();
      await tester.pump();
      expect(find.text('Chào bạn nhỏ!'), findsNothing);
    });

    testWidgets('Tapping Mai triggers hint request callback', (tester) async {
      var hintRequested = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            maiAiServiceProvider.overrideWithValue(MaiAiService(apiClient: MockGeminiApiClient(), apiKey: '')),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MaiCompanionWidget(
                  context: const MaiContext(
                    currentModule: 'math',
                    currentLesson: 'count',
                    currentActivity: 'quiz',
                    currentQuestion: 'Đếm 1 2 3',
                    learningObjective: 'Đếm',
                  ),
                  onHintRequested: () {
                    hintRequested = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Tap on the mascot
      await tester.tap(find.byType(VimaiMascot));
      await tester.pump();

      expect(hintRequested, isTrue);
    });

    test('ChildProfile getters for AI settings work correctly with defaults', () {
      final profile = ChildProfile(
        id: 'test_child',
        name: 'Bé An',
        age: 5,
        avatar: 'mint',
        createdAt: DateTime.now(),
        settings: const {},
      );

      expect(profile.aiEnabled, isTrue);
      expect(profile.aiVoiceEnabled, isTrue);

      final disabledProfile = profile.copyWith(
        settings: {'ai_enabled': false, 'ai_voice_enabled': false},
      );

      expect(disabledProfile.aiEnabled, isFalse);
      expect(disabledProfile.aiVoiceEnabled, isFalse);
    });

    test('MaiAIService class is directly accessible and functional', () {
      final service = MaiAIService(apiKey: 'test-key');
      expect(service.apiKey, 'test-key');
      expect(service.isAiEnabled, isTrue);
      expect(service.isVoiceEnabled, isTrue);
      expect(service.getHintLevel('q1'), 0);
    });

    testWidgets('MaiAssistantBubble renders AI badge and interactive bubble', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: MaiAssistantBubble(
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      // Verify AI badge text and mascot avatar
      expect(find.text('AI'), findsOneWidget);
      expect(find.text('Mai AI Companion'), findsOneWidget);
      expect(find.byKey(const Key('mai-assistant-avatar')), findsOneWidget);
      expect(find.byKey(const Key('mai-assistant-bubble')), findsOneWidget);

      // Tap on avatar to cycle message and trigger callback
      await tester.tap(find.byKey(const Key('mai-assistant-avatar')));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tapped, isTrue);
    });

    testWidgets('LessonContinuePill renders both Previous and Next navigation buttons', (tester) async {
      var prevClicked = false;
      var nextClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonContinuePill(
              label: 'Tiếp tục',
              onTap: () => nextClicked = true,
              previousLabel: 'Quay lại',
              onPrevious: () => prevClicked = true,
              canPrevious: true,
            ),
          ),
        ),
      );

      expect(find.text('Tiếp tục'), findsOneWidget);
      expect(find.text('Quay lại'), findsOneWidget);
      expect(find.byKey(const Key('continue-flow')), findsOneWidget);
      expect(find.byKey(const Key('lesson-back-flow')), findsOneWidget);

      await tester.tap(find.byKey(const Key('lesson-back-flow')));
      await tester.pump();
      expect(prevClicked, isTrue);

      await tester.tap(find.byKey(const Key('continue-flow')));
      await tester.pump();
      expect(nextClicked, isTrue);
    });
  });
}
