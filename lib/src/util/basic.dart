import 'dart:math' as m;

import 'package:dts/dts.dart' as dt;

final geomFactory = dt.GeometryFactory();

int computeCircleSegments(double radius, {double maxError = 0.1}) {
  if (radius <= 0) return 8;
  if (maxError <= 0) maxError = 0.01;

  final cosValue = (1 - maxError / radius).clamp(-1.0, 1.0);
  double anglePerSegment = 2 * m.acos(cosValue);
  if (anglePerSegment <= 0) return 100;
  int segments = (2 * m.pi / anglePerSegment).ceil();
  return segments.clamp(8, 100);
}
