
import 'package:bezier/bezier.dart';
import 'package:vector_math/vector_math.dart';

class EvenSpacer2 {
  final Bezier curve;
  late final List<Vector2> curveLookUpTable;
  final List<double> _cumulativeArcLengths = [0.0];
  late final List<double> _arcFractions;

  final int? parametersCount;

  EvenSpacer2(this.curve, {int? intervalsCount, this.parametersCount}) {
    int c = intervalsCount ?? (curve.length * 0.75).ceil();
    c = c.clamp(8, 1000);

    final lookUpTable = curve.positionLookUpTable(intervalsCount: c);
    curveLookUpTable = List.unmodifiable(lookUpTable);
    if (curveLookUpTable.length < 2) {
      throw ArgumentError('look up table requires at least two entries');
    }
    for (var i = 1; i < curveLookUpTable.length; i++) {
      final distance = curveLookUpTable[i - 1].distanceTo(curveLookUpTable[i]);
      _cumulativeArcLengths.add(_cumulativeArcLengths.last + distance);
    }

    final totalLength = _cumulativeArcLengths.last;
    _arcFractions = List.unmodifiable(_cumulativeArcLengths.map((l) => l / totalLength));
  }

  double get arcLength => _cumulativeArcLengths.last;

  double evenTValueAt(double t, {int maxIter = 5, double tol = 1e-5}) {
    if (t <= 0) return 0.0;
    if (t >= 1) return 1.0;

    int low = 0;
    int high = _arcFractions.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final midVal = _arcFractions[mid];
      if (midVal < t) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    double tempT = _interpolateT(low, t);
    final targetLength = t * arcLength;
    for (int i = 0; i < maxIter; i++) {
      final L = _arcLengthAt(tempT);
      final diff = L - targetLength;
      if (diff.abs() < tol) break;
      final d = curve.derivativeAt(tempT).length;
      if (d < 1e-9) break;
      final newT = tempT - diff / d;
      if (newT < 0 || newT > 1) {
        break;
      }
      tempT = newT;
    }
    return tempT.clamp(0.0, 1.0);
  }

  double _interpolateT(int upperIndex, double tFraction) {
    final lowerIndex = upperIndex - 1;
    final fractionLower = _arcFractions[lowerIndex];
    final fractionUpper = _arcFractions[upperIndex];
    final segmentFraction = (tFraction - fractionLower) / (fractionUpper - fractionLower);
    final paramCount = curveLookUpTable.length - 1;
    final paramLower = lowerIndex / paramCount;
    final paramUpper = upperIndex / paramCount;
    return mix(paramLower, paramUpper, segmentFraction);
  }

  /// 数值积分计算弧长 (梯形法)
  double _arcLengthAt(double t, {int steps = 20}) {
    double length = 0.0;
    Vector2 prev = curve.pointAt(0);
    for (int i = 1; i <= steps; i++) {
      double u = t * i / steps;
      Vector2 p = curve.pointAt(u);
      length += (p - prev).length;
      prev = p;
    }
    return length;
  }

  List<double>? _evenTValues;

  List<double> evenTValues() {
    final vv = _evenTValues;
    if (vv != null) {
      return vv;
    }
    int cc = parametersCount ?? curve.length.ceil();
    cc = cc.clamp(8, 1000);
    final result = List<double>.generate(cc + 1, (i) {
      return evenTValueAt(i / cc);
    }, growable: false);
    return _evenTValues = List.unmodifiable(result);
  }

  Vector2 pointAtLength(double S, {bool refined = false, int newtonSteps = 3}) {
    if (S <= 0) return curve.startPoint;

    if (S >= arcLength) return curve.endPoint;

    int low = 0;
    int high = _cumulativeArcLengths.length - 1;
    while (low <= high) {
      int mid = (low + high) >> 1;
      if (_cumulativeArcLengths[mid] < S) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    final lowerIndex = low - 1;
    final upperIndex = low;
    final lenLower = _cumulativeArcLengths[lowerIndex];
    final lenUpper = _cumulativeArcLengths[upperIndex];
    final segFraction = (S - lenLower) / (lenUpper - lenLower);
    final paramCount = curveLookUpTable.length - 1;
    final tLower = lowerIndex / paramCount;
    final tUpper = upperIndex / paramCount;
    double t = mix(tLower, tUpper, segFraction);

    if (refined) {
      for (int i = 0; i < newtonSteps; i++) {
        final f = _arcLengthAt(t) - S;
        final fp = curve.derivativeAt(t).length;
        if (fp == 0) break;
        t -= f / fp;
        if (t < 0) t = 0;
        if (t > 1) t = 1;
      }
    }
    return curve.pointAt(t);
  }

  Vector2 tangentAtLength(double S) {
    final totalLength = arcLength;
    final tFraction = (S / totalLength).clamp(0, 1);
    final t = evenTValueAt(tFraction.toDouble());
    final derivative = curve.derivativeAt(t);
    return derivative.normalized();
  }
}
