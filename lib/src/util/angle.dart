import 'dart:math' as math;
import 'dart:ui';

extension AngleExt on num {
  Angle get asRadians => Angle.radians(toDouble());

  Angle get asDegrees => Angle.degrees(toDouble());
}

class Angle implements Comparable<Angle> {
  static const _pi2 = math.pi * 2;
  static const _halfPi = math.pi / 2;
  static const _degToRad = math.pi / 180.0;
  static const _radToDeg = 180.0 / math.pi;

  static const zero = Angle.radians(0);
  static const full = Angle.radians(_pi2);
  static const half = Angle.radians(math.pi);
  static const quarter = Angle.radians(_halfPi);

  final double radians;

  const Angle.radians(this.radians);

  factory Angle.degrees(double degrees) => Angle.radians(degrees * _degToRad);

  double get degrees => radians * _radToDeg;

  Angle get normalized {
    if (radians >= 0 && radians <= _pi2) {
      return this;
    }
    var value = radians % _pi2;
    if (value < 0) value += _pi2;
    return Angle.radians(value);
  }

  Angle rotate(Angle delta) => this + delta;

  Angle get inverse => -this;

  Angle get abs => radians < 0 ? Angle.radians(-radians) : this;

  Offset toVector(double length) => Offset(length * cos, length * sin);

  /// Linearly interpolates between two angles, taking the shortest arc.
  ///
  /// [t] in [0,1].
  static Angle lerp(Angle a, Angle b, double t) {
    final da = ((b.radians - a.radians + math.pi) % _pi2) - math.pi;
    return Angle.radians(a.radians + da * t);
  }

  Angle operator +(Angle other) => Angle.radians(radians + other.radians);

  Angle add(num other, [bool otherIsDegrees = false]) {
    if (otherIsDegrees) {
      return Angle.degrees(degrees + other);
    }
    return Angle.radians(radians + other);
  }

  Angle operator -(Angle other) => Angle.radians(radians - other.radians);

  Angle sub(num other, [bool otherIsDegrees = false]) {
    if (otherIsDegrees) {
      return Angle.degrees(degrees - other);
    }
    return Angle.radians(radians - other);
  }

  Angle operator *(num factor) => Angle.radians(radians * factor);

  Angle multiply(num factor) => Angle.radians(radians * factor);

  Angle operator /(num factor) => Angle.radians(radians / factor);

  Angle div(num factor) => Angle.radians(radians / factor);

  Angle operator %(num factor) => Angle.radians(radians % factor);

  Angle operator -() => Angle.radians(-radians);

  bool operator <=(Angle other) => radians <= other.radians;

  bool operator >=(Angle other) => radians >= other.radians;

  bool operator <(Angle other) => radians < other.radians;

  bool isLessRadians(double theta) => radians < theta;

  bool isLessDegrees(double theta) => degrees < theta;

  bool operator >(Angle other) => radians > other.radians;

  bool isMoreRadians(double theta) => radians > theta;

  bool isMoreDegrees(double theta) => degrees > theta;

  double get sin => math.sin(radians);

  double get cos => math.cos(radians);

  double get tan => math.tan(radians);

  bool get isZero => radians.abs() <= 1e-9;

  bool get isFull => (radians - _pi2).abs() <= 1e-9;

  /// Compare equality with tolerance.
  bool equals(Angle other, [double epsilon = 1e-10]) => (radians - other.radians).abs() < epsilon;

  @override
  String toString() => 'Angle(${degrees.toStringAsFixed(2)}°)';

  @override
  int get hashCode => radians.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! Angle) {
      return false;
    }
    return equals(other);
  }

  @override
  int compareTo(Angle other) => radians.compareTo(other.radians);
}
