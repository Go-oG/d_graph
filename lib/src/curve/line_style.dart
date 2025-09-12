import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:dart_graph/src/curve/curve_util.dart';
import 'package:flutter/foundation.dart';

import 'curve.dart';

interface class LineStyle {
  List<Curve> apply(List<Offset> points) {
    throw UnimplementedError();
  }
}

class NormalLineStyle implements LineStyle {
  const NormalLineStyle();

  @override
  List<Curve> apply(List<Offset> points) {
    if (points.length < 2) {
      return const [];
    }
    List<Curve> list = [];
    for (int i = 0; i < points.length - 1; i++) {
      list.add(CurveUtil.ofLine(points[i], points[i + 1]));
    }
    return list;
  }
}

class StepLineStyle implements LineStyle {
  static const _kAfter = 1;
  static const _kBefore = 2;
  static const _kCenter = 2;

  final int _type;

  const StepLineStyle.after() : _type = _kAfter;

  const StepLineStyle.before() : _type = _kBefore;

  const StepLineStyle.center() : _type = _kCenter;

  @override
  List<Curve> apply(List<Offset> points) {
    if (points.length < 2) {
      return const [];
    }
    List<List<Offset>> list = [];
    for (int i = 0; i < points.length - 1; i++) {
      Offset s = points[i];
      Offset e = points[i + 1];
      Offset cen;
      if (_type == _kBefore) {
        cen = Offset(s.dx, e.dy);
      } else if (_type == _kCenter) {
        cen = Offset((s.dx + e.dx) / 2, (s.dy + e.dy) / 2);
      } else {
        cen = Offset(e.dx, s.dy);
      }
      list.add([s, cen, e]);
    }
    List<Curve> curveList = [];
    for (var pl in list) {
      curveList.add(CurveUtil.ofLine(pl[0], pl[1]));
      curveList.add(CurveUtil.ofLine(pl[1], pl[2]));
    }
    return curveList;
  }
}

abstract class CurveStyle implements LineStyle {
  final double smooth;

  const CurveStyle({required this.smooth});

  @override
  @nonVirtual
  List<Curve> apply(List<Offset> points) {
    if (points.length < 2) {
      return [];
    }
    return onApply(points, smooth);
  }

  @protected
  List<Curve> onApply(List<Offset> points, double smooth);

  @protected
  List<Offset> fillPointsIfNeed(List<Offset> points, int minCount) {
    if (points.length >= minCount) {
      return points;
    }
    points = List.from(points);
    bool useStart = true;
    while (points.length < minCount) {
      if (useStart) {
        points.insert(0, points.first);
      } else {
        points.add(points.last);
      }
      useStart = !useStart;
    }
    return points;
  }

  @protected
  Offset lerp(Offset a, Offset b, double t) => Offset.lerp(a, b, t)!;

  @protected
  Offset bezierPoint(Offset a, Offset b, Offset c, List<double> multiArgs, double dived) {
    if (multiArgs.length != 3 || dived == 0) {
      throw ArgumentError("");
    }

    if (multiArgs[0] != 1) {
      a = a * multiArgs[0];
    }
    if (multiArgs[1] != 1) {
      b = b * multiArgs[1];
    }
    if (multiArgs[2] != 1) {
      c = c * multiArgs[2];
    }
    return (a + b + c) / dived;
  }
}

final class BasisCurve extends CurveStyle {
  const BasisCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    points = fillPointsIfNeed(points, 4);
    final List<double> args = [1, 4, 1];
    final double dived = 6;
    final result = <Curve>[];
    for (int i = 0; i < points.length - 3; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final p2 = points[i + 2];
      final p3 = points[i + 3];

      final startLinear = (p1 + p2) / 2;
      final endLinear = (p2 + p3) / 2;

      final startCurve = (p0 + (p1 * 2) + p2) / 4;
      final endCurve = (p1 + (p2 * 2) + p3) / 4;

      final cp1Curve = bezierPoint(p0, p1, p2, args, dived);
      final cp2Curve = bezierPoint(p1, p2, p3, args, dived);

      final start = lerp(startLinear, startCurve, smooth);
      final end = lerp(endLinear, endCurve, smooth);
      final cp1 = lerp(startLinear, cp1Curve, smooth);
      final cp2 = lerp(endLinear, cp2Curve, smooth);

      result.add(Curve.of(start, cp1, cp2, end));
    }
    return result;
  }
}

final class BasisClosedCurve extends CurveStyle {
  const BasisClosedCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    points = fillPointsIfNeed(points, 3);
    final n = points.length;
    final curves = <Curve>[];
    final ring = <Offset>[points[n - 2], points[n - 1], ...points, points[0], points[1]];

    final List<double> args = [1, 4, 1];
    final double dived = 6;

    for (int i = 0; i < n; i++) {
      final p0 = ring[i];
      final p1 = ring[i + 1];
      final p2 = ring[i + 2];
      final p3 = ring[i + 3];
      final startLinear = (p1 + p2) / 2;
      final endLinear = (p2 + p3) / 2;
      final start = lerp(startLinear, (p0 + (p1 * 2) + p2) / 4, smooth);
      final end = lerp(endLinear, (p1 + (p2 * 2) + p3) / 4, smooth);
      final cp1 = lerp(startLinear, bezierPoint(p0, p1, p2, args, dived), smooth);
      final cp2 = lerp(endLinear, bezierPoint(p1, p2, p3, args, dived), smooth);
      curves.add(Curve.of(start, cp1, cp2, end));
    }
    return curves;
  }
}

final class BasisOpenCurve extends CurveStyle {
  const BasisOpenCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    points = fillPointsIfNeed(points, 4);
    final n = points.length;
    final result = <Curve>[];
    for (int i = 0; i <= n - 4; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final p2 = points[i + 2];
      final p3 = points[i + 3];

      Offset curveStart = (p0 + (p1 * 4) + p2) / 6;
      Offset curveEnd = (p1 + (p2 * 4) + p3) / 6;

      Offset cp1 = curveStart;
      Offset cp2 = curveEnd;

      final startLinear = (p1 + p2) / 2;
      final endLinear = (p1 + p2) / 2;
      final start = lerp(startLinear, curveStart, smooth);
      final end = lerp(endLinear, curveEnd, smooth);
      final control1 = lerp(startLinear, cp1, smooth);
      final control2 = lerp(endLinear, cp2, smooth);
      result.add(Curve.of(start, control1, control2, end));
    }
    return result;
  }
}

final class BsplineCurve extends CurveStyle {
  const BsplineCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    points = fillPointsIfNeed(points, 4);
    final result = <Curve>[];

    final List<double> args = [1, 6, 1];
    final double dived = 8;

    for (int i = 0; i < points.length - 3; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final p2 = points[i + 2];
      final p3 = points[i + 3];

      Offset startCurve = (p0 + p1 * 4 + p2) / 6;
      Offset endCurve = (p1 + p2 * 4 + p3) / 6;

      Offset cp1 = bezierPoint(p0, p1, p2, args, dived);
      Offset cp2 = bezierPoint(p1, p2, p3, args, dived);

      final startLinear = (p1 + p2) / 2;
      final endLinear = (p2 + p3) / 2;

      result.add(
        Curve.of(lerp(startLinear, startCurve, smooth), lerp(startLinear, cp1, smooth), lerp(endLinear, cp2, smooth),
            lerp(endLinear, endCurve, smooth)),
      );
    }

    return result;
  }
}

final class BumpXCurve extends CurveStyle {
  const BumpXCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    final result = <Curve>[];
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final dx1 = (2 * p0.dx + p1.dx) / 3;
      final dx2 = (p0.dx + 2 * p1.dx) / 3;

      final c1 = Offset(dx1, p0.dy);
      final c2 = Offset(dx2, p1.dy);

      final mx1 = Offset((p0.dx * 2 + p1.dx) / 3, (2 * p0.dy + p1.dy) / 3);
      final mx2 = Offset((p0.dx + p1.dx * 2) / 3, (p0.dy + 2 * p1.dy) / 3);
      result.add(Curve.of(p0, lerp(mx1, c1, smooth), lerp(mx2, c2, smooth), p1));
    }

    return result;
  }
}

final class BumpYCurve extends CurveStyle {
  const BumpYCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    final result = <Curve>[];

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final dy1 = (2 * p0.dy + p1.dy) / 3;
      final dy2 = (p0.dy + 2 * p1.dy) / 3;

      final c1 = Offset(p0.dx, dy1);
      final c2 = Offset(p1.dx, dy2);

      final mx1 = Offset((2 * p0.dx + p1.dx) / 3, (2 * p0.dy + p1.dy) / 3);
      final mx2 = Offset((p0.dx + 2 * p1.dx) / 3, (p0.dy + 2 * p1.dy) / 3);
      result.add(Curve.of(p0, lerp(mx1, c1, smooth), lerp(mx2, c2, smooth), p1));
    }

    return result;
  }
}

final class BundleCurve extends CurveStyle {
  const BundleCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    smooth = 1 - smooth;

    points = fillPointsIfNeed(points, 4);
    final curves = <Curve>[];
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = (i + 2 < points.length) ? points[i + 2] : p2;
      final t1 = (p2 - p0) / 6;
      final t2 = (p3 - p1) / 6;
      final cp1 = p1 + t1;
      final cp2 = p2 - t2;
      final mid = (p1 + p2) / 2;
      final newCp1 = lerp(cp1, mid, smooth);
      final newCp2 = lerp(cp2, mid, smooth);
      curves.add(Curve.of(p1, newCp1, newCp2, p2));
    }

    return curves;
  }
}

final class BundleAlphaCurve extends CurveStyle {
  final double beta;

  const BundleAlphaCurve({required super.smooth, this.beta = 1 / 6});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    smooth = 1 - smooth;
    points = fillPointsIfNeed(points, 4);
    final curves = <Curve>[];

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = (i + 2 < points.length) ? points[i + 2] : p2;

      final t1 = (p2 - p0) * beta;
      final t2 = (p3 - p1) * beta;

      final cp1 = p1 + t1;
      final cp2 = p2 - t2;
      final mid = (p1 + p2) / 2;

      curves.add(Curve.of(p1, lerp(cp1, mid, smooth), lerp(cp2, mid, smooth), p2));
    }

    return curves;
  }
}

final class CardinalCurve extends CurveStyle {
  const CardinalCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    final curves = <Curve>[];
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;
      final t1 = ((p2 - p0) * smooth) / 2;
      final t2 = ((p3 - p1) * smooth) / 2;
      final cp1 = p1 + t1 / 3;
      final cp2 = p2 - t2 / 3;

      curves.add(Curve.of(p1, cp1, cp2, p2));
    }
    return curves;
  }
}

final class CardinalClosedCurve extends CurveStyle {
  const CardinalClosedCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    smooth = 1 - smooth;
    points = fillPointsIfNeed(points, 3);
    final n = points.length;
    final curves = <Curve>[];
    final s = (1 - smooth) / 2;

    final ring = <Offset>[points[n - 2], points[n - 1], ...points, points[0], points[1]];

    for (int i = 0; i < n; i++) {
      final p0 = ring[i];
      final p1 = ring[i + 1];
      final p2 = ring[i + 2];
      final p3 = ring[i + 3];

      final cp1 = Offset(p1.dx + s * (p2.dx - p0.dx), p1.dy + s * (p2.dy - p0.dy));
      final cp2 = Offset(p2.dx - s * (p3.dx - p1.dx), p2.dy - s * (p3.dy - p1.dy));

      curves.add(Curve.of(p1, cp1, cp2, p2));
    }

    return curves;
  }
}

final class CardinalOpenCurve extends CurveStyle {
  const CardinalOpenCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    int n = points.length;
    final s = smooth / 2;
    final curves = <Curve>[];
    final extended = <Offset>[points[0], ...points, points[n - 1]];
    for (int i = 0; i < n - 1; i++) {
      final p0 = extended[i];
      final p1 = extended[i + 1];
      final p2 = extended[i + 2];
      final p3 = extended[i + 3];

      final cp1 = Offset(p1.dx + s * (p2.dx - p0.dx), p1.dy + s * (p2.dy - p0.dy));
      final cp2 = Offset(p2.dx - s * (p3.dx - p1.dx), p2.dy - s * (p3.dy - p1.dy));
      curves.add(Curve.of(p1, cp1, cp2, p2));
    }

    return curves;
  }
}

final class CardinalTensionCurve extends CurveStyle {
  final bool closed;

  const CardinalTensionCurve(this.closed, {required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    smooth = 1 - smooth;
    if (closed) {
      points = fillPointsIfNeed(points, 3);
    }

    final n = points.length;
    final s = (1 - smooth) / 2;
    final curves = <Curve>[];

    List<Offset> ring;
    if (closed) {
      ring = [points[n - 2], points[n - 1], ...points, points[0], points[1]];
    } else {
      ring = [points[0], ...points, points[n - 1]];
    }

    final limit = closed ? n : n - 1;
    for (int i = 0; i < limit; i++) {
      final p0 = ring[i];
      final p1 = ring[i + 1];
      final p2 = ring[i + 2];
      final p3 = ring[i + 3];
      final cp1 = Offset(p1.dx + s * (p2.dx - p0.dx), p1.dy + s * (p2.dy - p0.dy));
      final cp2 = Offset(p2.dx - s * (p3.dx - p1.dx), p2.dy - s * (p3.dy - p1.dy));
      curves.add(Curve.of(p1, cp1, cp2, p2));
    }
    return curves;
  }
}

final class CatmullRomCurve extends CurveStyle {
  const CatmullRomCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    final result = <Curve>[];
    int N = points.length - 1;
    for (int i = 0; i < N; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      final d1 = (p1 - p0).distance;
      final d2 = (p2 - p1).distance;
      final d3 = (p3 - p2).distance;

      final t1 = d1 == 0 ? Offset.zero : ((p2 - p0) * (smooth * d1 / (d1 + d2)));
      final t2 = d2 == 0 ? Offset.zero : ((p3 - p1) * (smooth * d2 / (d2 + d3)));

      final cp1 = p1 + t1 / 3;
      final cp2 = p2 - t2 / 3;

      result.add(Curve.of(p1, cp1, cp2, p2));
    }
    return result;
  }
}

final class CatmullRomCloseCurve extends CatmullRomAlphaCurve {
  CatmullRomCloseCurve({required super.smooth}) : super(closed: true, alpha: 1);
}

final class CatmullRomOpenCurve extends CurveStyle {
  const CatmullRomOpenCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    final curves = <Curve>[];
    final s = smooth / 2;
    int n = points.length;
    final extended = <Offset>[points[0], ...points, points[n - 1]];
    for (int i = 0; i < n - 1; i++) {
      final p0 = extended[i];
      final p1 = extended[i + 1];
      final p2 = extended[i + 2];
      final p3 = extended[i + 3];
      final cp1 = Offset(p1.dx + s * (p2.dx - p0.dx), p1.dy + s * (p2.dy - p0.dy));
      final cp2 = Offset(p2.dx - s * (p3.dx - p1.dx), p2.dy - s * (p3.dy - p1.dy));
      curves.add(Curve.of(p1, cp1, cp2, p2));
    }

    return curves;
  }
}

class CatmullRomAlphaCurve extends CurveStyle {
  final double alpha;
  final bool closed;

  const CatmullRomAlphaCurve({required this.alpha, this.closed = false, required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    if (closed) {
      points = fillPointsIfNeed(points, 3);
    }
    final n = points.length;
    final curves = <Curve>[];

    List<Offset> pts;
    if (closed) {
      pts = [points[n - 2], points[n - 1], ...points, points[0], points[1]];
    } else {
      pts = [points[0], ...points, points[n - 1]];
    }

    final limit = closed ? n : n - 1;
    for (int i = 0; i < limit; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final p2 = pts[i + 2];
      final p3 = pts[i + 3];

      final t0 = 0.0;
      final t1 = t0 + _powDist(p0, p1, alpha);
      final t2 = t1 + _powDist(p1, p2, alpha);
      final t3 = t2 + _powDist(p2, p3, alpha);

      final m1 = lerp(p0, p2, (t1 - t0) / (t2 - t0));
      final m2 = lerp(p1, p3, (t2 - t1) / (t3 - t1));

      final cp1 = lerp(p1, m1, (t2 - t1) / 3 / (t2 - t1));
      final cp2 = lerp(p2, m2, -(t2 - t1) / 3 / (t2 - t1));

      curves.add(Curve.of(p1, cp1, cp2, p2));
    }
    return curves;
  }

  double _powDist(Offset a, Offset b, double alpha) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    return pow(dx * dx + dy * dy, 0.5 * alpha).toDouble();
  }
}

final class MonotoneCurve extends CurveStyle {
  const MonotoneCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    final result = <Curve>[];
    final n = points.length;
    final m = List.filled(n, Offset.zero);
    for (int i = 1; i < n; i++) {
      final dx = points[i].dx - points[i - 1].dx;
      final dy = points[i].dy - points[i - 1].dy;
      m[i] = dx == 0 ? Offset.zero : Offset(1, dy / dx);
    }
    for (int i = 1; i < n - 1; i++) {
      if (m[i].dy * m[i + 1].dy < 0) {
        m[i] = Offset.zero;
      }
    }
    for (int i = 0; i < n - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final dx = p1.dx - p0.dx;
      final m0 = m[i];
      final m1 = m[i + 1];
      final cp1 = Offset(p0.dx + dx / 3, p0.dy + m0.dy * dx / 3 * smooth);
      final cp2 = Offset(p1.dx - dx / 3, p1.dy - m1.dy * dx / 3 * smooth);
      result.add(Curve.of(p0, cp1, cp2, p1));
    }
    return result;
  }
}

final class MonotoneXCurve extends CurveStyle {
  const MonotoneXCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    final n = points.length;
    final curves = <Curve>[];
    final dx = <double>[];
    final dy = <double>[];
    final slope = <double>[];

    for (int i = 0; i < n - 1; i++) {
      final dxi = points[i + 1].dx - points[i].dx;
      final dyi = points[i + 1].dy - points[i].dy;
      dx.add(dxi);
      dy.add(dyi);
      slope.add(dxi != 0 ? dyi / dxi : 0);
    }

    final tangents = List<double>.filled(n, 0);
    tangents[0] = slope[0];
    tangents[n - 1] = slope[n - 2];

    for (int i = 1; i < n - 1; i++) {
      if (slope[i - 1] * slope[i] <= 0) {
        tangents[i] = 0;
      } else {
        final w1 = dx[i];
        final w2 = dx[i - 1];
        final m1 = slope[i - 1];
        final m2 = slope[i];
        tangents[i] = (w1 + w2 > 0) ? (w1 + w2) / ((w1 / m1) + (w2 / m2)) : 0.0;
      }
    }

    for (int i = 0; i < n - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final h = p1.dx - p0.dx;

      final t0 = tangents[i];
      final t1 = tangents[i + 1];

      final cp1 = Offset(p0.dx + h / 3, p0.dy + smooth * t0 * h / 3);
      final cp2 = Offset(p1.dx - h / 3, p1.dy - smooth * t1 * h / 3);

      curves.add(Curve.of(p0, cp1, cp2, p1));
    }

    return curves;
  }
}

final class MonotoneYCurve extends CurveStyle {
  const MonotoneYCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    final n = points.length;
    final curves = <Curve>[];
    final dy = <double>[];
    final dx = <double>[];
    final slope = <double>[];
    for (int i = 0; i < n - 1; i++) {
      final dyi = points[i + 1].dy - points[i].dy;
      final dxi = points[i + 1].dx - points[i].dx;
      dy.add(dyi);
      dx.add(dxi);
      slope.add(dyi != 0 ? dxi / dyi : 0);
    }
    final tangents = List<double>.filled(n, 0);
    tangents[0] = slope[0];
    tangents[n - 1] = slope[n - 2];
    for (int i = 1; i < n - 1; i++) {
      if (slope[i - 1] * slope[i] <= 0) {
        tangents[i] = 0;
      } else {
        final w1 = dy[i];
        final w2 = dy[i - 1];
        final m1 = slope[i - 1];
        final m2 = slope[i];
        tangents[i] = (w1 + w2 > 0) ? (w1 + w2) / ((w1 / m1) + (w2 / m2)) : 0.0;
      }
    }

    for (int i = 0; i < n - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final h = p1.dy - p0.dy;
      final t0 = tangents[i];
      final t1 = tangents[i + 1];
      final cp1 = Offset(p0.dx + smooth * t0 * h / 3, p0.dy + h / 3);
      final cp2 = Offset(p1.dx - smooth * t1 * h / 3, p1.dy - h / 3);
      curves.add(Curve.of(p0, cp1, cp2, p1));
    }

    return curves;
  }
}

final class NaturalCurve extends CurveStyle {
  const NaturalCurve({required super.smooth});

  @override
  List<Curve> onApply(List<Offset> points, double smooth) {
    int n = points.length;
    final h = List<double>.generate(n - 1, (i) => points[i + 1].dx - points[i].dx);
    final alpha = List<double>.filled(n - 1, 0);
    for (int i = 1; i < n - 1; i++) {
      final dy1 = (points[i].dy - points[i - 1].dy) / h[i - 1];
      final dy2 = (points[i + 1].dy - points[i].dy) / h[i];
      alpha[i] = (3 * (dy2 - dy1));
    }

    final l = List<double>.filled(n, 1);
    final mu = List<double>.filled(n, 0);
    final z = List<double>.filled(n, 0);
    final c = List<double>.filled(n, 0);
    final b = List<double>.filled(n - 1, 0);
    final d = List<double>.filled(n - 1, 0);

    for (int i = 1; i < n - 1; i++) {
      l[i] = 2 * (points[i + 1].dx - points[i - 1].dx) - h[i - 1] * mu[i - 1];
      mu[i] = h[i] / l[i];
      z[i] = (alpha[i] - h[i - 1] * z[i - 1]) / l[i];
    }

    for (int j = n - 2; j >= 0; j--) {
      c[j] = z[j] - mu[j] * c[j + 1];
      b[j] = (points[j + 1].dy - points[j].dy) / h[j] - h[j] * (c[j + 1] + 2 * c[j]) / 3;
      d[j] = (c[j + 1] - c[j]) / (3 * h[j]);
    }

    final curves = <Curve>[];
    for (int i = 0; i < n - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final dx = h[i];

      final m0 = b[i];
      final m1 = b[i] + 2 * c[i] * dx + 3 * d[i] * dx * dx;

      final startLinear = p0;
      final endLinear = p1;

      final cp1 = Offset(p0.dx + dx / 3, p0.dy + m0 * dx / 3);
      final cp2 = Offset(p1.dx - dx / 3, p1.dy - m1 * dx / 3);

      curves.add(
        Curve.of(lerp(startLinear, p0, smooth), lerp((p0 + p1) / 2, cp1, smooth), lerp((p0 + p1) / 2, cp2, smooth),
            lerp(endLinear, p1, smooth)),
      );
    }
    return curves;
  }
}
