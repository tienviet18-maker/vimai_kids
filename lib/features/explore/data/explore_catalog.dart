import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One picture card in "Khám phá thế giới": an emoji, its spoken name
/// ("con mèo") and one short, true fact a 4-year-old understands.
class ExploreItem {
  const ExploreItem({required this.id, required this.emoji, required this.name, required this.fact});

  final String id;
  final String emoji;
  final String name;
  final String fact;

  /// What Mai asks in the quiz. Shared with the speech exporter so the
  /// question clip id always matches.
  String get question => exploreQuestion(name);

  factory ExploreItem.fromJson(Map<String, dynamic> json) => ExploreItem(
        id: json['id'] as String,
        emoji: json['emoji'] as String,
        name: json['name'] as String,
        fact: json['fact'] as String,
      );
}

/// "Đâu là con mèo?" — the quiz question for an item name.
String exploreQuestion(String name) => 'Đâu là $name?';

class ExploreCategory {
  const ExploreCategory({
    required this.id,
    required this.title,
    required this.emoji,
    required this.color,
    required this.cover,
    required this.items,
  });

  final String id;
  final String title;
  final String emoji;
  final Color color;

  /// Small emoji that orbit the big one on the category tile.
  final List<String> cover;
  final List<ExploreItem> items;

  factory ExploreCategory.fromJson(Map<String, dynamic> json) => ExploreCategory(
        id: json['id'] as String,
        title: json['title'] as String,
        emoji: json['emoji'] as String,
        color: _parseColor(json['color'] as String),
        cover: [for (final e in (json['cover'] as List? ?? const [])) e as String],
        items: [
          for (final raw in (json['items'] as List)) ExploreItem.fromJson(raw as Map<String, dynamic>),
        ],
      );

  static Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }
}

class ExploreCatalog {
  const ExploreCatalog(this.categories);

  static const assetPath = 'assets/data/explore/explore.json';

  final List<ExploreCategory> categories;

  ExploreCategory? byId(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  factory ExploreCatalog.parse(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return ExploreCatalog([
      for (final c in (data['categories'] as List)) ExploreCategory.fromJson(c as Map<String, dynamic>),
    ]);
  }
}

final exploreCatalogProvider = FutureProvider<ExploreCatalog>((ref) async {
  final raw = await rootBundle.loadString(ExploreCatalog.assetPath);
  return ExploreCatalog.parse(raw);
});
