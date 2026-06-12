import 'dart:math' as math;
import 'dart:math';

import 'package:dart_graph/dart_graph.dart';
import 'package:dts/dts.dart' as dt;
import 'package:flutter/painting.dart';

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
    final coords = buildPoints(or, startAngle, endAngle, center);
    coords.addAll(buildPoints(ir, startAngle, endAngle, center).reversed);
    coords.add(coords[0]);
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
    final sweep = (endAngle - startAngle).abs.radians;
    if (sweep <= 0) return 1;
    if (radius <= 1) {
      return max(3, (sweep / (pi / 4)).ceil());
    }
    double theta = 2 * acos((1 - 1 / radius).clamp(-1.0, 1.0));
    int seg = (sweep / theta).ceil();
    if (seg < 3) seg = 3;
    return seg;
  }
}

final class AnnularSector {
  final Offset center;
  final double innerRadius;
  final double outerRadius;
  final Angle startAngle;
  final Angle endAngle;

  late final double _startRad;
  late final double _endRad;
  late final double _sweepRad;
  late final Rect _aabb;

  AnnularSector({
    required this.center,
    required this.innerRadius,
    required this.outerRadius,
    required this.startAngle,
    required this.endAngle,
  }) : assert(innerRadius >= 0 && outerRadius >= innerRadius) {
    _startRad = startAngle.radians;
    _endRad = endAngle.radians;

    double sweep = _endRad - _startRad;
    while (sweep < 0) {
      sweep += 2 * math.pi;
    }
    while (sweep >= 2 * math.pi) {
      sweep -= 2 * math.pi;
    }

    if (sweep == 0 && startAngle.radians != endAngle.radians) {
      sweep = 2 * math.pi;
    }

    _sweepRad = sweep;
    _aabb = _computeAABB();
  }

  Rect _computeAABB() {
    final points = getBoundaryPoints();
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    void add(double x, double y) {
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    for (var p in points) {
      add(p.dx, p.dy);
    }

    final checkAngles = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2];
    for (final angle in checkAngles) {
      if (ContainsUtil.angleInSweep(
        target: angle.asRadians,
        startAngle: _startRad.asRadians,
        sweepAngle: _sweepRad.asRadians,
      )) {
        final p = CoordUtil.circlePoint(outerRadius, angle.asRadians, center: center);
        add(p.dx, p.dy);
      }
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Rect get aabb => _aabb;

  double get area => 0.5 * _sweepRad * (outerRadius * outerRadius - innerRadius * innerRadius);

  double get perimeter => _sweepRad * (outerRadius + innerRadius) + 2 * (outerRadius - innerRadius);

  bool contains(Offset p, {double epsilon = 1e-9}) {
    if (!ContainsUtil.rectContainsPoint(_aabb, p, epsilon)) return false;

    final v = p - center;
    final d2 = v.distanceSquared;
    if (d2 < (innerRadius - epsilon) * (innerRadius - epsilon) ||
        d2 > (outerRadius + epsilon) * (outerRadius + epsilon)) {
      return false;
    }

    final angle = math.atan2(v.dy, v.dx);
    return ContainsUtil.angleInSweep(
      target: angle.asRadians,
      startAngle: _startRad.asRadians,
      sweepAngle: _sweepRad.asRadians,
      epsilon: epsilon,
    );
  }

  bool isIntersectsCircle(Offset circleCenter, double circleRadius) {
    if (!IntersectUtil.rectsIntersect(_aabb, Rect.fromCircle(center: circleCenter, radius: circleRadius))) {
      return false;
    }
    Offset closest = _closestPointOnSector(circleCenter);
    return (circleCenter - closest).distanceSquared <= circleRadius * circleRadius;
  }

  bool isIntersectsPolygon(List<Offset> polygon) {
    if (polygon.isEmpty) return false;
    for (int i = 0; i < polygon.length; i++) {
      Offset p1 = polygon[i];
      Offset p2 = polygon[(i + 1) % polygon.length];
      if (isIntersectsLine(p1, p2)) return true;
    }

    if (contains(polygon.first)) return true;
    return ContainsUtil.pointInPolygon(center, polygon);
  }

  bool isIntersectsLine(Offset p1, Offset p2) {
    if (!IntersectUtil.rectsIntersect(_aabb, Rect.fromPoints(p1, p2))) {
      return false;
    }
    if (contains(p1) || contains(p2)) return true;
    final corners = getBoundaryPoints();
    if (IntersectUtil.intersectWithLine(p1, p2, corners[2], corners[0])) {
      return true;
    }
    if (IntersectUtil.intersectWithLine(p1, p2, corners[3], corners[1])) {
      return true;
    }
    if (_lineIntersectArc(p1, p2, innerRadius)) return true;
    if (_lineIntersectArc(p1, p2, outerRadius)) return true;

    return false;
  }

  Offset _closestPointOnSector(Offset p) {
    Offset v = p - center;
    double r = v.distance;
    double theta = math.atan2(v.dy, v.dx);

    double clampedR = r.clamp(innerRadius, outerRadius);

    double relTheta = theta - _startRad;
    while (relTheta < 0) {
      relTheta += 2 * math.pi;
    }
    while (relTheta >= 2 * math.pi) {
      relTheta -= 2 * math.pi;
    }
    double clampedTheta = theta;

    if (relTheta > _sweepRad) {
      double distToStart = 2 * math.pi - relTheta;
      double distToEnd = relTheta - _sweepRad;

      if (distToStart < distToEnd) {
        clampedTheta = _startRad;
      } else {
        clampedTheta = _endRad;
      }
    }
    return center + Offset(math.cos(clampedTheta), math.sin(clampedTheta)) * clampedR;
  }

  List<Offset> getBoundaryPoints() {
    return [
      CoordUtil.circlePoint(outerRadius, _startRad.asRadians, center: center),
      CoordUtil.circlePoint(outerRadius, _endRad.asRadians, center: center),
      CoordUtil.circlePoint(innerRadius, _startRad.asRadians, center: center),
      CoordUtil.circlePoint(innerRadius, _endRad.asRadians, center: center),
    ];
  }

  bool _lineIntersectArc(Offset p1, Offset p2, double r) {
    if (r <= 0) return false;
    List<Offset> hits = IntersectUtil.crossPointsLineWithCircle(p1, p2, center, r);

    for (var hit in hits) {
      final angle = math.atan2(hit.dy - center.dy, hit.dx - center.dx);
      if (ContainsUtil.angleInSweep(
        target: angle.asRadians,
        startAngle: _startRad.asRadians,
        sweepAngle: _sweepRad.asRadians,
      )) {
        return true;
      }
    }
    return false;
  }

  static bool intersect(AnnularSector s1, AnnularSector s2, {double epsilon = 1e-9}) {
    if (!IntersectUtil.rectsIntersect(s1.aabb, s2.aabb, epsilon: epsilon)) {
      return false;
    }

    if (!IntersectUtil.intersectWithCircle(s1.center, s1.outerRadius, s2.center, s2.outerRadius)) {
      return false;
    }

    double s2MidAngle = s2._startRad + s2._sweepRad / 2;
    double s2MidRadius = (s2.innerRadius + s2.outerRadius) / 2;
    Offset s2MidPoint = CoordUtil.circlePoint(s2MidRadius, s2MidAngle.asRadians, center: s2.center);
    if (s1.contains(s2MidPoint)) return true;

    double s1MidAngle = s1._startRad + s1._sweepRad / 2;
    double s1MidRadius = (s1.innerRadius + s1.outerRadius) / 2;
    Offset s1MidPoint = CoordUtil.circlePoint(s1MidRadius, s1MidAngle.asRadians, center: s1.center);
    if (s2.contains(s1MidPoint)) return true;

    List<Offset> s1Pts = s1.getBoundaryPoints();
    List<List<Offset>> s1Lines = [
      [s1Pts[2], s1Pts[0]],
      [s1Pts[3], s1Pts[1]],
    ];

    List<double> s1Radii = [s1.innerRadius, s1.outerRadius];

    for (var line in s1Lines) {
      if (s2.isIntersectsLine(line[0], line[1])) return true;
    }

    List<Offset> s2Pts = s2.getBoundaryPoints();
    List<List<Offset>> s2Lines = [
      [s2Pts[2], s2Pts[0]],
      [s2Pts[3], s2Pts[1]],
    ];
    for (var line in s2Lines) {
      if (s1.isIntersectsLine(line[0], line[1])) return true;
    }

    for (double r1 in s1Radii) {
      for (double r2 in [s2.innerRadius, s2.outerRadius]) {
        if (_arcArcIntersect(s1, r1, s2, r2)) return true;
      }
    }

    return false;
  }

  static bool _arcArcIntersect(AnnularSector s1, double r1, AnnularSector s2, double r2) {
    final hits = IntersectUtil.crossPointsWithCircle(s1.center, r1, s2.center, r2);

    bool check(Offset p) {
      double a1 = math.atan2(p.dy - s1.center.dy, p.dx - s1.center.dx);
      double a2 = math.atan2(p.dy - s2.center.dy, p.dx - s2.center.dx);
      return ContainsUtil.angleInSweep(
            target: a1.asRadians,
            startAngle: s1._startRad.asRadians,
            sweepAngle: s1._sweepRad.asRadians,
          ) &&
          ContainsUtil.angleInSweep(
            target: a2.asRadians,
            startAngle: s2._startRad.asRadians,
            sweepAngle: s2._sweepRad.asRadians,
          );
    }

    return hits.any(check);
  }
}
