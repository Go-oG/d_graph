import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:d_util/d_util.dart';

final class BoundsUtil {
  BoundsUtil._();

  static const _tau = pi * 2.0;

  static Rect? pointsBounds(Iterable<Offset?> rects) {
    if (rects.isEmpty) {
      return null;
    }
    double left = double.infinity;
    double top = double.infinity;
    double bottom = double.negativeInfinity;
    double right = double.negativeInfinity;

    for (var p0 in rects) {
      if (p0 == null) {
        continue;
      }
      left = min(p0.dx, left);
      top = min(p0.dy, top);
      right = max(p0.dx, right);
      bottom = max(p0.dy, bottom);
    }

    if (left.isInfinite) {
      return null;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static Rect? rectsBounds(Iterable<Rect?> rects) {
    if (rects.isEmpty) {
      return null;
    }

    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;
    for (final rect in rects) {
      if (rect == null) {
        continue;
      }
      left = left < rect.left ? left : rect.left;
      top = top < rect.top ? top : rect.top;
      right = right > rect.right ? right : rect.right;
      bottom = bottom > rect.bottom ? bottom : rect.bottom;
    }

    if (left.isInfinite) {
      return null;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static Rect? boundsOf<T>(
    Iterable<T> nodes,
    double Function(T node) leftFun,
    double Function(T node) topFun,
    double Function(T node) rightFun,
    double Function(T node) bottomFun,
  ) {
    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;
    for (final node in nodes) {
      double l = leftFun(node);
      double t = topFun(node);
      double r = rightFun(node);
      double b = bottomFun(node);
      left = left < l ? left : l;
      top = top < t ? top : t;
      right = right > r ? right : r;
      bottom = bottom > b ? bottom : b;
    }

    if (left.isInfinite) {
      return null;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static Rect arcBounds({
    required Offset center,
    required double ir,
    required double or,
    required Angle startAngle,
    required Angle sweepAngle,
  }) {
    final endAngle = startAngle + sweepAngle;
    final cx = center.dx;
    final cy = center.dy;
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    void add(double r, double a) {
      final x = cx + cos(a) * r;
      final y = cy + sin(a) * r;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    add(ir, startAngle.radians);
    add(ir, endAngle.radians);
    add(or, startAngle.radians);
    add(or, endAngle.radians);

    const qs = <double>[0.0, pi / 2, pi, 3 * pi / 2];
    for (final q in qs) {
      if (_angleInSweep(startAngle, sweepAngle, q)) {
        add(or, q);
        if (ir > 0) add(ir, q);
      }
    }

    if (minX == double.infinity) {
      return Rect.fromLTWH(cx, cy, 0, 0);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static bool _angleInSweep(
    Angle startAngle,
    Angle sweepAngle,
    double angleRad,
  ) {
    final sa = _norm0ToTau(startAngle.radians);
    final a = _norm0ToTau(angleRad);
    final sweep = sweepAngle.radians;
    final sAbs = sweep.abs();
    if (sAbs <= 1e-12) return false;
    if (sweep >= 0) {
      if (sAbs >= _tau - 1e-12) return true;
      return _norm0ToTau(a - sa) <= sAbs + 1e-12;
    }
    if (sAbs >= _tau - 1e-12) return true;
    return _norm0ToTau(sa - a) <= sAbs + 1e-12;
  }

  static double _norm0ToTau(double a) {
    var x = a % _tau;
    if (x < 0) x += _tau;
    return x;
  }
}
