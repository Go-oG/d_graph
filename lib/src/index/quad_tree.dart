import 'dart:typed_data';
import 'dart:ui';

import '../util/extra_mixin.dart';

typedef Accessor<T> = double Function(T data);

typedef VisitCallback<T> = bool Function(QuadNode<T> node, double x0, double y0, double x1, double y1);

class QuadTree<T> {
  final Accessor<T> xFun;
  final Accessor<T> yFun;
  QuadNode<T>? _root;

  double _x0 = double.nan;
  double _y0 = double.nan;
  double _x1 = double.nan;
  double _y1 = double.nan;

  QuadTree(this.xFun, this.yFun, [double? x0, double? y0, double? x1, double? y1]) {
    if (x0 != null && y0 != null && x1 != null && y1 != null) {
      _x0 = x0;
      _y0 = y0;
      _x1 = x1;
      _y1 = y1;
    }
  }

  static QuadTree<T> fromList<T>(Accessor<T> xFun, Accessor<T> yFun, List<T> nodes) {
    QuadTree<T> tree = QuadTree(xFun, yFun);
    tree.addAll(nodes);
    return tree;
  }

  void add(T data) {
    final x = xFun(data);
    final y = yFun(data);
    if (x.isNaN || y.isNaN) return;
    _cover(x, y);
    _addInner(x, y, data);
  }

  void addAll(List<T> data) {
    final int n = data.length;
    if (n == 0) return;
    final Float64List xs = Float64List(n);
    final Float64List ys = Float64List(n);
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (int i = 0; i < n; ++i) {
      final d = data[i];
      final x = xFun(d);
      final y = yFun(d);
      xs[i] = x;
      ys[i] = y;

      if (x.isNaN || y.isNaN) continue;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    if (minX > maxX || minY > maxY) return;
    _cover(minX, minY);
    _cover(maxX, maxY);

    for (int i = 0; i < n; ++i) {
      _addInner(xs[i], ys[i], data[i]);
    }
  }

  void _cover(double x, double y) {
    if (x.isNaN || y.isNaN) return;
    if (_x0.isNaN) {
      _x0 = x.floorToDouble();
      _y0 = y.floorToDouble();
      _x1 = _x0 + 1;
      _y1 = _y0 + 1;
      return;
    }
    if (x >= _x0 && x < _x1 && y >= _y0 && y < _y1) return;

    double z = _x1 - _x0;
    QuadNode<T>? node = _root;
    QuadNode<T>? parent;
    int i;

    while (x < _x0 || x >= _x1 || y < _y0 || y >= _y1) {
      i = (y < _y0 ? 1 : 0) << 1 | (x < _x0 ? 1 : 0);
      parent = QuadNode<T>.internal();
      int childIndex;
      switch (i) {
        case 0:
          z *= 2;
          _x1 = _x0 + z;
          _y1 = _y0 + z;
          childIndex = 0;
          break;
        case 1:
          z *= 2;
          _x0 = _x1 - z;
          _y1 = _y0 + z;
          childIndex = 1;
          break;
        case 2:
          z *= 2;
          _x1 = _x0 + z;
          _y0 = _y1 - z;
          childIndex = 2;
          break;
        case 3:
          z *= 2;
          _x0 = _x1 - z;
          _y0 = _y1 - z;
          childIndex = 3;
          break;
        default:
          throw Error();
      }
      if (node != null) parent.children[childIndex] = node;
      node = parent;
    }
    _root = node;
  }

  void _addInner(double x, double y, T data) {
    if (x.isNaN || y.isNaN) return;
    QuadNode<T> leaf = QuadNode<T>.leaf(data, x, y);
    if (_root == null) {
      _root = leaf;
      return;
    }
    double x0 = _x0, y0 = _y0, x1 = _x1, y1 = _y1;
    QuadNode<T>? parent;
    QuadNode<T>? node = _root;
    int i = 0;

    while (node!.isInternal) {
      double xm = (x0 + x1) / 2;
      double ym = (y0 + y1) / 2;
      int right = x >= xm ? 1 : 0;
      int bottom = y >= ym ? 1 : 0;
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
      if (node.children[i] == null) {
        node.children[i] = leaf;
        return;
      }
      node = node.children[i];
    }

    double xp = node.x;
    double yp = node.y;

    if (x == xp && y == yp) {
      leaf.next = node;
      if (parent != null) {
        parent.children[i] = leaf;
      } else {
        _root = leaf;
      }
      return;
    }

    do {
      if (parent != null) {
        var newInternal = QuadNode<T>.internal();
        parent.children[i] = newInternal;
        parent = newInternal;
      } else {
        _root = QuadNode<T>.internal();
        parent = _root;
      }
      double xm = (x0 + x1) / 2;
      double ym = (y0 + y1) / 2;
      int right = x >= xm ? 1 : 0;
      int bottom = y >= ym ? 1 : 0;
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
      int j = (yp >= ym ? 1 : 0) << 1 | (xp >= xm ? 1 : 0);
      if (i != j) {
        parent!.children[j] = node;
        parent.children[i] = leaf;
        return;
      }
    } while (true);
  }

  T? find(double x, double y, [double radius = double.infinity]) {
    if (_root == null) return null;

    T? data;
    double minDistanceSq = radius * radius;

    //stackCoords=> 存放 x0, y0, x1, y1 (4个一组)
    final List<QuadNode<T>> stackNodes = [_root!];
    final List<double> stackCoords = [_x0, _y0, _x1, _y1];

    QuadNode<T> node;
    double x0, y0, x1, y1;

    while (stackNodes.isNotEmpty) {
      node = stackNodes.removeLast();
      y1 = stackCoords.removeLast();
      x1 = stackCoords.removeLast();
      y0 = stackCoords.removeLast();
      x0 = stackCoords.removeLast();

      double dx = 0, dy = 0;
      if (x < x0) {
        dx = x0 - x;
      } else if (x > x1) {
        dx = x - x1;
      }
      if (y < y0) {
        dy = y0 - y;
      } else if (y > y1) {
        dy = y - y1;
      }

      if (dx * dx + dy * dy > minDistanceSq) continue;

      if (!node.isInternal) {
        QuadNode<T>? leaf = node;
        while (leaf != null) {
          double dSq = (leaf.x - x) * (leaf.x - x) + (leaf.y - y) * (leaf.y - y);
          if (dSq < minDistanceSq) {
            minDistanceSq = dSq;
            data = leaf.data;
          }
          leaf = leaf.next;
        }
      } else {
        double xm = (x0 + x1) / 2;
        double ym = (y0 + y1) / 2;
        int right = x >= xm ? 1 : 0;
        int bottom = y >= ym ? 1 : 0;
        int targetIndex = bottom << 1 | right;
        for (int j = 0; j < 4; j++) {
          if (j != targetIndex) {
            final child = node.children[j];
            if (child != null) {
              stackNodes.add(child);
              _pushCoords(stackCoords, j, x0, y0, xm, ym, x1, y1);
            }
          }
        }
        final child = node.children[targetIndex];
        if (child != null) {
          stackNodes.add(child);
          _pushCoords(stackCoords, targetIndex, x0, y0, xm, ym, x1, y1);
        }
      }
    }
    return data;
  }

  void _pushCoords(List<double> stack, int i, double x0, double y0, double xm, double ym, double x1, double y1) {
    if (i == 0) {
      stack.add(x0);
      stack.add(y0);
      stack.add(xm);
      stack.add(ym);
    } else if (i == 1) {
      // NE
      stack.add(xm);
      stack.add(y0);
      stack.add(x1);
      stack.add(ym);
    } else if (i == 2) {
      // SW
      stack.add(x0);
      stack.add(ym);
      stack.add(xm);
      stack.add(y1);
    } else {
      // SE
      stack.add(xm);
      stack.add(ym);
      stack.add(x1);
      stack.add(y1);
    }
  }

  void visit(VisitCallback<T> callback) {
    if (_root == null) return;

    final List<QuadNode<T>> stackNodes = [_root!];
    final List<double> stackCoords = [_x0, _y0, _x1, _y1];

    QuadNode<T> node;
    double x0, y0, x1, y1;

    while (stackNodes.isNotEmpty) {
      node = stackNodes.removeLast();
      y1 = stackCoords.removeLast();
      x1 = stackCoords.removeLast();
      y0 = stackCoords.removeLast();
      x0 = stackCoords.removeLast();

      if (callback(node, x0, y0, x1, y1)) continue;

      if (node.isInternal) {
        double xm = (x0 + x1) / 2;
        double ym = (y0 + y1) / 2;
        if (node.children[3] != null) {
          stackNodes.add(node.children[3]!);
          stackCoords.add(xm);
          stackCoords.add(ym);
          stackCoords.add(x1);
          stackCoords.add(y1);
        }
        if (node.children[2] != null) {
          stackNodes.add(node.children[2]!);
          stackCoords.add(x0);
          stackCoords.add(ym);
          stackCoords.add(xm);
          stackCoords.add(y1);
        }
        if (node.children[1] != null) {
          stackNodes.add(node.children[1]!);
          stackCoords.add(xm);
          stackCoords.add(y0);
          stackCoords.add(x1);
          stackCoords.add(ym);
        }
        if (node.children[0] != null) {
          stackNodes.add(node.children[0]!);
          stackCoords.add(x0);
          stackCoords.add(y0);
          stackCoords.add(xm);
          stackCoords.add(ym);
        }
      }
    }
  }

  List<T> search(Rect rect) {
    List<T> results = [];
    double rL = rect.left, rT = rect.top, rR = rect.right, rB = rect.bottom;

    visit((node, x0, y0, x1, y1) {
      if (x0 >= rR || x1 < rL || y0 >= rB || y1 < rT) return true;

      if (!node.isInternal) {
        QuadNode<T>? leaf = node;
        while (leaf != null) {
          if (leaf.x >= rL && leaf.x < rR && leaf.y >= rT && leaf.y < rB) {
            results.add(leaf.data!);
          }
          leaf = leaf.next;
        }
      }
      return false;
    });
    return results;
  }

  void remove(T d) {
    if (_root == null) return;
    final x = xFun(d);
    final y = yFun(d);
    if (x.isNaN || y.isNaN) return;
    _removeInner(_root, null, 0, x, y, d, _x0, _y0, _x1, _y1);
  }

  bool _removeInner(QuadNode<T>? node, QuadNode<T>? parent, int parentIndex, double x, double y, T d, double x0,
      double y0, double x1, double y1) {
    if (node == null) return false;
    if (node.isInternal) {
      double xm = (x0 + x1) / 2, ym = (y0 + y1) / 2;
      int right = x >= xm ? 1 : 0, bottom = y >= ym ? 1 : 0;
      int i = bottom << 1 | right;
      bool removed = _removeInner(node.children[i], node, i, x, y, d, right == 1 ? xm : x0, bottom == 1 ? ym : y0,
          right == 1 ? x1 : xm, bottom == 1 ? y1 : ym);
      if (removed) {
        int childCount = 0;
        QuadNode<T>? onlyChild;
        for (var c in node.children) {
          if (c != null) {
            childCount++;
            onlyChild = c;
          }
        }
        if (childCount == 0 && parent != null) {
          parent.children[parentIndex] = null;
        } else if (childCount == 1 && onlyChild != null && !onlyChild.isInternal) {
          if (parent != null) {
            parent.children[parentIndex] = onlyChild;
          } else {
            _root = onlyChild;
          }
        }
      }

      return removed;
    }

    QuadNode<T>? current = node, prev;
    while (current != null) {
      if (current.data == d) {
        if (prev != null) {
          prev.next = current.next;
          return true;
        }

        if (current.next != null) {
          if (parent != null) {
            parent.children[parentIndex] = current.next;
          } else {
            _root = current.next;
          }
          return true;
        }

        if (parent != null) {
          parent.children[parentIndex] = null;
        } else {
          _root = null;
        }
        return true;
      }

      prev = current;
      current = current.next;
    }
    return false;
  }
}

class QuadNode<T> with ValueExtraMixin {
  final T? data;
  late final List<QuadNode<T>?> children;
  QuadNode<T>? next;

  double x = 0;
  double y = 0;

  QuadNode.internal() : data = null {
    children = List.filled(4, null);
  }

  QuadNode.leaf(this.data, this.x, this.y);

  bool get isInternal => data == null;
}
