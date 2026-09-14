import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/session/session_binder.dart';
import '../../../core/theme/vimai_tokens.dart';
import '../../../data/content/creativity_catalog.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../japanese/writing/presentation/widgets/writing_canvas.dart';
import '../../shared/widgets/choice_grid.dart';
import '../../shared/widgets/vimai_ui.dart';
import '../../shared/widgets/vimai_world.dart';

class CreativityScreen extends ConsumerStatefulWidget {
  final String? initialMode;

  const CreativityScreen({super.key, this.initialMode});

  @override
  ConsumerState<CreativityScreen> createState() => _CreativityScreenState();
}

class _CreativityScreenState extends ConsumerState<CreativityScreen> {
  Color _color = VimaiColor.coral;
  double _width = 14;
  String _mode = 'draw';

  @override
  void initState() {
    super.initState();
    if (widget.initialMode != null && widget.initialMode!.isNotEmpty) {
      _mode = widget.initialMode!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(audioServiceProvider).playAudio('sys_creativity_intro'));
    });
  }

  int _colorIndex = 0;
  int _dotIndex = 0;
  int _matchIndex = 0;
  int _patternIndex = 0;
  int _challengeIndex = 0;
  final _fills = <String, Color>{};
  final _connected = <int>{};
  String? _dotFeedback;
  String? _patternFeedback;
  bool _patternDone = false;
  int? _matchLeft;
  final _matched = <int>{};
  List<int> _rightPerm = const [];

  static const _palette = [
    VimaiColor.coral,
    VimaiColor.sky,
    VimaiColor.mint,
    VimaiColor.peach,
    VimaiColor.ink,
    VimaiColor.grape,
    VimaiColor.honey,
    VimaiColor.teal,
  ];

  int get _age => ref.read(currentProfileProvider)?.age ?? 5;

  List<ColoringPicture> get _pictures => CreativityCatalog.coloringForAge(_age);
  List<DotPuzzle> get _dots => CreativityCatalog.dotsForAge(_age);
  List<MatchPuzzle> get _matches => CreativityCatalog.matchesForAge(_age);
  List<PatternPuzzle> get _patterns => CreativityCatalog.patternsForAge(_age);
  List<DrawingChallenge> get _challenges => CreativityCatalog.drawingForAge(_age);

  void _cheer() {
    unawaited(ref.read(audioServiceProvider).playRandomSuccess());
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppStrings.of(ref.watch(currentProfileProvider), context);
    return SessionBinder(
      subject: 'creativity',
      child: Scaffold(
      backgroundColor: VimaiColor.bgWarmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => context.pop()),
        title: Text('Sáng tạo', style: VimaiType.title.copyWith(color: VimaiColor.peach)),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const WorldSky(),
          SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: HubIntro(
                    title: copy.creativity,
                    body: copy.creativitySub,
                    color: VimaiSubject.creativity.color,
                    glyph: VimaiSubject.creativity.glyph,
                    icon: VimaiSubject.creativity.icon,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: VimaiColor.peachSoft.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(VimaiRadius.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                    children: [
                      _chip('Vẽ tự do', 'draw'),
                      _chip('Tô màu', 'color'),
                      _chip('Nối điểm', 'dots'),
                      _chip('Ghép hình', 'pattern'),
                      _chip('Quy luật', 'rules'),
                      _chip('Thử thách vẽ', 'challenge'),
                    ],
                  ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _palette.length; i++)
                      Semantics(
                        button: true,
                        label: copy.colorName(i),
                        selected: _color == _palette[i],
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setState(() => _color = _palette[i]),
                            child: Container(
                              width: VimaiSize.touchMin,
                              height: VimaiSize.touchMin,
                              alignment: Alignment.center,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: _palette[i],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _color == _palette[i] ? VimaiColor.ink : Colors.white,
                                    width: _color == _palette[i] ? 3 : 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_mode == 'draw' || _mode == 'challenge') ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      (6.0, copy.brushThin),
                      (10.0, copy.brushMedium),
                      (14.0, copy.brushThick),
                      (22.0, copy.brushHeavy),
                    ].map((w) {
                      return ChoiceChip(
                        label: Text(w.$2),
                        selected: _width == w.$1,
                        onSelected: (_) => setState(() => _width = w.$1),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 8),
                Expanded(child: _body(constraints)),
              ],
            );
          },
        ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _chip(String label, String mode) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _mode == mode,
        onSelected: (_) => setState(() {
          _mode = mode;
          _dotFeedback = null;
          _patternFeedback = null;
          _patternDone = false;
          _matchLeft = null;
          _matched.clear();
          _rightPerm = const [];
        }),
      ),
    );
  }

  Widget _body(BoxConstraints constraints) {
    if (_mode == 'draw' || _mode == 'challenge') {
      final challenge = _mode == 'challenge' && _challenges.isNotEmpty ? _challenges[_challengeIndex % _challenges.length] : null;
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (challenge != null)
              Row(
                children: [
                  Expanded(child: Text(challenge.prompt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(
                    onPressed: () => setState(() => _challengeIndex++),
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ],
              ),
            Expanded(child: WritingCanvas(strokeColor: _color, strokeWidth: _width, onCleared: () {})),
          ],
        ),
      );
    }
    if (_mode == 'color') {
      if (_pictures.isEmpty) return const Center(child: Text('Chưa có tranh'));
      final picture = _pictures[_colorIndex % _pictures.length];
      return Column(
        children: [
          Text(picture.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, box) {
                  return GestureDetector(
                    onTapDown: (d) {
                      final size = Size(box.maxWidth, box.maxHeight);
                      for (final region in picture.regions.reversed) {
                        final poly = region.points.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();
                        if (_contains(d.localPosition, poly)) {
                          setState(() => _fills[region.id] = _color);
                          break;
                        }
                      }
                    },
                    child: CustomPaint(
                      painter: _ColoringPainter(picture: picture, fills: _fills),
                      size: Size(box.maxWidth, box.maxHeight),
                    ),
                  );
                },
              ),
            ),
          ),
          _nextBar(
            label: '${_colorIndex + 1}/${_pictures.length}',
            onNext: () => setState(() {
              _colorIndex = (_colorIndex + 1) % _pictures.length;
              _fills.clear();
            }),
          ),
        ],
      );
    }
    if (_mode == 'dots') {
      if (_dots.isEmpty) return const Center(child: Text('Chưa có bài'));
      final puzzle = _dots[_dotIndex % _dots.length];
      final done = _connected.length == puzzle.points.length;
      return Column(
        children: [
          Text('Nối điểm: ${puzzle.title}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (_dotFeedback != null)
            Text(_dotFeedback!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VimaiColor.coral)),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final pts = puzzle.points.map((p) => Offset(p.dx * box.maxWidth, p.dy * box.maxHeight)).toList();
                return Stack(
                  children: [
                    CustomPaint(size: Size(box.maxWidth, box.maxHeight), painter: _DotsPainter(pts, _connected)),
                    for (var i = 0; i < pts.length; i++)
                      Positioned(
                        left: (pts[i].dx - 18).clamp(0, box.maxWidth - 36),
                        top: (pts[i].dy - 18).clamp(0, box.maxHeight - 36),
                        child: GestureDetector(
                          onTap: () => _tapDot(i, puzzle.points.length),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: _connected.contains(i) ? _color : Colors.white,
                            child: Text('${i + 1}', style: const TextStyle(color: VimaiColor.ink, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          if (done)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () {
                setState(() {
                  if (_dots.length <= 1) return;
                  var next = (_dotIndex + 1) % _dots.length;
                  if (next == _dotIndex) next = (next + 1) % _dots.length;
                  _dotIndex = next;
                  _connected.clear();
                  _dotFeedback = null;
                });
              },
                child: const Text('Bài tiếp theo'),
              ),
            )
          else
            TextButton(onPressed: () => setState(_connected.clear), child: const Text('Làm lại')),
        ],
      );
    }

    if (_mode == 'rules') {
      if (_patterns.isEmpty) return const Center(child: Text('Chưa có bài'));
      final puzzle = _patterns[_patternIndex % _patterns.length];
      return Column(
        children: [
          Text(puzzle.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Hình tiếp theo là gì?', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          Text(
            '${puzzle.sequence.join('  ')}  ?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          if (_patternFeedback != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _patternFeedback!,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: VimaiColor.coral),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ChoiceGrid(
                choices: _patternChoices(puzzle),
                color: VimaiColor.coral,
                onSelected: (value) {
                  final ok = value == puzzle.answer;
                  setState(() {
                    _patternFeedback = ok ? 'Giỏi lắm!' : 'Thử lại nhé!';
                    _patternDone = ok;
                  });
                  if (ok) _cheer();
                },
              ),
            ),
          ),
          if (_patternDone)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () => setState(() {
                  if (_patterns.length <= 1) return;
                  var next = (_patternIndex + 1) % _patterns.length;
                  if (next == _patternIndex) next = (next + 1) % _patterns.length;
                  _patternIndex = next;
                  _patternFeedback = null;
                  _patternDone = false;
                }),
                child: const Text('Bài tiếp theo'),
              ),
            )
          else
            _nextBar(
              label: '${_patternIndex + 1}/${_patterns.length}',
              onNext: () => setState(() {
                _patternIndex = (_patternIndex + 1) % _patterns.length;
                _patternFeedback = null;
                _patternDone = false;
              }),
            ),
        ],
      );
    }

    if (_matches.isEmpty) return const Center(child: Text('Chưa có bài'));
    final puzzle = _matches[_matchIndex % _matches.length];
    if (_rightPerm.length != puzzle.right.length) {
      _rightPerm = List<int>.generate(puzzle.right.length, (i) => i)..shuffle();
    }
    return Column(
      children: [
        Text(puzzle.instruction, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(puzzle.title, style: const TextStyle(color: VimaiColor.inkSoft)),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: puzzle.left.length,
                  itemBuilder: (context, i) {
                    final done = _matched.contains(i);
                    return ListTile(
                      selected: _matchLeft == i,
                      enabled: !done,
                      onTap: done ? null : () => setState(() => _matchLeft = i),
                      title: Center(child: Text(puzzle.left[i], style: const TextStyle(fontSize: 32))),
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _rightPerm.length,
                  itemBuilder: (context, i) {
                    final actual = _rightPerm[i];
                    return ListTile(
                      onTap: () => _tapMatchRight(actual, puzzle),
                      title: Center(child: Text(puzzle.right[actual], style: const TextStyle(fontSize: 32))),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_matched.length == puzzle.left.length)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton(
              onPressed: () => setState(() {
                if (_matches.length <= 1) return;
                var next = (_matchIndex + 1) % _matches.length;
                if (next == _matchIndex) next = (next + 1) % _matches.length;
                _matchIndex = next;
                _matched.clear();
                _matchLeft = null;
                _rightPerm = const [];
              }),
              child: const Text('Bài tiếp theo'),
            ),
          ),
      ],
    );
  }

  List<String> _patternChoices(PatternPuzzle puzzle) {
    const extras = ['🌈', '🍀', '☀️', '🧸', '🔴', '🔵', '⭐', '🌙', '🍎', '🍌'];
    final choices = <String>{puzzle.answer};
    for (final e in [...puzzle.sequence, ...extras]) {
      if (choices.length >= 4) break;
      choices.add(e);
    }
    final list = choices.toList()..shuffle(Random(puzzle.id.hashCode));
    return list;
  }

  void _tapDot(int i, int total) {
    if (_connected.contains(i)) return;
    if (_connected.length != i) {
      setState(() => _dotFeedback = 'Nối theo số nhé!');
      return;
    }
    setState(() {
      _connected.add(i);
      _dotFeedback = _connected.length == total ? 'Giỏi lắm!' : null;
    });
    if (_connected.length == total) _cheer();
  }

  void _tapMatchRight(int rightIndex, MatchPuzzle puzzle) {
    final left = _matchLeft;
    if (left == null || _matched.contains(left)) return;
    final ok = rightIndex == left;
    if (ok) {
      setState(() {
        _matched.add(left);
        _matchLeft = null;
      });
      if (_matched.length == puzzle.left.length) _cheer();
    } else {
      setState(() => _matchLeft = null);
    }
  }

  Widget _nextBar({required String label, required VoidCallback onNext}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          ElevatedButton(onPressed: onNext, child: const Text('Bài tiếp theo')),
        ],
      ),
    );
  }

  bool _contains(Offset p, List<Offset> poly) {
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final pi = poly[i];
      final pj = poly[j];
      final intersect = (pi.dy > p.dy) != (pj.dy > p.dy) &&
          p.dx < (pj.dx - pi.dx) * (p.dy - pi.dy) / ((pj.dy - pi.dy) == 0 ? 0.0001 : (pj.dy - pi.dy)) + pi.dx;
      if (intersect) inside = !inside;
    }
    return inside;
  }
}

class _ColoringPainter extends CustomPainter {
  final ColoringPicture picture;
  final Map<String, Color> fills;
  _ColoringPainter({required this.picture, required this.fills});

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in picture.regions) {
      if (region.points.length < 3) continue;
      final path = Path()
        ..moveTo(region.points.first.dx * size.width, region.points.first.dy * size.height);
      for (final p in region.points.skip(1)) {
        path.lineTo(p.dx * size.width, p.dy * size.height);
      }
      path.close();
      final fill = fills[region.id] ?? Colors.white;
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(
        path,
        Paint()
          ..color = VimaiColor.ink.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ColoringPainter oldDelegate) => true;
}

class _DotsPainter extends CustomPainter {
  final List<Offset> points;
  final Set<int> connected;
  _DotsPainter(this.points, this.connected);

  @override
  void paint(Canvas canvas, Size size) {
    if (connected.length < 2) return;
    final paint = Paint()
      ..color = Colors.pinkAccent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final ordered = connected.toList()..sort();
    for (var i = 1; i < ordered.length; i++) {
      canvas.drawLine(points[ordered[i - 1]], points[ordered[i]], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) => true;
}
