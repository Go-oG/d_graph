import 'dart:core';
import 'dart:math' as math;
import 'dart:math';
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';

const _kRadianToAngle = 180 / pi;
const _kAngleToRadian = pi / 180;

final class ContainsUtil {
  ContainsUtil._();

  static bool arcContainsPoint({
    required Offset point,
    double innerRadius = 0,
    Offset center = Offset.zero,
    required double outerRadius,
    required double startAngle,
    required double sweepAngle,
  }) {
    if (sweepAngle.abs() == 0 || (outerRadius - innerRadius) <= 0) {
      return false;
    }
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance < innerRadius || distance > outerRadius) {
      return false;
    }

    startAngle = startAngle * _kAngleToRadian;
    sweepAngle = sweepAngle * _kAngleToRadian;

    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;

    double start = startAngle % (2 * math.pi);
    if (start < 0) start += 2 * math.pi;

    double end = (start + sweepAngle) % (2 * math.pi);
    if (end < 0) end += 2 * math.pi;

    bool angleInSweep;
    if (sweepAngle >= 0) {
      angleInSweep = start <= end ? (angle >= start && angle <= end) : (angle >= start || angle <= end);
    } else {
      angleInSweep = start >= end ? (angle <= start && angle >= end) : (angle <= start || angle >= end);
    }
    return angleInSweep;
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
    for (final metric in metrics) {
      for (int i = 0; i <= samplePoints; i++) {
        final t = i / samplePoints;
        final pos = metric.getTangentForOffset(metric.length * t)?.position;
        if (pos != null) {
          final dx = (pos.dx - point.dx);
          final dy = (pos.dy - point.dy);
          final distance = math.sqrt(dx * dx + dy * dy);
          if (distance <= tolerance) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static bool pointOnSegment(Offset p, Offset a, Offset b, {double epsilon = 1e-10}) {
    double cross = (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
    if (cross.abs() > epsilon) return false;
    double dot = (p.x - a.x) * (b.x - a.x) + (p.y - a.y) * (b.y - a.y);
    double lenSq = (b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y);
    if (dot < -epsilon || dot > lenSq + epsilon) return false;
    return true;
  }

  static bool pointIsOnArc(
      Offset p, Offset center, double innerRadius, double outerRadius, double startAngle, double endAngle) {
    num disSquared = pow(p.dx - center.dx, 2) + pow(p.dy - center.dy, 2);
    num irSquared = pow(innerRadius, 2);
    num orSquared = pow(outerRadius, 2);

    if (disSquared < irSquared || disSquared > orSquared) {
      return false;
    }
    double angle = (atan2(p.dy - center.dy, p.dx - center.dx)) * _kRadianToAngle;
    if (angle < 0) {
      angle += 360;
    }

    if (startAngle <= endAngle) {
      return angle >= startAngle && angle <= endAngle;
    } else {
      return angle >= startAngle || angle <= endAngle;
    }
  }
}