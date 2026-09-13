import 'dart:convert';

import 'gemini_client.dart';
import 'mai_action.dart';
import 'mai_context.dart';
import 'mai_offline_fallback.dart';
import 'mai_response.dart';
import 'mai_safety.dart';

/// Central orchestration service for the Mai AI Learning Companion.
///
/// Follows Clean Architecture principles:
/// - Context-aware pedagogical orchestration
/// - Progressive Hint Model (Level 0 to 4)
/// - Safe communication with Gemini API (timeout, API key protection, safety blocks)
/// - Instant offline-first fallback guarantees (no raw errors or stack traces)
class MaiAIService {
  final GeminiApiClient _apiClient;
  final MaiOfflineFallback _fallback;
  String _apiKey;
  bool isAiEnabled;
  bool isVoiceEnabled;

  /// Tracks Progressive Hint levels per active question/item key.
  final Map<String, int> _hintLevels = {};

  MaiAIService({
    GeminiApiClient? apiClient,
    MaiOfflineFallback? fallback,
    String? apiKey,
    this.isAiEnabled = true,
    this.isVoiceEnabled = true,
  })  : _apiClient = apiClient ?? HttpGeminiApiClient(),
        _fallback = fallback ?? const MaiOfflineFallback(),
        _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  String get apiKey => _apiKey;
  set apiKey(String value) => _apiKey = value.trim();

  /// Gets current hint level (0 to 4) for a question key.
  int getHintLevel(String questionKey) => _hintLevels[questionKey] ?? 0;

  /// Resets progressive hint level when question is solved or changed.
  void resetHintLevel(String questionKey) {
    _hintLevels.remove(questionKey);
  }

  /// Advances hint level up to maximum Level 4 (Demonstration).
  int advanceHintLevel(String questionKey) {
    final current = getHintLevel(questionKey);
    final next = (current + 1).clamp(0, 4);
    _hintLevels[questionKey] = next;
    return next;
  }

  /// Requests a pedagogical hint using the Progressive Hint Model (Level 0..4).
  Future<MaiResponse> requestHint(MaiContext context) async {
    final questionKey = _contextKey(context);
    final level = advanceHintLevel(questionKey);
    final activeContext = context.copyWith(hintLevel: level);

    if (!isAiEnabled || _apiKey.isEmpty) {
      return _fallback.generate(activeContext, requestedAction: MaiAction.hint);
    }

    try {
      final prompt = _buildHintPrompt(activeContext);
      final rawResponse = await _apiClient.generateContent(
        prompt: prompt,
        apiKey: _apiKey,
        timeout: const Duration(seconds: 4),
      );

      if (rawResponse == null || rawResponse.trim().isEmpty) {
        return _fallback.generate(activeContext, requestedAction: MaiAction.hint);
      }

      final parsed = MaiResponseParser.parse(rawResponse, requestedHintLevel: level);
      return MaiSafety.screen(parsed, activeContext);
    } catch (_) {
      // Graceful offline fallback on any network or parsing error
      return _fallback.generate(activeContext, requestedAction: MaiAction.hint);
    }
  }

  /// Called upon correct answer to celebrate and reset hint progression.
  Future<MaiResponse> onCorrectAnswer(MaiContext context) async {
    resetHintLevel(_contextKey(context));
    final activeContext = context.copyWith(hintLevel: 0);

    if (!isAiEnabled || _apiKey.isEmpty) {
      return _fallback.generate(activeContext, requestedAction: MaiAction.celebrate);
    }

    try {
      final prompt = _buildPraisePrompt(activeContext);
      final rawResponse = await _apiClient.generateContent(
        prompt: prompt,
        apiKey: _apiKey,
        timeout: const Duration(seconds: 3),
      );

      if (rawResponse == null) {
        return _fallback.generate(activeContext, requestedAction: MaiAction.celebrate);
      }

      final parsed = MaiResponseParser.parse(rawResponse, requestedHintLevel: 0);
      return MaiSafety.screen(parsed, activeContext);
    } catch (_) {
      return _fallback.generate(activeContext, requestedAction: MaiAction.celebrate);
    }
  }

  /// Called upon incorrect answer to encourage child and advance hint.
  Future<MaiResponse> onIncorrectAnswer(MaiContext context) async {
    final questionKey = _contextKey(context);
    final level = advanceHintLevel(questionKey);
    final activeContext = context.copyWith(
      attemptNumber: context.attemptNumber + 1,
      hintLevel: level,
    );

    if (!isAiEnabled || _apiKey.isEmpty) {
      return _fallback.generate(activeContext, requestedAction: MaiAction.encourage);
    }

    try {
      final prompt = _buildEncouragementPrompt(activeContext);
      final rawResponse = await _apiClient.generateContent(
        prompt: prompt,
        apiKey: _apiKey,
        timeout: const Duration(seconds: 3),
      );

      if (rawResponse == null) {
        return _fallback.generate(activeContext, requestedAction: MaiAction.encourage);
      }

      final parsed = MaiResponseParser.parse(rawResponse, requestedHintLevel: level);
      return MaiSafety.screen(parsed, activeContext);
    } catch (_) {
      return _fallback.generate(activeContext, requestedAction: MaiAction.encourage);
    }
  }

  /// Contextual greeting when entering an activity or screen.
  Future<MaiResponse> getContextualGreeting(MaiContext context) async {
    return _fallback.generate(context, requestedAction: MaiAction.speak);
  }

  String _contextKey(MaiContext context) {
    return '${context.currentModule}_${context.currentLesson}_${context.currentQuestion}';
  }

  String _buildHintPrompt(MaiContext context) {
    final payloadJson = jsonEncode(context.toMinimalistPayload());
    return '''
You are Mai, a warm, gentle, and encouraging AI learning companion for Vietnamese children aged ${context.childAge}.
Act as a supportive teacher, NOT an answer machine.
Rules:
1. Speak in warm, simple Vietnamese (max 2 short sentences, under 120 characters).
2. Follow Progressive Hint Level ${context.hintLevel} (0: Nudge, 1: Concept Question, 2: Elimination Strategy, 3: Step-by-step guidance, 4: Model demonstration).
3. Vietnamese phonics MUST match standard curriculum: C is "cờ" (or name "xê"), B is "bờ", Ă is "á". NEVER use English phonics or foreign pronunciations.
4. Output MUST be valid JSON only with keys:
{"action": "HINT", "text": "...", "hint_level": ${context.hintLevel}, "mood": "thinking"}

Educational Context:
$payloadJson
''';
  }

  String _buildPraisePrompt(MaiContext context) {
    return '''
You are Mai, a warm AI companion for Vietnamese children.
The child has just answered correctly! Give a short, cheerful congratulation (max 1 sentence, in Vietnamese).
Output JSON only:
{"action": "CELEBRATE", "text": "...", "mood": "celebrating"}
Context: ${jsonEncode(context.toMinimalistPayload())}
''';
  }

  String _buildEncouragementPrompt(MaiContext context) {
    return '''
You are Mai, a gentle AI companion for Vietnamese children.
The child got an answer wrong. Provide a kind, uplifting encouragement without shaming (max 1-2 short sentences, in Vietnamese).
Output JSON only:
{"action": "ENCOURAGE", "text": "...", "hint_level": ${context.hintLevel}, "mood": "encouraging"}
Context: ${jsonEncode(context.toMinimalistPayload())}
''';
  }
}

/// Backward compatibility typedef for standard naming convention.
typedef MaiAiService = MaiAIService;
