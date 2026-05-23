import 'dart:core';
import 'dart:math' as math;
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';

final class IntersectUtil {
  IntersectUtil._();

  static const double _defaultEpsilon = 1e-9;

  static bool intersectWithCircle(Offset c1, double r1, Offset c2, double r2) {
    final dx = c1.dx - c2.dx;
    final dy = c1.dy - c2.dy;
    final d2 = dx * dx + dy * dy;
    final rSum = r1 + r2;

    return d2 <= rSum * rSum + _defaultEpsilon;
  }

  static bool intersectWithPolygon({
    required List<Offset> polygon1,
    required List<Offset> polygon2,
    bool closePoly1 = true,
    bool closePoly2 = true,
  }) {
    final rect1 = _computeBoundingBox(polygon1);
    final rect2 = _computeBoundingBox(polygon2);
    if (!rect1.overlaps(rect2)) return false;

    final gf = geomFactory;
    final p1 = gf.createPolygon5(polygon1, closePoly1);
    final p2 = gf.createPolygon5(polygon2, closePoly2);
    return p1.intersects(p2);
  }

  static bool intersectWithLine(
    Offset p1,
    Offset p2,
    Offset q1,
    Offset q2, {
    double eps = _defaultEpsilon,
  }) {
    if (math.max(p1.dx, p2.dx) < math.min(q1.dx, q2.dx) ||
        math.max(q1.dx, q2.dx) < math.min(p1.dx, p2.dx) ||
        math.max(p1.dy, p2.dy) < math.min(q1.dy, q2.dy) ||
        math.max(q1.dy, q2.dy) < math.min(p1.dy, p2.dy)) {
      return false;
    }

    final r = p2 - p1;
    final s = q2 - q1;
    final rxs = _crossProduct(r, s);
    final qpxr = _crossProduct(q1 - p1, r);

    if (rxs.abs() <= eps) {
      if (qpxr.abs() <= eps) {
        final rDotr = r.dx * r.dx + r.dy * r.dy;
        if (rDotr <= eps) return false;

        final q1p1 = q1 - p1;
        double t0 = (q1p1.dx * r.dx + q1p1.dy * r.dy) / rDotr;
        double t1 = t0 + (s.dx * r.dx + s.dy * r.dy) / rDotr;

        if (t0 > t1) {
          final temp = t0;
          t0 = t1;
          t1 = temp;
        }
        return !(t1 < -eps || t0 > 1 + eps);
      }
      return false;
    }

    final qp = q1 - p1;
    final t = _crossProduct(qp, s) / rxs;
    final u = _crossProduct(qp, r) / rxs;
    return t >= -eps && t <= 1 + eps && u >= -eps && u <= 1 + eps;
  }

  static bool intersectRectWithArc(
    Rect rect, {
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    required double startAngleRad,
    required double endAngleRad,
    double epsilon = _defaultEpsilon,
  }) {
    final sectorBounds = Rect.fromCircle(center: center, radius: outerRadius);
    if (!rect.overlaps(sectorBounds)) return false;

    final twoPi = math.pi * 2;
    double normalize(double angle) => (angle % twoPi + twoPi) % twoPi;

    final normStart = normalize(startAngleRad);
    final normEnd = normalize(endAngleRad);

    double sweep = normEnd - normStart;
    if (sweep < 0) sweep += twoPi;
    if (sweep < 1e-5) sweep = twoPi;

    bool isAngleBetween(double target) {
      double diff = normalize(target) - normStart;
      if (diff < 0) diff += twoPi;
      return diff <= sweep + epsilon;
    }

    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];

    for (final p in corners) {
      final v = p - center;
      final d2 = v.distanceSquared;
      if (d2 >= math.pow(innerRadius - epsilon, 2) &&
          d2 <= math.pow(outerRadius + epsilon, 2)) {
        if (isAngleBetween(math.atan2(v.dy, v.dx))) return true;
      }
    }

    if (rect.contains(center) && innerRadius <= epsilon) return true;
    final edges = [
      [corners[0], corners[1]],
      [corners[1], corners[2]],
      [corners[2], corners[3]],
      [corners[3], corners[0]],
    ];

    bool checkSegmentArc(Offset p1, Offset p2, double r) {
      if (r <= epsilon) return false;
      final hits = crossPointsLineWithCircle(p1, p2, center, r, eps: epsilon);
      for (final p in hits) {
        if (isAngleBetween(math.atan2(p.dy - center.dy, p.dx - center.dx))) {
          return true;
        }
      }
      return false;
    }

    bool checkSegmentRay(Offset p1, Offset p2, double theta) {
      final rayDir = Offset(math.cos(theta), math.sin(theta));
      final rayEnd = center + rayDir * outerRadius;
      final rayStart = center + rayDir * innerRadius;
      // 复用线段相交逻辑
      return intersectWithLine(p1, p2, rayStart, rayEnd, eps: epsilon);
    }

    for (final edge in edges) {
      if (checkSegmentArc(edge[0], edge[1], outerRadius)) return true;
      if (checkSegmentArc(edge[0], edge[1], innerRadius)) return true;
      if (checkSegmentRay(edge[0], edge[1], normStart)) return true;
      if (checkSegmentRay(edge[0], edge[1], normEnd)) return true;
    }

    return false;
  }

  static bool intersectLineWithCircle(
    Offset start,
    Offset end,
    Offset center,
    double radius, {
    double eps = _defaultEpsilon,
  }) {
    return crossPointsLineWithCircle(
      start,
      end,
      center,
      radius,
      eps: eps,
    ).isNotEmpty;
  }

  static bool intersectCircleWithRect(
    Offset circleCenter,
    double radius,
    Rect rect,
  ) {
    double closestX = circleCenter.dx.clamp(rect.left, rect.right);
    double closestY = circleCenter.dy.clamp(rect.top, rect.bottom);

    double dx = circleCenter.dx - closestX;
    double dy = circleCenter.dy - closestY;

    return (dx * dx + dy * dy) <= (radius * radius);
  }

  static Offset? crossPointWithLines(
    Offset p1,
    Offset p2,
    Offset q1,
    Offset q2,
  ) {
    final d =
        (p1.dx - p2.dx) * (q1.dy - q2.dy) - (p1.dy - p2.dy) * (q1.dx - q2.dx);
    if (d.abs() < _defaultEpsilon) return null;

    final t =
        ((p1.dx - q1.dx) * (q1.dy - q2.dy) -
            (p1.dy - q1.dy) * (q1.dx - q2.dx)) /
        d;
    final u =
        -((p1.dx - p2.dx) * (p1.dy - q1.dy) -
            (p1.dy - p2.dy) * (p1.dx - q1.dx)) /
        d;

    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      return Offset(p1.dx + t * (p2.dx - p1.dx), p1.dy + t * (p2.dy - p1.dy));
    }
    return null;
  }

  static List<Offset> crossPointsWithCircle(
    Offset c1,
    double r1,
    Offset c2,
    double r2,
  ) {
    final dx = c2.dx - c1.dx;
    final dy = c2.dy - c1.dy;
    final d2 = dx * dx + dy * dy;
    final d = math.sqrt(d2);

    if (d > r1 + r2 || d < (r1 - r2).abs() || d < _defaultEpsilon) return [];

    final a = (r1 * r1 - r2 * r2 + d2) / (2 * d);
    final h = math.sqrt(math.max(0, r1 * r1 - a * a));

    final x2 = c1.dx + a * dx / d;
    final y2 = c1.dy + a * dy / d;

    final x3_1 = x2 + h * dy / d;
    final y3_1 = y2 - h * dx / d;
    final x3_2 = x2 - h * dy / d;
    final y3_2 = y2 + h * dx / d;

    final p1 = Offset(x3_1, y3_1);
    final p2 = Offset(x3_2, y3_2);

    if ((p1 - p2).distanceSquared < _defaultEpsilon) return [p1];
    return [p1, p2];
  }

  static List<Offset> crossPointsWithPolygon({
    required List<Offset> polygon1,
    required List<Offset> polygon2,
    bool closePoly1 = true,
    bool closePoly2 = true,
  }) {
    final rect1 = _computeBoundingBox(polygon1);
    final rect2 = _computeBoundingBox(polygon2);
    if (!rect1.overlaps(rect2)) return [];

    final gf = geomFactory;
    final p1 = gf.createPolygon5(polygon1, closePoly1);
    final p2 = gf.createPolygon5(polygon2, closePoly2);

    final result = p1.intersection(p2)?.getCoordinates();
    if (result == null || result.isEmpty) return [];

    return result.map((e) => Offset(e.x, e.y)).toList();
  }

  static List<Offset> crossPointsCircleWithPolygon({
    required List<Offset> polygon,
    required Offset center,
    required double r,
    bool closePoly = true,
  }) {
    final polyBounds = _computeBoundingBox(polygon);
    final circleBounds = Rect.fromCircle(center: center, radius: r);

    if (!polyBounds.overlaps(circleBounds)) {
      return [];
    }

    final List<Offset> results = [];
    final int len = polygon.length;
    final int count = closePoly ? len : len - 1;

    for (int i = 0; i < count; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % len];
      final hits = crossPointsLineWithCircle(p1, p2, center, r);
      results.addAll(hits);
    }
    return results;
  }

  static List<Offset> crossPointsLineWithCircle(
    Offset p1,
    Offset p2,
    Offset center,
    double r, {
    double eps = _defaultEpsilon,
  }) {
    final d = p2 - p1;
    final f = p1 - center;

    final a = d.dx * d.dx + d.dy * d.dy;
    if (a < eps) {
      return [];
    }

    final b = 2 * (f.dx * d.dx + f.dy * d.dy);
    final c = (f.dx * f.dx + f.dy * f.dy) - r * r;

    double discriminant = b * b - 4 * a * c;

    if (discriminant < -eps) return [];

    final result = <Offset>[];
    discriminant = math.sqrt(math.max(0, discriminant));
    final t1 = (-b - discriminant) / (2 * a);
    final t2 = (-b + discriminant) / (2 * a);
    if (t1 >= -eps && t1 <= 1 + eps) result.add(p1 + d * t1);
    if (t2 >= -eps && t2 <= 1 + eps) {
      if (result.isEmpty ||
          (result.last - (p1 + d * t2)).distanceSquared > eps) {
        result.add(p1 + d * t2);
      }
    }
    return result;
  }

  static double _crossProduct(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;

  static Rect _computeBoundingBox(List<Offset> points) {
    if (points.isEmpty) return Rect.zero;
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (var p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
