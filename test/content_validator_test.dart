import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vietnamese Content Tests', () {
    test('Alphabet is complete (29 letters)', () {
      final file = File('assets/content/vietnamese/alphabet.json');
      expect(file.existsSync(), true);
      
      final jsonString = file.readAsStringSync();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      expect(jsonList.length, 29);
      
      final ids = <String>{};
      for (var item in jsonList) {
        expect(item['metadata']['letterName'], isNotEmpty);
        expect(item['metadata']['phoneme'], isNotEmpty);
        expect(ids.contains(item['id']), false, reason: 'Duplicate ID: ${item['id']}');
        ids.add(item['id']);
      }
    });

    test('Vocabulary has valid structure', () {
      final file = File('assets/content/vietnamese/vocabulary.json');
      expect(file.existsSync(), true);
      
      final jsonString = file.readAsStringSync();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      expect(jsonList.isNotEmpty, true);
      
      for (var item in jsonList) {
        expect(item['id'], isNotNull);
        expect(item['question'], isNotNull);
        expect(item['tags'], isNotEmpty);
      }
    });
  });

  group('Math Content Tests', () {
    test('Math questions have valid structure', () {
      final file = File('assets/content/math/questions.json');
      expect(file.existsSync(), true);
      
      final jsonString = file.readAsStringSync();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      expect(jsonList.isNotEmpty, true);
      
      for (var item in jsonList) {
        expect(item['id'], isNotNull);
        expect(item['skill'], isNotNull);
        expect(item['question'], isNotNull);
        expect(item['answer'], isNotNull);
        expect(item['choices'], isNotEmpty);
        expect(item['choices'].contains(item['answer']), true, reason: 'Answer must be in choices: ${item['id']}');
      }
    });
  });
}
