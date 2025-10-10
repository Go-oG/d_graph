import 'dart:math' as m;
import 'dart:math';
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';
import 'package:dts/dts.dart' show Geometry;

class Arc extends BasicGeometry {
  static final zero = Arc();
  static final Angle circleMinAngle = Angle.degrees(359.99);
  static const double cornerMin = 0.001;
  static const double innerMin = 0.01;

  @override
  final Offset center;
  final double innerRadius;
  final double outRadius;
  final Angle startAngle;
  final Angle sweepAngle;
  final double cornerRadius;
  final Angle padAngle;
  late final double maxRadius;

  Arc({
    this.innerRadius = 0,
    this.outRadius = 0,
    this.startAngle = Angle.zero,
    this.sweepAngle = Angle.zero,
    this.cornerRadius = 0,
    this.padAngle = Angle.zero,
    this.center = Offset.zero,
    double? maxRadius,
  }) {
    if (maxRadius != null && maxRadius >= outRadius) {
      this.maxRadius = maxRadius;
    } else {
      this.maxRadius = outRadius;
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
    double? maxRadius,
  }) {
    return Arc(
      innerRadius: innerRadius ?? this.innerRadius,
      outRadius: outRadius ?? this.outRadius,
      startAngle: startAngle ?? this.startAngle,
      sweepAngle: sweepAngle ?? this.sweepAngle,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      padAngle: padAngle ?? this.padAngle,
      center: center ?? this.center,
      maxRadius: maxRadius ?? this.maxRadius,
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
    final double ir = innerRadius <= 0.001 ? 0 : innerRadius.toDouble();
    final double or = outRadius.toDouble();
    final bool clockwise = sweepAngle >= 0.asRadians;
    final int direction = clockwise ? 1 : -1;
    if (sweepAngle.abs >= circleMinAngle) {
      return _buildCircle(center, startAngle, ir, or, direction);
    }
    var corner = m.min(cornerRadius, (or - ir) / 2);
    corner = m.max(corner, 0);

    ///普通扇形
    if (ir <= innerMin) {
      return _buildNormalArc(center, startAngle, sweepAngle, or, corner.toDouble());
    }

    /// 空心扇形
    return _buildEmptyArc(
      center,
      startAngle,
      sweepAngle,
      ir,
      or,
      corner.toDouble(),
      padAngle,
      maxRadius.toDouble(),
    );
  }

  Rect _onBuildBound() {
    return Rect.fromCircle(center: center, radius: outRadius.toDouble());
  }

  Path arcOpen() {
    double r = m.max(innerRadius, outRadius).toDouble();
    if (sweepAngle.abs >= circleMinAngle) {
      return _buildCircle(center, startAngle, 0, r, sweepAngle.radians > 0 ? 1 : -1);
    }

    Path path = Path();
    Offset op = circlePoint(r, startAngle, center);
    path.moveTo(op.dx, op.dy);
    path.arcTo(Rect.fromCircle(center: center, radius: r), startAngle.radians, sweepAngle.radians, false);
    return path;
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
    return Object.hash(innerRadius, outRadius, startAngle, sweepAngle, cornerRadius, center, padAngle, maxRadius);
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
        other.maxRadius == maxRadius;
  }

  ///构建圆形(可能为空心圆)
  static Path _buildCircle(Offset center, Angle startAngle, double ir, double or, int direction) {
    double sweep = direction * (m.pi * 359.99 / 180);

    ///直接为圆相关的
    Path outPath = Path();
    Offset o1 = circlePoint(or, startAngle, center);
    Rect orRect = Rect.fromCircle(center: center, radius: or);
    outPath.moveTo(o1.dx, o1.dy);
    outPath.arcTo(orRect, startAngle.radians, sweep, true);
    outPath.close();
    if (ir <= innerMin) {
      return outPath;
    }

    //在html模式下 不会生效
    Rect irRect = Rect.fromCircle(center: center, radius: ir);
    Path innerPath = Path();
    o1 = circlePoint(ir, startAngle, center);
    innerPath.moveTo(o1.dx, o1.dy);
    innerPath.arcTo(irRect, startAngle.radians, sweep, true);
    innerPath.close();
    return Path.combine(PathOperation.difference, outPath, innerPath);

    ///由于Flutter中的Path.combine 在Web环境下会出现剪切错误的BUG，
    ///因此这里我们自行实现一个路径
    // sweep = angleUnit * 359.9;
    // Path rp = Path();
    //
    // ///Out
    // o1 = circlePoint(or, startAngle, center);
    // rp.moveTo(o1.dx, o1.dy);
    // Offset o2 = circlePoint(or, startAngle + 359.99, center);
    // rp.arcToPoint(o2, radius: Radius.circular(or), largeArc: true, clockwise: true);
    //
    // ///Inner
    // o1 = circlePoint(ir, startAngle, center);
    // rp.moveTo(o1.dx, o1.dy);
    // o2 = circlePoint(ir, startAngle + 359.99, center);
    // rp.arcToPoint(o2, radius: Radius.circular(ir), largeArc: true, clockwise: true);
    // rp.lineTo(o1.dx, o1.dy);
    // rp.close();
    // return rp;
  }

  static Path _buildNormalArc(Offset center, Angle startAngle, Angle sweepAngle, double or, double corner) {
    Path path = Path();
    path.moveTo(center.dx, center.dy);

    ///扫过角度对应的弧长度
    double dd = or * sweepAngle.abs.radians;
    corner = m.min(dd / 2, corner);
    final swRadian = sweepAngle.abs;
    final int direction = sweepAngle.radians < 0 ? -1 : 1;
    final bool clockwise = sweepAngle.radians >= 0;
    Rect orRect = Rect.fromCircle(center: center, radius: or);
    if (corner <= cornerMin) {
      Offset o1 = circlePoint(or, startAngle, center);
      path.lineTo(o1.dx, o1.dy);
      path.arcTo2(orRect, startAngle, swRadian * direction, false);
      path.close();
      return path;
    }

    final Radius cr = Radius.circular(corner);

    final endAngle = startAngle + sweepAngle;

    ///扇形外部有圆角
    _InnerOffset lt = _computeLT(center, or, corner, startAngle);
    _InnerOffset rt = _computeRT(center, or, corner, endAngle);
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

  static Path _buildEmptyArc(
    Offset center,
    Angle startAngle,
    Angle sweepAngle,
    double ir,
    double or,
    double corner,
    Angle padAngle,
    double maxRadius,
  ) {
    final int direction = sweepAngle.radians < 0 ? -1 : 1;
    final bool clockwise = sweepAngle.radians >= 0;
    final Rect orRect = Rect.fromCircle(center: center, radius: or);
    final Rect irRect = Rect.fromCircle(center: center, radius: ir);

    Angle osa = startAngle;
    Angle oea = startAngle + sweepAngle;
    Angle isa = startAngle;
    Angle iea = startAngle + sweepAngle;

    ///修正存在angleGap时视觉上间隔不一致问题(只有innerRadius>0时有效)
    if (padAngle.radians > 0 && ir > 0) {
      List<Angle> al = computeOffsetAngle(ir, or, startAngle, sweepAngle, padAngle, maxRadius);
      isa = al[0];
      iea = al[1];
      osa = al[2];
      oea = al[3];
    }

    ///角度转弧度
    final Angle outRadian = (oea - osa).abs;
    final Angle inRadian = (iea - isa).abs;
    final Angle outStartRadian = osa;
    final Angle inEndRadian = iea;

    final Path path = Path();
    if (corner < cornerMin) {
      ///没有圆角-outer
      path.moveTo2(circlePoint(or, osa, center));
      if (outRadian.radians > 1e-6) {
        path.arcTo(orRect, outStartRadian.radians, outRadian.radians * direction, true);
      }

      ///inner
      path.lineTo2(circlePoint(ir, iea, center));
      if (inRadian.radians > 1e-6) {
        path.arcTo(irRect, inEndRadian.radians, inRadian.radians * direction * -1, false);
      }
      path.close();
      return path;
    }

    ///计算外圆环和内圆环的最小corner
    final num outLength = or * outRadian.radians;
    final num inLength = ir * inRadian.radians;
    double outCorner = corner;
    double inCorner = corner;
    if (corner * m.pi > outLength) {
      outCorner = outLength / m.pi;
    }
    if (outRadian.radians <= 1e-6) {
      outCorner = 0;
    }
    if (corner * m.pi > inLength) {
      inCorner = inLength / m.pi;
    }
    if (inRadian.radians <= 1e-6) {
      inCorner = 0;
    }

    ///外圈层
    if (outCorner >= cornerMin) {
      final Radius radius = Radius.circular(outCorner);
      var lt = _computeLT(center, or, outCorner, clockwise ? osa : oea);
      var rt = _computeRT(center, or, outCorner, clockwise ? oea : osa);
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
      path.arcTo2(orRect, a, b - a, false);
      path.lineTo2(clockwise ? rt.p1 : lt.p2);
      path.arcToPoint(clockwise ? rt.p2 : lt.p1, radius: radius, largeArc: false, clockwise: clockwise);
    } else {
      path.moveTo2(circlePoint(or, osa, center));
      if (outRadian.radians > 1e-6) {
        path.arcTo2(orRect, outStartRadian, outRadian * direction, false);
      }
    }

    ///内圈层
    if (inCorner >= cornerMin) {
      final Radius radius = Radius.circular(inCorner);
      var lb = _computeLB(center, ir, inCorner, clockwise ? isa : iea);
      var rb = _computeRB(center, ir, inCorner, clockwise ? iea : isa);
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
      path.arcTo2(irRect, a, b - a, false);
      path.lineTo2(clockwise ? lb.p1 : rb.p2);
      path.arcToPoint(clockwise ? lb.p2 : rb.p1, radius: radius, largeArc: false, clockwise: clockwise);
    } else {
      path.lineTo2(circlePoint(ir, iea, center));
      if (inRadian.radians > 1e-6) {
        path.arcTo2(irRect, inEndRadian, inRadian * -1 * direction, false);
      }
    }
    path.close();
    return path;
  }

  static List<Angle> computeOffsetAngle(
    double ir,
    double or,
    Angle startAngle,
    Angle sweepAngle,
    Angle padAngle,
    double maxRadius,
  ) {
    List<Angle> il = [startAngle, startAngle + sweepAngle];
    il = adjustAngle(ir, startAngle, sweepAngle, padAngle, maxRadius);

    List<Angle> ol = adjustAngle(or, startAngle, sweepAngle, padAngle, maxRadius);
    return [...il, ...ol];
  }

  static List<Angle> adjustAngle(double r, Angle startAngle, Angle sweepAngle, Angle padAngle, double maxRadius) {
    final radian = padAngle * 0.5;
    final gap = maxRadius * radian.sin;
    var sa = startAngle, ea = startAngle + sweepAngle;
    final dis = r * radian.sin;
    if (dis == gap) {
      return [sa, ea];
    }
    var diff = m.asin(gap / r).asRadians;
    if (diff.radians.isNaN) {
      var s = startAngle + sweepAngle / 2;
      return [s, s];
    }

    diff = dis > gap ? radian - diff : diff - radian;
    diff *= 180 / m.pi;
    bool b1 = dis > gap;
    bool b2 = sweepAngle.radians >= 0;
    if (b1 == b2) {
      sa -= diff;
      ea += diff;
    } else {
      sa += diff;
      ea -= diff;
    }
    if (sweepAngle.radians >= 0 && ea < sa) {
      sa = ea = (startAngle + sweepAngle * 0.5);
    }
    if (sweepAngle.radians < 0 && ea > sa) {
      ea = sa = (startAngle + sweepAngle * 0.5);
    }
    return [sa, ea];
  }

  static _InnerOffset _computeLT(Offset center, num outRadius, num corner, Angle angle) {
    return _computeCornerPoint(center, outRadius, corner, angle, true, true);
  }

  static _InnerOffset _computeRT(Offset center, num outRadius, num corner, Angle angle) {
    return _computeCornerPoint(center, outRadius, corner, angle, false, true);
  }

  static _InnerOffset _computeLB(Offset center, num innerRadius, num corner, Angle angle) {
    return _computeCornerPoint(center, innerRadius, corner, angle, true, false);
  }

  static _InnerOffset _computeRB(Offset center, num innerRadius, num corner, Angle angle) {
    return _computeCornerPoint(center, innerRadius, corner, angle, false, false);
  }

  ///计算切点位置
  static _InnerOffset _computeCornerPoint(Offset center, num r, num corner, Angle angle, bool left, bool top) {
    _InnerOffset result = _InnerOffset();
    num dis = (r + corner * (top ? -1 : 1)).abs();
    double x = m.sqrt(dis * dis - corner * corner);
    Offset c = Offset(x, corner.toDouble() * (left ? 1 : -1));
    result.center = c.translate(center.dx, center.dy);
    Offset o1 = Offset(result.center.dx, center.dy);
    Offset o2 = computeCutPoint(center, r, result.center, corner);
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
  static Offset computeCutPoint(Offset c1, num r1, Offset c2, num r2) {
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

    ///交点1
    double x1 = (c2.dx - c1.dx) * l / d + ((c2.dy - c1.dy) * h / d) + c1.dx;
    double y1 = (c2.dy - c1.dy) * l / d - (c2.dx - c1.dx) * h / d + c1.dy;

    // ///交点2
    // double x2 = (c2.dx - c1.dx) * l / d - ((c2.dy - c1.dy) * h / d) + c1.dx;
    // double y2 = (c2.dy - c1.dy) * l / d + (c2.dx - c1.dx) * h / d + c1.dy;

    return Offset(x1, y1);
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
}

final class _InnerOffset {
  Offset center = Offset.zero;
  Offset p1 = Offset.zero;
  Offset p2 = Offset.zero;
}
