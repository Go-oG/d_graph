import 'dart:math';
import 'dart:ui';

import '../../dart_graph.dart';

final class CoordUtil {
  CoordUtil._();

  static PolarOffset pointToPolar(double x, double y, Offset center) {
    final dx = x - center.dx;
    final dy = y - center.dy;
    final radius = sqrt(dx * dx + dy * dy);
    Angle angle = atan2(dy, dx).asRadians.normalized;
    return PolarOffset(angle, radius);
  }

  ///计算 点p 绕点Q旋转Angle后的坐标(笛卡尔坐标)
  static Offset rotatePoint(Offset p, Offset q, Angle angle) {
    double xP = p.dx, yP = p.dy, xQ = q.dx, yQ = q.dy;

    double xPTranslated = xP - xQ;
    double yPTranslated = yP - yQ;

    double xNew = xPTranslated * angle.cos - yPTranslated * angle.sin;
    double yNew = xPTranslated * angle.sin + yPTranslated * angle.cos;

    xNew += xQ;
    yNew += yQ;
    return Offset(xNew, yNew);
  }

  ///计算 点p 绕点Q旋转Angle后的坐标(极坐标系)
  ///x=radius,y=angle
  static PolarOffset rotatePointForPolar(
    double pRadius,
    Angle pAngle,
    double qRadius,
    Angle qAngle,
    Angle rotateAngle,
  ) {
    double xP = pRadius * pAngle.cos;
    double yP = pRadius * pAngle.sin;
    double xQ = qRadius * qAngle.cos;
    double yQ = qRadius * qAngle.sin;

    double xNew =
        (xP - xQ) * rotateAngle.cos - (yP - yQ) * rotateAngle.sin + xQ;
    double yNew =
        (xP - xQ) * rotateAngle.sin + (yP - yQ) * rotateAngle.cos + yQ;

    double rNew = sqrt(xNew * xNew + yNew * yNew);
    double thetaNew = atan2(yNew, xNew);
    return PolarOffset(thetaNew.asRadians, rNew);
  }

  ///给定缩放前返回和缩放中心 缩放系数 计算缩放后的范围
  static List<double> scaleRange(
    List<double> range,
    double scaleCenter,
    double k,
  ) {
    double aScaled = scaleCenter + k * (range[0] - scaleCenter);
    double bScaled = scaleCenter + k * (range[1] - scaleCenter);
    return [aScaled, bScaled];
  }

  ///给定圆心 半径和角度计算坐标
  static Offset circlePoint(
    num radius,
    Angle radian, {
    Offset center = Offset.zero,
  }) {
    double x = center.dx + radius * radian.cos;
    double y = center.dy + radius * radian.sin;
    return Offset(x, y);
  }
}
