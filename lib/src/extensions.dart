import 'dart:math' as m;
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';
import 'package:dts/dts.dart' as dt;
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';

extension RectExt on Rect {
  bool contains2(Offset offset) {
    return offset.dx >= left && offset.dx <= right && offset.dy >= top && offset.dy <= bottom;
  }

  bool contains3(num x, num y) {
    return x >= left && x <= right && y >= top && y <= bottom;
  }

  String toString2() {
    return 'LTRB(${left.toStringAsFixed(1)}, ${top.toStringAsFixed(1)}, ${right.toStringAsFixed(1)}, ${bottom.toStringAsFixed(1)})';
  }

  ///返回一个新矩形 其每条边向内缩减指定量
  Rect deflate2({num left = 0, num right = 0, num top = 0, num bottom = 0}) {
    if (left == 0 && right == 0 && top == 0 && bottom == 0) {
      return this;
    }
    return Rect.fromLTRB(this.left - left, this.top - top, this.right - right, this.bottom - bottom);
  }

  double get centerX {
    return left + width / 2;
  }

  double get centerY {
    return top + height / 2;
  }

  bool containsPolygon(Polygon polygon) {
    double xMin = left;
    double yMin = top;
    double xMax = right;
    double yMax = bottom;
    for (var point in polygon.vertex) {
      if (point.dx < xMin || point.dx > xMax || point.dy < yMin || point.dy > yMax) {
        return false;
      }
    }
    return true;
  }

  Path toPath() {
    Path path = Path();
    path.moveTo(left, top);
    path.lineTo(right, top);
    path.lineTo(right, bottom);
    path.lineTo(left, bottom);
    path.close();
    return path;
  }

  dt.Geometry get asGeometry => geomFactory.createPolygon5([topLeft, topRight, bottomRight, bottomLeft], true);
}

extension RRectExt on RRect {
  Path toPath() {
    final path = Path();
    path.moveTo(left + tlRadiusX, top);
    path.lineTo(right - trRadiusX, top);
    path.arcToPoint(Offset(right, top + trRadiusY), radius: trRadius, clockwise: false);
    path.lineTo(right, bottom - brRadiusY);
    path.arcToPoint(Offset(right - brRadiusX, bottom), radius: brRadius, clockwise: false);
    path.lineTo(left + blRadiusX, bottom);
    path.arcToPoint(Offset(left, bottom - blRadiusY), radius: blRadius, clockwise: false);
    path.lineTo(left, top + tlRadiusY);
    path.arcToPoint(Offset(left + tlRadiusX, top), radius: tlRadius, clockwise: false);
    path.close();
    return path;
  }
}

extension OffsetExt on Offset {
  Offset get invert => Offset(-dx, -dy);

  Offset get abs {
    if (dx >= 0 && dy >= 0) {
      return this;
    }
    return Offset(dx.abs(), dy.abs());
  }

  double get x => dx;

  double get y => dy;

  //向量叉积
  double cross(Offset b) => x * b.y - y * b.x;

  //向量点积
  double dot(Offset b) => x * b.x + y * b.y;

  double distance2(Offset p) => distance3(p.dx, p.dy);

  double distance3(num x, num y) => m.sqrt(distanceNotSqrt(x, y));

  double distanceNotSqrt(num x, num y) {
    double a = (dx - x).abs();
    double b = (dy - y).abs();
    return a * a + b * b;
  }

  bool inLine(Offset p1, Offset p2, {double deviation = 4}) {
    return Line(p1, p2).containsPoint(this, eps: deviation);
  }

  bool inPolygon(List<Offset> list) => Polygon(list).containsPoint(this);

  bool inSector(
    num innerRadius,
    num outerRadius,
    Angle startAngle,
    Angle sweepAngle, {
    Offset center = Offset.zero,
  }) {
    double d1 = distance2(center);
    if (d1 > outerRadius || d1 < innerRadius) {
      return false;
    }
    if (sweepAngle.radians >= 2 * m.pi) {
      return true;
    }
    return inArc(
      Arc(
        innerRadius: innerRadius.toDouble(),
        outRadius: outerRadius.toDouble(),
        sweepAngle: sweepAngle,
        startAngle: startAngle,
        center: center,
      ),
    );
  }

  bool inArc(Arc arc) => arc.containsPoint(this);

  bool inCircle(num radius, {Offset center = Offset.zero, bool equal = true}) {
    return inCircle2(radius, center.dx, center.dy, equal);
  }

  bool inCircle2(num radius, [num cx = 0, num cy = 0, bool equal = true]) {
    double a = (dx - cx).abs();
    double b = (dy - cy).abs();
    if (equal) {
      return a * a + b * b <= radius * radius;
    }
    return a * a + b * b < radius * radius;
  }

  Angle angle([Offset center = Offset.zero]) {
    double d = m.atan2(dy - center.dy, dx - center.dx);
    if (d < 0) {
      d += 2 * m.pi;
    }
    return d.asRadians;
  }

  ///返回绕center点旋转angle角度后的位置坐标
  ///逆时针 angle 为负数
  ///顺时针 angle 为正数
  Offset rotate(Angle angle, {Offset center = Offset.zero}) {
    angle = angle.normalized;
    double x = (dx - center.dx) * angle.cos - (dy - center.dy) * angle.sin + center.dx;
    double y = (dx - center.dx) * angle.sin + (dy - center.dy) * angle.cos + center.dy;
    return Offset(x, y);
  }

  Offset translate2(Offset other) {
    return translate(other.dx, other.dy);
  }

  Offset merge(Offset offset) {
    if (offset == this) {
      return offset;
    }
    return Offset((dx + offset.dx) / 2, (dy + offset.dy) / 2);
  }

  Offset symmetryPoint(Offset start, Offset end) {
    double v1 = (dx - start.dx) * (end.dx - start.dx) + (dy - start.dy) * (end.dy - start.dy);
    double v2 = (end.dx - start.dx) * (end.dx - start.dx) + (end.dy - start.dy) * (end.dy - start.dy);
    double t = v1 / v2;
    double qdx = start.dx + (end.dx - start.dx) * t;
    double qdy = start.dy + (end.dy - start.dy) * t;

    return Offset(2.0 * qdx - dx, 2.0 * qdy - dy);
  }

  bool equal(Offset other, [double accurate = 1e-6]) {
    var x = other.dx - dx;
    var y = other.dy - dy;
    return x.abs() <= accurate && y.abs() <= accurate;
  }

  dt.Coordinate get asCoordinate => dt.Coordinate(dx, dy);

  dt.Point get asPoint => geomFactory.createPoint4(this);
}

extension DTSPointExt on dt.Point {
  Offset get asOffset => Offset(getX(), getY());
}

extension DTSCoordinateExt on dt.Coordinate {
  Offset get asOffset => Offset(x, y);
}

extension DTSRectExt on dt.Envelope {
  Rect get asRect => Rect.fromLTRB(minX, minY, maxX, maxY);
}

extension PathExt on Path {
  void lineTo2(Offset p) => lineTo(p.x, p.y);

  void moveTo2(Offset p) => moveTo(p.x, p.y);

  void arcTo2(Rect rect, Angle startAngle, Angle sweepAngle, bool forceMoveTo) {
    arcTo(rect, startAngle.radians, sweepAngle.radians, forceMoveTo);
  }

  void drawShadows(Canvas canvas, Path path, List<BoxShadow> shadows) {
    for (final BoxShadow shadow in shadows) {
      final Paint shadowPainter = shadow.toPaint();
      if (shadow.spreadRadius == 0) {
        canvas.drawPath(path.shift(shadow.offset), shadowPainter);
      } else {
        Rect zone = path.getBounds();
        double xScale = (zone.width + shadow.spreadRadius) / zone.width;
        double yScale = (zone.height + shadow.spreadRadius) / zone.height;
        Matrix4 m4 = Matrix4.identity();
        m4.translate(zone.width / 2, zone.height / 2);
        m4.scale(xScale, yScale);
        m4.translate(-zone.width / 2, -zone.height / 2);
        canvas.drawPath(path.shift(shadow.offset).transform(m4.storage), shadowPainter);
      }
    }
  }

  ///给定一个Path和dash数据返回一个新的Path
  Path dashPath(List<num> dash) {
    if (dash.isEmpty) {
      return this;
    }
    num dashLength = dash[0];
    num dashGapLength = dashLength >= 2 ? dash[1] : dash[0];
    final properties = _DashedProperties(path: Path(), dashLength: dashLength, dashGapLength: dashGapLength);
    final metricsIterator = computeMetrics().iterator;
    while (metricsIterator.moveNext()) {
      final metric = metricsIterator.current;
      properties.extractedPathLength = 0.0;
      while (properties.extractedPathLength < metric.length) {
        if (properties.addDashNext) {
          properties.addDash(metric, dashLength);
        } else {
          properties.addDashGap(metric, dashGapLength);
        }
      }
    }
    return properties.path;
  }

  List<Offset> dashPath2(
    List<num> dash, {
    double phase = 0.0,
    bool startWithDraw = true,
    bool resetOnSubpath = false,
    bool closeSegment = true,
  }) {
    final result = <Offset>[];
    if (dash.isEmpty) return result;
    final pattern = dash.map((d) => d.toDouble()).toList();

    int patIndex = 0;
    double patRemaining = pattern[0];
    bool draw = startWithDraw;
    Offset? pendingStart;

    void resetPatternState() {
      patIndex = 0;
      patRemaining = pattern[0];
      draw = startWithDraw;
      pendingStart = null;
    }

    const double eps = 1e-9;

    for (final pm in computeMetrics()) {
      double localPos = 0.0;
      final double subLen = pm.length;
      if (resetOnSubpath) {
        resetPatternState();
      }

      if (phase > 0) {
        double skipped = 0.0;
        while (skipped + eps < phase) {
          final double consume = (patRemaining <= (phase - skipped)) ? patRemaining : (phase - skipped);
          skipped += consume;
          patRemaining -= consume;

          if (patRemaining <= eps) {
            patIndex = (patIndex + 1) % pattern.length;
            patRemaining = pattern[patIndex];
            draw = !draw;
          }
        }
        localPos = phase.clamp(0.0, subLen);
        phase = 0.0;
      }

      while (localPos + eps < subLen) {
        final double available = subLen - localPos;
        final double consume = (patRemaining <= available) ? patRemaining : available;

        if (draw && pendingStart == null) {
          final t = pm.getTangentForOffset(localPos);
          if (t != null) pendingStart = t.position;
        }

        localPos += consume;
        patRemaining -= consume;

        if (draw && patRemaining <= eps) {
          final tEnd = pm.getTangentForOffset(localPos.clamp(0.0, subLen));
          final end = tEnd?.position;
          if (pendingStart != null && end != null) {
            result.add(pendingStart!);
            result.add(end);
            pendingStart = null;
          }
        }

        if (patRemaining <= eps) {
          patIndex = (patIndex + 1) % pattern.length;
          patRemaining = pattern[patIndex];
          draw = !draw;
        }
      }

      if (closeSegment && pendingStart != null) {
        final tend = pm.getTangentForOffset(pm.length)?.position;
        if (tend != null) {
          result.add(pendingStart!);
          result.add(tend);
        }
        pendingStart = null;
      }
    }

    return result;
  }

  /// 给定一个Path和路径百分比返回给定百分比路径
  Path percentPath(double percent) {
    if (percent >= 1) {
      return this;
    }
    if (percent <= 0) {
      return Path();
    }
    PathMetrics metrics = computeMetrics();
    Path newPath = Path();
    for (PathMetric metric in metrics) {
      Path tmp = metric.extractPath(0, metric.length * percent);
      newPath.addPath(tmp, Offset.zero);
    }
    return newPath;
  }

  double getLength() {
    double l = 0;
    PathMetrics metrics = computeMetrics();
    for (PathMetric metric in metrics) {
      l += metric.length;
    }
    return l;
  }

  //返回路径百分比上的一点
  Offset? percentOffset(double percent) {
    PathMetrics metrics = computeMetrics();
    for (PathMetric metric in metrics) {
      if (metric.length <= 0) {
        continue;
      }
      var result = metric.getTangentForOffset(metric.length * percent);
      if (result == null) {
        continue;
      }

      return result.position;
    }
    return null;
  }

  Offset? firstOffset() {
    PathMetrics metrics = computeMetrics();
    for (PathMetric metric in metrics) {
      if (metric.length <= 0) {
        continue;
      }
      var result = metric.getTangentForOffset(1);
      if (result == null) {
        continue;
      }
      return result.position;
    }
    return null;
  }

  Offset? lastOffset() {
    PathMetrics metrics = computeMetrics();
    List<Offset> ol = [];
    for (PathMetric metric in metrics) {
      if (metric.length <= 0) {
        continue;
      }
      var result = metric.getTangentForOffset(metric.length);
      if (result == null) {
        continue;
      }
      ol.add(result.position);
    }
    if (ol.isEmpty) {
      return null;
    }
    return ol[ol.length - 1];
  }

  ///将当前Path进行拆分
  List<Path> split([num maxLength = 300]) {
    List<Path> pathList = [];

    PathMetrics metrics = computeMetrics();
    for (PathMetric metric in metrics) {
      final double length = metric.length;
      if (metric.length <= 0) {
        continue;
      }
      if (length <= maxLength) {
        pathList.add(metric.extractPath(0, length));
        continue;
      }
      double start = 0;
      while (start < length) {
        double end = start + maxLength;
        if (end > length) {
          end = length;
        }
        pathList.add(metric.extractPath(start, end));
        if (end >= length) {
          break;
        }
        start += maxLength;
      }
    }
    return pathList;
  }

  ///合并两个Path,并将其头相连，尾相连
  Path mergePath(Path p2) {
    Path path = this;
    PathMetric metric = p2.computeMetrics().single;
    double length = metric.length;
    while (length >= 0) {
      Tangent? t = metric.getTangentForOffset(length);
      if (t != null) {
        Offset offset = t.position;
        path.lineTo(offset.dx, offset.dy);
      }
      length -= 1;
    }
    path.close();
    return path;
  }

  bool overlapRect(Rect rect) {
    if (contains(rect.topLeft)) {
      return true;
    }
    if (contains(rect.topRight)) {
      return true;
    }
    if (contains(rect.bottomLeft)) {
      return true;
    }
    if (contains(rect.bottomRight)) {
      return true;
    }
    var bound = getBounds();
    return bound.overlaps(rect);
  }
}

///用于实现 path dash
class _DashedProperties {
  num extractedPathLength;
  Path path;

  final num _dashLength;
  num _remainingDashLength;
  num _remainingDashGapLength;
  bool _previousWasDash;

  _DashedProperties({
    required this.path,
    required num dashLength,
    required num dashGapLength,
  })  : assert(dashLength > 0.0, 'dashLength must be > 0.0'),
        assert(dashGapLength > 0.0, 'dashGapLength must be > 0.0'),
        _dashLength = dashLength,
        _remainingDashLength = dashLength,
        _remainingDashGapLength = dashGapLength,
        _previousWasDash = false,
        extractedPathLength = 0.0;

  bool get addDashNext {
    if (!_previousWasDash || _remainingDashLength != _dashLength) {
      return true;
    }
    return false;
  }

  void addDash(PathMetric metric, num dashLength) {
    final end = _calculateLength(metric, _remainingDashLength).toDouble();
    final availableEnd = _calculateLength(metric, dashLength);
    final pathSegment = metric.extractPath(extractedPathLength.toDouble(), end);
    path.addPath(pathSegment, Offset.zero);
    final delta = _remainingDashLength - (end - extractedPathLength);
    _remainingDashLength = _updateRemainingLength(
      delta: delta,
      end: end,
      availableEnd: availableEnd,
      initialLength: dashLength,
    );
    extractedPathLength = end;
    _previousWasDash = true;
  }

  void addDashGap(PathMetric metric, num dashGapLength) {
    final end = _calculateLength(metric, _remainingDashGapLength);
    final availableEnd = _calculateLength(metric, dashGapLength);
    Tangent tangent = metric.getTangentForOffset(end.toDouble())!;
    path.moveTo(tangent.position.dx, tangent.position.dy);
    final delta = end - extractedPathLength;
    _remainingDashGapLength =
        _updateRemainingLength(delta: delta, end: end, availableEnd: availableEnd, initialLength: dashGapLength);
    extractedPathLength = end;
    _previousWasDash = false;
  }

  num _calculateLength(PathMetric metric, num addedLength) {
    return m.min(extractedPathLength + addedLength, metric.length);
  }

  num _updateRemainingLength({
    required num delta,
    required num end,
    required num availableEnd,
    required num initialLength,
  }) {
    return (delta > 0 && availableEnd == end) ? delta : initialLength;
  }
}
