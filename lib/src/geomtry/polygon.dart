import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';
import 'package:dts/dts.dart' as dt;
import 'package:flutter/foundation.dart';


class Polygon extends BasicGeometry {
  static final Polygon zero = Polygon([]);
  late final List<Offset> vertex;
  late final List<SegmentLine> lines;

  @override
  late final Rect bbox = asGeometry.getEnvelopeInternal().asRect;
  @override
  late final double area = asGeometry.getArea();
  @override
  late final double length = asGeometry.getLength();
  @override
  late final Offset center = asGeometry.getCentroid().asOffset;

  late final List<Offset> hull = _getHull();

  Polygon(Iterable<Offset> vertex) {
    this.vertex = List.unmodifiable(vertex);
    int n = this.vertex.length;
    List<SegmentLine> tmp = [];
    for (int i = 0; i < n; i++) {
      tmp.add(SegmentLine(this.vertex[i], this.vertex[(i + 1) % n]));
    }
    lines = List.unmodifiable(tmp);
  }

  Offset operator [](int index) {
    return vertex[index];
  }

  @override
  int get hashCode => Object.hashAll(vertex);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is Polygon && listEquals(vertex, other.vertex);
  }

  bool containsRect(Rect rect) {
    for (var item in [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft]) {
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
    bool hasMove = false;
    for (final p in vertex) {
      hasMove ? path.lineTo(p.x, p.y) : path.moveTo(p.x, p.y);
      hasMove = true;
    }
    if (vertex.first == vertex.last) {
      path.close();
    }
    return path;
  }

  List<Offset> _getHull() {
    final ch = dt.ConvexHull.of(asGeometry);
    final hull = ch.getConvexHull();
    if (hull is dt.Polygon) {
      return hull.getExteriorRing().getCoordinates().map((e) => e.asOffset).toList();
    }
    return hull.getCoordinates().map((e) => e.asOffset).toList();
  }

  @override
  dt.Geometry buildGeometry() {
      return geomFactory.createPolygon5(vertex,false);
  }
}
