import 'dart:math';
import 'dart:ui';
import 'package:dart_graph/dart_graph.dart';
import 'package:dts/dts.dart' as dt;

final class Circle extends BasicGeometry {
  @override
  final Offset center;
  final double radius;

  Circle({required this.center, required this.radius});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Circle && runtimeType == other.runtimeType && center == other.center && radius == other.radius;

  @override
  int get hashCode => Object.hash(center, radius);

  @override
  double get area => pi * radius * radius;

  @override
  double get length => pi * 2 * radius;

  @override
  Rect get bbox => Rect.fromCircle(center: center, radius: radius);

  @override
  bool containsPoint(Offset p, {double eps = 1e-9}) {
    return (((p - center).distanceSquared) - (radius * radius)) <= eps;
  }

  bool containsRect(Rect rect) {
    bool contains(double x, double y) {
      final dx = x - center.dx;
      final dy = y - center.dy;
      final dist2 = dx * dx + dy * dy;
      return dist2 < radius * radius;
    }

    return contains(rect.left, rect.top) &&
        contains(rect.right, rect.top) &&
        contains(rect.right, rect.bottom) &&
        contains(rect.left, rect.bottom);
  }

  @override
  double distance(BasicGeometry geom) {
    if (geom is Circle) {
      return _distanceWithCircle(geom.center, geom.radius);
    }
    if (geom is SegmentLine) {
      return _distanceWithLine(geom);
    }
    if (geom is Polygon) {
      return _distanceWithPolygon(geom);
    }
    if (geom is Triangle) {
      return _distanceWithTriangle(geom);
    }
    return geom.asGeometry.distance(asGeometry);
  }

  @override
  double distanceWithPoint(Offset p) {
    if (containsPoint(p)) {
      return 0;
    }
    return (p - center).distance - radius;
  }

  @override
  double distanceWithRect(Rect rect) {
    List<SegmentLine> lineList = [
      SegmentLine(rect.topLeft, rect.topRight),
      SegmentLine(rect.topRight, rect.bottomRight),
      SegmentLine(rect.bottomRight, rect.bottomLeft),
      SegmentLine(rect.bottomLeft, rect.topLeft),
    ];

    double dis = double.infinity;

    for (var line in lineList) {
      final d = line.distanceWithCircle(center, radius);
      if (d <= 0) {
        return 0;
      }
      dis = min(dis, d);
    }
    return dis;
  }

  @override
  bool isOverlap(BasicGeometry geom, {double eps = 1e-9}) {
    if (geom is Circle) {
      return IntersectUtil.intersectWithCircle(center, radius, geom.center, geom.radius);
    }
    if (geom is BasicLine) {
      return _isCrossLine(geom, eps: eps);
    }
    if (geom is Polygon) {
      return _isCrossPolygon(geom);
    }
    if (geom is Triangle) {
      return _isCrossTriangle(geom);
    }
    if (geom is Arc) {
      return geom.annularSector.isIntersectsCircle(center, radius);
    }
    return super.isOverlap(geom, eps: eps);
  }

  @override
  List<Offset> crossPoint(BasicGeometry geom) {
    if (geom is Circle) {
      return _crossPointWithCircle(geom.center, geom.radius);
    }
    if (geom is SegmentLine) {
      return geom.crossPointWithCircle(center, radius);
    }
    if (geom is Polygon) {
      return _crossPointWithPolygon(geom);
    }
    if (geom is Triangle) {
      return _crossPointWithTriangle(geom);
    }
    if (geom is Arc) {
      return geom.crossPoint(this);
    }
    throw UnimplementedError();
  }

  @override
  List<Offset> crossPointWithRect(Rect rect) {
    List<Offset> list = [];
    List<SegmentLine> lineList = [
      SegmentLine(rect.topLeft, rect.topRight),
      SegmentLine(rect.topRight, rect.bottomRight),
      SegmentLine(rect.bottomRight, rect.bottomLeft),
      SegmentLine(rect.bottomLeft, rect.topLeft),
    ];
    for (final line in lineList) {
      list.addAll(_crossPointWithLine(line));
    }
    return list;
  }

  @override
  Path onBuildPath() {
    Path path = Path();
    path.addOval(bbox);
    return path;
  }

  bool _isCrossLine(BasicLine line, {double eps = 1e-9}) {
    return IntersectUtil.intersectLineWithCircle(line.start, line.end, center, radius);
  }

  bool _isCrossTriangle(Triangle triangle) {
    for (final line in triangle.lines) {
      if (_isCrossLine(line)) {
        return true;
      }
    }
    return false;
  }

  bool _isCrossPolygon(Polygon polygon) {
    for (final line in polygon.lines) {
      if (_isCrossLine(line)) {
        return true;
      }
    }
    return false;
  }

  List<Offset> _crossPointWithLine(SegmentLine line) => line.crossPointWithCircle(center, radius);

  List<Offset> _crossPointWithTriangle(Triangle triangle) {
    List<Offset> list = [];
    for (final line in triangle.lines) {
      list.addAll(_crossPointWithLine(line));
    }
    return list;
  }

  List<Offset> _crossPointWithCircle(Offset center, double radius) {
    final x0 = center.dx;
    final y0 = center.dy;

    final x1 = this.center.dx;
    final y1 = this.center.dy;

    final dx = x1 - x0;
    final dy = y1 - y0;
    final d = (center - this.center).distance;
    final rSum = radius + this.radius;

    if (d > rSum || d < (radius - this.radius).abs()) return [];

    final r0 = radius;
    final r1 = this.radius;

    final a = (r0 * r0 - r1 * r1 + d * d) / (2 * d);
    final h = sqrt(r0 * r0 - a * a);
    final x2 = x0 + a * dx / d;
    final y2 = y0 + a * dy / d;

    final rx = -dy * (h / d);
    final ry = dx * (h / d);

    final list = [
      Offset(x2 + rx, y2 + ry),
      Offset(x2 - rx, y2 - ry),
    ];
    if (list.first == list.last) {
      list.removeLast();
    }
    return list;
  }

  List<Offset> _crossPointWithPolygon(Polygon polygon) {
    List<Offset> list = [];
    for (final line in polygon.lines) {
      list.addAll(_crossPointWithLine(line));
    }
    return list;
  }

  double _distanceWithLine(SegmentLine line) => line.distanceWithCircle(center, radius);

  double _distanceWithCircle(Offset center, double radius) {
    final u = center - this.center;
    final rSum = radius + this.radius;
    if (u.distanceSquared <= rSum * rSum) {
      return 0;
    }
    return u.distance - rSum;
  }

  double _distanceWithTriangle(Triangle triangle) {
    double dis = double.infinity;
    for (var line in triangle.lines) {
      final d = line.distanceWithPoint(center);
      if (d <= radius) {
        return 0;
      }
      dis = min(d, dis);
    }
    return dis;
  }

  double _distanceWithPolygon(Polygon polygon) {
    double dis = double.infinity;
    for (var line in polygon.lines) {
      final d = line.distanceWithPoint(center);
      if (d <= radius) {
        return 0;
      }
      dis = min(d, dis);
    }
    return dis;
  }

  @override
  dt.Geometry buildGeometry() {
    List<Offset> list = AnnularSectorFactory.buildPoints(radius, Angle.zero, Angle.radians(2 * pi - 0.0001), center);
    return geomFactory.createPolygon5(list);
  }
}
