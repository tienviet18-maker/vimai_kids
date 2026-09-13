import 'dart:convert';

import '../../features/shared/widgets/vimai_mascot.dart';
import 'mai_action.dart';

/// Structured response received from or generated for Mai AI Companion.
class MaiResponse {
  final MaiAction action;
  final String text;
  final int hintLevel;
  final MascotMood mood;
  final String? suggestedChoice;
  final bool isOfflineFallback;
  final Map<String, dynamic> metadata;

  const MaiResponse({
    required this.action,
    required this.text,
    this.hintLevel = 0,
    this.mood = MascotMood.happy,
    this.suggestedChoice,
    this.isOfflineFallback = false,
    this.metadata = const {},
  });

  /// Factory for a safe immediate offline fallback response.
  factory MaiResponse.fallback({
    required MaiAction action,
    required String text,
    int hintLevel = 0,
    MascotMood? mood,
    String? suggestedChoice,
  }) {
    return MaiResponse(
      action: action,
      text: text,
      hintLevel: hintLevel,
      mood: mood ?? _moodForAction(action),
      suggestedChoice: suggestedChoice,
      isOfflineFallback: true,
      metadata: const {'source': 'offline_fallback'},
    );
  }

  static MascotMood _moodForAction(MaiAction action) {
    switch (action) {
      case MaiAction.celebrate:
        return MascotMood.celebrating;
      case MaiAction.hint:
      case MaiAction.demonstrate:
        return MascotMood.thinking;
      case MaiAction.encourage:
        return MascotMood.encouraging;
      case MaiAction.ask:
      case MaiAction.speak:
        return MascotMood.happy;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action.toUppercaseString(),
      'text': text,
      'hintLevel': hintLevel,
      'mood': mood.name,
      if (suggestedChoice != null) 'suggestedChoice': suggestedChoice,
      'isOfflineFallback': isOfflineFallback,
      'metadata': metadata,
    };
  }
}

/// Parser that cleans, validates, and transforms Gemini output into [MaiResponse].
class MaiResponseParser {
  /// Parses raw string output from Gemini or returns a safe fallback.
  static MaiResponse parse(String raw, {int requestedHintLevel = 0}) {
    final sanitized = raw.trim();
    if (sanitized.isEmpty) {
      return MaiResponse.fallback(
        action: MaiAction.encourage,
        text: 'Bé làm tốt lắm, chúng mình cùng tiếp tục nhé!',
        hintLevel: requestedHintLevel,
      );
    }

    try {
      // 1. Try extracting JSON object if enclosed in markdown backticks or within text
      String jsonCandidate = sanitized;
      if (jsonCandidate.contains('```')) {
        final regex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', multiLine: true);
        final match = regex.firstMatch(jsonCandidate);
        if (match != null) {
          jsonCandidate = match.group(1)?.trim() ?? jsonCandidate;
        }
      }

      // If text still contains non-JSON prefix or suffix, find the first '{' and last '}'
      final start = jsonCandidate.indexOf('{');
      final end = jsonCandidate.lastIndexOf('}');
      if (start != -1 && end != -1 && end > start) {
        jsonCandidate = jsonCandidate.substring(start, end + 1);
        final dynamic decoded = jsonDecode(jsonCandidate);
        if (decoded is Map<String, dynamic>) {
          final actionStr = decoded['action']?.toString() ?? 'SPEAK';
          final action = MaiAction.fromString(actionStr);
          final text = _cleanText(decoded['text']?.toString() ?? '');
          final hintLevel = (decoded['hint_level'] ?? decoded['hintLevel'] ?? requestedHintLevel) as int? ?? requestedHintLevel;
          final suggestedChoice = decoded['suggested_choice']?.toString() ?? decoded['suggestedChoice']?.toString();

          MascotMood mood = MaiResponse._moodForAction(action);
          final moodStr = decoded['mood']?.toString().toLowerCase();
          if (moodStr != null) {
            for (final m in MascotMood.values) {
              if (m.name.toLowerCase() == moodStr) {
                mood = m;
                break;
              }
            }
          }

          if (text.isNotEmpty) {
            return MaiResponse(
              action: action,
              text: text,
              hintLevel: hintLevel.clamp(0, 4),
              mood: mood,
              suggestedChoice: suggestedChoice,
              isOfflineFallback: false,
              metadata: decoded,
            );
          }
        }
      }
    } catch (_) {
      // JSON parse failed; fall through to text heuristic
    }

    // Heuristic fallback for plain text output from model
    final clean = _cleanText(sanitized);
    return MaiResponse(
      action: requestedHintLevel > 0 ? MaiAction.hint : MaiAction.speak,
      text: clean.isNotEmpty ? clean : 'Mai luôn ở đây học cùng bé!',
      hintLevel: requestedHintLevel.clamp(0, 4),
      mood: requestedHintLevel > 0 ? MascotMood.thinking : MascotMood.happy,
      isOfflineFallback: false,
    );
  }

  /// Removes code symbols, markdown artifacts, json syntax, and stack traces.
  static String _cleanText(String input) {
    var out = input;
    // Strip code fences
    out = out.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    // Strip markdown formatting (*, _, #, `, ~, etc.)
    out = out.replaceAll(RegExp(r'[*_#`~]'), '');
    // Strip curly braces and JSON-like fragments
    out = out.replaceAll(RegExp(r'\{[^}]*\}'), '');
    // Strip common error patterns
    if (out.contains('Exception') || out.contains('Error:') || out.contains('StackTrace')) {
      return 'Bé ơi, cùng Mai khám phá câu hỏi này nhé!';
    }
    // Collapse excess whitespace
    out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
    return out;
  }
}
