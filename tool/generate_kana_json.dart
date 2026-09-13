import 'dart:convert';
import 'dart:io';
import 'package:mai_an_learning/data/kana/hiragana_data.dart';
import 'package:mai_an_learning/data/kana/kana_examples.dart';
import 'package:mai_an_learning/data/kana/katakana_data.dart';
import 'package:mai_an_learning/domain/models/kana_item.dart';

void main() {
  final outDir = Directory('assets/content/japanese/kana');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  void writeJson(String filename, List<KanaItem> items) {
    final file = File('${outDir.path}/$filename');
    final jsonList = items.map((e) {
      final json = e.toJson();
      final word = KanaExamples.wordFor(e.character);
      final meaning = KanaExamples.meaningFor(e.character);
      if (word.isNotEmpty) json['exampleWord'] = word;
      if (meaning.isNotEmpty) json['exampleMeaningVietnamese'] = meaning;
      return json;
    }).toList();
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(jsonList));
    print('Wrote $filename (${items.length} items)');
  }

  writeJson('hiragana_basic.json', hiraganaData.where((e) => e.kanaType == KanaType.basic).toList());
  writeJson('hiragana_dakuten.json', hiraganaData.where((e) => e.kanaType == KanaType.dakuten).toList());
  writeJson('hiragana_handakuten.json', hiraganaData.where((e) => e.kanaType == KanaType.handakuten).toList());
  writeJson('hiragana_yoon.json', hiraganaData.where((e) => e.kanaType == KanaType.yoon).toList());
  writeJson('hiragana_small.json', hiraganaData.where((e) => e.kanaType == KanaType.small).toList());
  writeJson('hiragana_sokuon.json', hiraganaData.where((e) => e.kanaType == KanaType.sokuon).toList());
  writeJson('hiragana_choon.json', hiraganaData.where((e) => e.kanaType == KanaType.choon).toList());

  writeJson('katakana_basic.json', katakanaData.where((e) => e.kanaType == KanaType.basic).toList());
  writeJson('katakana_dakuten.json', katakanaData.where((e) => e.kanaType == KanaType.dakuten).toList());
  writeJson('katakana_handakuten.json', katakanaData.where((e) => e.kanaType == KanaType.handakuten).toList());
  writeJson('katakana_yoon.json', katakanaData.where((e) => e.kanaType == KanaType.yoon).toList());
  writeJson('katakana_small.json', katakanaData.where((e) => e.kanaType == KanaType.small).toList());
  writeJson('katakana_sokuon.json', katakanaData.where((e) => e.kanaType == KanaType.sokuon).toList());
  writeJson('katakana_choon.json', katakanaData.where((e) => e.kanaType == KanaType.choon).toList());
  writeJson('katakana_extended.json', katakanaData.where((e) => e.kanaType == KanaType.extended).toList());
}
