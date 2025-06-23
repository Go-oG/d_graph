import 'dart:ui';

class MultiLine {
  ///给定路径点坐标和矩形区域范围 返回裁剪后的路径点坐标
  static List<Offset> clipPathWithRect(List<Offset> path, Rect rect) {
    final List<Offset> result = [];

    for (int i = 0; i < path.length - 1; i++) {
      final p0 = path[i];
      final p1 = path[i + 1];
      final clipped = _cohenSutherlandClip(p0, p1, rect);
      if (clipped != null) {
        if (result.isEmpty || result.last != clipped[0]) {
          result.add(clipped[0]);
        }
        result.add(clipped[1]);
      }
    }
    return result;
  }

  static int _computeOutCode(Offset p, Rect rect) {
    const int INSIDE = 0; // 0000
    const int LEFT = 1; // 0001
    const int RIGHT = 2; // 0010
    const int BOTTOM = 4; // 0100
    const int TOP = 8; // 1000

    int code = INSIDE;

    if (p.dx < rect.left) {
      code |= LEFT;
    } else if (p.dx > rect.right) {
      code |= RIGHT;
    }

    if (p.dy < rect.top) {
      code |= TOP;
    } else if (p.dy > rect.bottom) {
      code |= BOTTOM;
    }

    return code;
  }

  static List<Offset>? _cohenSutherlandClip(Offset p0, Offset p1, Rect rect) {
    const int LEFT = 1, RIGHT = 2, BOTTOM = 4, TOP = 8;

    double x0 = p0.dx, y0 = p0.dy;
    double x1 = p1.dx, y1 = p1.dy;

    int outCode0 = _computeOutCode(p0, rect);
    int outCode1 = _computeOutCode(p1, rect);

    bool accept = false;

    while (true) {
      if ((outCode0 | outCode1) == 0) {
        // 两点都在矩形内
        accept = true;
        break;
      } else if ((outCode0 & outCode1) != 0) {
        // 两点在矩形外同一侧
        break;
      } else {
        double x = 0.0, y = 0.0;
        int outCodeOut = outCode0 != 0 ? outCode0 : outCode1;

        if ((outCodeOut & TOP) != 0) {
          x = x0 + (x1 - x0) * (rect.top - y0) / (y1 - y0);
          y = rect.top;
        } else if ((outCodeOut & BOTTOM) != 0) {
          x = x0 + (x1 - x0) * (rect.bottom - y0) / (y1 - y0);
          y = rect.bottom;
        } else if ((outCodeOut & RIGHT) != 0) {
          y = y0 + (y1 - y0) * (rect.right - x0) / (x1 - x0);
          x = rect.right;
        } else if ((outCodeOut & LEFT) != 0) {
          y = y0 + (y1 - y0) * (rect.left - x0) / (x1 - x0);
          x = rect.left;
        }

        if (outCodeOut == outCode0) {
          x0 = x;
          y0 = y;
          outCode0 = _computeOutCode(Offset(x0, y0), rect);
        } else {
          x1 = x;
          y1 = y;
          outCode1 = _computeOutCode(Offset(x1, y1), rect);
        }
      }
    }

    if (accept) {
      return [Offset(x0, y0), Offset(x1, y1)];
    } else {
      return null;
    }
  }
}
