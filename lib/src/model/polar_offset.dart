import 'package:d_util/d_util.dart';

class PolarOffset {
  final Angle angle;
  final double radius;

  const PolarOffset(this.angle, this.radius);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarOffset && runtimeType == other.runtimeType && angle == other.angle && radius == other.radius;

  @override
  int get hashCode => Object.hash(angle, radius);

}
