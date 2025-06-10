import 'dart:ui';
import 'dart:math' as m;
import 'package:dart_graph/src/geomtry/rect_ext.dart';
import 'package:dart_graph/src/list_ext.dart';
import 'package:flutter/foundation.dart';

import 'line.dart';

class Polygon {
  static final Polygon zero = Polygon([]);

  late List<Offset> vertex;
  late final List<Line> lines;

  late final Rect bound = _onBuildBound();

  bool pathUseHull;

  Polygon(this.vertex, [this.pathUseHull = false]) {
    int n = vertex.length;
    List<Line> tmp = [];
    for (int i = 0; i < n; i++) {
      tmp.add(Line.segment(vertex[i], vertex[(i + 1) % n]));
    }
    lines = List.of(tmp, growable: false);
  }

  bool contains(Offset offset) {
    if (vertex.isEmpty) {
      return false;
    }
    if (vertex.length < 3) {
      for (var c in vertex) {
        if (c == offset) {
          return true;
        }
      }
      return false;
    }
    if (!bound.contains(offset)) {
      return false;
    }
    return inInner2(offset);
  }

  Rect _onBuildBound() {
    double left = double.maxFinite;
    double top = double.maxFinite;
    double bottom = double.minPositive;
    double right = double.minPositive;
    vertex.each((p0, p1) {
      left = m.min(p0.dx, left);
      top = m.min(p0.dy, top);
      right = m.max(p0.dx, right);
      bottom = m.max(p0.dy, bottom);
    });
    var rect = Rect.fromLTRB(left, top, right, bottom);
    if (rect.isInfinite || rect.isEmpty) {
      return Rect.zero;
    }
    return rect;
  }

  @override
  int get hashCode {
    return Object.hashAll(vertex);
  }

  Offset operator [](int index) {
    return vertex[index];
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is Polygon && listEquals(vertex, other.vertex);
  }

  // 判断点是否在多边形内部（射线法）
  bool containsPoint(Offset p) {
    int n = vertex.length;
    bool inside = false;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      Offset vi = vertex[i];
      Offset vj = vertex[j];
      if (((vi.dy > p.dy) != (vj.dy > p.dy)) && (p.dx < (vj.dx - vi.dx) * (p.dy - vi.dy) / (vj.dy - vi.dy) + vi.dx)) {
        inside = !inside;
      }
    }
    return inside;
  }

  bool containsRect(Rect rect) {
    for (var item in [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft]) {
      if (!containsPoint(item)) {
        return false;
      }
    }
    return true;
  }

  bool isCrossPolygon(Polygon polygon) {
    for (var line in lines) {
      for (var line2 in polygon.lines) {
        if (line.isCrossLine(line2)) {
          return true;
        }
      }
    }

    for (var p in vertex) {
      if (polygon.containsPoint(p)) {
        return true;
      }
    }

    for (var p in polygon.vertex) {
      if (containsPoint(p)) {
        return true;
      }
    }

    return false;
  }

  ///给定一个矩形范围 裁剪多边形
  Polygon? clipRange(Rect rect) {
    if (rect.containsPolygon(this)) {
      return this;
    }
    if (containsRect(rect)) {
      return null;
    }
    return _clipRangeForInner(rect);
  }

  Polygon _clipRangeForInner(Rect rect) {
    List<Offset> clippedPolygon = List.from(vertex);
    List<Offset> clipEdges = [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft];
    for (int i = 0; i < 4; i++) {
      final p1 = clipEdges[i];
      final p2 = clipEdges[(i + 1) % 4];

      List<Offset> inputPolygon = List.from(clippedPolygon);
      clippedPolygon.clear();

      for (int j = 0; j < inputPolygon.length; j++) {
        final current = inputPolygon[j];
        final next = inputPolygon[(j + 1) % inputPolygon.length];
        if (!rect.contains(current)) {
          continue;
        }

        // 检查与矩形边相交的部分
        if (rect.contains(next)) {
          clippedPolygon.add(current);
        } else {
          final intersection = _intersect(current, next, p1, p2);
          if (intersection != null) {
            clippedPolygon.add(intersection);
          }
        }
      }
    }
    return Polygon(clippedPolygon);
  }

  // 求两条线段的交点
  Offset? _intersect(Offset p1, Offset p2, Offset p3, Offset p4) {
    double denom = (p1.dx - p2.dx) * (p3.dy - p4.dy) - (p1.dy - p2.dy) * (p3.dx - p4.dx);
    if (denom == 0) return null;
    double x =
        ((p1.dx * p2.dy - p1.dy * p2.dx) * (p3.dx - p4.dx) - (p1.dx - p2.dx) * (p3.dx * p4.dy - p3.dy * p4.dx)) / denom;
    double y =
        ((p1.dx * p2.dy - p1.dy * p2.dx) * (p3.dy - p4.dy) - (p1.dy - p2.dy) * (p3.dx * p4.dy - p3.dy * p4.dx)) / denom;

    return Offset(x, y);
  }

  ///多边形的面积
  ///如果多边形的顶点按逆时针顺序排列（假设坐标系的原点 ⟨0，0⟩ 位于左上角）
  ///则返回的区域为正数;否则为负数或零
  double area() {
    int i = -1;
    int n = vertex.length;
    Offset a;
    Offset b = vertex[n - 1];
    double area = 0;
    while (++i < n) {
      a = b;
      b = vertex[i];
      area += a.dy * b.dx - a.dx * b.dy;
    }
    return area / 2;
  }

  ///返回多边形重心坐标
  Offset center() {
    int i = -1;
    int n = vertex.length;
    double x = 0;
    double y = 0;
    Offset a;
    Offset b = vertex[n - 1];
    double c;
    double k = 0;

    while (++i < n) {
      a = b;
      b = vertex[i];
      c = a.dx * b.dy - b.dx * a.dy;
      k += c;
      x += (a.dx + b.dx) * c;
      y += (a.dy + b.dy) * c;
    }
    k *= 3;
    return Offset(x / k, y / k);
  }

  /// 返回一个点是否在一个多边形区域内
  bool inInner(Offset offset) {
    var dx = offset.dx;
    var dy = offset.dy;
    int nCross = 0;
    for (int i = 0; i < vertex.length; i++) {
      Offset p1 = vertex[i];
      Offset p2 = vertex[((i + 1) % vertex.length)];
      if (p1.dy == p2.dy) {
        continue;
      }

      if (dy < m.min(p1.dy, p2.dy)) {
        continue;
      }
      if (dy >= m.max(p1.dy, p2.dy)) {
        continue;
      }

      double x = (dy - p1.dy) * (p2.dx - p1.dx) / (p2.dy - p1.dy) + p1.dx;
      if (x > dx) {
        //统计单边交点
        nCross++;
      }
    }
    return (nCross % 2 == 1);
  }

  bool inInner2(Offset offset) {
    int n = vertex.length;
    var p = vertex[n - 1];
    var x = offset.dx, y = offset.dy;
    var x0 = p.dx, y0 = p.dy;

    bool inside = false;
    double x1, y1;
    for (var i = 0; i < n; ++i) {
      p = vertex[i];
      x1 = p.dx;
      y1 = p.dy;
      if (((y1 > y) != (y0 > y)) && (x < (x0 - x1) * (y - y1) / (y0 - y1) + x1)) {
        inside = !inside;
      }
      x0 = x1;
      y0 = y1;
    }
    return inside;
  }

  /// 返回一个点是否在一个多边形边界上
  bool inBorder(Offset offset) {
    var dx = offset.dx;
    var dy = offset.dy;
    for (int i = 0; i < vertex.length; i++) {
      Offset p1 = vertex[i];
      Offset p2 = vertex[((i + 1) % vertex.length)];
      if (dy < m.min(p1.dy, p2.dy)) {
        continue;
      }
      if (dy > m.max(p1.dy, p2.dy)) {
        continue;
      }
      if (p1.dy == p2.dy) {
        double minX = m.min(p1.dx, p2.dx);
        double maxX = m.max(p1.dx, p2.dx);
        if ((dy == p1.dy) && (dx >= minX && dx <= maxX)) {
          return true;
        }
      } else {
        // 求解交点
        double x = (dy - p1.dy) * (p2.dx - p1.dx) / (p2.dy - p1.dy) + p1.dx;
        if (x == dx) {
          return true;
        }
      }
    }
    return false;
  }

  ///多边形周长
  double length() {
    int i = -1;
    int n = vertex.length;
    Offset b = vertex[n - 1];
    double xa;
    double ya;
    double xb = b.dx;
    double yb = b.dy;
    double perimeter = 0;
    while (++i < n) {
      xa = xb;
      ya = yb;
      b = vertex[i];
      xb = b.dx;
      yb = b.dy;
      xa -= xb;
      ya -= yb;
      perimeter += hypot([xa, ya]);
    }
    return perimeter;
  }

  ///返回多边形的包裹点集合
  List<Offset> hull() {
    int n = vertex.length;
    if (n < 3) {
      return [];
    }

    List<Hull> sortedPoints = [];
    List<Offset> flippedPoints = [];
    for (int i = 0; i < n; ++i) {
      sortedPoints.add(Hull(vertex[i].dx, vertex[i].dy, i));
    }
    sortedPoints.sort((a, b) {
      var r = a.x.compareTo(b.x);
      if (r != 0) {
        return r;
      }
      return a.y.compareTo(b.y);
    });

    for (int i = 0; i < n; ++i) {
      flippedPoints.add(Offset(sortedPoints[i].x, -sortedPoints[i].y));
    }

    var upperIndexes = _computeUpperHullIndexes(sortedPoints);
    var lowerIndexes = _computeUpperHullIndexes(flippedPoints);

    int skipLeft = lowerIndexes[0] == upperIndexes[0] ? 1 : 0;
    int skipRight = lowerIndexes[lowerIndexes.length - 1] == upperIndexes[upperIndexes.length - 1] ? 1 : 0;
    List<Offset> hull = [];

    for (int i = upperIndexes.length - 1; i >= 0; --i) {
      hull.add(vertex[sortedPoints[upperIndexes[i]].i]);
    }
    for (int i = skipLeft; i < lowerIndexes.length - skipRight; ++i) {
      hull.add(vertex[sortedPoints[lowerIndexes[i]].i]);
    }
    return hull;
  }

  ///返回 AB AC的差积
  double _cross(Offset a, Offset b, Offset c) {
    return (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
  }

  List<int> _computeUpperHullIndexes(List<dynamic> points) {
    int n = points.length;
    List<int> indexes = [0, 1];
    int size = 2;
    for (int i = 2; i < n; ++i) {
      while (size > 1) {
        dynamic a = points[indexes[size - 2]];
        if (a is Hull) {
          a = Offset(a.x, a.y);
        }
        dynamic b = points[indexes[size - 1]];
        if (b is Hull) {
          b = Offset(b.x, b.y);
        }
        dynamic c = points[i];
        if (c is Hull) {
          c = Offset(c.x, c.y);
        }
        num r = _cross(a, b, c);
        if (r <= 0) {
          --size;
        }
      }
      indexes[size++] = i;
    }
    return indexes.sublist(0, size);
  }

  double hypot(List<num> list) {
    double a = 0;
    for (var c in list) {
      a += c * c;
    }
    return m.sqrt(a);
  }
}

class Hull {
  final double x;
  final double y;
  final int i;

  Hull(this.x, this.y, this.i);
}
