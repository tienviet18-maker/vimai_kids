import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/core/audio/audio_service.dart';
import 'package:mai_an_learning/core/audio/kid_guide.dart';
import 'package:mai_an_learning/core/audio/speech_id.dart';

bool _bundled(String id) => File('assets/audio/$id.mp3').existsSync();

void main() {
  test('every guide line Mai says has a bundled clip', () {
    final missing = [
      for (final line in KidGuide.all)
        if (!_bundled(SpeechId.idForLine(line)!)) line,
    ];
    expect(missing, isEmpty, reason: 'Run tools/generate_missing_audio.py (or the Generate missing voice clips workflow).');
  });

  test('every exported on-screen line has a bundled clip', () {
    final groups = jsonDecode(File('tool/speech/speech_lines.json').readAsStringSync()) as Map<String, dynamic>;
    final missing = [
      for (final lines in groups.values)
        for (final line in (lines as List).cast<Map<String, dynamic>>())
          if (!_bundled(line['id'] as String)) line['text'],
    ];
    expect(missing, isEmpty);
  });

  test('math expressions are read with number and sign clips', () {
    expect(AudioService.mathClips('3 + 4 = ?'), ['math_num_3', 'math_op_plus', 'math_num_4', 'math_op_equal']);
    expect(AudioService.mathClips('12 − 5'), ['math_num_12', 'math_op_minus', 'math_num_5']);
    expect(AudioService.mathClips('Bé có 3 quả'), isNull);
    expect(AudioService.mathClips('150 + 1'), isNull);
    for (var n = 0; n <= 100; n++) {
      expect(_bundled('math_num_$n'), isTrue, reason: 'math_num_$n');
    }
  });
}
