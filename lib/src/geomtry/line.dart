import 'dart:math';
import 'dart:ui';

import 'package:dart_graph/src/geomtry/offset_ext.dart';
import 'package:dart_graph/src/geomtry/polygon.dart';

class Line {
  final LineType type;
  final Offset start;
  final Offset end;

  const Line.ray(this.start, this.end) : type = LineType.ray;

  const Line.line(this.start, this.end) : type = LineType.line;

  const Line.segment(this.start, this.end) : type = LineType.segment;

  bool isCrossLine(Line other) {
    final p1 = start, p2 = end, p3 = other.start, p4 = other.end;

    double x1 = p1.dx, y1 = p1.dy;
    double x2 = p2.dx, y2 = p2.dy;
    double x3 = p3.dx, y3 = p3.dy;
    double x4 = p4.dx, y4 = p4.dy;

    // 计算叉积
    double cross1 = (x2 - x1) * (y3 - y1) - (y2 - y1) * (x3 - x1);
    double cross2 = (x2 - x1) * (y4 - y1) - (y2 - y1) * (x4 - x1);
    double cross3 = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3);
    double cross4 = (x4 - x3) * (y2 - y3) - (y4 - y3) * (x2 - x3);

    // 判断是否相交
    if (((cross1 > 0 && cross2 < 0) || (cross1 < 0 && cross2 > 0)) &&
        ((cross3 > 0 && cross4 < 0) || (cross3 < 0 && cross4 > 0))) {
      return true;
    }

    // 检查端点是否在另一条线段上
    if (cross1 == 0 && _isOnLineRange(p1, p2, p3)) return true;
    if (cross2 == 0 && _isOnLineRange(p1, p2, p4)) return true;
    if (cross3 == 0 && _isOnLineRange(p3, p4, p1)) return true;
    if (cross4 == 0 && _isOnLineRange(p3, p4, p2)) return true;
    return false;
  }

  ///是否和其它线段有重合
  bool isOverlapLine(Line other) {
    double cross(Offset o, Offset a, Offset b) {
      return (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
    }

    bool onSegment(Offset a, Offset b, Offset p) {
      return (p.dx >= a.dx && p.dx <= b.dx || p.dx >= b.dx && p.dx <= a.dx) &&
          (p.dy >= a.dy && p.dy <= b.dy || p.dy >= b.dy && p.dy <= a.dy);
    }

    bool doSegmentsOverlap(Offset p1, Offset p2, Offset p3, Offset p4) {
      if (cross(p1, p2, p3) != 0 || cross(p1, p2, p4) != 0) {
        return false;
      }
      return onSegment(p3, p4, p1) || onSegment(p3, p4, p2) || onSegment(p1, p2, p3) || onSegment(p1, p2, p4);
    }

    return doSegmentsOverlap(start, end, other.start, other.end);
  }

  //计算两条线段的交点
  Offset? lineCrossPoint(Line line) {
    final p1 = start, p2 = end, p3 = line.start, p4 = line.end;

    double x1 = p1.dx, y1 = p1.dy;
    double x2 = p2.dx, y2 = p2.dy;
    double x3 = p3.dx, y3 = p3.dy;
    double x4 = p4.dx, y4 = p4.dy;

    // 计算分母
    double denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
    if (denom == 0) {
      return null;
    }

    // 计算参数 t 和 u
    double ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom;
    double ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom;

    // 检查交点是否在线段上
    if (ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1) {
      double x = x1 + ua * (x2 - x1);
      double y = y1 + ua * (y2 - y1);
      return Offset(x, y);
    }
    return null;
  }

  // 计算直线与矩形的交点
  List<Offset> rectCrossPoint(Rect rect) {
    List<Offset> intersections = [];
    double x1 = start.dx, y1 = start.dy;
    double x2 = end.dx, y2 = end.dy;
    double dx = x2 - x1;
    double dy = y2 - y1;
    if (dy != 0) {
      double tTop = (rect.top - y1) / dy;
      double tBottom = (rect.bottom - y1) / dy;

      if (tTop >= 0 && tTop <= 1) {
        double x = x1 + tTop * dx;
        if (x >= rect.left && x <= rect.right) {
          intersections.add(Offset(x, rect.top));
        }
      }

      if (tBottom >= 0 && tBottom <= 1) {
        double x = x1 + tBottom * dx;
        if (x >= rect.left && x <= rect.right) {
          intersections.add(Offset(x, rect.bottom));
        }
      }
    }
    if (dx != 0) {
      double tLeft = (rect.left - x1) / dx;
      double tRight = (rect.right - x1) / dx;

      if (tLeft >= 0 && tLeft <= 1) {
        double y = y1 + tLeft * dy;
        if (y >= rect.top && y <= rect.bottom) {
          intersections.add(Offset(rect.left, y));
        }
      }

      if (tRight >= 0 && tRight <= 1) {
        double y = y1 + tRight * dy;
        if (y >= rect.top && y <= rect.bottom) {
          intersections.add(Offset(rect.right, y));
        }
      }
    }
    return intersections;
  }

  // 判断点是否在线段对应区间
  bool _isOnLineRange(Offset p1, Offset p2, Offset p) {
    double minX = min(p1.dx, p2.dx);
    double maxX = max(p1.dx, p2.dx);
    double minY = min(p1.dy, p2.dy);
    double maxY = max(p1.dy, p2.dy);
    return (p.dx >= minX && p.dx <= maxX) && (p.dy >= minY && p.dy <= maxY);
  }

  bool isCrossPolygon(Polygon polygon) {
    for(var line in polygon.lines){
      if (isCrossLine(line)) {
        return true;
      }
    }
    return (polygon.containsPoint(start) || polygon.containsPoint(end));
  }

  /// 计算线上一点该点距离起点[start] 距离为 d
  Offset distancePoint(double d) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final magnitude = sqrt(pow(dx, 2) + pow(dy, 2));
    if (magnitude == 0) {
      throw ArgumentError("起点和终止点不能重合");
    }
    final unitX = dx / magnitude;
    final unitY = dy / magnitude;
    return Offset(start.dx + d * unitX, start.dy + d * unitY);
  }

  /// 计算直线上点P的垂点Q，满足 PQ垂直于L 且距离为D
  /// [xA, yA] 和 [xB, yB] 是直线L上的两点，用于确定直线方向
  /// [dis] 是PQ的距离（可为正负，方向由垂线方向决定）
  Offset verticalPoint(Offset p, double dis) {
    // 计算直线L的方向向量
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    // 计算垂直于直线的方向向量（左侧垂直方向）
    final perpX = -dy;
    final perpY = dx;

    final magnitude = sqrt(perpX * perpX + perpY * perpY);
    if (magnitude == 0) {
      throw ArgumentError("直线L的两点重合，无法确定方向");
    }

    // 单位化垂线向量
    final unitX = perpX / magnitude;
    final unitY = perpY / magnitude;

    return Offset(p.dx + dis * unitX, p.dy + dis * unitY);
  }

  ///判断给定点是否在当前线段上
  bool contains(Offset p, {double deviation = 4}) {
    if (deviation < 0) {
      deviation = 0;
    }
    var dx = p.dx;
    var dy = p.dy;
    if (dy > max(start.dy, end.dy) + deviation || dy < min(start.dy, end.dy) - deviation) {
      return false;
    }
    if (dx > max(start.dx, end.dx) + deviation || dx < min(start.dx, end.dx) - deviation) {
      return false;
    }
    return distance(p) <= deviation;
  }

  /// 求点Q到直线的距离
  double distance(Offset p) {
    var dx = p.dx;
    var dy = p.dy;
    if (start.dx.compareTo(end.dx) == 0 && start.dy.compareTo(end.dy) == 0) {
      return p.distance2(start);
    }
    double A = end.dy - start.dy;
    double B = start.dx - end.dx;
    double C = end.dx * start.dy - start.dx * end.dy;
    return ((A * dx + B * dy + C) / (sqrt(A * A + B * B))).abs();
  }

  @override
  int get hashCode {
    return Object.hash(start, end);
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is Line && other.start == start && other.end == end;
  }
}

enum LineType {
  line,
  segment,
  ray;
}
