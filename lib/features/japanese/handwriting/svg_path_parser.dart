import 'dart:math';

import 'package:flutter/material.dart';

/// Parses SVG path `d` from KanjiVG (typically M/m, C/c, L/l, Z).
/// Does not invent geometry; only interprets the licensed path string.
class SvgPathParser {
  SvgPathParser._();

  static Path parse(String d, {double scale = 1, Offset shift = Offset.zero}) {
    final path = Path();
    final tokens = _tokenize(d);
    var i = 0;
    var cmd = '';
    var cx = 0.0;
    var cy = 0.0;
    var startX = 0.0;
    var startY = 0.0;
    var lastCx = 0.0;
    var lastCy = 0.0;
    var lastWasCubic = false;

    double n() {
      if (i >= tokens.length) return 0;
      return double.tryParse(tokens[i++]) ?? 0;
    }

    Offset p(double x, double y) => Offset(x * scale + shift.dx, y * scale + shift.dy);

    while (i < tokens.length) {
      final t = tokens[i];
      if (_isCommand(t)) {
        cmd = t;
        i++;
      } else if (cmd.isEmpty) {
        i++;
        continue;
      }

      final rel = cmd == cmd.toLowerCase();
      final c = cmd.toUpperCase();
      switch (c) {
        case 'M':
          var x = n();
          var y = n();
          if (rel) {
            x += cx;
            y += cy;
          }
          cx = x;
          cy = y;
          startX = cx;
          startY = cy;
          path.moveTo(p(cx, cy).dx, p(cx, cy).dy);
          cmd = rel ? 'l' : 'L';
        case 'L':
          var x = n();
          var y = n();
          if (rel) {
            x += cx;
            y += cy;
          }
          cx = x;
          cy = y;
          path.lineTo(p(cx, cy).dx, p(cx, cy).dy);
          lastWasCubic = false;
        case 'H':
          var x = n();
          if (rel) x += cx;
          cx = x;
          path.lineTo(p(cx, cy).dx, p(cx, cy).dy);
          lastWasCubic = false;
        case 'V':
          var y = n();
          if (rel) y += cy;
          cy = y;
          path.lineTo(p(cx, cy).dx, p(cx, cy).dy);
          lastWasCubic = false;
        case 'C':
          var x1 = n();
          var y1 = n();
          var x2 = n();
          var y2 = n();
          var x = n();
          var y = n();
          if (rel) {
            x1 += cx;
            y1 += cy;
            x2 += cx;
            y2 += cy;
            x += cx;
            y += cy;
          }
          path.cubicTo(p(x1, y1).dx, p(x1, y1).dy, p(x2, y2).dx, p(x2, y2).dy, p(x, y).dx, p(x, y).dy);
          lastCx = x2;
          lastCy = y2;
          cx = x;
          cy = y;
          lastWasCubic = true;
        case 'S':
          var x2 = n();
          var y2 = n();
          var x = n();
          var y = n();
          if (rel) {
            x2 += cx;
            y2 += cy;
            x += cx;
            y += cy;
          }
          final x1 = lastWasCubic ? 2 * cx - lastCx : cx;
          final y1 = lastWasCubic ? 2 * cy - lastCy : cy;
          path.cubicTo(p(x1, y1).dx, p(x1, y1).dy, p(x2, y2).dx, p(x2, y2).dy, p(x, y).dx, p(x, y).dy);
          lastCx = x2;
          lastCy = y2;
          cx = x;
          cy = y;
          lastWasCubic = true;
        case 'Q':
          var x1 = n();
          var y1 = n();
          var x = n();
          var y = n();
          if (rel) {
            x1 += cx;
            y1 += cy;
            x += cx;
            y += cy;
          }
          path.quadraticBezierTo(p(x1, y1).dx, p(x1, y1).dy, p(x, y).dx, p(x, y).dy);
          lastCx = x1;
          lastCy = y1;
          cx = x;
          cy = y;
          lastWasCubic = false;
        case 'Z':
          path.close();
          cx = startX;
          cy = startY;
          lastWasCubic = false;
        default:
          if (i < tokens.length && !_isCommand(tokens[i])) {
            i++;
          } else {
            cmd = '';
          }
      }
    }
    return path;
  }

  static bool _isCommand(String t) => t.length == 1 && RegExp(r'[A-Za-z]').hasMatch(t);

  static List<String> _tokenize(String d) {
    final out = <String>[];
    final buf = StringBuffer();
    void flush() {
      if (buf.isNotEmpty) {
        out.add(buf.toString());
        buf.clear();
      }
    }

    for (var i = 0; i < d.length; i++) {
      final ch = d[i];
      if (RegExp(r'[A-Za-z]').hasMatch(ch)) {
        flush();
        out.add(ch);
      } else if (ch == ',' || ch == ' ' || ch == '\n' || ch == '\t' || ch == '\r') {
        flush();
      } else if (ch == '-') {
        if (buf.isNotEmpty && buf.toString().endsWith('e')) {
          buf.write(ch);
        } else {
          flush();
          buf.write(ch);
        }
      } else {
        buf.write(ch);
      }
    }
    flush();
    return out;
  }
}

class PathMetricsHelper {
  PathMetricsHelper._();

  static List<Offset> sample(Path path, {int count = 24}) {
    final metrics = path.computeMetrics();
    final points = <Offset>[];
    for (final metric in metrics) {
      if (metric.length <= 0) continue;
      for (var i = 0; i < count; i++) {
        final t = i / (count - 1);
        final tan = metric.getTangentForOffset(metric.length * t);
        if (tan != null) points.add(tan.position);
      }
    }
    return points;
  }

  static Offset? start(Path path) {
    for (final metric in path.computeMetrics()) {
      final tan = metric.getTangentForOffset(0);
      if (tan != null) return tan.position;
    }
    return null;
  }

  static Offset? tangent(Path path, double t) {
    for (final metric in path.computeMetrics()) {
      final tan = metric.getTangentForOffset(metric.length * t.clamp(0.0, 1.0));
      if (tan != null) return tan.vector;
    }
    return null;
  }

  static Path extract(Path path, double t) {
    final out = Path();
    for (final metric in path.computeMetrics()) {
      out.addPath(metric.extractPath(0, metric.length * t.clamp(0.0, 1.0)), Offset.zero);
    }
    return out;
  }

  static double proximity(List<Offset> user, Path target) {
    if (user.length < 2) return 999;
    final samples = sample(target, count: 20);
    if (samples.isEmpty) return 999;
    var sum = 0.0;
    for (final p in user) {
      var best = 1e9;
      for (final s in samples) {
        best = min(best, (p - s).distance);
      }
      sum += best;
    }
    return sum / user.length;
  }
}
