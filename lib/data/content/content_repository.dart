import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/content/content_item.dart';

class ContentRepository {
  List<ContentItem> _vietnameseAlphabet = [];
  List<ContentItem> _vietnameseVocabulary = [];
  List<ContentItem> _vietnamesePhonics = [];
  List<ContentItem> _vietnameseWords = [];
  List<ContentItem> _vietnameseRimes = [];
  List<ContentItem> _mathQuestions = [];
  List<ContentItem> _thinkingPatterns = [];

  List<ContentItem> _vietnameseSentences = [];

  Future<void> loadAllContent() async {
    _vietnameseAlphabet = await _loadJson('assets/data/vietnamese/alphabet.json', fallbackPath: 'assets/content/vietnamese/alphabet.json');
    _vietnameseVocabulary = await _loadJson('assets/data/vietnamese/vocabulary.json', fallbackPath: 'assets/content/vietnamese/vocabulary.json');
    _vietnamesePhonics = await _loadJson('assets/data/vietnamese/phonics.json', fallbackPath: 'assets/content/vietnamese/phonics.json');
    _vietnameseWords = await _loadJson('assets/data/vietnamese/words.json', fallbackPath: 'assets/content/vietnamese/words.json');
    _vietnameseRimes = await _loadJson('assets/data/vietnamese/rimes.json', fallbackPath: 'assets/content/vietnamese/rimes.json');
    _vietnameseSentences = await _loadJson('assets/data/vietnamese/sentences.json', fallbackPath: 'assets/content/vietnamese/sentences.json');
    _mathQuestions = await _loadJson('assets/data/math/questions.json', fallbackPath: 'assets/content/math/questions.json');
    _thinkingPatterns = await _loadJson('assets/data/thinking/patterns.json', fallbackPath: 'assets/content/thinking/patterns.json');
  }

  Future<List<ContentItem>> _loadJson(String path, {String? fallbackPath}) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => ContentItem.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      if (fallbackPath != null) {
        try {
          final jsonString = await rootBundle.loadString(fallbackPath);
          final jsonList = jsonDecode(jsonString) as List<dynamic>;
          return jsonList.map((json) => ContentItem.fromJson(json as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
      return [];
    }
  }

  List<ContentItem> getVietnameseAlphabet() => _vietnameseAlphabet;
  ContentItem? getVietnameseLetter(String id) {
    try {
      return _vietnameseAlphabet.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ContentItem> getVietnameseVocabulary() => _vietnameseVocabulary;
  List<ContentItem> getVietnamesePhonics() => _vietnamesePhonics;
  List<ContentItem> getVietnameseWords() => _vietnameseWords;
  List<ContentItem> getVietnameseRimes() => _vietnameseRimes;
  List<ContentItem> getVietnameseSentences() => _vietnameseSentences;
  List<ContentItem> getMathQuestions() => _mathQuestions;
  List<ContentItem> getThinkingPatterns() => _thinkingPatterns;
}
