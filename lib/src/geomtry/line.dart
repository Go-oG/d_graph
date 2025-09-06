import 'dart:math';
import 'dart:ui';
import 'package:dart_graph/dart_graph.dart';
import 'package:dts/dts.dart' as dt;
import 'basic.dart';
import 'circle.dart';
import 'polygon.dart';
import 'triangle.dart';
import '../extensions.dart';

abstract class BasicLine extends BasicGeometry {
  final Offset start;
  final Offset end;

  BasicLine(this.start, this.end);

  @override
  late final Rect bbox = Rect.fromPoints(start, end);
  @override
  late final double area = 0;
  @override
  late final double length = (start - end).distance;
  @override
  late final Offset center = (start + end) / 2;

  Offset get vector => end - start;

  Offset get unitVector {
    final v = vector;
    final d = v.distance;
    if (d <= 0) {
      return Offset.zero;
    }
    return v / d;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is BasicLine && other.start == start && other.end == end && other.runtimeType == runtimeType;
  }

  @override
  bool isOverlap(BasicGeometry geom, {double eps = 1e-9}) {
    if (geom is Circle) {
      return geom.isOverlap(this, eps: eps);
    }
    if (geom is BasicLine) {
      return IntersectUtil.intersectWithLine(start, end, geom.start, geom.end);
    }
    if (geom is Arc) {
      return geom.annularSector.isIntersectsLine(start, end);
    }
    return super.isOverlap(geom, eps: eps);
  }
}

class SegmentLine extends BasicLine {
  SegmentLine(super.start, super.end);

  @override
  Path onBuildPath() {
    Path path = Path();
    path.moveTo(start.x, start.y);
    path.lineTo(end.x, end.y);
    return path;
  }

  @override
  bool contains(BasicGeometry geom) => false;

  @override
  bool containsPoint(Offset p, {double eps = 1e-9}) {
    eps = max(0, eps);
    final dx = p.dx;
    final dy = p.dy;
    if (dy > max(start.dy, end.dy) + eps || dy < min(start.dy, end.dy) - eps) {
      return false;
    }
    if (dx > max(start.dx, end.dx) + eps || dx < min(start.dx, end.dx) - eps) {
      return false;
    }
    return distanceWithPoint(p) <= eps;
  }

  @override
  double distance(BasicGeometry geom) {
    if (geom is Circle) {
      return distanceWithCircle(geom.center, geom.radius);
    }
    if (geom is SegmentLine) {
      return distanceWithLine(geom);
    }
    if (geom is Triangle) {
      return distanceWithTriangle(geom);
    }
    if (geom is Polygon) {
      return distanceWithPolygon(geom);
    }
    return asGeometry.distance(geom.asGeometry);
  }

  @override
  double distanceWithPoint(Offset p) {
    final line = geomFactory.createLinearRing4([start, end]);
    return line.distance(geomFactory.createPoint4(p));
  }

  @override
  double distanceWithRect(Rect rect) {
    final line = geomFactory.createLineString3([start, end]);
    final rr = geomFactory.createPolygon5([rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft]);
    return rr.distance(line);
  }

  double distanceWithCircle(Offset center, double radius) {
    double dis = distanceWithPoint(center);
    if (dis <= 0 || dis.isNaN || dis <= radius) {
      return 0;
    }
    return dis - radius;
  }

  double distanceWithTriangle(Triangle triangle) {
    if (triangle.containsPoint(start) || triangle.containsPoint(end)) return 0.0;
    double minDist = double.infinity;
    for (var edge in triangle.lines) {
      double dist = distanceWithLine(edge);
      minDist = min(minDist, dist);
    }
    return minDist;
  }

  double distanceWithPolygon(Polygon polygon) {
    if (polygon.containsPoint(start) || polygon.containsPoint(end)) {
      return 0;
    }

    double minDist = double.infinity;
    for (var edge in polygon.lines) {
      double dist = distanceWithLine(edge);
      if (dist <= 0) {
        return 0;
      }
      minDist = min(minDist, dist);
    }
    return minDist;
  }

  ///求点Q到线的距离
  /// 如果是射线 或者直线 则为垂直距离
  /// 如果为线段 则为最近距离
  double distanceWithLine(SegmentLine line) {
    double dis = double.infinity;
    dis = min(dis, distanceWithPoint(line.start));
    dis = min(dis, distanceWithPoint(line.end));
    dis = min(dis, line.distanceWithPoint(start));
    dis = min(dis, line.distanceWithPoint(end));
    return dis;
  }

  /// 计算和起点[start] 距离为 d 且在线上的点的坐标
  Offset distancePoint(double d) {
    Offset off = end - start;
    final magnitude = off.distance;
    if (magnitude == 0) {
      throw ArgumentError("起点和终止点不能重合");
    }
    off = off * (d / magnitude);
    return start + off;
  }

  @override
  List<Offset> crossPoint(BasicGeometry geom) {
    if (geom is Circle) {
      return crossPointWithCircle(geom.center, geom.radius);
    }
    if (geom is Triangle) {
      return crossPointWithTriangle(geom);
    }
    if (geom is Polygon) {
      return crossPointWithPolygon(geom);
    }

    return BasicGeometry.pickCrossPoint(asGeometry.intersection(geom.asGeometry));
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
      final p = crossPointWithLine(line);
      if (p != null) {
        list.add(p);
      }
    }
    return list;
  }

  Offset? crossPointWithLine(BasicLine line) {
    final p1 = start, p2 = end, p3 = line.start, p4 = line.end;
    double x1 = p1.dx, y1 = p1.dy;
    double x2 = p2.dx, y2 = p2.dy;
    double x3 = p3.dx, y3 = p3.dy;
    double x4 = p4.dx, y4 = p4.dy;
    double denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
    if (denom == 0) {
      return null;
    }

    double ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom;
    double ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom;

    if (ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1) {
      double x = x1 + ua * (x2 - x1);
      double y = y1 + ua * (y2 - y1);
      return Offset(x, y);
    }
    return null;
  }

  List<Offset> crossPointWithTriangle(Triangle triangle) {
    List<Offset> list = [];
    for (final line in triangle.lines) {
      final point = crossPointWithLine(line);
      if (point != null) {
        list.add(point);
      }
    }
    return list;
  }

  List<Offset> crossPointWithCircle(Offset center, double radius, {double eps = 1e-10}) {
    final d = end - start;
    final fx = start.x - center.x;
    final fy = start.y - center.y;
    final dx = d.x, dy = d.y;
    final aCoeff = dx * dx + dy * dy;
    final bCoeff = 2 * (fx * dx + fy * dy);
    final cCoeff = fx * fx + fy * fy - radius * radius;

    final disc = bCoeff * bCoeff - 4 * aCoeff * cCoeff;
    if (disc < -eps) return [];
    bool acceptT(double t) => t >= 0 && t <= 1;
    final result = <Offset>[];
    if (disc.abs() <= eps) {
      final t = -bCoeff / (2 * aCoeff);
      if (acceptT(t)) result.add(start + d * t);
    } else {
      final sqrtDisc = sqrt(disc);
      final t1 = (-bCoeff - sqrtDisc) / (2 * aCoeff);
      final t2 = (-bCoeff + sqrtDisc) / (2 * aCoeff);
      if (acceptT(t1)) result.add(start + d * t1);
      if (acceptT(t2)) result.add(start + d * t2);
    }
    return result;
  }

  List<Offset> crossPointWithPolygon(Polygon polygon) {
    List<Offset> list = [];
    for (final line in polygon.lines) {
      final p = crossPointWithLine(line);
      if (p != null) {
        list.add(p);
      }
    }

    return list;
  }

  /// 计算直线上点P的垂点Q，满足 PQ垂直于L 且距离为D
  /// [xA, yA] 和 [xB, yB] 是直线L上的两点，用于确定直线方向
  /// [dis] 是PQ的距离（可为正负，方向由垂线方向决定）
  Offset verticalPoint(Offset p, double dis) {
    Offset unit = Offset(end.dx - start.dx, start.dy - end.dy);
    final magnitude = unit.distance;
    if (magnitude == 0) {
      throw ArgumentError("直线L的两点重合，无法确定方向");
    }
    unit = unit * (dis / magnitude);
    return unit + p;
  }

  @override
  dt.Geometry buildGeometry() => geomFactory.createLineString3([start, end]);
}

final class RayLine extends BasicLine {
  late final SegmentLine _proxyLine;

  RayLine(super.start, super.end) {
    final res = _extendLineSimple(start, end);
    _proxyLine = SegmentLine(start, res.last);
  }

  @override
  double get area => 0;

  @override
  dt.Geometry get asGeometry => _proxyLine.asGeometry;

  @override
  Rect get bbox => _proxyLine.bbox;

  @override
  dt.Geometry buildGeometry() => throw UnimplementedError();

  @override
  Offset get center => _proxyLine.center;

  @override
  bool contains(BasicGeometry geom) => _proxyLine.contains(geom);

  @override
  bool containsPoint(Offset p, {double eps = 1e-9}) => _proxyLine.containsPoint(p, eps: eps);

  @override
  List<Offset> crossPoint(BasicGeometry geom) => _proxyLine.crossPoint(geom);

  @override
  List<Offset> crossPointWithRect(Rect rect) => _proxyLine.crossPointWithRect(rect);

  @override
  double distance(BasicGeometry geom) => _proxyLine.distance(geom);

  @override
  double distanceWithPoint(Offset p) => _proxyLine.distanceWithPoint(p);

  @override
  double distanceWithRect(Rect rect) => _proxyLine.distanceWithRect(rect);

  @override
  bool isOverlap(BasicGeometry geom, {double eps = 1e-9}) => _proxyLine.isOverlap(geom, eps: eps);

  @override
  bool isOverlapRect(Rect rect) => _proxyLine.isOverlapRect(rect);

  @override
  double get length => double.infinity;

  @override
  Path onBuildPath() => throw UnimplementedError();

  @override
  Path get path => throw UnimplementedError();

  SegmentLine get segmentLine => _proxyLine;
}

final class Line extends BasicLine {
  late final SegmentLine _proxyLine;

  Line(super.start, super.end) {
    final res = _extendLineSimple(start, end);
    _proxyLine = SegmentLine(res.first, res.last);
  }

  @override
  double get area => 0;

  @override
  dt.Geometry get asGeometry => _proxyLine.asGeometry;

  @override
  Rect get bbox => _proxyLine.bbox;

  @override
  dt.Geometry buildGeometry() => throw UnimplementedError();

  @override
  Offset get center => _proxyLine.center;

  @override
  bool contains(BasicGeometry geom) => _proxyLine.contains(geom);

  @override
  bool containsPoint(Offset p, {double eps = 1e-9}) => _proxyLine.containsPoint(p, eps: eps);

  @override
  List<Offset> crossPoint(BasicGeometry geom) => _proxyLine.crossPoint(geom);

  @override
  List<Offset> crossPointWithRect(Rect rect) => _proxyLine.crossPointWithRect(rect);

  @override
  double distance(BasicGeometry geom) => _proxyLine.distance(geom);

  @override
  double distanceWithPoint(Offset p) => _proxyLine.distanceWithPoint(p);

  @override
  double distanceWithRect(Rect rect) => _proxyLine.distanceWithRect(rect);

  @override
  bool isOverlap(BasicGeometry geom, {double eps = 1e-9}) => _proxyLine.isOverlap(geom, eps: eps);

  @override
  bool isOverlapRect(Rect rect) => _proxyLine.isOverlapRect(rect);

  @override
  double get length => double.infinity;

  @override
  Path onBuildPath() => throw UnimplementedError();

  @override
  Path get path => throw UnimplementedError();

  SegmentLine get segmentLine => _proxyLine;
}

/// 简洁版：把直线 p1->p2 延伸成“超长”线段
/// [L] 是半长度，返回 [start, end]
List<Offset> _extendLineSimple(Offset p1, Offset p2, {double L = 1e10}) {
  final dx = p2.dx - p1.dx;
  final dy = p2.dy - p1.dy;
  final dist = sqrt(dx * dx + dy * dy);

  if (dist < 1e-12) {
    return [Offset(p1.dx - L, p1.dy), Offset(p1.dx + L, p1.dy)];
  }

  final ux = dx / dist;
  final uy = dy / dist;
  final center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
  final start = Offset(center.dx - ux * L, center.dy - uy * L);
  final end = Offset(center.dx + ux * L, center.dy + uy * L);
  return [start, end];
}
