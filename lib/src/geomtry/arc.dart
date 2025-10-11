import 'dart:math' as m;
import 'dart:math';
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';
import 'package:dts/dts.dart' show Geometry;

class Arc extends BasicGeometry {
  static final zero = Arc();
  static const _cornerMin = 0.5;
  static const _innerMin = 0.01;

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
    if (padRadius != null && padRadius >= outRadius) {
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

  @override
  late final Rect bbox = _onBuildBound();

  @override
  late final double length = annularSector.perimeter;

  @override
  late final double area = annularSector.area;

  @override
  Path onBuildPath() {
    if (sweepAngle.radians.abs() <= 1e-5) {
      return Path();
    }
    final double ir = innerRadius <= 0.001 ? 0 : innerRadius;
    final double or = outRadius;
    final bool clockwise = sweepAngle.radians >= 0;
    final int direction = clockwise ? 1 : -1;
    if (sweepAngle.isFull) {
      if (innerRadius <= 0.001) {
        return _buildCircle(center, startAngle, or, direction);
      }
      return _buildHollowCircle(center, startAngle, ir, or, direction);
    }

    //修正corner
    var corner = m.min(cornerRadius, (or - ir) / 2);
    double dd = or * sweepAngle.abs.radians;
    corner = m.min(dd / 2, corner);
    corner = m.max(corner, 0);
    if (corner <= 0.001) {
      corner = 0;
    }

    ///普通扇形
    if (ir <= _innerMin) {
      return _buildNormalArc(center, startAngle, sweepAngle, or, corner);
    }

    /// 空心扇形
    return _buildHollowArc(center, startAngle, sweepAngle, ir, or, corner, padAngle, padRadius);
  }

  Rect _onBuildBound() {
    return Rect.fromCircle(center: center, radius: outRadius.toDouble());
  }

  Offset centroid() {
    var r = (innerRadius + outRadius) / 2;
    var a = (startAngle + endAngle) / 2;
    return circlePoint(r, a, center);
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
      final a1 = AnnularSector(
        center: center,
        innerRadius: innerRadius,
        outerRadius: outRadius,
        startAngle: startAngle * pi / 180,
        endAngle: endAngle * pi / 180,
      );
      final a2 = AnnularSector(
        center: geom.center,
        innerRadius: geom.innerRadius,
        outerRadius: geom.outRadius,
        startAngle: geom.startAngle * pi / 180,
        endAngle: geom.endAngle * pi / 180,
      );
      return AnnularSector.intersect(a1, a2);
    }
    if (geom is BasicLine) {
      return annularSector.isIntersectsLine(geom.start, geom.end);
    }
    if (geom is Circle) {
      return annularSector.isIntersectsCircle(geom.center, geom.radius);
    }
    if (geom is Polygon) {
      return annularSector.isIntersectsPolygon(geom.lines);
    }

    if (geom is Triangle) {
      return annularSector.isIntersectsPolygon(geom.lines);
    }

    return super.isOverlap(geom, eps: eps);
  }

  AnnularSector get annularSector {
    return AnnularSector(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outRadius,
      startAngle: startAngle * pi / 180,
      endAngle: endAngle * pi / 180,
    );
  }

  bool _containsArc(Arc arc) {
    if (arc.innerRadius < innerRadius || arc.outRadius > outRadius) return false;
    return _angleContains(startAngle, endAngle, arc.startAngle, arc.endAngle);
  }

  bool _angleContains(Angle aStart, Angle aEnd, Angle bStart, Angle bEnd) {
    final pi2 = m.pi * 2;
    aStart = aStart % pi2;
    aEnd = aEnd % pi2;
    bStart = bStart % pi2;
    bEnd = bEnd % pi2;

    if (aEnd >= aStart) {
      return (bStart >= aStart && bEnd <= aEnd);
    } else {
      return (bStart >= aStart || bEnd <= aEnd);
    }
  }

  bool _containsCircle(double rCircle, double x, double y) {
    final A = annularSector;
    final dx = x - center.x;
    final dy = y - center.y;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist - rCircle < A.innerRadius || dist + rCircle > A.outerRadius) return false;
    if (dist == 0) {
      return rCircle <= (A.outerRadius) && rCircle >= (A.innerRadius);
    }
    final angleCenter = atan2(dy, dx).asRadians;
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
    Offset o1 = circlePoint(or, startAngle, center);
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
    path.addArc(Rect.fromCircle(center: center, radius: or), 0, 2 * pi * direction);
    path.addArc(Rect.fromCircle(center: center, radius: ir), 0, -2 * pi * direction);
    path.close();
    return path;
  }

  ///扇形
  static Path _buildNormalArc(Offset center, Angle startAngle, Angle sweepAngle, double or, double corner) {
    Path path = Path();
    path.moveTo(center.dx, center.dy);
    Rect orRect = Rect.fromCircle(center: center, radius: or);
    if (corner <= _cornerMin) {
      Offset o1 = circlePoint(or, startAngle, center);
      path.lineTo(o1.dx, o1.dy);
      path.arcTo2(orRect, startAngle, sweepAngle, false);
      path.close();
      return path;
    }

    ///扇形外部有圆角
    final Radius cr = Radius.circular(corner);
    final endAngle = startAngle + sweepAngle;

    final bool clockwise = sweepAngle.radians >= 0;
    final lt = _computeCornerPoint(center, or, corner, startAngle, true, true);
    final rt = _computeCornerPoint(center, or, corner, endAngle, false, true);
    path.lineTo2(clockwise ? lt.p1 : rt.p2);
    path.arcToPoint(clockwise ? lt.p2 : rt.p1, radius: cr, largeArc: false, clockwise: clockwise);

    Angle a, b;
    if (clockwise) {
      a = lt.p2.angle(center);
      b = rt.p1.angle(center);
      if (b < a) {
        b = b.add(2 * m.pi);
      }
    } else {
      a = rt.p1.angle(center);
      b = lt.p2.angle(center);
      if (b > a) {
        b = b.sub(2 * m.pi);
      }
    }
    path.arcTo(orRect, a.radians, (b - a).radians, false);
    path.arcToPoint(clockwise ? rt.p2 : lt.p1, radius: cr, largeArc: false, clockwise: clockwise);
    path.close();
    return path;
  }

  ///空心扇形
  static Path _buildHollowArc(
    Offset center,
    Angle startAngle,
    Angle sweepAngle,
    double ir,
    double or,
    double corner,
    Angle padAngle,
    double padRadius,
  ) {
    final bool clockwise = sweepAngle.radians >= 0;
    final Rect outRect = Rect.fromCircle(center: center, radius: or);
    final Rect inRect = Rect.fromCircle(center: center, radius: ir);

    Angle osa = startAngle;
    Angle oea = startAngle + sweepAngle;
    Angle isa = startAngle;
    Angle iea = startAngle + sweepAngle;

    ///修正存在angleGap时视觉上间隔不一致问题(只有innerRadius>0时有效)
    if (padAngle.radians > 0 && ir > 0) {
      final al = _adjustAngle(ir, or, startAngle, sweepAngle, padAngle, or);
      isa = al[0];
      iea = al[1];
      osa = al[2];
      oea = al[3];
    }
    final outSweep = oea - osa;
    final inSweep = iea - isa;

    final Path path = Path();
    if (corner <= _cornerMin) {
      ///outer
      path.moveTo2(circlePoint(or, osa, center));
      path.arcTo2(outRect, osa, outSweep, false);

      ///inner
      path.lineTo2(circlePoint(ir, iea, center));
      path.arcTo2(inRect, iea, -inSweep, false);
      path.close();
      return path;
    }

    ///计算外圆环和内圆环的最小corner
    final num outLength = or * outSweep.radians.abs();
    final num inLength = ir * inSweep.radians.abs();
    double outCorner = corner;
    double inCorner = corner;
    if (corner * m.pi > outLength) {
      outCorner = outLength / m.pi;
    }
    if (outSweep.radians.abs() <= 1e-6 || outCorner <= _cornerMin) {
      outCorner = 0;
    }
    if (corner * m.pi > inLength) {
      inCorner = inLength / m.pi;
    }
    if (inSweep.radians.abs() <= 1e-6 || inCorner <= _cornerMin) {
      inCorner = 0;
    }

    ///外圈层
    if (outCorner >= _cornerMin) {
      final Radius radius = Radius.circular(outCorner);
      final lt = _computeCornerPoint(center, or, outCorner, clockwise ? osa : oea, true, true);
      final rt = _computeCornerPoint(center, or, outCorner, clockwise ? oea : osa, false, true);
      path.moveTo2(clockwise ? lt.p1 : rt.p2);
      path.arcToPoint(clockwise ? lt.p2 : rt.p1, radius: radius, largeArc: false, clockwise: clockwise);
      Angle a, b;
      a = (clockwise ? lt.p2 : rt.p1).angle(center);
      b = (clockwise ? rt.p1 : lt.p2).angle(center);
      if (clockwise && b < a) {
        b = b.add(2 * m.pi);
      }
      if (!clockwise && b > a) {
        a = a.add(2 * m.pi);
      }
      path.arcTo2(outRect, a, b - a, false);
      path.lineTo2(clockwise ? rt.p1 : lt.p2);
      path.arcToPoint(clockwise ? rt.p2 : lt.p1, radius: radius, largeArc: false, clockwise: clockwise);
    } else {
      path.moveTo2(circlePoint(or, osa, center));
      if (outSweep.radians > 1e-6) {
        path.arcTo2(outRect, osa, outSweep, false);
      }
    }

    ///内圈层
    if (inCorner >= _cornerMin) {
      final Radius radius = Radius.circular(inCorner);
      final lb = _computeCornerPoint(center, ir, inCorner, clockwise ? isa : iea, true, false);
      final rb = _computeCornerPoint(center, ir, inCorner, clockwise ? iea : isa, false, false);
      path.lineTo2(clockwise ? rb.p1 : lb.p2);
      path.arcToPoint(clockwise ? rb.p2 : lb.p1, radius: radius, largeArc: false, clockwise: clockwise);
      Angle a, b;
      a = (clockwise ? rb.p2 : lb.p1).angle(center);
      b = (clockwise ? lb.p1 : rb.p2).angle(center);
      if (clockwise && b > a) {
        b = b.sub(2 * m.pi);
      }
      if (!clockwise && a > b) {
        a = a.sub(2 * m.pi);
      }
      path.arcTo2(inRect, a, b - a, false);
      path.lineTo2(clockwise ? lb.p1 : rb.p2);
      path.arcToPoint(clockwise ? lb.p2 : rb.p1, radius: radius, largeArc: false, clockwise: clockwise);
    } else {
      path.lineTo2(circlePoint(ir, iea, center));
      if (inSweep.radians > 1e-6) {
        path.arcTo2(inRect, iea, -inSweep, false);
      }
    }
    path.close();
    return path;
  }

  static List<Angle> _adjustAngle(
    double ir,
    double or,
    Angle startAngle,
    Angle sweepAngle,
    Angle padAngle,
    double maxRadius,
  ) {
    List<Angle> il = [startAngle, startAngle + sweepAngle];
    il = _offsetAngle(ir, startAngle, sweepAngle, padAngle, maxRadius);
    List<Angle> ol = _offsetAngle(or, startAngle, sweepAngle, padAngle, maxRadius);
    il.addAll(ol);
    return il;
  }

  static List<Angle> _offsetAngle(double r, Angle startAngle, Angle sweepAngle, Angle padAngle, double padRadius) {
    final sa = startAngle.radians;
    final sw = sweepAngle.radians;
    final pad = padAngle.radians;

    if (pad == 0 || r == 0) {
      return [startAngle, startAngle + sweepAngle];
    }

    final outerPad = asin((padRadius / r) * sin(pad / 2)).clamp(-1, 1);
    final innerPad = asin(sin(pad / 2)).clamp(-1, 1);
    double start = sa + outerPad - innerPad;
    double end = sa + sw - (outerPad - innerPad);

    if (sw > 0 && end < start) {
      final mid = (sa + sa + sw) / 2;
      start = end = mid;
    } else if (sw < 0 && end > start) {
      final mid = (sa + sa + sw) / 2;
      start = end = mid;
    }

    return [Angle.radians(start), Angle.radians(end)];
  }

  ///计算切点位置
  static _CornerOffset _computeCornerPoint(Offset center, num r, double corner, Angle angle, bool left, bool top) {
    _CornerOffset result = _CornerOffset();

    final dis = (r + corner * (top ? -1 : 1.0)).abs();
    final double x = sqrt(max(0.0, dis * dis - corner * corner));
    Offset c = Offset(x, corner * (left ? 1 : -1));
    result.center = c.translate(center.dx, center.dy);
    Offset o1 = Offset(result.center.dx, center.dy);
    Offset o2 = _computeCutPoint(center, r, result.center, corner);
    if (left != top) {
      Offset tmp = o1;
      o1 = o2;
      o2 = tmp;
    }
    result.p1 = o1;
    result.p2 = o2;

    ///旋转
    result.center = result.center.rotate(angle, center: center);
    result.p1 = result.p1.rotate(angle, center: center);
    result.p2 = result.p2.rotate(angle, center: center);
    return result;
  }

  ///计算两个圆相切时的切点坐标
  static Offset _computeCutPoint(Offset c1, num r1, Offset c2, num r2) {
    double dx = c1.dx - c2.dx;
    double dy = c1.dy - c2.dy;
    num r12 = r1 * r1;
    num r22 = r2 * r2;

    double d = m.sqrt(dx * dx + dy * dy);
    double l = (r12 - r22 + d * d) / (2 * d);
    double h2 = r12 - l * l;
    double h;
    if (h2.abs() <= 0.00001) {
      h = 0;
    } else {
      h = m.sqrt(h2);
    }

    ///只需要交点1
    double x1 = (c2.dx - c1.dx) * l / d + ((c2.dy - c1.dy) * h / d) + c1.dx;
    double y1 = (c2.dy - c1.dy) * l / d - (c2.dx - c1.dx) * h / d + c1.dy;

    return Offset(x1, y1);
  }
}

final class _CornerOffset {
  Offset center = Offset.zero;
  Offset p1 = Offset.zero;
  Offset p2 = Offset.zero;
}
