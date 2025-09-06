
import 'package:dts/dts.dart' as dt;
import 'package:flutter/material.dart';

import '../extensions.dart';

abstract class BasicGeometry {
  late final Path path = onBuildPath();

  @protected
  Path onBuildPath();

  double get area;

  double get length;

  Offset get center;

  Rect get bbox;

  ///是否有重叠 这个和JTS中的overlap有区别
  bool isOverlap(BasicGeometry geom, {double eps = 1e-9}) => asGeometry.intersects(geom.asGeometry);

  ///是否有重叠 这个和JTS中的overlap有区别
  bool isOverlapRect(Rect rect) => asGeometry.intersects(rect.asGeometry);

  List<Offset> crossPoint(BasicGeometry geom) => BasicGeometry.pickCrossPoint(asGeometry.intersection(geom.asGeometry));

  List<Offset> crossPointWithRect(Rect rect) {
    return BasicGeometry.pickCrossPoint(asGeometry.intersection(rect.asGeometry));
  }

  double distance(BasicGeometry geom) => asGeometry.distance(geom.asGeometry);

  double distanceWithPoint(Offset p) => asGeometry.distance(p.asPoint);

  double distanceWithRect(Rect rect) => asGeometry.distance(rect.asGeometry);

  bool contains(BasicGeometry geom) => asGeometry.contains(geom.asGeometry);

  bool containsPoint(Offset p, {double eps = 1e-9}) => asGeometry.contains(p.asPoint);

  static List<Offset> pickCrossPoint(dt.Geometry? res) {
    if (res == null || res.isEmpty()) {
      return [];
    }
    if (res is dt.Point) {
      final p = res.getCoordinate();
      if (p == null) {
        return [];
      }
      return [Offset(p.x, p.y)];
    }
    if (res is dt.MultiPoint && res.getNumGeometries() > 0) {
      return res.getCoordinates().map((e) => Offset(e.x, e.y)).toList();
    }
    return [];
  }

  dt.Geometry? _geometry;

  dt.Geometry get asGeometry {
    return _geometry ??= buildGeometry();
  }

  @protected
  dt.Geometry buildGeometry();
}

