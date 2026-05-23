import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';
import 'package:dts/dts.dart' as dt;
import 'package:flutter/foundation.dart';

class Polygon extends BasicGeometry {
  static final Polygon zero = Polygon([]);
  late final List<Offset> vertices;
  late final List<SegmentLine> lines;

  @override
  late final Rect bbox = _calcBBox();
  @override
  late final double area = _calcArea();
  @override
  late final double length = _calcLength();
  @override
  late final Offset center = _calcCenter();

  List<Offset>? _hull;

  List<Offset> get hull => _hull ??= _getHull();

  Polygon(Iterable<Offset> vertex) {
    vertices = List.unmodifiable(vertex);
    int n = vertices.length;
    List<SegmentLine> tmp = [];
    for (int i = 0; i < n; i++) {
      tmp.add(SegmentLine(vertices[i], vertices[(i + 1) % n]));
    }
    lines = List.unmodifiable(tmp);
  }

  Offset operator [](int index) {
    return vertices[index];
  }

  @override
  int get hashCode => Object.hashAll(vertices);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is Polygon && listEquals(vertices, other.vertices);
  }

  bool containsRect(Rect rect) {
    for (var item in [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ]) {
      if (!containsPoint(item)) {
        return false;
      }
    }
    return true;
  }

  ///给定一个矩形范围 裁剪多边形
  List<Polygon> clipRange(Rect rect) {
    final clipResult = asGeometry.intersection(rect.asGeometry);
    if (clipResult == null || clipResult.isEmpty()) {
      return [];
    }
    List<Polygon> polygons = [];
    for (int i = 0; i < clipResult.getNumGeometries(); i++) {
      final g = clipResult.getGeometryN(i);
      if (g is dt.Polygon) {
        polygons.add(Polygon(g.getCoordinates().map((e) => e.asOffset)));
      } else if (g is dt.MultiPolygon) {
        for (final po in g.geometries) {
          polygons.add(Polygon(po.getCoordinates().map((e) => e.asOffset)));
        }
      }
    }
    return polygons;
  }

  @override
  Path onBuildPath() {
    Path path = Path();
    if (vertices.isEmpty) {
      return path;
    }
    bool hasMove = false;
    for (final p in vertices) {
      hasMove ? path.lineTo(p.x, p.y) : path.moveTo(p.x, p.y);
      hasMove = true;
    }
    if (vertices.first == vertices.last) {
      path.close();
    }
    return path;
  }

  List<Offset> _getHull() {
    if (vertices.length <= 1) {
      return vertices;
    }
    final points = vertices.toSet().toList()
      ..sort((a, b) {
        final xCompare = a.dx.compareTo(b.dx);
        return xCompare != 0 ? xCompare : a.dy.compareTo(b.dy);
      });
    if (points.length <= 1) {
      return List.unmodifiable(points);
    }

    double cross(Offset o, Offset a, Offset b) {
      return (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
    }

    final lower = <Offset>[];
    for (final p in points) {
      while (lower.length >= 2 &&
          cross(lower[lower.length - 2], lower.last, p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    final upper = <Offset>[];
    for (final p in points.reversed) {
      while (upper.length >= 2 &&
          cross(upper[upper.length - 2], upper.last, p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }

    lower.removeLast();
    upper.removeLast();
    return List.unmodifiable([...lower, ...upper]);
  }

  Rect _calcBBox() {
    if (vertices.isEmpty) {
      return Rect.zero;
    }
    double minX = vertices.first.dx;
    double maxX = vertices.first.dx;
    double minY = vertices.first.dy;
    double maxY = vertices.first.dy;
    for (var i = 1; i < vertices.length; i++) {
      final p = vertices[i];
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  double _calcArea() {
    if (vertices.length < 3) {
      return 0.0;
    }
    double sum = 0.0;
    for (var i = 0; i < vertices.length; i++) {
      final a = vertices[i];
      final b = vertices[(i + 1) % vertices.length];
      sum += a.dx * b.dy - b.dx * a.dy;
    }
    return sum.abs() / 2.0;
  }

  double _calcLength() {
    if (vertices.length < 2) {
      return 0.0;
    }
    double sum = 0.0;
    for (var i = 0; i < vertices.length; i++) {
      sum += (vertices[(i + 1) % vertices.length] - vertices[i]).distance;
    }
    return sum;
  }

  Offset _calcCenter() {
    if (vertices.isEmpty) {
      return Offset.zero;
    }
    double signedArea = 0.0;
    double cx = 0.0;
    double cy = 0.0;
    for (var i = 0; i < vertices.length; i++) {
      final a = vertices[i];
      final b = vertices[(i + 1) % vertices.length];
      final cross = a.dx * b.dy - b.dx * a.dy;
      signedArea += cross;
      cx += (a.dx + b.dx) * cross;
      cy += (a.dy + b.dy) * cross;
    }

    if (signedArea.abs() < 1e-12) {
      double sx = 0.0;
      double sy = 0.0;
      for (final p in vertices) {
        sx += p.dx;
        sy += p.dy;
      }
      return Offset(sx / vertices.length, sy / vertices.length);
    }

    final factor = 1 / (3 * signedArea);
    return Offset(cx * factor, cy * factor);
  }

  @override
  dt.Geometry buildGeometry() {
    if (vertices.isEmpty) {
      return geomFactory.createEmpty(2);
    }
    return geomFactory.createPolygon5(vertices, false);
  }
}
