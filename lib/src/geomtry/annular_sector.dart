import 'dart:math' as math;
import 'dart:math';
import 'package:dart_graph/dart_graph.dart';
import 'package:flutter/painting.dart';
import 'package:dts/dts.dart' as dt;

final class AnnularSector {
  final Offset center;
  final double innerRadius;
  final double outerRadius;
  final Angle startAngle;
  final Angle endAngle;

  AnnularSector({
    required this.center,
    required this.innerRadius,
    required this.outerRadius,
    required this.startAngle,
    required this.endAngle,
  }) : assert(innerRadius >= 0 && outerRadius >= innerRadius);

  bool contains(Offset p, {double epsilon = 1e-9}) {
    final v = p - center;
    final d = v.distance;
    if (d < innerRadius - epsilon || d > outerRadius + epsilon) return false;
    final ang = math.atan2(v.dy, v.dx).asRadians;
    return _angleInRange(ang, startAngle, endAngle, epsilon);
  }

  Angle get angle => (endAngle - startAngle).normalized;

  double get area => angle.radians * 0.5 * (outerRadius * outerRadius - innerRadius * innerRadius);

  double get perimeter => (innerRadius + outerRadius) * angle.radians + 2 * (outerRadius - innerRadius);

  double get cx => center.dx;

  double get cy => center.dy;

  /// 获取边界顶点（外弧端点 + 内弧端点）
  List<Offset> getBoundaryPoints() {
    return [
      center + Offset(startAngle.cos, startAngle.sin) * outerRadius,
      center + Offset(endAngle.cos, endAngle.sin) * outerRadius,
      center + Offset(startAngle.cos, startAngle.sin) * innerRadius,
      center + Offset(endAngle.cos, endAngle.sin) * innerRadius,
    ];
  }

  bool isIntersectsCircle(Offset circleCenter, double circleRadius) {
    if (contains(circleCenter)) {
      return true;
    }
    final int arcSamples = 24;

    if (IntersectUtil.intersectWithCircle(center, outerRadius, circleCenter, circleRadius)) {
      for (int i = 0; i <= arcSamples; i++) {
        Angle t = startAngle + (endAngle - startAngle) * i / arcSamples;
        final p = Offset(circleCenter.dx + outerRadius * t.cos, circleCenter.dy + outerRadius * t.sin);
        if ((p - circleCenter).distance <= circleRadius) return true;
      }
    }
    if (IntersectUtil.intersectWithCircle(circleCenter, innerRadius, circleCenter, circleRadius)) {
      for (int i = 0; i <= arcSamples; i++) {
        Angle t = startAngle + (endAngle - startAngle) * i / arcSamples;
        final p = Offset(circleCenter.dx + outerRadius * t.cos, circleCenter.dy + outerRadius * t.sin);
        if ((p - circleCenter).distance <= circleRadius) return true;
      }
    }

    final or = outerRadius;
    final ir = innerRadius;

    final pStartOuter = Offset(circleCenter.dx + or * startAngle.cos, circleCenter.dy + or * startAngle.sin);
    final pStartInner = Offset(circleCenter.dx + ir * startAngle.cos, circleCenter.dy + ir * startAngle.sin);
    final pEndOuter = Offset(circleCenter.dx + or * endAngle.cos, circleCenter.dy + or * endAngle.sin);
    final pEndInner = Offset(circleCenter.dx + ir * endAngle.cos, circleCenter.dy + ir * endAngle.sin);

    if (IntersectUtil.intersectLineWithCircle(pStartInner, pStartOuter, circleCenter, circleRadius)) return true;
    if (IntersectUtil.intersectLineWithCircle(pEndInner, pEndOuter, circleCenter, circleRadius)) return true;

    int insideCount = 0;
    final samplePoints = <Offset>[pStartOuter, pEndOuter, pStartInner, pEndInner];
    for (int i = 0; i <= arcSamples; i++) {
      Angle t = startAngle + (endAngle - startAngle) * i / arcSamples;
      samplePoints.add(Offset(circleCenter.dx + or * t.cos, circleCenter.dy + or * t.sin));
      samplePoints.add(Offset(circleCenter.dx + ir * t.cos, circleCenter.dy + ir * t.sin));
    }
    for (final p in samplePoints) {
      if ((p - circleCenter).distance <= circleRadius) insideCount++;
    }
    if (insideCount == samplePoints.length) return true;

    return false;
  }

  bool isIntersectsLine(Offset p1, Offset p2) {
    final outerHits = IntersectUtil.crossPointsLineWithCircle(p1, p2, center, outerRadius);
    for (final hit in outerHits) {
      if (contains(hit)) return true;
    }

    final innerHits = IntersectUtil.crossPointsLineWithCircle(p1, p2, center, innerRadius);
    for (final hit in innerHits) {
      if (contains(hit)) return true;
    }

    final startRad = Offset(cx + outerRadius * startAngle.cos, cy + outerRadius * startAngle.sin);
    final endRad = Offset(cx + outerRadius * endAngle.cos, cy + outerRadius * endAngle.sin);
    for (final rad in [startRad, endRad]) {
      final intersection = IntersectUtil.crossPointWithLines(center, rad, p1, p2);
      if (intersection != null) {
        final dist = sqrt(pow(intersection.x - cx, 2) + pow(intersection.y - cy, 2));
        if (dist >= innerRadius && dist <= outerRadius) return true;
      }
    }
    if (contains(p1) || contains(p2)) return true;
    return false;
  }

  bool isIntersectsPolygon(List<BasicLine> lines) {
    for (var line in lines) {
      if (isIntersectsLine(line.start, line.end)) {
        return true;
      }
    }
    return false;
  }

  static bool intersect(AnnularSector s1, AnnularSector s2, {double epsilon = 1e-9}) {
    for (final p in s1.getBoundaryPoints()) {
      if (s2.contains(p, epsilon: epsilon)) return true;
    }
    for (final p in s2.getBoundaryPoints()) {
      if (s1.contains(p, epsilon: epsilon)) return true;
    }

    bool circleIntersectsCircle(Offset c1, double r1, Offset c2, double r2) {
      final d = (c1 - c2).distance;
      return d <= r1 + r2 + epsilon && d >= (r1 - r2).abs() - epsilon;
    }

    if (circleIntersectsCircle(s1.center, s1.outerRadius, s2.center, s2.outerRadius)) {
      if (_arcArcIntersect(s1, true, s2, true, epsilon)) return true;
    }
    if (circleIntersectsCircle(s1.center, s1.outerRadius, s2.center, s2.innerRadius)) {
      if (_arcArcIntersect(s1, true, s2, false, epsilon)) return true;
    }
    if (circleIntersectsCircle(s1.center, s1.innerRadius, s2.center, s2.outerRadius)) {
      if (_arcArcIntersect(s1, false, s2, true, epsilon)) return true;
    }
    if (circleIntersectsCircle(s1.center, s1.innerRadius, s2.center, s2.innerRadius)) {
      if (_arcArcIntersect(s1, false, s2, false, epsilon)) return true;
    }

    if (_rayArcIntersect(s1, s2, epsilon)) return true;
    if (_rayArcIntersect(s2, s1, epsilon)) return true;

    final midAngle2 = (s2.startAngle + s2.endAngle) / 2;
    final midRadius2 = (s2.innerRadius + s2.outerRadius) / 2;
    final midPoint2 = s2.center + Offset(midAngle2.cos, midAngle2.sin) * midRadius2;
    if (s1.contains(midPoint2, epsilon: epsilon)) return true;

    final midAngle1 = (s1.startAngle + s1.endAngle) / 2;
    final midRadius1 = (s1.innerRadius + s1.outerRadius) / 2;
    final midPoint1 = s1.center + Offset(midAngle1.cos, midAngle1.sin) * midRadius1;
    if (s2.contains(midPoint1, epsilon: epsilon)) return true;

    return false;
  }

  static bool _angleInRange(Angle a, Angle s, Angle e, double epsilon) {
    double twoPi = math.pi * 2;

    Angle aa = a.normalized, ss = s.normalized, ee = e.normalized;
    Angle span = (ee - ss).normalized;
    if (span.radians <= epsilon) span = Angle.full;

    Angle rel = (aa - ss) % twoPi;
    if (rel < Angle.zero) rel = Angle.full;
    return rel <= span.add(epsilon);
  }

  static bool _arcArcIntersect(AnnularSector s1, bool useOuter1, AnnularSector s2, bool useOuter2, double epsilon) {
    final r1 = useOuter1 ? s1.outerRadius : s1.innerRadius;
    final r2 = useOuter2 ? s2.outerRadius : s2.innerRadius;

    final c1 = s1.center;
    final c2 = s2.center;
    final d = (c1 - c2).distance;

    if (d > r1 + r2 + epsilon || d < (r1 - r2).abs() - epsilon) return false;

    final a = (r1 * r1 - r2 * r2 + d * d) / (2 * d);
    final h2 = r1 * r1 - a * a;
    if (h2 < -epsilon) return false;
    final h = h2 < 0 ? 0 : math.sqrt(h2);

    final p2 = c1 + (c2 - c1) * (a / d);

    final rx = -(c2.dy - c1.dy) * (h / d);
    final ry = (c2.dx - c1.dx) * (h / d);

    final p3 = Offset(p2.dx + rx, p2.dy + ry);
    final p4 = Offset(p2.dx - rx, p2.dy - ry);

    return (s1.contains(p3, epsilon: epsilon) && s2.contains(p3, epsilon: epsilon)) ||
        (s1.contains(p4, epsilon: epsilon) && s2.contains(p4, epsilon: epsilon));
  }

  static bool _rayArcIntersect(AnnularSector raySector, AnnularSector arcSector, double epsilon) {
    for (final theta in [raySector.startAngle, raySector.endAngle]) {
      final dir = Offset(theta.cos, theta.sin);

      for (final useOuter in [true, false]) {
        final r = useOuter ? arcSector.outerRadius : arcSector.innerRadius;
        final d = arcSector.center - raySector.center;
        final A = dir.dx * dir.dx + dir.dy * dir.dy;
        final B = 2 * (d.dx * dir.dx + d.dy * dir.dy);
        final C = d.dx * d.dx + d.dy * d.dy - r * r;
        final disc = B * B - 4 * A * C;
        if (disc < -epsilon) continue;
        final sqrtDisc = disc < 0 ? 0 : math.sqrt(disc);
        final t1 = (-B - sqrtDisc) / (2 * A);
        final t2 = (-B + sqrtDisc) / (2 * A);

        for (final t in [t1, t2]) {
          if (t < -epsilon) continue;
          final p = raySector.center + dir * t;
          if (arcSector.contains(p, epsilon: epsilon) && raySector.contains(p, epsilon: epsilon)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}

class AnnularSectorFactory {
  static dt.Geometry createAnnularSector(Offset center, double ir, double or, Angle startAngle, Angle endAngle) {
    Angle sw = (endAngle - startAngle).abs;
    startAngle = startAngle.normalized;
    endAngle = endAngle.normalized;
    if (endAngle < startAngle) {
      endAngle += (2 * pi).asRadians;
    }
    if (ir <= 0.001) {
      if (sw.degrees >= 359.99) {
        return Circle(center: center, radius: or).asGeometry;
      }
      List<Offset> coords = [];
      coords.add(center);
      coords.addAll(buildPoints(or, startAngle, endAngle, center));
      coords.add(center);
      return geomFactory.createPolygon5(coords);
    }
    List<Offset> coords = buildPoints(or, startAngle, endAngle, center);
    coords.addAll(buildPoints(ir, startAngle, endAngle, center).reversed);
    coords.add(coords.get(0));
    return geomFactory.createPolygon5(coords, true);
  }

  static List<Offset> buildPoints(double radius, Angle startAngle, Angle endAngle, Offset center) {
    List<Offset> list = [];
    final int steps = _computeSegments(radius, startAngle, endAngle);
    Angle step = (endAngle - startAngle) / steps;
    for (int i = 0; i <= steps; i++) {
      Angle angle = startAngle + step * i;
      double x = center.x + radius * angle.cos;
      double y = center.y + radius * angle.sin;
      list.add(Offset(x, y));
    }
    return list;
  }

  static int _computeSegments(double radius, Angle startAngle, Angle endAngle) {
    if (radius <= 0) return 1;
    double theta = 2 * acos(1 / radius);
    int seg = ((endAngle - startAngle) / theta).radians.ceil();
    if (seg < 3) seg = 3;
    return seg;
  }
}
