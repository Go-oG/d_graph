import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:d_util/d_util.dart';

class QuadTree<T> {
  static const double _epsilon = 1e-9;

  final Fun2<T, double> xFun;
  final Fun2<T, double> yFun;
  QuadNode<T>? _root;

  double _left;
  double _top;
  double _right;
  double _bottom;

  QuadTree(this.xFun, this.yFun, this._left, this._top, this._right, this._bottom);

  QuadTree.fromRect(this.xFun, this.yFun, Rect rect)
    : _left = rect.left,
      _top = rect.top,
      _right = rect.right,
      _bottom = rect.bottom;

  static QuadTree<T> simple<T>(Fun2<T, double> xFun, Fun2<T, double> yFun, List<T> nodes) {
    QuadTree<T> tree = QuadTree(xFun, yFun, double.nan, double.nan, double.nan, double.nan);
    if (nodes.isNotEmpty) {
      tree.addAll(nodes);
    }
    return tree;
  }

  QuadNode<T> leafCopy(QuadNode<T> leaf) {
    QuadNode<T> copy = QuadNode.leaf(leaf.data!);
    QuadNode<T>? next = copy;
    QuadNode<T>? source = leaf;

    while ((source = source?.next) != null) {
      next!.next = QuadNode.leaf(source!.data!);
      next = next.next;
    }
    return copy;
  }

  QuadTree<T> add(T data) {
    final x = xFun.call(data);
    final y = yFun.call(data);
    if (x.isNaN || y.isNaN) return this;
    return _addInner(cover(x, y), x, y, data);
  }

  QuadTree<T> addAll(List<T> data) {
    int n = data.length;
    if (n == 0) return this;

    Float64List xz = Float64List(n);
    Float64List yz = Float64List(n);
    double x0 = double.infinity;
    double y0 = double.infinity;
    double x1 = double.negativeInfinity;
    double y1 = double.negativeInfinity;

    for (int i = 0; i < n; ++i) {
      T d = data[i];
      double x = xFun.call(d);
      double y = yFun.call(d);
      if (x.isNaN || y.isNaN || x.isInfinite || y.isInfinite) continue;

      xz[i] = x;
      yz[i] = y;
      if (x < x0) x0 = x;
      if (x > x1) x1 = x;
      if (y < y0) y0 = y;
      if (y > y1) y1 = y;
    }

    if (x0 > x1 || y0 > y1) return this;

    cover(x0, y0).cover(x1, y1);

    for (int i = 0; i < n; ++i) {
      _addInner(this, xz[i], yz[i], data[i]);
    }
    return this;
  }

  QuadTree<T> _addInner(QuadTree<T> tree, double x, double y, T data) {
    QuadNode<T> leaf = QuadNode<T>.leaf(data);
    if (tree._root == null) {
      tree._root = leaf;
      return tree;
    }

    double x0 = tree._left, y0 = tree._top, x1 = tree._right, y1 = tree._bottom;
    QuadNode<T>? parent;
    QuadNode<T>? node = tree._root!;

    double xm, ym;
    int right, bottom;
    int i = 0, j = 0;

    while (node!.isInternal) {
      xm = (x0 + x1) / 2;
      ym = (y0 + y1) / 2;

      right = x >= xm ? 1 : 0;
      bottom = y >= ym ? 1 : 0;

      if (right == 1) {
        x0 = xm;
      } else {
        x1 = xm;
      }
      if (bottom == 1) {
        y0 = ym;
      } else {
        y1 = ym;
      }

      parent = node;
      i = bottom << 1 | right;

      if ((node = node.children[i]) == null) {
        parent.children[i] = leaf;
        return tree;
      }
    }

    double xp = xFun.call(node.data as T);
    double yp = yFun.call(node.data as T);

    //  坐标完全重合
    if ((x - xp).abs() < _epsilon && (y - yp).abs() < _epsilon) {
      leaf.next = node;
      if (parent != null) {
        parent.children[i] = leaf;
      } else {
        tree._root = leaf;
      }
      return tree;
    }

    // 坐标不重合，分裂叶子节点
    do {
      if ((x1 - x0).abs() < _epsilon || (y1 - y0).abs() < _epsilon) {
        leaf.next = node;
        j = i;
        break;
      }

      if (parent != null) {
        parent.children[i] = QuadNode.internal();
        parent = parent.children[i];
      } else {
        tree._root = QuadNode.internal();
        parent = tree._root;
      }

      xm = (x0 + x1) / 2;
      ym = (y0 + y1) / 2;

      right = x >= xm ? 1 : 0;
      bottom = y >= ym ? 1 : 0;

      if (right == 1) {
        x0 = xm;
      } else {
        x1 = xm;
      }
      if (bottom == 1) {
        y0 = ym;
      } else {
        y1 = ym;
      }

      i = bottom << 1 | right;
      j = (yp >= ym ? 1 : 0) << 1 | (xp >= xm ? 1 : 0);
    } while (i == j);

    if (i == j) {
      parent!.children[i] = leaf;
    } else {
      parent!.children[j] = node;
      parent.children[i] = leaf;
    }
    return tree;
  }

  QuadTree<T> extent(Rect rect) {
    cover(rect.left, rect.top).cover(rect.right, rect.bottom);
    return this;
  }

  QuadTree<T> cover(double x, double y) {
    if (x.isNaN || y.isNaN) return this;

    double x0 = _left, y0 = _top, x1 = _right, y1 = _bottom;

    if (x0.isNaN || x0.isInfinite) {
      x1 = (x0 = x.floorToDouble()) + 1.0;
      y1 = (y0 = y.floorToDouble()) + 1.0;
    } else {
      if (x >= x0 && x < x1 && y >= y0 && y < y1) return this;

      double z = x1 - x0;
      QuadNode<T>? node = _root;
      QuadNode<T>? parent;
      int i;

      while (x0 > x || x >= x1 || y0 > y || y >= y1) {
        i = (y < y0 ? 1 : 0) << 1 | (x < x0 ? 1 : 0);
        parent = QuadNode.internal();
        parent.children[i] = node;
        node = parent;
        z *= 2;

        switch (i) {
          case 0:
            x1 = x0 + z;
            y1 = y0 + z;
            break;
          case 1:
            x0 = x1 - z;
            y1 = y0 + z;
            break;
          case 2:
            x1 = x0 + z;
            y0 = y1 - z;
            break;
          case 3:
            x0 = x1 - z;
            y0 = y1 - z;
            break;
        }
      }

      if (_root != null) {
        _root = node;
      }
    }

    _left = x0;
    _top = y0;
    _right = x1;
    _bottom = y1;
    return this;
  }

  QuadTree<T> each(QuadVisitCallback<T> callback) {
    List<_InnerNode<T>> quads = [];
    QuadNode<T>? node = _root;
    if (node != null) {
      quads.add(_InnerNode(node, _left, _top, _right, _bottom));
    }

    while (quads.isNotEmpty) {
      _InnerNode<T> q = quads.removeLast();
      node = q.node;
      double x0 = q.left, y0 = q.top, x1 = q.right, y1 = q.bottom;
      if (!callback(node, x0, y0, x1, y1) && node.isInternal) {
        double xm = (x0 + x1) / 2;
        double ym = (y0 + y1) / 2;
        if (node.children[3] != null) quads.add(_InnerNode(node.children[3]!, xm, ym, x1, y1));
        if (node.children[2] != null) quads.add(_InnerNode(node.children[2]!, x0, ym, xm, y1));
        if (node.children[1] != null) quads.add(_InnerNode(node.children[1]!, xm, y0, x1, ym));
        if (node.children[0] != null) quads.add(_InnerNode(node.children[0]!, x0, y0, xm, ym));
      }
    }
    return this;
  }

  T? find(double x, double y, [double? r]) {
    double x0 = _left, y0 = _top, x3 = _right, y3 = _bottom;
    List<_InnerNode<T>> quads = [];
    QuadNode<T>? node = _root;
    if (node != null) {
      quads.add(_InnerNode(node, x0, y0, x3, y3));
    }

    double radiusSq = (r == null) ? double.infinity : r * r;
    T? data;
    double searchX0 = x - (r ?? double.infinity);
    double searchY0 = y - (r ?? double.infinity);
    double searchX1 = x + (r ?? double.infinity);
    double searchY1 = y + (r ?? double.infinity);

    void updateSearchBounds(double currentRadiusSq) {
      if (currentRadiusSq.isInfinite) return;
      double rad = sqrt(currentRadiusSq);
      searchX0 = x - rad;
      searchY0 = y - rad;
      searchX1 = x + rad;
      searchY1 = y + rad;
    }

    if (r != null) updateSearchBounds(radiusSq);

    while (quads.isNotEmpty) {
      _InnerNode<T> q = quads.removeLast();
      node = q.node;
      double qx0 = q.left, qy0 = q.top, qx1 = q.right, qy1 = q.bottom;
      if (qx0 > searchX1 || qy0 > searchY1 || qx1 < searchX0 || qy1 < searchY0) {
        continue;
      }

      if (node.isInternal) {
        double xm = (qx0 + qx1) / 2;
        double ym = (qy0 + qy1) / 2;

        int i = (y >= ym ? 1 : 0) << 1 | (x >= xm ? 1 : 0);
        var children = node.children;
        for (int k = 0; k < 4; k++) {
          if (k == i) continue;
          if (children[k] != null) {
            _pushQuad(quads, children[k]!, k, qx0, qy0, xm, ym, qx1, qy1);
          }
        }
        if (children[i] != null) {
          _pushQuad(quads, children[i]!, i, qx0, qy0, xm, ym, qx1, qy1);
        }
      } else {
        QuadNode<T>? leaf = node;
        do {
          double dx = x - xFun(leaf!.data!);
          double dy = y - yFun(leaf.data!);
          double d2 = dx * dx + dy * dy;
          if (d2 < radiusSq) {
            radiusSq = d2;
            data = leaf.data;
            updateSearchBounds(radiusSq);
          }
          leaf = leaf.next;
        } while (leaf != null);
      }
    }
    return data;
  }

  void _pushQuad(
    List<_InnerNode<T>> quads,
    QuadNode<T> node,
    int k,
    double x0,
    double y0,
    double xm,
    double ym,
    double x1,
    double y1,
  ) {
    switch (k) {
      case 0:
        quads.add(_InnerNode(node, x0, y0, xm, ym));
        break; // TL
      case 1:
        quads.add(_InnerNode(node, xm, y0, x1, ym));
        break; // TR
      case 2:
        quads.add(_InnerNode(node, x0, ym, xm, y1));
        break; // BL
      case 3:
        quads.add(_InnerNode(node, xm, ym, x1, y1));
        break; // BR
    }
  }

  List<T> search(Rect rect) {
    if (_root == null) {
      return const [];
    }
    List<T> results = [];
    double xmin = rect.left;
    double ymin = rect.top;
    double xmax = rect.right;
    double ymax = rect.bottom;

    each((node, x1, y1, x2, y2) {
      bool outside = x1 >= xmax || y1 >= ymax || x2 < xmin || y2 < ymin;
      if (outside) return true;

      if (!node.isInternal) {
        QuadNode<T>? leaf = node;
        while (leaf != null) {
          T d = leaf.data!;
          double dx = xFun.call(d);
          double dy = yFun.call(d);
          if (dx >= xmin && dx < xmax && dy >= ymin && dy < ymax) {
            results.add(d);
          }
          leaf = leaf.next;
        }
      }
      return false;
    });
    return results;
  }

  int get size {
    int count = 0;
    each((node, x0, y0, x1, y1) {
      if (!node.isInternal) {
        QuadNode<T>? leaf = node;
        while (leaf != null) {
          count++;
          leaf = leaf.next;
        }
      }
      return false;
    });
    return count;
  }
}

class _InnerNode<T> {
  final QuadNode<T> node;
  final double left;
  final double top;
  final double right;
  final double bottom;

  _InnerNode(this.node, this.left, this.top, this.right, this.bottom);
}

class QuadNode<T> {
  T? data;

  late final bool _hasChildrenList;
  late final List<QuadNode<T>?> children;

  QuadNode<T>? next;

  bool get isInternal => data == null && _hasChildrenList;

  QuadNode.leaf(this.data) {
    _hasChildrenList = false;
    children = const [];
  }

  QuadNode.internal() {
    data = null;
    children = List.filled(4, null);
    _hasChildrenList = true;
  }

  QuadNode<T>? operator [](int index) {
    if (!_hasChildrenList) return null;
    return children[index];
  }

  void operator []=(int index, QuadNode<T>? node) {
    if (_hasChildrenList) {
      children[index] = node;
    }
  }
}

typedef QuadVisitCallback<T> = bool Function(QuadNode<T> node, double left, double top, double right, double bottom);
