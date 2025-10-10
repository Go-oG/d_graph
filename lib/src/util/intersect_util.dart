import 'dart:core';
import 'dart:math' as math;
import 'dart:math';
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';

final class IntersectUtil {
  IntersectUtil._();

  static bool intersectWithCircle(Offset c1, double r1, Offset c2, double r2) {
    final dx = c1.dx - c2.dx;
    final dy = c1.dy - c2.dy;
    final distance = sqrt(dx * dx + dy * dy);
    return distance <= r1 + r2 && distance >= (r1 - r2).abs();
  }

  static bool intersectWithPolygon({
    required List<Offset> polygon1,
    required List<Offset> polygon2,
    bool closePoly1 = true,
    bool closePoly2 = true,
  }) {
    final gf = geomFactory;
    final p1 = gf.createPolygon5(polygon1, closePoly1);
    final p2 = gf.createPolygon5(polygon2, closePoly2);
    return p1.intersects(p2);
  }

  static bool intersectWithLine(Offset p1, Offset p2, Offset q1, Offset q2, {double eps = 1e-9}) {
    final r = p2 - p1;
    final s = q2 - q1;
    final rxs = r.dx * s.dy - r.dy * s.dx;
    final qpxr = (q1 - p1).dx * r.dy - (q1 - p1).dy * r.dx;

    if (rxs.abs() <= eps) {
      if (qpxr.abs() <= eps) {
        double t0 = ((q1 - p1).dx * r.dx + (q1 - p1).dy * r.dy) / (r.dx * r.dx + r.dy * r.dy);
        double t1 = t0 + (s.dx * r.dx + s.dy * r.dy) / (r.dx * r.dx + r.dy * r.dy);
        if (t0 > t1) {
          final tmp = t0;
          t0 = t1;
          t1 = tmp;
        }
        return !(t1 < 0 || t0 > 1);
      }
      return false;
    }

    final qp = q1 - p1;
    final t = (qp.dx * s.dy - qp.dy * s.dx) / rxs;
    final u = (qp.dx * r.dy - qp.dy * r.dx) / rxs;
    return t >= -eps && t <= 1 + eps && u >= -eps && u <= 1 + eps;
  }

  static bool intersectRectWithArc(
    Rect rect, {
    required Offset center,
    required double ir,
    required double or,
    required Angle startAngle,
    required Angle endAngle,
    double epsilon = 1e-9,
  }) {
    final epsAngle = epsilon.asRadians;
    final twoPi = pi * 2;
    bool angleInRange(Angle a, Angle s, Angle e) {
      Angle aa = a.normalized, ss = s.normalized, ee = e.normalized;
      Angle span = (ee - ss).normalized;
      if (span <= epsAngle) span = twoPi.asRadians;
      Angle rel = (aa - ss).normalized;
      return rel <= span + epsilon.asRadians;
    }

    final corners = <Offset>[
      rect.topLeft - center,
      rect.topRight - center,
      rect.bottomRight - center,
      rect.bottomLeft - center,
    ];

    for (final p in corners) {
      final d2 = p.dx * p.dx + p.dy * p.dy;
      final d = math.sqrt(d2);
      if (d >= ir - epsilon &&
          d <= or + epsilon &&
          angleInRange(math.atan2(p.dy, p.dx).asRadians, startAngle, endAngle)) {
        return true;
      }
    }

    List<Offset> pts = corners;
    List<List<Offset>> edges = [
      [pts[0], pts[1]],
      [pts[1], pts[2]],
      [pts[2], pts[3]],
      [pts[3], pts[0]],
    ];

    bool segmentCircleHit(Offset a, Offset b, double r) {
      final d = b - a;
      final A = d.dx * d.dx + d.dy * d.dy;
      final B = 2 * (a.dx * d.dx + a.dy * d.dy);
      final C = a.dx * a.dx + a.dy * a.dy - r * r;
      final disc = B * B - 4 * A * C;
      if (disc < -epsilon) return false;
      final sqrtDisc = disc < 0 ? 0 : math.sqrt(disc);

      bool check(double t) {
        if (t < -epsilon || t > 1 + epsilon) return false;
        final p = Offset(a.dx + d.dx * t, a.dy + d.dy * t);
        final dlen = p.distance;
        if (dlen < ir - epsilon || dlen > or + epsilon) {
          return false;
        }
        return angleInRange(math.atan2(p.dy, p.dx).asRadians, startAngle, endAngle);
      }

      final t1 = (-B - sqrtDisc) / (2 * A);
      final t2 = (-B + sqrtDisc) / (2 * A);
      if (check(t1)) return true;
      if (check(t2)) return true;
      return false;
    }

    for (final e in edges) {
      if (segmentCircleHit(e[0], e[1], or)) return true;
      if (ir > epsilon && segmentCircleHit(e[0], e[1], ir)) {
        return true;
      }
    }
    bool segmentRayHit(Offset a, Offset b, Angle theta) {
      final u = Offset(theta.cos, theta.sin);
      final d = b - a;
      final denom = d.cross(u);
      if (denom.abs() < epsilon) return false;
      final t = -a.cross(u) / denom;
      if (t < -epsilon || t > 1 + epsilon) return false;

      final p = a + d * t;
      final s = p.dx * u.dx + p.dy * u.dy;
      if (s < -epsilon) return false;
      final dist = p.distance;
      return dist >= ir - epsilon && dist <= or + epsilon;
    }

    for (final e in edges) {
      if (segmentRayHit(e[0], e[1], startAngle)) return true;
      if (segmentRayHit(e[0], e[1], endAngle)) return true;
    }
    return false;
  }

  ///线和圆相交判断
  static bool intersectLineWithCircle(Offset start, Offset end, Offset center, double radius, {double eps = 1e-9}) {
    final d = end - start;
    final fx = start.dx - center.dx;
    final fy = start.dy - center.dy;

    final dx = d.dx, dy = d.dy;
    final a = dx * dx + dy * dy;
    if (a.abs() <= eps) {
      return fx * fx + fy * fy <= radius * radius + eps;
    }
    final b = 2 * (fx * dx + fy * dy);
    final c = fx * fx + fy * fy - radius * radius;
    final disc = b * b - 4 * a * c;
    if (disc < -eps) return false;
    bool acceptT(double t) => t >= 0 && t <= 1;
    if (disc.abs() <= eps) {
      final t = -b / (2 * a);
      return acceptT(t);
    }
    final sqrtDisc = sqrt(disc < 0 ? 0 : disc);
    final t1 = (-b - sqrtDisc) / (2 * a);
    final t2 = (-b + sqrtDisc) / (2 * a);
    return acceptT(t1) || acceptT(t2);
  }

  static bool intersectCircleWithRect(double cx, double cy, num radius, Rect rect) {
    if (rect.contains3(cx, cy)) {
      return true;
    }
    var hx = rect.width * 0.5;
    var hy = rect.height * 0.5;
    var vx = (rect.centerX - cx).abs();
    var vy = (rect.centerY - cy).abs();
    var cx2 = max(vx - hx, 0);
    var cy2 = max(vy - hy, 0);
    return (cx2 * cx2 + cy2 * cy2) <= radius * radius;
  }

  static Offset? crossPointWithLines(Offset p1, Offset p2, Offset q1, Offset q2) {
    final a1 = p2.y - p1.y;
    final b1 = p1.x - p2.x;
    final c1 = a1 * p1.x + b1 * p1.y;

    final a2 = q2.y - q1.y;
    final b2 = q1.x - q2.x;
    final c2 = a2 * q1.x + b2 * q1.y;

    final det = a1 * b2 - a2 * b1;
    if (det == 0) return null;

    final x = (b2 * c1 - b1 * c2) / det;
    final y = (a1 * c2 - a2 * c1) / det;

    bool onSegment(Offset p, Offset r1, Offset r2) {
      return (min(r1.x, r2.x) - 1e-10 <= p.x && p.x <= max(r1.x, r2.x) + 1e-10) &&
          (min(r1.y, r2.y) - 1e-10 <= p.y && p.y <= max(r1.y, r2.y) + 1e-10);
    }

    final intersection = Offset(x, y);
    if (onSegment(intersection, p1, p2) && onSegment(intersection, q1, q2)) return intersection;
    return null;
  }

  static List<Offset>? crossPointsWithCircle(Offset c1, double r1, Offset c2, double r2) {
    final dx = (c2.dx - c1.dx);
    final dy = (c2.dy - c1.dy);
    final d = sqrt(dx * dx + dy * dy);

    if (d > r1 + r2 || d < (r1 - r2).abs()) return null;
    if (d == 0 && r1 == r2) return null;

    final a = (r1 * r1 - r2 * r2 + d * d) / (2 * d);
    final h2 = r1 * r1 - a * a;
    if (h2 < 0) return null;

    final h = sqrt(h2);

    final xm = c1.dx + a * dx / d;
    final ym = c1.dy + a * dy / d;

    final rx = -dy * (h / d);
    final ry = dx * (h / d);

    final p1 = Offset(xm + rx, ym + ry);
    final p2 = Offset(xm - rx, ym - ry);

    if ((p1.dx - p2.dx).abs() < 1e-10 && (p1.dy - p2.dy).abs() < 1e-10) {
      return [p1];
    }
    return [p1, p2];
  }

  static List<Offset>? crossPointsWithPolygon({
    required List<Offset> polygon1,
    required List<Offset> polygon2,
    bool closePoly1 = true,
    bool closePoly2 = true,
  }) {
    final gf = geomFactory;
    final p1 = gf.createPolygon5(polygon1, closePoly1);
    final p2 = gf.createPolygon5(polygon2, closePoly2);

    final result = p1.intersection(p2)?.getCoordinates();
    if (result == null || result.isEmpty) {
      return null;
    }
    return result.map((e) => Offset(e.x, e.y)).toList();
  }

  static List<Offset>? crossPointsCircleWithPolygon({
    required List<Offset> polygon,
    required Offset center,
    required double r,
    bool closePoly = true,
  }) {
    final p1 = geomFactory.createPolygon5(polygon, closePoly);
    int segments = (pi * sqrt(r)).floor();
    segments = max(8, min(segments, 100));
    final p2 = geomFactory.createPoint4(center).buffer2(r, segments);

    final result = p1.intersection(p2)?.getCoordinates();
    if (result == null || result.isEmpty) {
      return null;
    }
    return result.map((e) => Offset(e.x, e.y)).toList();
  }

  static List<Offset> crossPointsLineWithCircle(Offset p1, Offset p2, Offset center, double r, {double eps = 1e-9}) {
    final cx = center.dx, cy = center.dy;
    final x1 = p1.dx, y1 = p1.dy;
    final x2 = p2.dx, y2 = p2.dy;

    final dx = x2 - x1, dy = y2 - y1;
    final fx = x1 - cx, fy = y1 - cy;

    final a = dx * dx + dy * dy;
    final b = 2 * (fx * dx + fy * dy);
    final c = fx * fx + fy * fy - r * r;
    final discriminant = b * b - 4 * a * c;

    final result = <Offset>[];
    if (discriminant < -eps) return result;

    final sqrtD = sqrt(discriminant.abs());
    for (final t in [(-b + sqrtD) / (2 * a), (-b - sqrtD) / (2 * a)]) {
      if (t >= -eps && t <= 1 + eps) {
        result.add(Offset(x1 + t * dx, y1 + t * dy));
      }
    }
    if (result.length == 2 && (result[0] - result[1]).distance < eps) {
      result.removeLast();
    }
    return result;
  }
}
