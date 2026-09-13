import 'dart:math';
import 'dart:ui';

import '../../domain/content/content_item.dart';

class ColorRegion {
  final String id;
  final List<Offset> points;
  const ColorRegion(this.id, this.points);
}

class ColoringPicture {
  final String id;
  final String title;
  final String category;
  final int ageMin;
  final int ageMax;
  final List<ColorRegion> regions;

  const ColoringPicture({
    required this.id,
    required this.title,
    required this.category,
    required this.ageMin,
    required this.ageMax,
    required this.regions,
  });
}

class DotPuzzle {
  final String id;
  final String title;
  final int ageMin;
  final int ageMax;
  final List<Offset> points;

  const DotPuzzle({
    required this.id,
    required this.title,
    required this.ageMin,
    required this.ageMax,
    required this.points,
  });
}

class MatchPuzzle {
  final String id;
  final String title;
  final String instruction;
  final int ageMin;
  final int ageMax;
  final List<String> left;
  final List<String> right;

  const MatchPuzzle({
    required this.id,
    required this.title,
    required this.instruction,
    required this.ageMin,
    required this.ageMax,
    required this.left,
    required this.right,
  });
}

class DrawingChallenge {
  final String id;
  final String title;
  final String prompt;
  final int ageMin;
  final int ageMax;

  const DrawingChallenge({
    required this.id,
    required this.title,
    required this.prompt,
    required this.ageMin,
    required this.ageMax,
  });
}

class PatternPuzzle {
  final String id;
  final String title;
  final int ageMin;
  final int ageMax;
  final List<String> sequence;
  final String answer;

  const PatternPuzzle({
    required this.id,
    required this.title,
    required this.ageMin,
    required this.ageMax,
    required this.sequence,
    required this.answer,
  });
}

List<Offset> _ring(double cx, double cy, double rx, double ry, [int n = 18]) {
  return List.generate(n, (i) {
    final a = i / n * pi * 2;
    return Offset(cx + cos(a) * rx, cy + sin(a) * ry);
  });
}

List<Offset> _rect(double l, double t, double r, double b) => [
      Offset(l, t),
      Offset(r, t),
      Offset(r, b),
      Offset(l, b),
    ];

class CreativityCatalog {
  static List<ColoringPicture> coloringPages() => [
        ColoringPicture(id: 'color_apple', title: 'Quả táo', category: 'fruit', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('body', _ring(0.5, 0.55, 0.28, 0.32)),
          ColorRegion('leaf', _ring(0.62, 0.22, 0.12, 0.08)),
          ColorRegion('stem', _rect(0.47, 0.18, 0.53, 0.32)),
        ]),
        ColoringPicture(id: 'color_cat', title: 'Con mèo', category: 'animal', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('head', _ring(0.5, 0.48, 0.26, 0.26)),
          const ColorRegion('earL', [Offset(0.28, 0.42), Offset(0.34, 0.18), Offset(0.46, 0.34)]),
          const ColorRegion('earR', [Offset(0.54, 0.34), Offset(0.66, 0.18), Offset(0.72, 0.42)]),
          ColorRegion('body', _ring(0.5, 0.78, 0.3, 0.16)),
        ]),
        ColoringPicture(id: 'color_dog', title: 'Con chó', category: 'animal', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('head', _ring(0.5, 0.42, 0.24, 0.24)),
          ColorRegion('earL', _ring(0.28, 0.38, 0.1, 0.16)),
          ColorRegion('earR', _ring(0.72, 0.38, 0.1, 0.16)),
          ColorRegion('body', _ring(0.5, 0.76, 0.32, 0.16)),
        ]),
        ColoringPicture(id: 'color_fish', title: 'Con cá', category: 'animal', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('body', _ring(0.46, 0.5, 0.3, 0.2)),
          const ColorRegion('tail', [Offset(0.74, 0.5), Offset(0.92, 0.32), Offset(0.92, 0.68)]),
          const ColorRegion('fin', [Offset(0.46, 0.32), Offset(0.58, 0.22), Offset(0.52, 0.4)]),
        ]),
        ColoringPicture(id: 'color_butterfly', title: 'Con bướm', category: 'animal', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('wingL', _ring(0.32, 0.48, 0.22, 0.28)),
          ColorRegion('wingR', _ring(0.68, 0.48, 0.22, 0.28)),
          ColorRegion('body', _rect(0.47, 0.28, 0.53, 0.78)),
        ]),
        ColoringPicture(id: 'color_flower', title: 'Bông hoa', category: 'nature', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('petal1', _ring(0.5, 0.28, 0.14, 0.14)),
          ColorRegion('petal2', _ring(0.28, 0.48, 0.14, 0.14)),
          ColorRegion('petal3', _ring(0.72, 0.48, 0.14, 0.14)),
          ColorRegion('petal4', _ring(0.5, 0.68, 0.14, 0.14)),
          ColorRegion('center', _ring(0.5, 0.48, 0.1, 0.1)),
        ]),
        ColoringPicture(id: 'color_sun', title: 'Mặt trời', category: 'nature', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('core', _ring(0.5, 0.5, 0.22, 0.22)),
          ColorRegion('ray1', _rect(0.46, 0.08, 0.54, 0.24)),
          ColorRegion('ray2', _rect(0.46, 0.76, 0.54, 0.92)),
          ColorRegion('ray3', _rect(0.08, 0.46, 0.24, 0.54)),
          ColorRegion('ray4', _rect(0.76, 0.46, 0.92, 0.54)),
        ]),
        ColoringPicture(id: 'color_house', title: 'Ngôi nhà', category: 'object', ageMin: 3, ageMax: 7, regions: [
          const ColorRegion('roof', [Offset(0.18, 0.42), Offset(0.5, 0.12), Offset(0.82, 0.42)]),
          ColorRegion('wall', _rect(0.22, 0.42, 0.78, 0.88)),
          ColorRegion('door', _rect(0.42, 0.58, 0.58, 0.88)),
          ColorRegion('window', _rect(0.26, 0.5, 0.38, 0.64)),
        ]),
        ColoringPicture(id: 'color_tree', title: 'Cây', category: 'nature', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('leaves', _ring(0.5, 0.38, 0.28, 0.26)),
          ColorRegion('trunk', _rect(0.44, 0.52, 0.56, 0.9)),
        ]),
        ColoringPicture(id: 'color_car', title: 'Ô tô', category: 'vehicle', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('body', _rect(0.12, 0.42, 0.88, 0.68)),
          ColorRegion('cabin', _rect(0.28, 0.26, 0.68, 0.42)),
          ColorRegion('wheelL', _ring(0.28, 0.74, 0.1, 0.1)),
          ColorRegion('wheelR', _ring(0.72, 0.74, 0.1, 0.1)),
        ]),
        ColoringPicture(id: 'color_bus', title: 'Xe buýt', category: 'vehicle', ageMin: 4, ageMax: 7, regions: [
          ColorRegion('body', _rect(0.1, 0.32, 0.9, 0.68)),
          ColorRegion('window', _rect(0.18, 0.38, 0.78, 0.52)),
          ColorRegion('wheelL', _ring(0.28, 0.76, 0.1, 0.1)),
          ColorRegion('wheelR', _ring(0.72, 0.76, 0.1, 0.1)),
        ]),
        ColoringPicture(id: 'color_elephant', title: 'Con voi', category: 'animal', ageMin: 4, ageMax: 7, regions: [
          ColorRegion('body', _ring(0.5, 0.55, 0.28, 0.22)),
          ColorRegion('head', _ring(0.26, 0.46, 0.16, 0.16)),
          ColorRegion('ear', _ring(0.22, 0.34, 0.12, 0.16)),
          ColorRegion('trunk', _rect(0.1, 0.5, 0.22, 0.82)),
        ]),
        ColoringPicture(id: 'color_rabbit', title: 'Con thỏ', category: 'animal', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('head', _ring(0.5, 0.52, 0.22, 0.22)),
          ColorRegion('earL', _ring(0.38, 0.22, 0.08, 0.2)),
          ColorRegion('earR', _ring(0.62, 0.22, 0.08, 0.2)),
          ColorRegion('body', _ring(0.5, 0.8, 0.24, 0.14)),
        ]),
        ColoringPicture(id: 'color_ball', title: 'Quả bóng', category: 'object', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('left', _ring(0.38, 0.5, 0.22, 0.28)),
          ColorRegion('right', _ring(0.62, 0.5, 0.22, 0.28)),
          ColorRegion('band', _rect(0.46, 0.22, 0.54, 0.78)),
        ]),
        ColoringPicture(id: 'color_rainbow', title: 'Cầu vồng', category: 'nature', ageMin: 4, ageMax: 7, regions: [
          ColorRegion('arc1', _ring(0.5, 0.72, 0.4, 0.32, 12).take(8).toList()),
          ColorRegion('arc2', _ring(0.5, 0.72, 0.32, 0.24, 12).take(8).toList()),
          ColorRegion('arc3', _ring(0.5, 0.72, 0.24, 0.16, 12).take(8).toList()),
        ]),
        ColoringPicture(id: 'color_boat', title: 'Thuyền', category: 'vehicle', ageMin: 3, ageMax: 7, regions: [
          const ColorRegion('hull', [Offset(0.16, 0.58), Offset(0.84, 0.58), Offset(0.74, 0.78), Offset(0.26, 0.78)]),
          ColorRegion('sail', _rect(0.46, 0.18, 0.7, 0.56)),
          ColorRegion('mast', _rect(0.42, 0.16, 0.47, 0.58)),
        ]),
        const ColoringPicture(id: 'color_star', title: 'Ngôi sao', category: 'nature', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('star', [
            Offset(0.5, 0.1), Offset(0.6, 0.38), Offset(0.9, 0.38), Offset(0.66, 0.56), Offset(0.76, 0.86),
            Offset(0.5, 0.68), Offset(0.24, 0.86), Offset(0.34, 0.56), Offset(0.1, 0.38), Offset(0.4, 0.38),
          ]),
        ]),
        ColoringPicture(id: 'color_moon', title: 'Mặt trăng', category: 'nature', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('disc', _ring(0.52, 0.5, 0.28, 0.28)),
          ColorRegion('crater1', _ring(0.42, 0.4, 0.06, 0.06)),
          ColorRegion('crater2', _ring(0.62, 0.58, 0.08, 0.07)),
        ]),
        ColoringPicture(id: 'color_bird', title: 'Con chim', category: 'animal', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('body', _ring(0.48, 0.52, 0.22, 0.18)),
          ColorRegion('head', _ring(0.7, 0.38, 0.12, 0.12)),
          const ColorRegion('beak', [Offset(0.8, 0.36), Offset(0.94, 0.4), Offset(0.8, 0.46)]),
          const ColorRegion('wing', [Offset(0.38, 0.48), Offset(0.2, 0.32), Offset(0.52, 0.58)]),
        ]),
        ColoringPicture(id: 'color_icecream', title: 'Kem ốc quế', category: 'food', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('scoop1', _ring(0.5, 0.28, 0.16, 0.14)),
          ColorRegion('scoop2', _ring(0.5, 0.44, 0.18, 0.12)),
          const ColorRegion('cone', [Offset(0.34, 0.52), Offset(0.66, 0.52), Offset(0.5, 0.9)]),
        ]),
        ColoringPicture(id: 'color_cupcake', title: 'Bánh cupcake', category: 'food', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('frosting', _ring(0.5, 0.36, 0.22, 0.16)),
          ColorRegion('cherry', _ring(0.5, 0.18, 0.07, 0.07)),
          const ColorRegion('wrapper', [Offset(0.3, 0.44), Offset(0.7, 0.44), Offset(0.64, 0.86), Offset(0.36, 0.86)]),
        ]),
        ColoringPicture(id: 'color_balloon', title: 'Bóng bay', category: 'object', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('body', _ring(0.5, 0.38, 0.22, 0.28)),
          const ColorRegion('knot', [Offset(0.46, 0.64), Offset(0.54, 0.64), Offset(0.5, 0.72)]),
          ColorRegion('string', _rect(0.48, 0.7, 0.52, 0.92)),
        ]),
        ColoringPicture(id: 'color_mushroom', title: 'Nấm', category: 'nature', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('cap', _ring(0.5, 0.38, 0.3, 0.2)),
          ColorRegion('spot1', _ring(0.4, 0.32, 0.05, 0.05)),
          ColorRegion('spot2', _ring(0.6, 0.36, 0.06, 0.05)),
          ColorRegion('stem', _rect(0.42, 0.5, 0.58, 0.88)),
        ]),
        ColoringPicture(id: 'color_turtle', title: 'Con rùa', category: 'animal', ageMin: 4, ageMax: 7, regions: [
          ColorRegion('shell', _ring(0.5, 0.5, 0.28, 0.22)),
          ColorRegion('head', _ring(0.78, 0.48, 0.1, 0.1)),
          ColorRegion('legFL', _ring(0.28, 0.68, 0.08, 0.08)),
          ColorRegion('legBR', _ring(0.68, 0.7, 0.08, 0.08)),
        ]),
        ColoringPicture(id: 'color_penguin', title: 'Chim cánh cụt', category: 'animal', ageMin: 4, ageMax: 7, regions: [
          ColorRegion('body', _ring(0.5, 0.52, 0.2, 0.32)),
          ColorRegion('belly', _ring(0.5, 0.56, 0.12, 0.22)),
          const ColorRegion('beak', [Offset(0.5, 0.22), Offset(0.62, 0.28), Offset(0.5, 0.32)]),
          ColorRegion('footL', _rect(0.34, 0.8, 0.46, 0.9)),
          ColorRegion('footR', _rect(0.54, 0.8, 0.66, 0.9)),
        ]),
        ColoringPicture(id: 'color_strawberry', title: 'Quả dâu', category: 'fruit', ageMin: 3, ageMax: 7, regions: [
          const ColorRegion('body', [Offset(0.5, 0.22), Offset(0.78, 0.42), Offset(0.5, 0.88), Offset(0.22, 0.42)]),
          ColorRegion('leaf1', _rect(0.34, 0.12, 0.48, 0.26)),
          ColorRegion('leaf2', _rect(0.52, 0.12, 0.66, 0.26)),
        ]),
        ColoringPicture(id: 'color_watermelon', title: 'Dưa hấu', category: 'fruit', ageMin: 3, ageMax: 7, regions: [
          const ColorRegion('rind', [Offset(0.12, 0.7), Offset(0.5, 0.18), Offset(0.88, 0.7)]),
          const ColorRegion('flesh', [Offset(0.22, 0.68), Offset(0.5, 0.3), Offset(0.78, 0.68)]),
          ColorRegion('seed1', _ring(0.42, 0.52, 0.03, 0.04)),
          ColorRegion('seed2', _ring(0.58, 0.5, 0.03, 0.04)),
        ]),
        ColoringPicture(id: 'color_plane', title: 'Máy bay', category: 'vehicle', ageMin: 4, ageMax: 7, regions: [
          ColorRegion('fuselage', _rect(0.18, 0.44, 0.82, 0.58)),
          const ColorRegion('wing', [Offset(0.22, 0.5), Offset(0.5, 0.22), Offset(0.78, 0.5)]),
          const ColorRegion('tail', [Offset(0.78, 0.32), Offset(0.88, 0.32), Offset(0.82, 0.5)]),
          ColorRegion('window', _ring(0.36, 0.5, 0.05, 0.05)),
        ]),
        ColoringPicture(id: 'color_train', title: 'Tàu hỏa', category: 'vehicle', ageMin: 4, ageMax: 7, regions: [
          ColorRegion('engine', _rect(0.08, 0.36, 0.42, 0.68)),
          ColorRegion('cabin', _rect(0.42, 0.44, 0.88, 0.68)),
          ColorRegion('chimney', _rect(0.16, 0.18, 0.26, 0.36)),
          ColorRegion('wheel1', _ring(0.22, 0.76, 0.08, 0.08)),
          ColorRegion('wheel2', _ring(0.54, 0.76, 0.08, 0.08)),
          ColorRegion('wheel3', _ring(0.76, 0.76, 0.08, 0.08)),
        ]),
        ColoringPicture(id: 'color_castle', title: 'Lâu đài', category: 'object', ageMin: 5, ageMax: 7, regions: [
          ColorRegion('wall', _rect(0.18, 0.42, 0.82, 0.88)),
          ColorRegion('towerL', _rect(0.1, 0.22, 0.28, 0.88)),
          ColorRegion('towerR', _rect(0.72, 0.22, 0.9, 0.88)),
          const ColorRegion('flag', [Offset(0.18, 0.1), Offset(0.34, 0.16), Offset(0.18, 0.22)]),
          ColorRegion('door', _rect(0.42, 0.58, 0.58, 0.88)),
        ]),
        ColoringPicture(id: 'color_heart', title: 'Trái tim', category: 'object', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('left', _ring(0.38, 0.4, 0.18, 0.18)),
          ColorRegion('right', _ring(0.62, 0.4, 0.18, 0.18)),
          const ColorRegion('tip', [Offset(0.22, 0.48), Offset(0.78, 0.48), Offset(0.5, 0.88)]),
        ]),
        ColoringPicture(id: 'color_duck', title: 'Con vịt', category: 'animal', ageMin: 3, ageMax: 7, regions: [
          ColorRegion('body', _ring(0.46, 0.58, 0.26, 0.18)),
          ColorRegion('head', _ring(0.68, 0.36, 0.14, 0.14)),
          const ColorRegion('beak', [Offset(0.8, 0.34), Offset(0.94, 0.38), Offset(0.8, 0.44)]),
          ColorRegion('wing', _ring(0.42, 0.56, 0.12, 0.08)),
        ]),
      ];

  static List<DotPuzzle> dotPuzzles() => const [
        DotPuzzle(id: 'dot_fish', title: 'Con cá', ageMin: 3, ageMax: 7, points: [Offset(0.18, 0.5), Offset(0.32, 0.32), Offset(0.55, 0.28), Offset(0.72, 0.42), Offset(0.78, 0.58), Offset(0.58, 0.72), Offset(0.34, 0.68), Offset(0.2, 0.56)]),
        DotPuzzle(id: 'dot_cat', title: 'Con mèo', ageMin: 3, ageMax: 7, points: [Offset(0.28, 0.28), Offset(0.38, 0.18), Offset(0.5, 0.3), Offset(0.62, 0.18), Offset(0.72, 0.3), Offset(0.7, 0.52), Offset(0.5, 0.7), Offset(0.3, 0.52)]),
        DotPuzzle(id: 'dot_dog', title: 'Con chó', ageMin: 3, ageMax: 7, points: [Offset(0.22, 0.42), Offset(0.3, 0.26), Offset(0.48, 0.3), Offset(0.68, 0.28), Offset(0.78, 0.46), Offset(0.7, 0.68), Offset(0.46, 0.74), Offset(0.26, 0.62)]),
        DotPuzzle(id: 'dot_flower', title: 'Bông hoa', ageMin: 3, ageMax: 7, points: [Offset(0.5, 0.18), Offset(0.68, 0.32), Offset(0.72, 0.52), Offset(0.58, 0.7), Offset(0.42, 0.7), Offset(0.28, 0.52), Offset(0.32, 0.32), Offset(0.5, 0.42)]),
        DotPuzzle(id: 'dot_sun', title: 'Mặt trời', ageMin: 3, ageMax: 7, points: [Offset(0.5, 0.16), Offset(0.72, 0.28), Offset(0.84, 0.5), Offset(0.72, 0.72), Offset(0.5, 0.84), Offset(0.28, 0.72), Offset(0.16, 0.5), Offset(0.28, 0.28)]),
        DotPuzzle(id: 'dot_apple', title: 'Quả táo', ageMin: 3, ageMax: 7, points: [Offset(0.5, 0.22), Offset(0.68, 0.32), Offset(0.78, 0.52), Offset(0.68, 0.74), Offset(0.5, 0.82), Offset(0.32, 0.74), Offset(0.22, 0.52), Offset(0.32, 0.32)]),
        DotPuzzle(id: 'dot_car', title: 'Ô tô', ageMin: 4, ageMax: 7, points: [Offset(0.12, 0.58), Offset(0.22, 0.42), Offset(0.4, 0.32), Offset(0.62, 0.32), Offset(0.8, 0.44), Offset(0.88, 0.58), Offset(0.72, 0.72), Offset(0.28, 0.72)]),
        DotPuzzle(id: 'dot_rocket', title: 'Tên lửa', ageMin: 4, ageMax: 7, points: [Offset(0.5, 0.12), Offset(0.62, 0.32), Offset(0.62, 0.62), Offset(0.74, 0.78), Offset(0.5, 0.7), Offset(0.26, 0.78), Offset(0.38, 0.62), Offset(0.38, 0.32)]),
        DotPuzzle(id: 'dot_butterfly', title: 'Con bướm', ageMin: 4, ageMax: 7, points: [Offset(0.5, 0.22), Offset(0.28, 0.28), Offset(0.18, 0.5), Offset(0.32, 0.7), Offset(0.5, 0.58), Offset(0.68, 0.7), Offset(0.82, 0.5), Offset(0.72, 0.28)]),
        DotPuzzle(id: 'dot_rabbit', title: 'Con thỏ', ageMin: 3, ageMax: 7, points: [Offset(0.38, 0.16), Offset(0.42, 0.34), Offset(0.5, 0.46), Offset(0.58, 0.34), Offset(0.62, 0.16), Offset(0.7, 0.52), Offset(0.5, 0.78), Offset(0.3, 0.52)]),
        DotPuzzle(id: 'dot_elephant', title: 'Con voi', ageMin: 5, ageMax: 7, points: [Offset(0.22, 0.28), Offset(0.38, 0.22), Offset(0.58, 0.3), Offset(0.78, 0.42), Offset(0.74, 0.68), Offset(0.5, 0.8), Offset(0.28, 0.7), Offset(0.16, 0.5)]),
        DotPuzzle(id: 'dot_house', title: 'Ngôi nhà', ageMin: 3, ageMax: 7, points: [Offset(0.2, 0.48), Offset(0.5, 0.18), Offset(0.8, 0.48), Offset(0.8, 0.82), Offset(0.58, 0.82), Offset(0.58, 0.62), Offset(0.42, 0.62), Offset(0.2, 0.82)]),
        DotPuzzle(id: 'dot_tree', title: 'Cây', ageMin: 3, ageMax: 7, points: [Offset(0.5, 0.14), Offset(0.7, 0.32), Offset(0.62, 0.52), Offset(0.58, 0.72), Offset(0.5, 0.88), Offset(0.42, 0.72), Offset(0.38, 0.52), Offset(0.3, 0.32)]),
        DotPuzzle(id: 'dot_cloud', title: 'Đám mây', ageMin: 3, ageMax: 7, points: [Offset(0.22, 0.52), Offset(0.3, 0.36), Offset(0.46, 0.28), Offset(0.62, 0.32), Offset(0.76, 0.44), Offset(0.78, 0.6), Offset(0.58, 0.7), Offset(0.34, 0.66)]),
        DotPuzzle(id: 'dot_rainbow', title: 'Cầu vồng', ageMin: 5, ageMax: 7, points: [Offset(0.12, 0.72), Offset(0.22, 0.46), Offset(0.36, 0.28), Offset(0.5, 0.2), Offset(0.64, 0.28), Offset(0.78, 0.46), Offset(0.88, 0.72), Offset(0.5, 0.55)]),
        DotPuzzle(id: 'dot_star', title: 'Ngôi sao', ageMin: 3, ageMax: 7, points: [Offset(0.5, 0.12), Offset(0.58, 0.36), Offset(0.84, 0.36), Offset(0.64, 0.52), Offset(0.72, 0.78), Offset(0.5, 0.62), Offset(0.28, 0.78), Offset(0.36, 0.52), Offset(0.16, 0.36), Offset(0.42, 0.36)]),
        DotPuzzle(id: 'dot_moon', title: 'Mặt trăng', ageMin: 3, ageMax: 7, points: [Offset(0.58, 0.18), Offset(0.72, 0.28), Offset(0.78, 0.48), Offset(0.7, 0.7), Offset(0.5, 0.82), Offset(0.38, 0.62), Offset(0.48, 0.48), Offset(0.4, 0.3)]),
        DotPuzzle(id: 'dot_boat', title: 'Thuyền', ageMin: 3, ageMax: 7, points: [Offset(0.18, 0.58), Offset(0.5, 0.16), Offset(0.5, 0.56), Offset(0.86, 0.58), Offset(0.74, 0.78), Offset(0.26, 0.78)]),
        DotPuzzle(id: 'dot_heart', title: 'Trái tim', ageMin: 3, ageMax: 7, points: [Offset(0.5, 0.32), Offset(0.62, 0.18), Offset(0.8, 0.28), Offset(0.78, 0.48), Offset(0.5, 0.82), Offset(0.22, 0.48), Offset(0.2, 0.28), Offset(0.38, 0.18)]),
        DotPuzzle(id: 'dot_triangle', title: 'Tam giác', ageMin: 3, ageMax: 7, points: [Offset(0.5, 0.14), Offset(0.62, 0.38), Offset(0.84, 0.82), Offset(0.5, 0.82), Offset(0.16, 0.82), Offset(0.38, 0.38)]),
        DotPuzzle(id: 'dot_diamond', title: 'Hình thoi', ageMin: 4, ageMax: 7, points: [Offset(0.5, 0.12), Offset(0.7, 0.32), Offset(0.86, 0.5), Offset(0.7, 0.68), Offset(0.5, 0.88), Offset(0.3, 0.68), Offset(0.14, 0.5), Offset(0.3, 0.32)]),
        DotPuzzle(id: 'dot_bird', title: 'Con chim', ageMin: 4, ageMax: 7, points: [Offset(0.18, 0.48), Offset(0.32, 0.32), Offset(0.5, 0.28), Offset(0.72, 0.22), Offset(0.86, 0.38), Offset(0.7, 0.52), Offset(0.58, 0.7), Offset(0.34, 0.62)]),
        DotPuzzle(id: 'dot_icecream', title: 'Kem ốc quế', ageMin: 3, ageMax: 7, points: [Offset(0.5, 0.12), Offset(0.66, 0.24), Offset(0.7, 0.42), Offset(0.62, 0.52), Offset(0.5, 0.9), Offset(0.38, 0.52), Offset(0.3, 0.42), Offset(0.34, 0.24)]),
        DotPuzzle(id: 'dot_mushroom', title: 'Nấm', ageMin: 3, ageMax: 7, points: [Offset(0.22, 0.42), Offset(0.32, 0.22), Offset(0.5, 0.14), Offset(0.68, 0.22), Offset(0.78, 0.42), Offset(0.62, 0.5), Offset(0.58, 0.86), Offset(0.42, 0.86), Offset(0.38, 0.5)]),
        DotPuzzle(id: 'dot_turtle', title: 'Con rùa', ageMin: 4, ageMax: 7, points: [Offset(0.2, 0.5), Offset(0.34, 0.32), Offset(0.58, 0.28), Offset(0.78, 0.4), Offset(0.86, 0.52), Offset(0.72, 0.7), Offset(0.48, 0.78), Offset(0.28, 0.68)]),
        DotPuzzle(id: 'dot_penguin', title: 'Chim cánh cụt', ageMin: 4, ageMax: 7, points: [Offset(0.5, 0.12), Offset(0.64, 0.22), Offset(0.68, 0.48), Offset(0.62, 0.78), Offset(0.5, 0.88), Offset(0.38, 0.78), Offset(0.32, 0.48), Offset(0.36, 0.22)]),
        DotPuzzle(id: 'dot_plane', title: 'Máy bay', ageMin: 5, ageMax: 7, points: [Offset(0.12, 0.5), Offset(0.32, 0.46), Offset(0.5, 0.22), Offset(0.58, 0.46), Offset(0.86, 0.42), Offset(0.78, 0.54), Offset(0.58, 0.58), Offset(0.5, 0.78), Offset(0.32, 0.56)]),
        DotPuzzle(id: 'dot_train', title: 'Tàu hỏa', ageMin: 4, ageMax: 7, points: [Offset(0.1, 0.42), Offset(0.22, 0.22), Offset(0.28, 0.42), Offset(0.7, 0.42), Offset(0.88, 0.5), Offset(0.86, 0.68), Offset(0.7, 0.78), Offset(0.28, 0.78), Offset(0.12, 0.68)]),
        DotPuzzle(id: 'dot_castle', title: 'Lâu đài', ageMin: 5, ageMax: 7, points: [Offset(0.16, 0.28), Offset(0.16, 0.82), Offset(0.38, 0.82), Offset(0.38, 0.48), Offset(0.5, 0.32), Offset(0.62, 0.48), Offset(0.62, 0.82), Offset(0.84, 0.82), Offset(0.84, 0.28), Offset(0.5, 0.12)]),
        DotPuzzle(id: 'dot_balloon', title: 'Bóng bay', ageMin: 3, ageMax: 7, points: [Offset(0.5, 0.12), Offset(0.68, 0.24), Offset(0.74, 0.44), Offset(0.62, 0.6), Offset(0.5, 0.88), Offset(0.38, 0.6), Offset(0.26, 0.44), Offset(0.32, 0.24)]),
        DotPuzzle(id: 'dot_duck', title: 'Con vịt', ageMin: 3, ageMax: 7, points: [Offset(0.22, 0.52), Offset(0.34, 0.38), Offset(0.52, 0.36), Offset(0.7, 0.22), Offset(0.86, 0.32), Offset(0.72, 0.48), Offset(0.62, 0.68), Offset(0.36, 0.7)]),
        DotPuzzle(id: 'dot_leaf', title: 'Chiếc lá', ageMin: 4, ageMax: 7, points: [Offset(0.22, 0.22), Offset(0.48, 0.16), Offset(0.78, 0.32), Offset(0.86, 0.58), Offset(0.7, 0.78), Offset(0.42, 0.72), Offset(0.28, 0.5), Offset(0.5, 0.48)]),
      ];

  static List<MatchPuzzle> matchPuzzles() => const [
        MatchPuzzle(id: 'match_shadow_1', title: 'Ghép bóng', instruction: 'Ghép hình với bóng', ageMin: 3, ageMax: 4, left: ['⭐', '🌙', '☀️'], right: ['⭐', '🌙', '☀️']),
        MatchPuzzle(id: 'match_shadow_2', title: 'Ghép bóng', instruction: 'Ghép hình với bóng', ageMin: 3, ageMax: 4, left: ['🍎', '🍌', '🍇'], right: ['🍎', '🍌', '🍇']),
        MatchPuzzle(id: 'match_shadow_3', title: 'Ghép bóng', instruction: 'Ghép hình với bóng', ageMin: 3, ageMax: 5, left: ['🐱', '🐶', '🐭'], right: ['🐱', '🐶', '🐭']),
        MatchPuzzle(id: 'match_food_1', title: 'Con vật — thức ăn', instruction: 'Con vật ăn gì?', ageMin: 3, ageMax: 5, left: ['🐱', '🐶', '🐰'], right: ['🐟', '🦴', '🥕']),
        MatchPuzzle(id: 'match_food_2', title: 'Con vật — thức ăn', instruction: 'Con vật ăn gì?', ageMin: 4, ageMax: 6, left: ['🐵', '🐼', '🐮'], right: ['🍌', '🎋', '🌿']),
        MatchPuzzle(id: 'match_home_1', title: 'Nơi sống', instruction: 'Con vật sống ở đâu?', ageMin: 4, ageMax: 6, left: ['🐟', '🐦', '🐶'], right: ['🌊', '🌳', '🏠']),
        MatchPuzzle(id: 'match_home_2', title: 'Nơi sống', instruction: 'Con vật sống ở đâu?', ageMin: 5, ageMax: 7, left: ['🐝', '🐸', '🐧'], right: ['🌸', '🌿', '❄️']),
        MatchPuzzle(id: 'match_use_1', title: 'Công dụng', instruction: 'Dùng để làm gì?', ageMin: 4, ageMax: 6, left: ['✏️', '🥄', '🔑'], right: ['📝', '🍚', '🚪']),
        MatchPuzzle(id: 'match_use_2', title: 'Công dụng', instruction: 'Dùng để làm gì?', ageMin: 5, ageMax: 7, left: ['☂️', '🛏️', '🧼'], right: ['🌧️', '😴', '🚿']),
        MatchPuzzle(id: 'match_shape_1', title: 'Hình hoàn chỉnh', instruction: 'Ghép nửa hình', ageMin: 3, ageMax: 5, left: ['◐', '▲', '■'], right: ['◑', '△', '□']),
        MatchPuzzle(id: 'match_shape_2', title: 'Hình hoàn chỉnh', instruction: 'Ghép nửa hình', ageMin: 4, ageMax: 6, left: ['♥', '●', '◆'], right: ['♡', '○', '◇']),
        MatchPuzzle(id: 'match_num_1', title: 'Số và lượng', instruction: 'Ghép số với chấm', ageMin: 3, ageMax: 5, left: ['1', '2', '3'], right: ['•', '••', '•••']),
        MatchPuzzle(id: 'match_num_2', title: 'Số và lượng', instruction: 'Ghép số với chấm', ageMin: 5, ageMax: 7, left: ['4', '5', '6'], right: ['••••', '•••••', '••••••']),
        MatchPuzzle(id: 'match_opposites', title: 'Đối lập', instruction: 'Ghép cặp đối lập', ageMin: 6, ageMax: 7, left: ['⬆️', '☀️', '🔥'], right: ['⬇️', '🌙', '❄️']),
        MatchPuzzle(id: 'match_logic', title: 'Ghép logic', instruction: 'Cái nào đi cùng?', ageMin: 6, ageMax: 7, left: ['👟', '📖', '🎨'], right: ['🦶', '📚', '🖌️']),
        MatchPuzzle(id: 'match_color_1', title: 'Màu sắc', instruction: 'Ghép màu với đồ vật', ageMin: 3, ageMax: 5, left: ['🔴', '🟡', '🟢'], right: ['🍎', '🍌', '🍀']),
        MatchPuzzle(id: 'match_color_2', title: 'Màu sắc', instruction: 'Ghép màu với đồ vật', ageMin: 4, ageMax: 6, left: ['🟠', '🟣', '⚪'], right: ['🍊', '🍇', '☁️']),
        MatchPuzzle(id: 'match_weather', title: 'Thời tiết', instruction: 'Ghép với thời tiết', ageMin: 4, ageMax: 6, left: ['☀️', '🌧️', '❄️'], right: ['😎', '☂️', '🧤']),
        MatchPuzzle(id: 'match_jobs', title: 'Nghề nghiệp', instruction: 'Ai dùng gì?', ageMin: 5, ageMax: 7, left: ['👩‍🚒', '👨‍⚕️', '👩‍🏫'], right: ['🚒', '🩺', '📚']),
        MatchPuzzle(id: 'match_baby', title: 'Con non', instruction: 'Con non của ai?', ageMin: 4, ageMax: 6, left: ['🐔', '🐄', '🐷'], right: ['🐣', '🐮', '🐽']),
        MatchPuzzle(id: 'match_tools', title: 'Dụng cụ', instruction: 'Ghép dụng cụ', ageMin: 5, ageMax: 7, left: ['🔨', '✂️', '🧹'], right: ['🪵', '📄', '🍃']),
        MatchPuzzle(id: 'match_sports', title: 'Thể thao', instruction: 'Ghép môn thể thao', ageMin: 4, ageMax: 7, left: ['⚽', '🏀', '🎾'], right: ['🥅', '⛹️', '🏸']),
        MatchPuzzle(id: 'match_family', title: 'Gia đình', instruction: 'Ghép thành viên', ageMin: 3, ageMax: 5, left: ['👨', '👩', '👶'], right: ['👔', '👗', '🍼']),
        MatchPuzzle(id: 'match_time', title: 'Buổi trong ngày', instruction: 'Ghép buổi với việc', ageMin: 5, ageMax: 7, left: ['🌅', '☀️', '🌙'], right: ['🥐', '🎮', '🛏️']),
        MatchPuzzle(id: 'match_season', title: 'Mùa', instruction: 'Ghép mùa với hình', ageMin: 5, ageMax: 7, left: ['🌸', '☀️', '🍂', '❄️'], right: ['🌷', '🏖️', '🍁', '⛄']),
        MatchPuzzle(id: 'match_transport', title: 'Phương tiện', instruction: 'Đi bằng gì?', ageMin: 3, ageMax: 5, left: ['🛣️', '🌊', '☁️'], right: ['🚗', '🚢', '✈️']),
        MatchPuzzle(id: 'match_num_3', title: 'Số và lượng', instruction: 'Ghép số với chấm', ageMin: 6, ageMax: 7, left: ['7', '8', '9'], right: ['•••••••', '••••••••', '•••••••••']),
        MatchPuzzle(id: 'match_letters', title: 'Chữ cái', instruction: 'Ghép chữ hoa — thường', ageMin: 5, ageMax: 7, left: ['A', 'B', 'C'], right: ['a', 'b', 'c']),
        MatchPuzzle(id: 'match_emotion', title: 'Cảm xúc', instruction: 'Ghép cảm xúc', ageMin: 3, ageMax: 5, left: ['😊', '😢', '😡'], right: ['🎁', '💔', '💢']),
        MatchPuzzle(id: 'match_body', title: 'Cơ thể', instruction: 'Dùng bộ phận nào?', ageMin: 4, ageMax: 6, left: ['👀', '👂', '👃'], right: ['👁️', '🎧', '🌸']),
        MatchPuzzle(id: 'match_kitchen', title: 'Nhà bếp', instruction: 'Dùng để làm gì?', ageMin: 5, ageMax: 7, left: ['🔪', '🍳', '🧊'], right: ['🥕', '🔥', '❄️']),
        MatchPuzzle(id: 'match_clothes', title: 'Quần áo', instruction: 'Mặc khi nào?', ageMin: 3, ageMax: 5, left: ['👕', '🧥', '🩱'], right: ['☀️', '❄️', '🏊']),
        MatchPuzzle(id: 'match_music', title: 'Âm nhạc', instruction: 'Ghép nhạc cụ', ageMin: 5, ageMax: 7, left: ['🎹', '🎤', '🎧'], right: ['🎼', '🎶', '🎵']),
        MatchPuzzle(id: 'match_plants', title: 'Cây cối', instruction: 'Ghép bộ phận cây', ageMin: 4, ageMax: 6, left: ['🌳', '🌸', '🍎'], right: ['🪵', '🐝', '🧺']),
        MatchPuzzle(id: 'match_space', title: 'Vũ trụ', instruction: 'Ghép vật thể trời', ageMin: 6, ageMax: 7, left: ['☀️', '🌙', '⭐'], right: ['🌞', '🌛', '✨']),
      ];

  static List<PatternPuzzle> patternPuzzles() => const [
        PatternPuzzle(id: 'pat_1', title: 'Luân phiên màu', ageMin: 3, ageMax: 7, sequence: ['🔴', '🔵', '🔴', '🔵'], answer: '🔴'),
        PatternPuzzle(id: 'pat_2', title: 'Sao và trăng', ageMin: 3, ageMax: 7, sequence: ['⭐', '⭐', '🌙', '⭐', '⭐'], answer: '🌙'),
        PatternPuzzle(id: 'pat_3', title: 'Tam giác tròn', ageMin: 3, ageMax: 7, sequence: ['▲', '●', '▲', '●'], answer: '▲'),
        PatternPuzzle(id: 'pat_4', title: 'Mèo chó', ageMin: 3, ageMax: 7, sequence: ['🐱', '🐶', '🐱', '🐶'], answer: '🐱'),
        PatternPuzzle(id: 'pat_5', title: 'Táo chuối', ageMin: 3, ageMax: 7, sequence: ['🍎', '🍌', '🍎', '🍌'], answer: '🍎'),
        PatternPuzzle(id: 'pat_6', title: 'Hai đỏ một xanh', ageMin: 4, ageMax: 7, sequence: ['🟥', '🟥', '🟦', '🟥', '🟥'], answer: '🟦'),
        PatternPuzzle(id: 'pat_7', title: 'Nắng đêm', ageMin: 3, ageMax: 7, sequence: ['🌞', '🌜', '🌞', '🌜'], answer: '🌞'),
        PatternPuzzle(id: 'pat_8', title: 'Hoa lá', ageMin: 3, ageMax: 7, sequence: ['🌸', '🌼', '🌸', '🌼'], answer: '🌸'),
        PatternPuzzle(id: 'pat_9', title: 'Vuông tròn', ageMin: 3, ageMax: 7, sequence: ['■', '□', '■', '□'], answer: '■'),
        PatternPuzzle(id: 'pat_10', title: 'Cá xen kẽ', ageMin: 4, ageMax: 7, sequence: ['🐟', '🐠', '🐟', '🐠'], answer: '🐟'),
        PatternPuzzle(id: 'pat_11', title: 'Xe luân phiên', ageMin: 4, ageMax: 7, sequence: ['🚗', '🚌', '🚗', '🚌'], answer: '🚗'),
        PatternPuzzle(id: 'pat_12', title: 'Ba màu lặp', ageMin: 5, ageMax: 7, sequence: ['🟦', '🟨', '🟩', '🟦', '🟨', '🟩'], answer: '🟦'),
        PatternPuzzle(id: 'pat_13', title: 'Cây lớn dần', ageMin: 4, ageMax: 7, sequence: ['🌱', '🌿', '🌳', '🌱', '🌿'], answer: '🌳'),
        PatternPuzzle(id: 'pat_14', title: 'Số đếm', ageMin: 4, ageMax: 7, sequence: ['1️⃣', '2️⃣', '3️⃣', '1️⃣', '2️⃣'], answer: '3️⃣'),
        PatternPuzzle(id: 'pat_15', title: 'Trái tim sao', ageMin: 3, ageMax: 7, sequence: ['❤️', '⭐', '❤️', '⭐'], answer: '❤️'),
        PatternPuzzle(id: 'pat_16', title: 'Mũi tên vòng', ageMin: 5, ageMax: 7, sequence: ['→', '↓', '←', '↑', '→'], answer: '↓'),
        PatternPuzzle(id: 'pat_17', title: 'Hai sao một mây', ageMin: 4, ageMax: 7, sequence: ['⭐', '⭐', '☁️', '⭐', '⭐'], answer: '☁️'),
        PatternPuzzle(id: 'pat_18', title: 'Nhạc cụ', ageMin: 5, ageMax: 7, sequence: ['🎹', '🎸', '🎹', '🎸'], answer: '🎹'),
        PatternPuzzle(id: 'pat_19', title: 'Trái cây ba loại', ageMin: 4, ageMax: 7, sequence: ['🍎', '🍌', '🍇', '🍎', '🍌'], answer: '🍇'),
        PatternPuzzle(id: 'pat_20', title: 'Hình học lặp', ageMin: 5, ageMax: 7, sequence: ['▲', '■', '●', '▲', '■'], answer: '●'),
        PatternPuzzle(id: 'pat_21', title: 'Thú rừng', ageMin: 4, ageMax: 7, sequence: ['🐘', '🦒', '🐘', '🦒'], answer: '🐘'),
        PatternPuzzle(id: 'pat_22', title: 'Thời tiết', ageMin: 4, ageMax: 7, sequence: ['☀️', '🌧️', '☀️', '🌧️'], answer: '☀️'),
        PatternPuzzle(id: 'pat_23', title: 'Bóng thể thao', ageMin: 5, ageMax: 7, sequence: ['⚽', '🏀', '🎾', '⚽', '🏀'], answer: '🎾'),
        PatternPuzzle(id: 'pat_24', title: 'Chữ AB', ageMin: 5, ageMax: 7, sequence: ['A', 'B', 'A', 'B', 'A'], answer: 'B'),
        PatternPuzzle(id: 'pat_25', title: 'Ba chữ lặp', ageMin: 6, ageMax: 7, sequence: ['A', 'B', 'C', 'A', 'B', 'C'], answer: 'A'),
        PatternPuzzle(id: 'pat_26', title: 'Kẹo bánh', ageMin: 3, ageMax: 7, sequence: ['🍪', '🍩', '🍪', '🍩'], answer: '🍪'),
        PatternPuzzle(id: 'pat_27', title: 'Hai xanh một vàng', ageMin: 4, ageMax: 7, sequence: ['🟢', '🟢', '🟡', '🟢', '🟢'], answer: '🟡'),
        PatternPuzzle(id: 'pat_28', title: 'Côn trùng', ageMin: 5, ageMax: 7, sequence: ['🐝', '🦋', '🐝', '🦋'], answer: '🐝'),
        PatternPuzzle(id: 'pat_29', title: 'Nhà cửa', ageMin: 5, ageMax: 7, sequence: ['🏠', '🏫', '🏠', '🏫'], answer: '🏠'),
        PatternPuzzle(id: 'pat_30', title: 'Mặt trời mây mưa', ageMin: 6, ageMax: 7, sequence: ['🌞', '☁️', '🌧️', '🌞', '☁️'], answer: '🌧️'),
        PatternPuzzle(id: 'pat_31', title: 'Số chẵn', ageMin: 6, ageMax: 7, sequence: ['2', '4', '6', '2', '4'], answer: '6'),
        PatternPuzzle(id: 'pat_32', title: 'Mũi tên trái phải', ageMin: 4, ageMax: 7, sequence: ['←', '→', '←', '→'], answer: '←'),
      ];

  static List<DrawingChallenge> drawingChallenges() => const [
        DrawingChallenge(id: 'draw_cat', title: 'Con mèo', prompt: 'Vẽ con mèo', ageMin: 3, ageMax: 7),
        DrawingChallenge(id: 'draw_house', title: 'Ngôi nhà', prompt: 'Vẽ ngôi nhà của con', ageMin: 3, ageMax: 7),
        DrawingChallenge(id: 'draw_sun', title: 'Mặt trời', prompt: 'Vẽ mặt trời và mây', ageMin: 3, ageMax: 5),
        DrawingChallenge(id: 'draw_tree', title: 'Cây xanh', prompt: 'Vẽ một cái cây', ageMin: 3, ageMax: 7),
        DrawingChallenge(id: 'draw_fish', title: 'Con cá', prompt: 'Vẽ con cá đang bơi', ageMin: 3, ageMax: 6),
        DrawingChallenge(id: 'draw_flower', title: 'Bông hoa', prompt: 'Vẽ bông hoa', ageMin: 3, ageMax: 7),
        DrawingChallenge(id: 'draw_car', title: 'Xe hơi', prompt: 'Vẽ một chiếc xe', ageMin: 4, ageMax: 7),
        DrawingChallenge(id: 'draw_family', title: 'Gia đình', prompt: 'Vẽ gia đình con', ageMin: 4, ageMax: 7),
        DrawingChallenge(id: 'draw_rainbow', title: 'Cầu vồng', prompt: 'Vẽ cầu vồng', ageMin: 3, ageMax: 6),
        DrawingChallenge(id: 'draw_boat', title: 'Thuyền', prompt: 'Vẽ thuyền trên sông', ageMin: 4, ageMax: 7),
        DrawingChallenge(id: 'draw_bird', title: 'Con chim', prompt: 'Vẽ chim đang bay', ageMin: 3, ageMax: 7),
        DrawingChallenge(id: 'draw_star', title: 'Bầu trời đêm', prompt: 'Vẽ trăng và sao', ageMin: 3, ageMax: 6),
        DrawingChallenge(id: 'draw_park', title: 'Công viên', prompt: 'Vẽ công viên', ageMin: 5, ageMax: 7),
        DrawingChallenge(id: 'draw_school', title: 'Trường học', prompt: 'Vẽ trường của con', ageMin: 5, ageMax: 7),
        DrawingChallenge(id: 'draw_cake', title: 'Bánh sinh nhật', prompt: 'Vẽ bánh kem', ageMin: 3, ageMax: 6),
        DrawingChallenge(id: 'draw_robot', title: 'Robot', prompt: 'Vẽ một robot', ageMin: 5, ageMax: 7),
        DrawingChallenge(id: 'draw_butterfly', title: 'Bướm', prompt: 'Vẽ con bướm', ageMin: 3, ageMax: 7),
        DrawingChallenge(id: 'draw_mountain', title: 'Núi', prompt: 'Vẽ núi và mặt trời', ageMin: 4, ageMax: 7),
        DrawingChallenge(id: 'draw_self', title: 'Chân dung', prompt: 'Vẽ chính con', ageMin: 4, ageMax: 7),
        DrawingChallenge(id: 'draw_pet', title: 'Thú cưng', prompt: 'Vẽ thú cưng', ageMin: 3, ageMax: 7),
        DrawingChallenge(id: 'draw_rain', title: 'Ngày mưa', prompt: 'Vẽ ngày mưa', ageMin: 4, ageMax: 7),
        DrawingChallenge(id: 'draw_beach', title: 'Bãi biển', prompt: 'Vẽ biển và cát', ageMin: 5, ageMax: 7),
        DrawingChallenge(id: 'draw_train', title: 'Tàu hỏa', prompt: 'Vẽ tàu hỏa', ageMin: 4, ageMax: 7),
        DrawingChallenge(id: 'draw_apple', title: 'Quả táo', prompt: 'Vẽ quả táo', ageMin: 3, ageMax: 5),
        DrawingChallenge(id: 'draw_friend', title: 'Bạn bè', prompt: 'Vẽ bạn của con', ageMin: 4, ageMax: 7),
        DrawingChallenge(id: 'draw_garden', title: 'Vườn hoa', prompt: 'Vẽ vườn hoa', ageMin: 4, ageMax: 7),
        DrawingChallenge(id: 'draw_rocket', title: 'Tên lửa', prompt: 'Vẽ tên lửa', ageMin: 5, ageMax: 7),
        DrawingChallenge(id: 'draw_castle', title: 'Lâu đài', prompt: 'Vẽ lâu đài', ageMin: 6, ageMax: 7),
        DrawingChallenge(id: 'draw_farm', title: 'Nông trại', prompt: 'Vẽ nông trại', ageMin: 5, ageMax: 7),
        DrawingChallenge(id: 'draw_birthday', title: 'Tiệc vui', prompt: 'Vẽ buổi tiệc', ageMin: 4, ageMax: 7),
      ];

  static List<DrawingChallenge> drawingForAge(int age) {
    final base = drawingChallenges().where((e) => age >= e.ageMin && age <= e.ageMax).toList();
    return [
      ...base,
      for (final e in base)
        DrawingChallenge(id: '${e.id}_b', title: e.title, prompt: e.prompt, ageMin: e.ageMin, ageMax: e.ageMax),
    ];
  }

  static List<ColoringPicture> coloringForAge(int age) {
    final base = coloringPages().where((e) => age >= e.ageMin && age <= e.ageMax).toList();
    return [
      ...base,
      for (final e in base)
        ColoringPicture(
          id: '${e.id}_b',
          title: e.title,
          category: e.category,
          ageMin: e.ageMin,
          ageMax: e.ageMax,
          regions: e.regions,
        ),
    ];
  }

  static List<DotPuzzle> dotsForAge(int age) {
    final base = dotPuzzles().where((e) => age >= e.ageMin && age <= e.ageMax).toList();
    return [
      ...base,
      for (final e in base)
        DotPuzzle(id: '${e.id}_b', title: e.title, ageMin: e.ageMin, ageMax: e.ageMax, points: e.points),
    ];
  }

  static List<MatchPuzzle> matchesForAge(int age) {
    final base = matchPuzzles().where((e) => age >= e.ageMin && age <= e.ageMax).toList();
    return [
      ...base,
      for (final e in base)
        MatchPuzzle(
          id: '${e.id}_b',
          title: e.title,
          instruction: e.instruction,
          ageMin: e.ageMin,
          ageMax: e.ageMax,
          left: e.left,
          right: e.right,
        ),
    ];
  }

  static List<PatternPuzzle> patternsForAge(int age) {
    final base = patternPuzzles().where((e) => age >= e.ageMin && age <= e.ageMax).toList();
    return [
      ...base,
      for (final e in base)
        PatternPuzzle(
          id: '${e.id}_b',
          title: e.title,
          ageMin: e.ageMin,
          ageMax: e.ageMax,
          sequence: e.sequence,
          answer: e.answer,
        ),
    ];
  }

  static List<ContentItem> asContentItems() {
    return [
      ...coloringPages().map((e) => ContentItem(
            id: e.id,
            subject: ContentSubject.creativity,
            ageMin: e.ageMin,
            ageMax: e.ageMax,
            level: 1,
            skill: 'coloring',
            difficulty: 1,
            title: e.title,
            instruction: 'Tô màu ${e.title}',
            metadata: {'category': e.category, 'regions': e.regions.length},
          )),
      ...dotPuzzles().map((e) => ContentItem(
            id: e.id,
            subject: ContentSubject.creativity,
            ageMin: e.ageMin,
            ageMax: e.ageMax,
            level: 1,
            skill: 'connect_dots',
            difficulty: 1,
            title: e.title,
            instruction: 'Nối điểm ${e.title}',
            metadata: {'points': e.points.length},
          )),
      ...matchPuzzles().map((e) => ContentItem(
            id: e.id,
            subject: ContentSubject.creativity,
            ageMin: e.ageMin,
            ageMax: e.ageMax,
            level: 1,
            skill: 'matching',
            difficulty: ageDifficulty(e.ageMin),
            title: e.title,
            instruction: e.instruction,
          )),
      ...patternPuzzles().map((e) => ContentItem(
            id: e.id,
            subject: ContentSubject.creativity,
            ageMin: e.ageMin,
            ageMax: e.ageMax,
            level: 1,
            skill: 'pattern',
            difficulty: ageDifficulty(e.ageMin),
            title: e.title,
            instruction: 'Hình tiếp theo: ${e.sequence.join()} ?',
            answer: e.answer,
          )),
      ...drawingChallenges().map((e) => ContentItem(
            id: e.id,
            subject: ContentSubject.creativity,
            ageMin: e.ageMin,
            ageMax: e.ageMax,
            level: 1,
            skill: 'drawing_challenge',
            difficulty: ageDifficulty(e.ageMin),
            title: e.title,
            instruction: e.prompt,
          )),
    ];
  }

  static int ageDifficulty(int ageMin) => ageMin <= 4 ? 1 : (ageMin <= 5 ? 2 : 3);
}
