import 'dart:math' as m;
import 'dart:ui';

import 'package:d_graph/src/geomtry/line.dart';

import 'polygon.dart';

extension RectExt on Rect {
  bool contains2(Offset offset) {
    return offset.dx >= left && offset.dx <= right && offset.dy >= top && offset.dy <= bottom;
  }

  bool contains3(num x, num y) {
    return x >= left && x <= right && y >= top && y <= bottom;
  }

  ///判断当前矩形是否和给定圆有交点
  bool overlapCircle(Offset center, num radius) {
    return overlapCircle2(center.dx, center.dy, radius);
  }

  bool overlapCircle2(double cx, double cy, num radius) {
    if (contains3(cx, cy)) {
      return true;
    }

    ///https://blog.csdn.net/noahzuo/article/details/52037151
    ///右上角顶点向量a
    var hx = width * 0.5;
    var hy = height * 0.5;

    ///翻转圆心到第一象限并求圆心间向量
    var vx = (center.dx - cx).abs();
    var vy = (center.dy - cy).abs();

    var cx2 = m.max(vx - hx, 0);
    var cy2 = m.max(vy - hy, 0);
    return (cx2 * cx2 + cy2 * cy2) <= radius * radius;
  }

  ///判断当前矩形是否和给定的线段重合
  bool overlapLine(Offset p0, Offset p1) {
    if (contains2(p0) || contains2(p1)) {
      return true;
    }

    return Line.segment(p0, p1).isCrossLine(Line.segment(topLeft, bottomRight));
  }

  String toString2() {
    return 'LTRB(${left.toStringAsFixed(1)}, ${top.toStringAsFixed(1)}, ${right.toStringAsFixed(1)}, ${bottom.toStringAsFixed(1)})';
  }

  ///返回一个新矩形 其每条边向内缩减指定量
  Rect deflate2({num left = 0, num right = 0, num top = 0, num bottom = 0}) {
    if (left == 0 && right == 0 && top == 0 && bottom == 0) {
      return this;
    }
    return Rect.fromLTRB(this.left - left, this.top - top, this.right - right, this.bottom - bottom);
  }

  double get centerX {
    return left + width / 2;
  }

  double get centerY {
    return top + height / 2;
  }

  bool containsPolygon(Polygon polygon) {
    double xMin = left;
    double yMin = top;
    double xMax = right;
    double yMax = bottom;

    for (var point in polygon.vertex) {
      if (point.dx < xMin || point.dx > xMax || point.dy < yMin || point.dy > yMax) {
        return false;
      }
    }
    return true;
  }

  Path toPath() {
    Path path = Path();
    path.moveTo(left, top);
    path.lineTo(right, top);
    path.lineTo(right, bottom);
    path.lineTo(left, bottom);
    path.close();
    return path;
  }
}

extension RRectExt on RRect {
  Path toPath() {
    final path = Path();
    path.moveTo(left + tlRadiusX, top);
    path.lineTo(right - trRadiusX, top);
    path.arcToPoint(Offset(right, top + trRadiusY), radius: trRadius, clockwise: false);
    path.lineTo(right, bottom - brRadiusY);
    path.arcToPoint(Offset(right - brRadiusX, bottom), radius: brRadius, clockwise: false);
    path.lineTo(left + blRadiusX, bottom);
    path.arcToPoint(Offset(left, bottom - blRadiusY), radius: blRadius, clockwise: false);
    path.lineTo(left, top + tlRadiusY);
    path.arcToPoint(Offset(left + tlRadiusX, top), radius: tlRadius, clockwise: false);
    path.close();
    return path;
  }
}
