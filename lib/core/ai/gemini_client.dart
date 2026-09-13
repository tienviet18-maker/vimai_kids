import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Abstraction for Gemini API requests to support testability, mock injection,
/// and offline resilience.
abstract class GeminiApiClient {
  Future<String?> generateContent({
    required String prompt,
    required String apiKey,
    Duration timeout = const Duration(seconds: 5),
  });
}

/// Standard HTTP implementation using dart:io [HttpClient].
class HttpGeminiApiClient implements GeminiApiClient {
  final HttpClient _httpClient;
  final String modelName;

  HttpGeminiApiClient({
    HttpClient? httpClient,
    this.modelName = 'gemini-1.5-flash',
  }) : _httpClient = httpClient ?? HttpClient();

  @override
  Future<String?> generateContent({
    required String prompt,
    required String apiKey,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (apiKey.trim().isEmpty) return null;

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
    );

    try {
      final request = await _httpClient.postUrl(uri).timeout(timeout);
      request.headers.set('content-type', 'application/json; charset=utf-8');

      final body = jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ],
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 180,
          'responseMimeType': 'application/json',
        },
      });

      request.write(body);
      final response = await request.close().timeout(timeout);

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final dynamic json = jsonDecode(responseBody);
        if (json is Map<String, dynamic>) {
          final candidates = json['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final first = candidates.first as Map<String, dynamic>;
            final content = first['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = (parts.first as Map<String, dynamic>)['text']?.toString();
              return text;
            }
          }
        }
      }
      return null;
    } catch (_) {
      // Network failure, socket exception, safety block, or timeout.
      // Gracefully return null to trigger instant offline fallback.
      return null;
    }
  }
}
