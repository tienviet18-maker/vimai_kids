import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mai_an_learning/features/japanese/handwriting/stroke_order_catalog.dart';
import 'package:mai_an_learning/features/japanese/handwriting/svg_path_parser.dart';

void main() {
  test('KanjiVG catalog covers 46 hiragana and 46 katakana with real paths', () {
    final data = jsonDecode(File('assets/content/japanese/strokes/catalog.json').readAsStringSync()) as Map<String, dynamic>;
    expect(data['license'], 'CC BY-SA 3.0');
    expect(data['source'], 'KanjiVG');
    final chars = data['characters'] as Map<String, dynamic>;
    final h = chars.keys.where((k) => k.startsWith('h_')).length;
    final k = chars.keys.where((k) => k.startsWith('k_')).length;
    expect(h, 46);
    expect(k, 46);
    StrokeOrderCatalog.loadJson(jsonEncode(data));
    expect(StrokeOrderCatalog().pathsFor('h_a').length, 3);
    final path = SvgPathParser.parse(StrokeOrderCatalog().pathsFor('h_a').first);
    expect(path.computeMetrics().length, greaterThan(0));
  });

  test('every basic kana path count matches strokeCount and can animate', () {
    final data = jsonDecode(File('assets/content/japanese/strokes/catalog.json').readAsStringSync()) as Map<String, dynamic>;
    final chars = data['characters'] as Map<String, dynamic>;
    StrokeOrderCatalog.loadJson(jsonEncode(data));
    final catalog = StrokeOrderCatalog();
    var hOk = 0;
    var kOk = 0;
    for (final entry in chars.entries) {
      final item = entry.value as Map<String, dynamic>;
      final paths = (item['paths'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      final declared = (item['strokeCount'] as num).toInt();
      expect(paths.length, declared, reason: '${entry.key} strokeCount=$declared pathCount=${paths.length}');
      expect(catalog.pathsFor(entry.key).length, declared);
      expect(catalog.strokeIdsFor(entry.key), [
        for (var i = 0; i < paths.length; i++) '${entry.key}_s${i + 1}',
      ]);
      for (final d in paths) {
        final parsed = SvgPathParser.parse(d);
        final metrics = parsed.computeMetrics().toList();
        expect(metrics, isNotEmpty, reason: '${entry.key} path not parseable');
        expect(PathMetricsHelper.extract(parsed, 0.5).computeMetrics().length, greaterThan(0));
        expect(PathMetricsHelper.start(parsed), isNotNull);
      }
      if (entry.key.startsWith('h_')) hOk++;
      if (entry.key.startsWith('k_')) kOk++;
    }
    expect(hOk, 46);
    expect(kOk, 46);
    expect(catalog.hasPaths('h_ga'), isFalse);
    expect(catalog.hasPaths('k_ga'), isFalse);
  });

  test('every basic kana SVG asset exists and has license metadata', () {
    final data = jsonDecode(File('assets/content/japanese/strokes/catalog.json').readAsStringSync()) as Map<String, dynamic>;
    expect(data['license'], 'CC BY-SA 3.0');
    expect(data['source'], 'KanjiVG');
    expect(data['attribution'], contains('Ulrich Apel'));
    expect(File('assets/licenses/KANJIVG_LICENSE.md').existsSync(), isTrue);
    final chars = data['characters'] as Map<String, dynamic>;
    for (final entry in chars.entries) {
      final item = entry.value as Map<String, dynamic>;
      final svg = item['svg'] as String;
      expect(File(svg).existsSync(), isTrue, reason: '${entry.key} missing $svg');
      final paths = (item['paths'] as List).map((e) => e.toString()).toList();
      expect(paths, isNotEmpty, reason: entry.key);
      expect(paths.every((e) => e.isNotEmpty), isTrue, reason: '${entry.key} empty path');
      expect(paths.every((e) => e.contains('M') || e.contains('m')), isTrue, reason: '${entry.key} malformed path');
    }
  });

  test('human audio inventory does not claim human recordings', () {
    final inv = jsonDecode(File('tool/human_audio_inventory.json').readAsStringSync()) as Map<String, dynamic>;
    expect(inv['human_recordings_present'], 0);
    expect(inv['counts']['EXISTING_HUMAN'], 0);
    expect(inv['counts']['HUMAN_REQUIRED'], 150);
    final rec = jsonDecode(File('tool/human_audio_recording_manifest.json').readAsStringSync()) as Map<String, dynamic>;
    expect(rec['items'], hasLength(150));
    expect((rec['items'] as List).every((e) => e['recording_status'] == 'NOT_RECORDED'), isTrue);
  });

  test('KANJIVG license file is bundled', () {
    expect(File('assets/licenses/KANJIVG_LICENSE.md').existsSync(), isTrue);
  });
}
