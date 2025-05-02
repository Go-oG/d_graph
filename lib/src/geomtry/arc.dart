import 'dart:ui';
import 'dart:math' as m;

import 'package:dart_graph/src/geomtry/offset_ext.dart';
import 'package:dart_graph/src/geomtry/path_ext.dart';

class Arc {
  static const angleUnit = m.pi / 180;
  static final zero = Arc();
  static const double circleMinAngle = 359.99;
  static const double cornerMin = 0.001;
  static const double innerMin = 0.01;

  final Offset center;
  final double innerRadius;
  final double outRadius;
  final double startAngle;
  final double sweepAngle;
  final double cornerRadius;
  final double padAngle;
  late final double maxRadius;

  Path? _path;

  Arc({
    this.innerRadius = 0,
    this.outRadius = 0,
    this.startAngle = 0,
    this.sweepAngle = 0,
    this.cornerRadius = 0,
    this.padAngle = 0,
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
    double? startAngle,
    double? sweepAngle,
    double? cornerRadius,
    double? padAngle,
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

  Path get path {
    final pp = _path;
    if (pp != null) {
      return pp;
    }
    final double ir = innerRadius <= 0.001 ? 0 : innerRadius.toDouble();
    final double or = outRadius.toDouble();
    final bool clockwise = sweepAngle >= 0;
    final int direction = clockwise ? 1 : -1;
    if (sweepAngle.abs() >= circleMinAngle) {
      _path = _buildCircle(center, startAngle, ir, or, direction);
      return _path!;
    }
    var corner = m.min(cornerRadius, (or - ir) / 2);
    corner = m.max(corner, 0);

    ///普通扇形
    if (ir <= innerMin) {
      _path = _buildNormalArc(center, startAngle.toDouble(), sweepAngle.toDouble(), or, corner.toDouble());
      return _path!;
    }

    /// 空心扇形
    _path = _buildEmptyArc(
      center,
      startAngle.toDouble(),
      sweepAngle.toDouble(),
      ir,
      or,
      corner.toDouble(),
      padAngle.toDouble(),
      maxRadius.toDouble(),
    );
    return _path!;
  }

  Rect onBuildBound() {
    return Rect.fromCircle(center: center, radius: outRadius.toDouble());
  }

  Path arcOpen() {
    double r = m.max(innerRadius, outRadius).toDouble();
    if (sweepAngle.abs() >= circleMinAngle) {
      return _buildCircle(center, startAngle, 0, r, sweepAngle > 0 ? 1 : -1);
    }

    Path path = Path();
    Offset op = circlePoint(r, startAngle, center);
    path.moveTo(op.dx, op.dy);
    path.arcTo(Rect.fromCircle(center: center, radius: r), startAngle * angleUnit, sweepAngle * angleUnit, false);
    return path;
  }

  Offset centroid() {
    var r = (innerRadius + outRadius) / 2;
    var a = (startAngle + endAngle) / 2;
    return circlePoint(r, a, center);
  }

  double centerAngle() {
    return startAngle + (sweepAngle / 2);
  }

  double get startRadian => startAngle * angleUnit;

  double get endRadian => endAngle * angleUnit;

  double get endAngle => (startAngle + sweepAngle).toDouble();

  double get sweepRadian => sweepAngle * angleUnit;

  bool get isEmpty {
    return (sweepAngle.abs()) == 0 || (outRadius - innerRadius).abs() == 0;
  }

  bool contains(Offset offset) {
    double d1 = offset.distance2(center);
    if (d1 > outRadius || d1 < innerRadius) {
      return false;
    }
    if (sweepAngle.abs() >= 360) {
      return true;
    }
    return path.contains(offset);
  }

  @override
  String toString() {
    return 'IR:${innerRadius.toStringAsFixed(1)} OR:${outRadius.toStringAsFixed(1)} SA:${startAngle.toStringAsFixed(1)} '
        'EA:${endAngle.toStringAsFixed(1)} center:$center';
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
  static Path _buildCircle(Offset center, num startAngle, double ir, double or, int direction) {
    double sweep = direction * (m.pi * 359.99 / 180);

    ///直接为圆相关的
    Path outPath = Path();
    Offset o1 = circlePoint(or, startAngle, center);
    Rect orRect = Rect.fromCircle(center: center, radius: or);
    outPath.moveTo(o1.dx, o1.dy);
    outPath.arcTo(orRect, startAngle * angleUnit, sweep, true);
    outPath.close();
    if (ir <= innerMin) {
      return outPath;
    }

    //  if (!isWeb) {
    Rect irRect = Rect.fromCircle(center: center, radius: ir);
    Path innerPath = Path();
    o1 = circlePoint(ir, startAngle, center);
    innerPath.moveTo(o1.dx, o1.dy);
    innerPath.arcTo(irRect, startAngle * angleUnit, sweep, true);
    innerPath.close();
    return Path.combine(PathOperation.difference, outPath, innerPath);
    //   }

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

  ///构建普通的扇形
  static Path _buildNormalArc(Offset center, double startAngle, double sweepAngle, double or, double corner) {
    Path path = Path();
    path.moveTo(center.dx, center.dy);

    ///扫过角度对应的弧长度
    double dd = or * sweepAngle.abs() * angleUnit;
    corner = m.min(dd / 2, corner);
    final swRadian = sweepAngle.abs() * angleUnit;
    final int direction = sweepAngle < 0 ? -1 : 1;
    final bool clockwise = sweepAngle >= 0;
    Rect orRect = Rect.fromCircle(center: center, radius: or);
    if (corner <= cornerMin) {
      Offset o1 = circlePoint(or, startAngle, center);
      path.lineTo(o1.dx, o1.dy);
      path.arcTo(orRect, startAngle * angleUnit, swRadian * direction, false);
      path.close();
      return path;
    }

    final Radius cr = Radius.circular(corner);

    final endAngle = startAngle + sweepAngle;

    ///扇形外部有圆角
    InnerOffset lt = _computeLT(center, or, corner, startAngle);
    InnerOffset rt = _computeRT(center, or, corner, endAngle);
    path.lineTo2(clockwise ? lt.p1 : rt.p2);
    path.arcToPoint(clockwise ? lt.p2 : rt.p1, radius: cr, largeArc: false, clockwise: clockwise);

    double a, b;
    if (clockwise) {
      a = lt.p2.angle(center) * angleUnit;
      b = rt.p1.angle(center) * angleUnit;
      if (b < a) {
        b += 2 * m.pi;
      }
    } else {
      a = rt.p1.angle(center) * angleUnit;
      b = lt.p2.angle(center) * angleUnit;
      if (b > a) {
        b -= 2 * m.pi;
      }
    }
    path.arcTo(orRect, a, b - a, false);
    path.arcToPoint(clockwise ? rt.p2 : lt.p1, radius: cr, largeArc: false, clockwise: clockwise);
    path.close();
    return path;
  }

  static Path _buildEmptyArc(
    Offset center,
    double startAngle,
    double sweepAngle,
    double ir,
    double or,
    double corner,
    double padAngle,
    double maxRadius,
  ) {
    final int direction = sweepAngle < 0 ? -1 : 1;
    final bool clockwise = sweepAngle >= 0;
    final Rect orRect = Rect.fromCircle(center: center, radius: or);
    final Rect irRect = Rect.fromCircle(center: center, radius: ir);

    double osa = startAngle;
    double oea = startAngle + sweepAngle;
    double isa = startAngle;
    double iea = startAngle + sweepAngle;

    ///修正存在angleGap时视觉上间隔不一致问题(只有innerRadius>0时有效)
    if (padAngle > 0 && ir > 0) {
      List<num> al = computeOffsetAngle(ir, or, startAngle, sweepAngle, padAngle, maxRadius);
      isa = al[0].toDouble();
      iea = al[1].toDouble();
      osa = al[2].toDouble();
      oea = al[3].toDouble();
    }

    ///角度转弧度
    final double outRadian = (oea - osa).abs() * angleUnit;
    final double inRadian = (iea - isa).abs() * angleUnit;
    final double outStartRadian = osa * angleUnit;
    final double inEndRadian = iea * angleUnit;

    final Path path = Path();
    if (corner < cornerMin) {
      ///没有圆角-outer
      path.moveTo2(circlePoint(or, osa, center));
      if (outRadian > 1e-6) {
        path.arcTo(orRect, outStartRadian, outRadian * direction, true);
      }

      ///inner
      path.lineTo2(circlePoint(ir, iea, center));
      if (inRadian > 1e-6) {
        path.arcTo(irRect, inEndRadian, inRadian * direction * -1, false);
      }
      path.close();
      return path;
    }

    ///计算外圆环和内圆环的最小corner
    final num outLength = or * outRadian;
    final num inLength = ir * inRadian;
    double outCorner = corner;
    double inCorner = corner;
    if (corner * m.pi > outLength) {
      outCorner = outLength / m.pi;
    }
    if (outRadian <= 1e-6) {
      outCorner = 0;
    }
    if (corner * m.pi > inLength) {
      inCorner = inLength / m.pi;
    }
    if (inRadian <= 1e-6) {
      inCorner = 0;
    }

    ///外圈层
    if (outCorner >= cornerMin) {
      final Radius radius = Radius.circular(outCorner);
      var lt = _computeLT(center, or, outCorner, clockwise ? osa : oea);
      var rt = _computeRT(center, or, outCorner, clockwise ? oea : osa);
      path.moveTo2(clockwise ? lt.p1 : rt.p2);
      path.arcToPoint(clockwise ? lt.p2 : rt.p1, radius: radius, largeArc: false, clockwise: clockwise);
      double a, b;
      a = (clockwise ? lt.p2 : rt.p1).angle(center) * angleUnit;
      b = (clockwise ? rt.p1 : lt.p2).angle(center) * angleUnit;
      if (clockwise && b < a) {
        b += 2 * m.pi;
      }
      if (!clockwise && b > a) {
        a += 2 * m.pi;
      }
      path.arcTo(orRect, a, b - a, false);
      path.lineTo2(clockwise ? rt.p1 : lt.p2);
      path.arcToPoint(clockwise ? rt.p2 : lt.p1, radius: radius, largeArc: false, clockwise: clockwise);
    } else {
      path.moveTo2(circlePoint(or, osa, center));
      if (outRadian > 1e-6) {
        path.arcTo(orRect, outStartRadian, outRadian * direction, false);
      }
    }

    ///内圈层
    if (inCorner >= cornerMin) {
      final Radius radius = Radius.circular(inCorner);
      var lb = _computeLB(center, ir, inCorner, clockwise ? isa : iea);
      var rb = _computeRB(center, ir, inCorner, clockwise ? iea : isa);
      path.lineTo2(clockwise ? rb.p1 : lb.p2);
      path.arcToPoint(clockwise ? rb.p2 : lb.p1, radius: radius, largeArc: false, clockwise: clockwise);
      double a, b;
      a = (clockwise ? rb.p2 : lb.p1).angle(center) * angleUnit;
      b = (clockwise ? lb.p1 : rb.p2).angle(center) * angleUnit;
      if (clockwise && b > a) {
        b -= 2 * m.pi;
      }
      if (!clockwise && a > b) {
        a -= 2 * m.pi;
      }
      path.arcTo(irRect, a, b - a, false);
      path.lineTo2(clockwise ? lb.p1 : rb.p2);
      path.arcToPoint(clockwise ? lb.p2 : rb.p1, radius: radius, largeArc: false, clockwise: clockwise);
    } else {
      path.lineTo2(circlePoint(ir, iea, center));
      if (inRadian > 1e-6) {
        path.arcTo(irRect, inEndRadian, -1 * inRadian * direction, false);
      }
    }
    path.close();
    return path;
  }

  static List<num> computeOffsetAngle(
    double ir,
    double or,
    double startAngle,
    double sweepAngle,
    double padAngle,
    double maxRadius,
  ) {
    List<num> il = [startAngle, startAngle + sweepAngle];
    il = adjustAngle(ir, startAngle, sweepAngle, padAngle, maxRadius);

    List<num> ol = adjustAngle(or, startAngle, sweepAngle, padAngle, maxRadius);
    return [...il, ...ol];
  }

  static List<num> adjustAngle(double r, double startAngle, double sweepAngle, double padAngle, double maxRadius) {
    final radian = padAngle * angleUnit * 0.5;
    final gap = maxRadius * m.sin(radian);
    var sa = startAngle, ea = startAngle + sweepAngle;
    final dis = r * m.sin(radian);
    if (dis == gap) {
      return [sa, ea];
    }
    var diff = m.asin(gap / r);
    if (diff.isNaN) {
      var s = startAngle + sweepAngle / 2;
      return [s, s];
    }

    diff = dis > gap ? radian - diff : diff - radian;
    diff *= 180 / m.pi;
    bool b1 = dis > gap;
    bool b2 = sweepAngle >= 0;
    if (b1 == b2) {
      sa -= diff;
      ea += diff;
    } else {
      sa += diff;
      ea -= diff;
    }
    if (sweepAngle >= 0 && ea < sa) {
      sa = ea = (startAngle + sweepAngle * 0.5);
    }
    if (sweepAngle < 0 && ea > sa) {
      ea = sa = (startAngle + sweepAngle * 0.5);
    }
    return [sa, ea];
  }

  static InnerOffset _computeLT(Offset center, num outRadius, num corner, num angle) {
    return _computeCornerPoint(center, outRadius, corner, angle, true, true);
  }

  static InnerOffset _computeRT(Offset center, num outRadius, num corner, num angle) {
    return _computeCornerPoint(center, outRadius, corner, angle, false, true);
  }

  static InnerOffset _computeLB(Offset center, num innerRadius, num corner, num angle) {
    return _computeCornerPoint(center, innerRadius, corner, angle, true, false);
  }

  static InnerOffset _computeRB(Offset center, num innerRadius, num corner, num angle) {
    return _computeCornerPoint(center, innerRadius, corner, angle, false, false);
  }

  ///计算切点位置
  static InnerOffset _computeCornerPoint(Offset center, num r, num corner, num angle, bool left, bool top) {
    InnerOffset result = InnerOffset();
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
}

class InnerOffset {
  Offset center = Offset.zero;
  Offset p1 = Offset.zero;
  Offset p2 = Offset.zero;
}
