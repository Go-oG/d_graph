import 'dart:math';
import 'dart:ui';
import 'package:dart_graph/dart_graph.dart';
import 'package:dts/dts.dart' as dt;

final class Triangle extends BasicGeometry {
  final Offset a;
  final Offset b;
  final Offset c;
  late final List<SegmentLine> lines;

  Triangle({required this.a, required this.b, required this.c}) {
    lines = List.unmodifiable([
      SegmentLine(a, b),
      SegmentLine(b, c),
      SegmentLine(c, a),
    ]);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Triangle && runtimeType == other.runtimeType && a == other.a && b == other.b && c == other.c;

  @override
  int get hashCode => Object.hash(a, b, c);

  @override
  bool containsPoint(Offset p, {double eps = 1e-9}) {
    final ab = b - a;
    final bc = c - b;
    final ca = a - c;
    final ap = p - a;
    final bp = p - b;
    final cp = p - c;
    final cross1 = ab.cross(ap);
    final cross2 = bc.cross(bp);
    final cross3 = ca.cross(cp);
    bool sameSign(double x, double y) => x * y >= -eps;
    return sameSign(cross1, cross2) && sameSign(cross2, cross3);
  }

  @override
  bool contains(BasicGeometry geom) {
    if (geom is Circle) {
      return _isContainsCircle(geom.center, geom.radius);
    }
    return asGeometry.contains(geom.asGeometry);
  }

  @override
  double distance(BasicGeometry geom) {
    if (geom is Circle) {
      return _distanceWithCircle(geom.center, geom.radius);
    }

    return asGeometry.distance(geom.asGeometry);
  }

  @override
  double distanceWithPoint(Offset p) => asGeometry.distance(geomFactory.createPoint4(p));

  @override
  double distanceWithRect(Rect rect) {
    final p1 = geomFactory.createPolygon5([a, b, c]);
    final p2 = geomFactory.createPolygon5([rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft]);
    return p1.distance(p2);
  }

  @override
  bool isOverlap(BasicGeometry geom, {double eps = 1e-9}) {
    if (geom is Circle) {
      return _isOverlapCircle(geom.center, geom.radius);
    }
    return super.isOverlap(geom, eps: eps);
  }

  @override
  List<Offset> crossPoint(BasicGeometry geom) {
    if (geom is Circle) {
      return _crossPointWithCircle(geom.center, geom.radius);
    }
    final res = asGeometry.intersection(geom.asGeometry);
    return BasicGeometry.pickCrossPoint(res);
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
  double get length => (a - b).distance + (b - c).distance + (c - a).distance;

  @override
  double get area {
    return (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y)).abs() / 2.0;
  }

  @override
  Rect get bbox {
    final xMin = [a.x, b.x, c.x].reduce((v, e) => v < e ? v : e);
    final xMax = [a.x, b.x, c.x].reduce((v, e) => v > e ? v : e);
    final yMin = [a.y, b.y, c.y].reduce((v, e) => v < e ? v : e);
    final yMax = [a.y, b.y, c.y].reduce((v, e) => v > e ? v : e);
    return Rect.fromLTRB(xMin, yMin, xMax, yMax);
  }

  @override
  Offset get center => Offset((a.x + b.x + c.x) / 3.0, (a.y + b.y + c.y) / 3.0);

  @override
  Path onBuildPath() {
    Path path = Path();
    path.moveTo(a.x, a.y);
    path.lineTo(b.x, b.y);
    path.lineTo(c.x, c.y);
    path.close();
    return path;
  }

  bool _isOverlapCircle(Offset center, double r) {
    if ((a.x - center.x) * (a.x - center.x) + (a.y - center.y) * (a.y - center.y) <= r * r) {
      return true;
    }
    if ((b.x - center.x) * (b.x - center.x) + (b.y - center.y) * (b.y - center.y) <= r * r) {
      return true;
    }
    if ((c.x - center.x) * (c.x - center.x) + (c.y - center.y) * (c.y - center.y) <= r * r) {
      return true;
    }

    if (_pointInTriangle(center, a, b, c)) return true;

    final d1 = _pointToSegmentDistance(center, a, b);
    final d2 = _pointToSegmentDistance(center, b, c);
    final d3 = _pointToSegmentDistance(center, c, a);
    return d1 <= r || d2 <= r || d3 <= r;
  }

  List<Offset> _crossPointWithLine(SegmentLine line) => line.crossPointWithTriangle(this);

  List<Offset> _crossPointWithCircle(Offset center, double radius) {
    List<Offset> resultList = [];
    for (final line in lines) {
      resultList.addAll(line.crossPointWithCircle(center, radius));
    }
    return resultList;
  }

  double _distanceWithCircle(Offset center, double radius) {
    double dis = double.infinity;
    for (var line in lines) {
      double d = line.distanceWithCircle(center, radius);
      if (d <= 0) {
        return 0;
      }
      dis = min(d, dis);
    }
    return dis;
  }

  double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
    final vx = b.x - a.x;
    final vy = b.y - a.y;
    final wx = p.x - a.x;
    final wy = p.y - a.y;

    final c1 = vx * wx + vy * wy;
    if (c1 <= 0) {
      return sqrt(pow(p.x - a.x, 2) + pow(p.y - a.y, 2));
    }
    final c2 = vx * vx + vy * vy;
    if (c2 <= c1) {
      return sqrt(pow(p.x - b.x, 2) + pow(p.y - b.y, 2));
    }
    final t = c1 / c2;
    final projX = a.x + t * vx;
    final projY = a.y + t * vy;
    return sqrt(pow(p.x - projX, 2) + pow(p.y - projY, 2));
  }

  bool _pointInTriangle(Offset p, Offset a, Offset b, Offset c) {
    double cross(Offset p1, Offset p2, Offset p3) {
      return (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x);
    }

    final c1 = cross(a, b, p);
    final c2 = cross(b, c, p);
    final c3 = cross(c, a, p);
    final hasNeg = (c1 < 0) || (c2 < 0) || (c3 < 0);
    final hasPos = (c1 > 0) || (c2 > 0) || (c3 > 0);
    return !(hasNeg && hasPos);
  }

  bool _isContainsCircle(Offset center, double r) {
    if (!_pointInTriangle(center, a, b, c)) return false;
    final d1 = _pointToSegmentDistance(center, a, b);
    final d2 = _pointToSegmentDistance(center, b, c);
    final d3 = _pointToSegmentDistance(center, c, a);
    return d1 >= r && d2 >= r && d3 >= r;
  }

  @override
  dt.Geometry buildGeometry() {
    final ring = geomFactory.createLinearRing4([a, b, c, a]);
    return geomFactory.createPolygon(ring);
  }
}
