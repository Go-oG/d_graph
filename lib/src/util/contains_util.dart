import 'dart:core';
import 'dart:math' as math;
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';

final class ContainsUtil {
  ContainsUtil._();

  static const double _defaultEpsilon = 1e-9;

  static bool arcContainsPoint({
    required Offset point,
    double innerRadius = 0,
    Offset center = Offset.zero,
    required double outerRadius,
    required Angle startAngle,
    required Angle sweepAngle,
  }) {
    final epsilon = _defaultEpsilon;
    if (sweepAngle.isZero || (outerRadius - innerRadius) <= epsilon) {
      return false;
    }
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance < innerRadius - epsilon || distance > outerRadius + epsilon) {
      return false;
    }
    if (sweepAngle.radians.abs() >= math.pi * 2 - epsilon) {
      return true;
    }

    final angle = math.atan2(dy, dx).asRadians;
    return angleInSweep(target: angle, startAngle: startAngle, sweepAngle: sweepAngle, epsilon: epsilon);
  }

  static bool angleInSweep({
    required Angle target,
    required Angle startAngle,
    required Angle sweepAngle,
    double epsilon = _defaultEpsilon,
  }) {
    final sweep = sweepAngle.radians;
    final sweepAbs = sweep.abs();
    if (sweepAbs <= epsilon) return false;
    if (sweepAbs >= math.pi * 2 - epsilon) return true;

    final start = _normalizeRadians(startAngle.radians);
    final angle = _normalizeRadians(target.radians);
    if (sweep >= 0) {
      return _normalizeRadians(angle - start) <= sweepAbs + epsilon;
    }
    return _normalizeRadians(start - angle) <= sweepAbs + epsilon;
  }

  static bool circleContainsPoint({required Offset point, required double radius, Offset center = Offset.zero}) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return dx * dx + dy * dy <= radius * radius;
  }

  static bool isPointNearPath({
    required List<PathMetric> metrics,
    required Offset point,
    double tolerance = 2.0,
    int samplePoints = 100,
  }) {
    final toleranceSq = tolerance * tolerance;
    for (final metric in metrics) {
      final steps = math.max(samplePoints, (metric.length / tolerance).ceil());
      for (int i = 0; i <= steps; i++) {
        final t = i / steps;
        final pos = metric.getTangentForOffset(metric.length * t)?.position;
        if (pos != null) {
          final dx = (pos.dx - point.dx);
          final dy = (pos.dy - point.dy);
          if (dx * dx + dy * dy <= toleranceSq) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static bool pointOnSegment(Offset p, Offset a, Offset b, {double epsilon = 1e-10}) {
    epsilon = math.max(0, epsilon);
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final lenSq = dx * dx + dy * dy;
    if (lenSq <= epsilon * epsilon) {
      return (p - a).distanceSquared <= epsilon * epsilon;
    }

    final length = math.sqrt(lenSq);
    double cross = (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
    if (cross.abs() > epsilon * length) return false;
    double dot = (p.x - a.x) * (b.x - a.x) + (p.y - a.y) * (b.y - a.y);
    final projectionEpsilon = epsilon * length;
    if (dot < -projectionEpsilon || dot > lenSq + projectionEpsilon) {
      return false;
    }
    return true;
  }

  static bool pointIsOnArc(
    Offset p,
    Offset center,
    double innerRadius,
    double outerRadius,
    Angle startAngle,
    Angle endAngle,
  ) {
    num disSquared = math.pow(p.dx - center.dx, 2) + math.pow(p.dy - center.dy, 2);
    num irSquared = math.pow(innerRadius, 2);
    num orSquared = math.pow(outerRadius, 2);

    if (disSquared < irSquared || disSquared > orSquared) {
      return false;
    }
    Angle angle = math.atan2(p.dy - center.dy, p.dx - center.dx).asRadians.normalized;
    final start = startAngle.normalized;
    final end = endAngle.normalized;
    if (start <= end) {
      return angle >= start && angle <= end;
    } else {
      return angle >= start || angle <= end;
    }
  }

  static bool pointInPolygon(Offset p, List<Offset> polygon, {double epsilon = _defaultEpsilon}) {
    if (polygon.isEmpty) {
      return false;
    }
    if (polygon.length == 1) {
      return (p - polygon.first).distanceSquared <= epsilon * epsilon;
    }
    if (polygon.length == 2) {
      return pointOnSegment(p, polygon.first, polygon.last, epsilon: epsilon);
    }

    double minX = polygon.first.dx;
    double maxX = polygon.first.dx;
    double minY = polygon.first.dy;
    double maxY = polygon.first.dy;
    for (var i = 1; i < polygon.length; i++) {
      final point = polygon[i];
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }
    if (p.dx < minX - epsilon || p.dx > maxX + epsilon || p.dy < minY - epsilon || p.dy > maxY + epsilon) {
      return false;
    }

    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; j = i++) {
      if (pointOnSegment(p, polygon[j], polygon[i], epsilon: epsilon)) {
        return true;
      }
      if (((polygon[i].dy > p.dy) != (polygon[j].dy > p.dy)) &&
          (p.dx <
              (polygon[j].dx - polygon[i].dx) * (p.dy - polygon[i].dy) / (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx)) {
        inside = !inside;
      }
    }
    return inside;
  }

  static double _normalizeRadians(double angle) {
    final twoPi = math.pi * 2;
    var value = angle % twoPi;
    if (value < 0) {
      value += twoPi;
    }
    return value;
  }

  static bool rectContainsPoint(Rect rect, Offset point, [double epsilon = _defaultEpsilon]) {
    return point.dx >= rect.left - epsilon &&
        point.dx <= rect.right + epsilon &&
        point.dy >= rect.top - epsilon &&
        point.dy <= rect.bottom + epsilon;
  }

}
