import 'dart:math' as m;
import 'dart:ui';

import 'package:dart_graph/src/geomtry/line.dart';
import 'package:dart_graph/src/geomtry/polygon.dart';

import 'arc.dart';

extension OffsetExt on Offset {
  Offset get invert {
    return Offset(-dx, -dy);
  }

  Offset get abs {
    if (dx >= 0 && dy >= 0) {
      return this;
    }
    return Offset(dx.abs(), dy.abs());
  }

  ///求两点之间的距离
  double distance2(Offset p) {
    return distance3(p.dx, p.dy);
  }

  double distance3(num x, num y) {
    return m.sqrt(distanceNotSqrt(x, y));
  }

  double distanceNotSqrt(num x, num y) {
    double a = (dx - x).abs();
    double b = (dy - y).abs();
    return a * a + b * b;
  }

  /// 判断点Q是否在由 p1 p2组成的线段上 允许偏移值
  /// [deviation] 偏差值必须大于等于0
  bool inLine(Offset p1, Offset p2, {double deviation = 4}) {
    return Line.segment(p1, p2).contains(this, deviation: deviation);
  }

  //判断点是否在多边形内部(包含边界)
  bool inPolygon(List<Offset> list) {
    return Polygon(list).containsPoint(this);
  }

  /// 判断点是否在一个扇形上
  /// 向量夹角公式
  bool inSector(
    num innerRadius,
    num outerRadius,
    num startAngle,
    num sweepAngle, {
    Offset center = Offset.zero,
  }) {
    double d1 = distance2(center);
    if (d1 > outerRadius || d1 < innerRadius) {
      return false;
    }
    if (sweepAngle.abs() >= 360) {
      return true;
    }
    return inArc(Arc(
      innerRadius: innerRadius.toDouble(),
      outRadius: outerRadius.toDouble(),
      sweepAngle: sweepAngle.toDouble(),
      startAngle: startAngle.toDouble(),
      center: center,
    ));
  }

  bool inArc(Arc arc) {
    return arc.contains(this);
  }

  bool inCircle(num radius, {Offset center = Offset.zero, bool equal = true}) {
    return inCircle2(radius, center.dx, center.dy, equal);
  }

  bool inCircle2(num radius, [num cx = 0, num cy = 0, bool equal = true]) {
    double a = (dx - cx).abs();
    double b = (dy - cy).abs();
    if (equal) {
      return a * a + b * b <= radius * radius;
    }
    return a * a + b * b < radius * radius;
  }

  /// 给定圆心坐标求当前点的偏移角度
  /// 返回值为角度[0,360]
  double angle([Offset center = Offset.zero]) {
    double d = m.atan2(dy - center.dy, dx - center.dx);
    if (d < 0) {
      d += 2 * m.pi;
    }
    return d * 180 / m.pi;
  }

  ///返回绕center点旋转angle角度后的位置坐标
  ///逆时针 angle 为负数
  ///顺时针 angle 为正数
  Offset rotate(num angle, {Offset center = Offset.zero}) {
    angle = angle % 360;
    num t = angle * Arc.angleUnit;
    double x = (dx - center.dx) * m.cos(t) - (dy - center.dy) * m.sin(t) + center.dx;
    double y = (dx - center.dx) * m.sin(t) + (dy - center.dy) * m.cos(t) + center.dy;
    return Offset(x, y);
  }

  Offset translate2(Offset other) {
    return translate(other.dx, other.dy);
  }

  Offset merge(Offset offset) {
    if (offset == this) {
      return offset;
    }
    return Offset((dx + offset.dx) / 2, (dy + offset.dy) / 2);
  }

  Offset symmetryPoint(Offset start, Offset end) {
    double v1 = (dx - start.dx) * (end.dx - start.dx) + (dy - start.dy) * (end.dy - start.dy);
    double v2 = (end.dx - start.dx) * (end.dx - start.dx) + (end.dy - start.dy) * (end.dy - start.dy);
    double t = v1 / v2;
    double qdx = start.dx + (end.dx - start.dx) * t;
    double qdy = start.dy + (end.dy - start.dy) * t;

    return Offset(2.0 * qdx - dx, 2.0 * qdy - dy);
  }

  bool equal(Offset other, [double accurate = 1e-6]) {
    var x = other.dx - dx;
    var y = other.dy - dy;
    return x.abs() <= accurate && y.abs() <= accurate;
  }
}

///给定一个半径和圆心计算给定角度对应的位置坐标
Offset circlePoint(num radius, num angle, [Offset center = Offset.zero]) {
  return circlePointRadian(radius, angle * Arc.angleUnit, center);
}

Offset circlePointRadian(num radius, num radian, [Offset center = Offset.zero]) {
  double x = center.dx + radius * m.cos(radian);
  double y = center.dy + radius * m.sin(radian);
  return Offset(x, y);
}
