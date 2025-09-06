import 'dart:math' as m;

import 'package:dart_graph/dart_graph.dart';
import 'package:dts/dts.dart' as dt;
import 'package:flutter/material.dart';

final geomFactory = dt.GeometryFactory();

///给定一个半径和圆心计算给定角度对应的位置坐标
Offset circlePoint(num radius, num angle, [Offset center = Offset.zero]) {
  return circlePointRadian(radius, angle * Arc.angleUnit, center);
}

Offset circlePointRadian(num radius, num radian, [Offset center = Offset.zero]) {
  double x = center.dx + radius * m.cos(radian);
  double y = center.dy + radius * m.sin(radian);
  return Offset(x, y);
}

int computeCircleSegments(double radius, {double maxError = 0.1}) {
  if (radius <= 0) return 8;
  if (maxError <= 0) maxError = 0.01;

  double anglePerSegment = 2 * m.acos(1 - maxError / radius);
  int segments = (2 * m.pi / anglePerSegment).ceil();
  return segments.clamp(8, 100);
}
