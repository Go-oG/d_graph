import 'dart:typed_data';
import 'dart:ui';

import 'package:bezier/bezier.dart';
import 'package:dart_graph/dart_graph.dart';
import 'package:vector_math/vector_math.dart';

class Curve {
  static final empty = Curve(start: Offset.zero, end: Offset.zero, c1: Offset.zero, c2: Offset.zero);
  final Offset start;
  final Offset end;
  final Offset c1;
  final Offset c2;
  final CubicBezier bezier;
  late final Rect boundary;

  Curve({required this.start, required this.end, required this.c1, required this.c2})
      : bezier = CubicBezier([
          Vector2(start.dx, start.dy),
          Vector2(c1.dx, c1.dy),
          Vector2(c2.dx, c2.dy),
          Vector2(end.dx, end.dy),
        ]) {
    final box = bezier.boundingBox;
    boundary = Rect.fromPoints(Offset(box.min.x, box.min.y), Offset(box.max.x, box.max.y));
  }

  Curve.of(this.start, this.c1, this.c2, this.end)
      : bezier = CubicBezier([
          Vector2(start.dx, start.dy),
          Vector2(c1.dx, c1.dy),
          Vector2(c2.dx, c2.dy),
          Vector2(end.dx, end.dy),
        ]) {
    final box = bezier.boundingBox;
    boundary = Rect.fromPoints(Offset(box.min.x, box.min.y), Offset(box.max.x, box.max.y));
  }

  Path? _path;

  Path get path {
    if (_path != null) {
      return _path!;
    }
    Path p = Path();
    p.moveTo2(start);
    p.cubicTo(c1.x, c1.y, c2.x, c2.y, end.x, end.y);
    return _path = p;
  }

  @override
  int get hashCode => Object.hash(start, end, c1, c2);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Curve && other.c1 == c1 && other.start == start && other.end == end && other.c2 == c2;
  }

  Offset pointAt(double t) {
    if (t < 0 || t > 1) {
      throw "t must in [0,1]";
    }
    final v = bezier.pointAt(t);
    return Offset(v.x, v.y);
  }

  List<Curve> splitAtT(double t) {
    if (t >= 1.0 || t <= 0) {
      return [this];
    }

    final b1 = bezier.leftSubcurveAt(t).points.map((e) => Offset(e.x, e.y)).toList();
    final b2 = bezier.rightSubcurveAt(t).points.map((e) => Offset(e.x, e.y)).toList();

    return [
      Curve(start: b1[0], c1: b1[1], c2: b1[2], end: b1[3]),
      Curve(start: b2[0], c1: b2[1], c2: b2[2], end: b2[3]),
    ];
  }

  List<Curve> splitParts(int n) {
    if (n <= 0) throw ArgumentError('分割段数必须大于0');
    if (n == 1) return [this];

    final result = <Curve>[];
    Curve currentCurve = this;
    for (var i = 0; i < n - 1; i++) {
      final t = 1.0 / (n - i);
      final list = currentCurve.splitAtT(t);
      result.add(list.first);
      currentCurve = list.last;
    }
    result.add(currentCurve);
    return result;
  }

  double computeSimilarity(Curve cubic) {
    var d1 = (start - cubic.start).distance;
    var d4 = (end - cubic.end).distance;
    return d1 + d4;
  }

  bool contains(Offset point) {
    if (!boundary.contains2(point)) {
      return false;
    }
    if (isLine) {
      return ContainsUtil.pointOnSegment(point, start, end, epsilon: 2);
    }

    double t = bezier.nearestTValue(Vector2(point.dx, point.dy));
    final at = bezier.pointAt(t);
    return Offset(point.dx - at.x, point.dy - at.y).distanceSquared < 4;
  }

  Curve get reversed => Curve(start: end, c1: c2, c2: c1, end: start);

  bool? _lineFlag;

  bool get isLine {
    _lineFlag ??= (start == c1 && end == c2) || bezier.isLinear;
    return _lineFlag!;
  }

  double _length = -1;

  double get length {
    if (_length >= 0) {
      return _length;
    }
    _length = bezier.length;
    return _length;
  }

  Float32List? _dashPath;

  void setDashSegment(List<Offset> dashSegList) {
    Float32List list = Float32List(dashSegList.length * 2);
    int k = 0;
    for (int i = 0; i < dashSegList.length; i += 2) {
      final start = dashSegList[i];
      final end = dashSegList[i + 1];
      list[k] = start.dx;
      list[k + 1] = start.dy;
      list[k + 2] = end.dx;
      list[k + 3] = end.dy;
      k += 4;
    }
    _dashPath = list;
  }

  void clearDashSegment() {
    _dashPath = null;
  }

  void draw(Canvas canvas, Paint paint) {
    final obj = _dashPath;
    if (obj != null) {
      canvas.drawRawPoints(PointMode.lines, obj, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  void drawDashPath(Canvas canvas, Paint paint) {
    final obj = _dashPath;
    if (obj != null) {
      canvas.drawRawPoints(PointMode.lines, obj, paint);
    }
  }

  bool get hasDashPath => _dashPath != null;
}
