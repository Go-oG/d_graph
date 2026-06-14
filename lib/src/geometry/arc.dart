import 'dart:math' as m;
import 'dart:math';
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';
import 'package:dts/dts.dart' show Geometry;

class Arc extends BasicGeometry {
  static final zero = Arc();
  static const _epsilon = 1e-12;
  static const _tau = 2 * pi;

  @override
  final Offset center;
  final double innerRadius;
  final double outRadius;
  final Angle startAngle;
  final Angle sweepAngle;
  final double cornerRadius;
  final Angle padAngle;
  late final double padRadius;

  Arc({
    this.innerRadius = 0,
    this.outRadius = 0,
    this.startAngle = Angle.zero,
    this.sweepAngle = Angle.zero,
    this.cornerRadius = 0,
    this.padAngle = Angle.zero,
    this.center = Offset.zero,
    double? padRadius,
  }) {
    if (padRadius != null && padRadius >= 0) {
      this.padRadius = padRadius;
    } else {
      this.padRadius = m.sqrt(innerRadius * innerRadius + outRadius * outRadius);
    }
    if (innerRadius > outRadius) {
      throw ("参数违法");
    }
  }

  Arc copy({
    double? innerRadius,
    double? outRadius,
    Angle? startAngle,
    Angle? sweepAngle,
    double? cornerRadius,
    Angle? padAngle,
    Offset? center,
    double? padRadius,
  }) {
    return Arc(
      innerRadius: innerRadius ?? this.innerRadius,
      outRadius: outRadius ?? this.outRadius,
      startAngle: startAngle ?? this.startAngle,
      sweepAngle: sweepAngle ?? this.sweepAngle,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      padAngle: padAngle ?? this.padAngle,
      center: center ?? this.center,
      padRadius: padRadius ?? this.padRadius,
    );
  }

  late final annularSector = AnnularSector(
    center: center,
    innerRadius: innerRadius,
    outerRadius: outRadius,
    startAngle: startAngle,
    endAngle: endAngle,
  );

  @override
  late final Rect bbox = _onBuildBound();

  @override
  late final double length = annularSector.perimeter;

  @override
  late final double area = annularSector.area;

  @override
  Path onBuildPath() {
    if (outRadius <= 0 || isEmpty || sweepAngle.radians.abs() <= 1e-5) {
      return Path();
    }
    final double ir = innerRadius <= 0.001 ? 0 : innerRadius;
    final double or = outRadius;
    final bool clockwise = sweepAngle.radians >= 0;
    final int direction = clockwise ? 1 : -1;
    if (_isFullSweep(sweepAngle)) {
      if (innerRadius <= 0.001) {
        return _buildCircle(center, startAngle, or, direction);
      }
      return _buildHollowCircle(center, startAngle, ir, or, direction);
    }

    return _buildArc(center, startAngle, sweepAngle, ir, or, cornerRadius, padAngle, padRadius);
  }

  Rect _onBuildBound() {
    return BoundsUtil.arcBounds(
      center: center,
      ir: innerRadius,
      or: outRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );
  }

  Offset centroid() {
    var r = (innerRadius + outRadius) / 2;
    var a = (startAngle + endAngle) / 2;
    return CoordUtil.circlePoint(r, a, center: center);
  }

  Angle centerAngle() => startAngle + (sweepAngle / 2);

  Angle get endAngle => (startAngle + sweepAngle);

  bool get isEmpty => sweepAngle.isZero || (outRadius - innerRadius).abs() == 0;

  @override
  String toString() {
    return 'IR:${innerRadius.toStringAsFixed(1)} OR:${outRadius.toStringAsFixed(1)} SA:$startAngle '
        'EA:$endAngle center:$center';
  }

  @override
  int get hashCode {
    return Object.hash(innerRadius, outRadius, startAngle, sweepAngle, cornerRadius, center, padAngle, padRadius);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Arc &&
        other.innerRadius == innerRadius &&
        other.outRadius == outRadius &&
        other.startAngle == startAngle &&
        other.sweepAngle == sweepAngle &&
        other.cornerRadius == cornerRadius &&
        other.center == center &&
        other.padAngle == padAngle &&
        other.padRadius == padRadius;
  }

  @override
  bool contains(BasicGeometry geom) {
    if (geom is Arc) {
      return _containsArc(geom);
    }
    if (geom is Circle) {
      return _containsCircle(geom.radius, geom.center.x, geom.center.y);
    }
    return asGeometry.contains(geom.asGeometry);
  }

  @override
  bool containsPoint(Offset p, {double eps = 1e-9}) => annularSector.contains(p, epsilon: eps);

  @override
  bool isOverlap(BasicGeometry geom, {double eps = 1e-9}) {
    if (geom is Arc) {
      return AnnularSector.intersect(annularSector, geom.annularSector);
    }
    if (geom is BasicLine) {
      return annularSector.isIntersectsLine(geom.start, geom.end);
    }
    if (geom is Circle) {
      return annularSector.isIntersectsCircle(geom.center, geom.radius);
    }
    if (geom is Polygon) {
      return annularSector.isIntersectsPolygon(geom.vertices);
    }

    if (geom is Triangle) {
      return annularSector.isIntersectsPolygon(geom.vertices);
    }

    return super.isOverlap(geom, eps: eps);
  }

  bool _containsArc(Arc arc) {
    if (arc.innerRadius < innerRadius || arc.outRadius > outRadius) {
      return false;
    }
    return _angleContains(startAngle, endAngle, arc.startAngle, arc.endAngle);
  }

  bool _angleContains(Angle aStart, Angle aEnd, Angle bStart, Angle bEnd) {
    final aParts = _angleRanges(aStart, aEnd);
    final bParts = _angleRanges(bStart, bEnd);
    for (final b in bParts) {
      var covered = false;
      for (final a in aParts) {
        if (b.$1 >= a.$1 - 1e-10 && b.$2 <= a.$2 + 1e-10) {
          covered = true;
          break;
        }
      }
      if (!covered) {
        return false;
      }
    }
    return true;
  }

  bool _containsCircle(double rCircle, double x, double y) {
    final A = annularSector;
    final polar = CoordUtil.pointToPolar(x, y, center);
    final dist = polar.radius;
    if (dist - rCircle < A.innerRadius || dist + rCircle > A.outerRadius) {
      return false;
    }
    if (dist == 0) {
      return rCircle <= (A.outerRadius) && rCircle >= (A.innerRadius);
    }
    final angleCenter = polar.angle;
    final deltaAngle = asin(rCircle / dist).asRadians;
    final circleStart = angleCenter - deltaAngle;
    final circleEnd = angleCenter + deltaAngle;
    return _angleContains(A.startAngle, A.endAngle, circleStart, circleEnd);
  }

  @override
  Geometry buildGeometry() =>
      AnnularSectorFactory.createAnnularSector(center, innerRadius, outRadius, startAngle, endAngle);

  ///普通圆形
  static Path _buildCircle(Offset center, Angle startAngle, double or, int direction) {
    final piOffset = pi * direction;
    Path path = Path();
    Offset o1 = CoordUtil.circlePoint(or, startAngle, center: center);
    Rect orRect = Rect.fromCircle(center: center, radius: or);
    path.moveTo(o1.dx, o1.dy);
    path.arcTo(orRect, startAngle.radians, piOffset, false);
    path.arcTo(orRect, startAngle.radians + piOffset, piOffset, false);
    path.close();
    return path;
  }

  ///空心圆形
  static Path _buildHollowCircle(Offset center, Angle startAngle, double ir, double or, int direction) {
    final path = Path();
    path.addArc(Rect.fromCircle(center: center, radius: or), startAngle.radians, 2 * pi * direction);
    path.addArc(Rect.fromCircle(center: center, radius: ir), startAngle.radians, -2 * pi * direction);
    path.close();
    return path;
  }

  static Path _buildArc(
    Offset center,
    Angle startAngle,
    Angle sweepAngle,
    double ir,
    double or,
    double corner,
    Angle padAngle,
    double padRadius,
  ) {
    final path = Path();
    final a0 = startAngle.radians;
    final a1 = (startAngle + sweepAngle).radians;
    final da = (a1 - a0).abs();
    final clockwise = a1 > a0;
    var a01 = a0;
    var a11 = a1;
    var a00 = a0;
    var a10 = a1;
    var da0 = da;
    var da1 = da;
    final ap = padAngle.radians / 2;
    final rp = ap > _epsilon ? padRadius : 0.0;
    final rc = m.min((or - ir).abs() / 2, m.max(0.0, corner));
    var rc0 = rc;
    var rc1 = rc;

    if (rp > _epsilon) {
      if (ir > _epsilon) {
        var p0 = _safeAsin(rp / ir * sin(ap));
        da0 -= p0 * 2;
        if (da0 > _epsilon) {
          p0 *= clockwise ? 1 : -1;
          a00 += p0;
          a10 -= p0;
        } else {
          da0 = 0;
          a00 = a10 = (a0 + a1) / 2;
        }
      } else {
        da0 = 0;
      }
      var p1 = _safeAsin(rp / or * sin(ap));
      da1 -= p1 * 2;
      if (da1 > _epsilon) {
        p1 *= clockwise ? 1 : -1;
        a01 += p1;
        a11 -= p1;
      } else {
        da1 = 0;
        a01 = a11 = (a0 + a1) / 2;
      }
    }

    final p01 = CoordUtil.circlePoint(or, a01.asRadians);
    final p10 = CoordUtil.circlePoint(ir, a10.asRadians);
    final x01 = p01.dx;
    final y01 = p01.dy;
    final x10 = p10.dx;
    final y10 = p10.dy;

    if (rc > _epsilon) {
      final p11 = CoordUtil.circlePoint(or, a11.asRadians);
      final p00 = CoordUtil.circlePoint(ir, a00.asRadians);
      final x11 = p11.dx;
      final y11 = p11.dy;
      final x00 = p00.dx;
      final y00 = p00.dy;
      final oc = _intersect(x01, y01, x00, y00, x11, y11, x10, y10);
      if (da < pi && oc != null) {
        final ax = x01 - oc.dx;
        final ay = y01 - oc.dy;
        final bx = x11 - oc.dx;
        final by = y11 - oc.dy;
        final dot = ax * bx + ay * by;
        final al = sqrt(ax * ax + ay * ay);
        final bl = sqrt(bx * bx + by * by);
        final divisor = al * bl;
        final kc = divisor <= _epsilon ? double.infinity : 1 / sin(_safeAcos(dot / divisor) / 2);
        final lc = sqrt(oc.dx * oc.dx + oc.dy * oc.dy);
        rc0 = m.max(0.0, m.min(rc, (ir - lc) / (kc - 1)));
        rc1 = m.max(0.0, m.min(rc, (or - lc) / (kc + 1)));
      } else if (da < pi) {
        rc0 = 0.0;
        rc1 = 0.0;
      }
    }

    if (da1 <= _epsilon) {
      path.moveTo(center.dx + x01, center.dy + y01);
    } else if (rc1 > _epsilon) {
      final p11 = CoordUtil.circlePoint(or, a11.asRadians);
      final p00 = CoordUtil.circlePoint(ir, a00.asRadians);
      final x11 = p11.dx;
      final y11 = p11.dy;
      final x00 = p00.dx;
      final y00 = p00.dy;
      final t0 = _cornerTangents(x00, y00, x01, y01, or, rc1, clockwise);
      final t1 = _cornerTangents(x11, y11, x10, y10, or, rc1, clockwise);

      path.moveTo(center.dx + t0.cx + t0.x01, center.dy + t0.cy + t0.y01);
      if (rc1 < rc) {
        _arcToCircle(
          path,
          center.translate(t0.cx, t0.cy),
          rc1,
          atan2(t0.y01, t0.x01),
          atan2(t1.y01, t1.x01),
          !clockwise,
        );
      } else {
        _arcToCircle(
          path,
          center.translate(t0.cx, t0.cy),
          rc1,
          atan2(t0.y01, t0.x01),
          atan2(t0.y11, t0.x11),
          !clockwise,
        );
        _arcToCircle(
          path,
          center,
          or,
          atan2(t0.cy + t0.y11, t0.cx + t0.x11),
          atan2(t1.cy + t1.y11, t1.cx + t1.x11),
          !clockwise,
        );
        _arcToCircle(
          path,
          center.translate(t1.cx, t1.cy),
          rc1,
          atan2(t1.y11, t1.x11),
          atan2(t1.y01, t1.x01),
          !clockwise,
        );
      }
    } else {
      path.moveTo(center.dx + x01, center.dy + y01);
      _arcToCircle(path, center, or, a01, a11, !clockwise);
    }

    if (ir <= _epsilon || da0 <= _epsilon) {
      path.lineTo(center.dx + x10, center.dy + y10);
    } else if (rc0 > _epsilon) {
      final p11 = CoordUtil.circlePoint(or, a11.asRadians);
      final p00 = CoordUtil.circlePoint(ir, a00.asRadians);
      final x11 = p11.dx;
      final y11 = p11.dy;
      final x00 = p00.dx;
      final y00 = p00.dy;
      final t0 = _cornerTangents(x10, y10, x11, y11, ir, -rc0, clockwise);
      final t1 = _cornerTangents(x01, y01, x00, y00, ir, -rc0, clockwise);

      path.lineTo(center.dx + t0.cx + t0.x01, center.dy + t0.cy + t0.y01);
      if (rc0 < rc) {
        _arcToCircle(
          path,
          center.translate(t0.cx, t0.cy),
          rc0,
          atan2(t0.y01, t0.x01),
          atan2(t1.y01, t1.x01),
          !clockwise,
        );
      } else {
        _arcToCircle(
          path,
          center.translate(t0.cx, t0.cy),
          rc0,
          atan2(t0.y01, t0.x01),
          atan2(t0.y11, t0.x11),
          !clockwise,
        );
        _arcToCircle(
          path,
          center,
          ir,
          atan2(t0.cy + t0.y11, t0.cx + t0.x11),
          atan2(t1.cy + t1.y11, t1.cx + t1.x11),
          clockwise,
        );
        _arcToCircle(
          path,
          center.translate(t1.cx, t1.cy),
          rc0,
          atan2(t1.y11, t1.x11),
          atan2(t1.y01, t1.x01),
          !clockwise,
        );
      }
    } else {
      _arcToCircle(path, center, ir, a10, a00, clockwise);
    }

    path.close();
    return path;
  }

  static bool _isFullSweep(Angle sweepAngle) => sweepAngle.radians.abs() >= 2 * pi - 1e-9;

  static void _arcToCircle(
    Path path,
    Offset center,
    double radius,
    double startAngle,
    double endAngle,
    bool counterClockwise,
  ) {
    final sweep = _sweepRadians(startAngle, endAngle, counterClockwise);
    if (sweep.abs() <= _epsilon) {
      return;
    }
    path.arcTo(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, false);
  }

  static double _sweepRadians(double startAngle, double endAngle, bool counterClockwise) {
    var delta = counterClockwise ? startAngle - endAngle : endAngle - startAngle;
    while (delta < 0) {
      delta += _tau;
    }
    return counterClockwise ? -delta : delta;
  }

  static double _safeAcos(double x) {
    if (x > 1) {
      return 0;
    }
    if (x < -1) {
      return pi;
    }
    return acos(x);
  }

  static double _safeAsin(double x) {
    if (x >= 1) {
      return pi / 2;
    }
    if (x <= -1) {
      return -pi / 2;
    }
    return asin(x);
  }

  static Offset? _intersect(double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3) {
    final x10 = x1 - x0;
    final y10 = y1 - y0;
    final x32 = x3 - x2;
    final y32 = y3 - y2;
    final t = y32 * x10 - x32 * y10;
    if (t * t < _epsilon) {
      return null;
    }
    final u = (x32 * (y0 - y2) - y32 * (x0 - x2)) / t;
    return Offset(x0 + u * x10, y0 + u * y10);
  }

  static _CornerTangents _cornerTangents(
    double x0,
    double y0,
    double x1,
    double y1,
    double r1,
    double rc,
    bool clockwise,
  ) {
    final x01 = x0 - x1;
    final y01 = y0 - y1;
    final lo = (clockwise ? rc : -rc) / sqrt(x01 * x01 + y01 * y01);
    final ox = lo * y01;
    final oy = -lo * x01;
    final x11 = x0 + ox;
    final y11 = y0 + oy;
    final x10 = x1 + ox;
    final y10 = y1 + oy;
    final x00 = (x11 + x10) / 2;
    final y00 = (y11 + y10) / 2;
    final dx = x10 - x11;
    final dy = y10 - y11;
    final d2 = dx * dx + dy * dy;
    final r = r1 - rc;
    final d = x11 * y10 - x10 * y11;
    final s = (dy < 0 ? -1 : 1) * sqrt(m.max(0, r * r * d2 - d * d));
    var cx0 = (d * dy - dx * s) / d2;
    var cy0 = (-d * dx - dy * s) / d2;
    final cx1 = (d * dy + dx * s) / d2;
    final cy1 = (-d * dx + dy * s) / d2;
    final dx0 = cx0 - x00;
    final dy0 = cy0 - y00;
    final dx1 = cx1 - x00;
    final dy1 = cy1 - y00;

    if (dx0 * dx0 + dy0 * dy0 > dx1 * dx1 + dy1 * dy1) {
      cx0 = cx1;
      cy0 = cy1;
    }

    return _CornerTangents(cx: cx0, cy: cy0, x01: -ox, y01: -oy, x11: cx0 * (r1 / r - 1), y11: cy0 * (r1 / r - 1));
  }

  static List<(double, double)> _angleRanges(Angle start, Angle end) {
    const eps = 1e-10;
    final rawSweep = end.radians - start.radians;
    if (rawSweep.abs() >= 2 * pi - eps) {
      return const [(0, 2 * pi)];
    }

    final s = _normalizeAngle(start.radians);
    final e = _normalizeAngle(end.radians);
    if ((e - s).abs() <= eps) {
      return [(s, s)];
    }
    if (e >= s) {
      return [(s, e)];
    }
    return [(s, 2 * pi), (0, e)];
  }

  static double _normalizeAngle(double angle) {
    var value = angle % (2 * pi);
    if (value < 0) {
      value += 2 * pi;
    }
    return value;
  }
}

final class _CornerTangents {
  final double cx;
  final double cy;
  final double x01;
  final double y01;
  final double x11;
  final double y11;

  const _CornerTangents({
    required this.cx,
    required this.cy,
    required this.x01,
    required this.y01,
    required this.x11,
    required this.y11,
  });
}
