import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';

abstract class CurveUtil {
  CurveUtil._();

  static Curve ofLine(Offset start, Offset end) {
    return Curve(start: start, end: end, c1: start, c2: end);
  }

  static Curve ofQuadratic(Offset start, Offset end, Offset control) {
    final control1 = start + (control - start) * 0.666667;
    final control2 = end + (control - end) * 0.666667;
    return Curve(start: start, end: end, c1: control1, c2: control2);
  }

  ///所有单位都为弧度
  static Curve ofArc(Rect rect, Angle startAngle, Angle sweepAngle, bool forceMoveTo) {
    final sinA = startAngle.sin;

    final cosA = startAngle.cos;
    final sinE = (startAngle + sweepAngle).sin;
    final cosE = (startAngle + sweepAngle).cos;

    final a = max(rect.width, rect.height) / 2;
    final b = min(rect.width, rect.height) / 2;

    final center = rect.center;
    final cx = center.dx;
    final cy = center.dy;

    final start = Offset(center.dx + a * cosA, center.dy + b * sinA);
    final end = Offset(center.dx + a * cosE, center.dy + b * sinE);
    final v = 1.3333333 * (sweepAngle * 0.25).tan;
    var c1x = cx + a * cosA - v * b * sinA;
    var c1y = cy + b * sinA + v * a * cosA;
    var c2x = cx + a * cosE + v * b * sinE;
    var c2y = cy + b * sinE - v * a * cosE;

    final control1 = Offset(c1x, c1y);
    final control2 = Offset(c2x, c2y);
    return Curve(start: start, end: end, c1: control1, c2: control2);
  }

  static Curve ofArc2(
    Offset start,
    Offset end,
    Radius radius,
    double rotation,
    bool largeArc,
    bool clockwise,
  ) {
    final r = max(radius.x, radius.y);
    double angle = acos((start.dx - end.dx) / (2 * r));
    if (!clockwise) {
      angle = -angle;
    }
    double controlLength = r * 4 / 3 * tan(angle / 4);
    double cosRotation = cos(rotation);
    double sinRotation = sin(rotation);

    final control1 = Offset(
      start.dx + controlLength * cosRotation,
      start.dy + controlLength * sinRotation,
    );
    final control2 = Offset(
      end.dx - controlLength * cosRotation,
      end.dy - controlLength * sinRotation,
    );
    return Curve(start: start, end: end, c1: control1, c2: control2);
  }

  static List<Curve> ofOval(Rect rect) {
    const k = 0.5522847498;

    final p1 = rect.centerRight;
    final p2 = rect.bottomCenter;
    final p3 = rect.centerLeft;
    final p4 = rect.topCenter;

    final tx = rect.center.dx;
    final ty = rect.center.dy;

    final a = rect.width / 2;
    final b = rect.height / 2;

    // 贝塞尔曲线控制点
    final cp1 = Offset(tx + a, ty + k * b);
    final cp2 = Offset(tx + k * a, ty + b);

    final cp3 = Offset(tx - k * a, ty + b);
    final cp4 = Offset(tx - a, ty + k * b);

    final cp5 = Offset(tx - a, ty - k * b);
    final cp6 = Offset(tx - k * a, ty - b);

    final cp7 = Offset(tx + k * a, ty - b);
    final cp8 = Offset(tx + a, ty - k * b);

    final cubic1 = Curve(start: p1, end: p2, c1: cp1, c2: cp2);
    final cubic2 = Curve(start: p2, end: p3, c1: cp3, c2: cp4);
    final cubic3 = Curve(start: p3, end: p4, c1: cp5, c2: cp6);
    final cubic4 = Curve(start: p4, end: p1, c1: cp7, c2: cp8);

    return [cubic4, cubic1, cubic2, cubic3];
  }

  static List<Curve> ofCircle(Offset center, double radius) {
    return ofOval(Rect.fromCircle(center: center, radius: radius));
  }

  static List<Curve> ofRRect(RRect rect) {
    final k = 1 - sqrt(2) / 2;
    final left = rect.left;
    final top = rect.top;
    final right = rect.right;
    final bottom = rect.bottom;

    // 计算四个角的控制点
    var cubic1 = Curve(
      start: Offset(left, top + rect.tlRadiusY),
      end: Offset(left + rect.tlRadiusX, top),
      c1: Offset(left, top + rect.tlRadiusY * k),
      c2: Offset(left + rect.tlRadiusX * k, top),
    );

    final cubic2 = Curve(
      start: Offset(right - rect.trRadiusX, top),
      end: Offset(right, top + rect.trRadiusY),
      c1: Offset(right - rect.trRadiusX * k, top),
      c2: Offset(right, top + rect.trRadiusY * k),
    );

    final cubic3 = Curve(
      start: Offset(right, bottom - rect.brRadiusY),
      end: Offset(right - rect.brRadiusX, bottom),
      c1: Offset(right, bottom - rect.brRadiusY * k),
      c2: Offset(right - rect.brRadiusX * k, bottom),
    );

    final cubic4 = Curve(
      start: Offset(left + rect.blRadiusX, bottom),
      end: Offset(left, bottom - rect.blRadiusY),
      c1: Offset(left + rect.blRadiusX * k, bottom),
      c2: Offset(left, bottom - rect.blRadiusY * k),
    );
    return [
      cubic1,
      ofLine(cubic1.end, cubic2.start),
      cubic2,
      ofLine(cubic2.end, cubic3.start),
      cubic3,
      ofLine(cubic3.end, cubic4.start),
      cubic4,
      ofLine(cubic4.end, cubic1.start),
    ];
  }

  static Curve lerp(Curve start, Curve end, double t) {
    final s = Offset.lerp(start.start, end.start, t)!;
    final e = Offset.lerp(start.end, end.end, t)!;
    final c1 = Offset.lerp(start.c1, end.c1, t)!;
    final c2 = Offset.lerp(start.c2, end.c2, t)!;
    return Curve(start: s, end: e, c1: c1, c2: c2);
  }

  static List<Curve> fromArc(Offset center, double radius, Angle startAngle, Angle sweepAngle) {
    double sa = startAngle.radians;
    double swa = sweepAngle.radians;

    const maxSweep = pi / 2;
    final List<Curve> beziers = [];

    final int segments = (swa.abs() / maxSweep).ceil();
    final double delta = swa / segments;

    for (int i = 0; i < segments; i++) {
      final double theta1 = sa + i * delta;
      final double theta2 = theta1 + delta;

      final p0 = Offset(center.dx + radius * cos(theta1), center.dy + radius * sin(theta1));

      final p3 = Offset(center.dx + radius * cos(theta2), center.dy + radius * sin(theta2));

      final alpha = (4 / 3) * tan((theta2 - theta1) / 4);

      final dx1 = -radius * sin(theta1) * alpha;
      final dy1 = radius * cos(theta1) * alpha;
      final dx2 = radius * sin(theta2) * alpha;
      final dy2 = -radius * cos(theta2) * alpha;

      final p1 = Offset(p0.dx + dx1, p0.dy + dy1);
      final p2 = Offset(p3.dx + dx2, p3.dy + dy2);

      beziers.add(Curve(start: p0, c1: p1, c2: p2, end: p3));
    }
    return beziers;
  }

  static List<Curve> buildCurve(
    List<Offset> dataList, {
    double smooth = 0.5,
    bool reversed = false,
    List<double> dash = const [],
    bool round = false,
  }) {
    if (dataList.isEmpty) {
      return [];
    }
    // if(round){
    //   dataList=dataList.map((e)=>e.round).toList();
    // }

    if (dataList.length == 1) {
      return [Curve(start: dataList.first, end: dataList.first, c1: dataList.first, c2: dataList.first)];
    }

    List<Offset> points = reversed ? List.from(dataList.reversed) : List.from(dataList);
    final controlPoints = _computeControlPoints(points, smooth);

    final resultList = <Curve>[];

    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final c1 = controlPoints[i].second;
      final c2 = controlPoints[i + 1].first;
      resultList.add(Curve(start: start, end: end, c1: c1, c2: c2));
    }

    return resultList;
  }

  static List<Pair<Offset, Offset>> _computeControlPoints(List<Offset> points, double smoothFactor) {
    final controlPoints = <Pair<Offset, Offset>>[];
    final n = points.length;
    for (var i = 0; i < n; i++) {
      Offset tangent;
      if (i == 0) {
        tangent = points[i + 1] - points[i];
      } else if (i == n - 1) {
        tangent = points[i] - points[i - 1];
      } else {
        tangent = (points[i + 1] - points[i - 1]) * smoothFactor;
      }
      final control1 = Offset(points[i].dx - tangent.dx / 3, points[i].dy);
      final control2 = Offset(points[i].dx + tangent.dx / 3, points[i].dy);
      controlPoints.add(Pair(control1, control2));
    }
    return controlPoints;
  }
}

extension CurveExt on Iterable<Curve?> {
  Path toCurvePath(bool close) {
    Path path = Path();
    bool hasMoved = false;
    bool hasBreakPoint = false;
    for (final curve in this) {
      if (curve == null) {
        if (close) {
          throw StateError("");
        }
        hasBreakPoint = true;
        hasMoved = false;
        continue;
      }
      if (!hasMoved) {
        hasMoved = true;
        path.moveTo2(curve.start);
      }
      if (curve.isLine) {
        path.lineTo2(curve.end);
      } else {
        path.cubicTo(curve.c1.dx, curve.c1.dy, curve.c2.dx, curve.c2.dy, curve.end.dx, curve.end.dy);
      }
    }
    if (close && !hasBreakPoint) {
      path.close();
    }
    return path;
  }
}
