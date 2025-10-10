import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:d_util/d_util.dart';

final class BoundaryUtil {
  BoundaryUtil._();

  static Rect? boundary(Iterable<Offset?> rects) {
    if (rects.isEmpty) {
      return null;
    }
    double left = double.maxFinite;
    double top = double.maxFinite;
    double bottom = double.minPositive;
    double right = double.minPositive;

    rects.each((p0, p1) {
      if (p0 == null) {
        return;
      }
      left = min(p0.dx, left);
      top = min(p0.dy, top);
      right = max(p0.dx, right);
      bottom = max(p0.dy, bottom);
    });
    if (left >= right || top >= bottom) {
      return null;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static Rect? boundaryWithRect(Iterable<Rect?> rects) {
    if (rects.isEmpty) {
      return null;
    }

    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;
    for (final rect in rects) {
      if (rect == null) {
        continue;
      }
      left = left < rect.left ? left : rect.left;
      top = top < rect.top ? top : rect.top;
      right = right > rect.right ? right : rect.right;
      bottom = bottom > rect.bottom ? bottom : rect.bottom;
    }

    if (left.isInfinite) {
      return null;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static Rect? boundaryWith<T>(Iterable<T> nodes, Fun2<T, double> leftFun, Fun2<T, double> topFun,
      Fun2<T, double> rightFun, Fun2<T, double> bottomFun) {
    double left = double.infinity;
    double top = double.infinity;
    double right = double.negativeInfinity;
    double bottom = double.negativeInfinity;
    for (final node in nodes) {
      double l = leftFun(node);
      double t = topFun(node);
      double r = rightFun(node);
      double b = bottomFun(node);
      left = left < l ? left : l;
      top = top < t ? top : t;
      right = right > r ? right : r;
      bottom = bottom > b ? bottom : b;
    }

    if (left.isInfinite) {
      return null;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}
