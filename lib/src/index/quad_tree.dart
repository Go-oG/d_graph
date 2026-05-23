import 'dart:typed_data';
import 'dart:ui';

import '../util/extra_mixin.dart';
import 'common.dart';

typedef Accessor<T> = double Function(T data);

typedef QuadTreeVisitor<T> = VisitResult Function(QuadNode<T> node, double x0, double y0, double x1, double y1);

class QuadTree<T> {
  final Accessor<T> xFun;
  final Accessor<T> yFun;
  QuadNode<T>? _root;
  int _size = 0;

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

  void remove(T d) {
    if (_root == null) return;
    final x = xFun(d);
    final y = yFun(d);
    if (x.isNaN || y.isNaN) return;
    if (_removeInner(_root, null, 0, x, y, d, _x0, _y0, _x1, _y1)) {
      _size--;
    }
  }

  bool _removeInner(
    QuadNode<T>? node,
    QuadNode<T>? parent,
    int? parentIndex,
    double x,
    double y,
    T d,
    double x0,
    double y0,
    double x1,
    double y1,
  ) {
    if (node == null) return false;
    if (node.isInternal) {
      double xm = (x0 + x1) / 2, ym = (y0 + y1) / 2;
      int right = x >= xm ? 1 : 0, bottom = y >= ym ? 1 : 0;
      int i = bottom << 1 | right;
      bool removed = _removeInner(
        node.children[i],
        node,
        i,
        x,
        y,
        d,
        right == 1 ? xm : x0,
        bottom == 1 ? ym : y0,
        right == 1 ? x1 : xm,
        bottom == 1 ? y1 : ym,
      );
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
          parent.children[parentIndex!] = null;
        } else if (childCount == 1 && onlyChild != null && !onlyChild.isInternal) {
          if (parent != null) {
            parent.children[parentIndex!] = onlyChild;
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
            parent.children[parentIndex!] = current.next;
          } else {
            _root = current.next;
          }
          return true;
        }

        if (parent != null) {
          parent.children[parentIndex!] = null;
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

  void clear() {
    _root = null;
    _size = 0;
    _x0 = _y0 = _x1 = _y1 = double.nan;
  }

  void add(T data) {
    final x = xFun(data);
    final y = yFun(data);
    if (x.isNaN || y.isNaN) return;
    _cover(x, y);
    _addInner(x, y, data);
    _size++;
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
      if (xs[i].isNaN || ys[i].isNaN) continue;
      _addInner(xs[i], ys[i], data[i]);
      _size++;
    }
  }

  void _addInner(double x, double y, T data) {
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

  void _pushCords(List<double> stack, int i, double x0, double y0, double xm, double ym, double x1, double y1) {
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

  void visit(QuadTreeVisitor<T> visitor) {
    if (_root == null) return;
    final List<_StackFrame<T>> stack = [_StackFrame(_root!, _x0, _y0, _x1, _y1)];
    while (stack.isNotEmpty) {
      final frame = stack.removeLast();
      final node = frame.node;
      final res = visitor(node, frame.x0, frame.y0, frame.x1, frame.y1);
      if (res == VisitResult.stop) {
        return;
      }
      if (res == VisitResult.skipChildren) {
        continue;
      }

      if (node.isInternal) {
        double xm = (frame.x0 + frame.x1) / 2;
        double ym = (frame.y0 + frame.y1) / 2;
        if (node.children[3] != null) {
          stack.add(_StackFrame(node.children[3]!, xm, ym, frame.x1, frame.y1));
        }
        if (node.children[2] != null) {
          stack.add(_StackFrame(node.children[2]!, frame.x0, ym, xm, frame.y1));
        }
        if (node.children[1] != null) {
          stack.add(_StackFrame(node.children[1]!, xm, frame.y0, frame.x1, ym));
        }
        if (node.children[0] != null) {
          stack.add(_StackFrame(node.children[0]!, frame.x0, frame.y0, xm, ym));
        }
      }
    }
  }

  void visitInOrder(QuadTreeVisitor<T> visitor) {
    if (_root == null) return;

    final List<_StackFrame<T>> stack = [_StackFrame(_root!, _x0, _y0, _x1, _y1)];

    while (stack.isNotEmpty) {
      final frame = stack.removeLast();
      final node = frame.node;
      if (frame.stage == 0) {
        frame.stage = 1;
        stack.add(frame);
        if (node.isInternal) {
          double xm = (frame.x0 + frame.x1) / 2;
          double ym = (frame.y0 + frame.y1) / 2;
          if (node.children[1] != null) {
            stack.add(_StackFrame(node.children[1]!, xm, frame.y0, frame.x1, ym));
          }
          if (node.children[0] != null) {
            stack.add(_StackFrame(node.children[0]!, frame.x0, frame.y0, xm, ym));
          }
        }
      } else if (frame.stage == 1) {
        frame.stage = 2;
        final res = visitor(node, frame.x0, frame.y0, frame.x1, frame.y1);
        if (res == VisitResult.stop) {
          return;
        }
        if (res == VisitResult.skipChildren) {
          continue;
        }
        stack.add(frame);
      } else {
        if (node.isInternal) {
          double xm = (frame.x0 + frame.x1) / 2;
          double ym = (frame.y0 + frame.y1) / 2;

          if (node.children[3] != null) {
            stack.add(_StackFrame(node.children[3]!, xm, ym, frame.x1, frame.y1));
          }
          if (node.children[2] != null) {
            stack.add(_StackFrame(node.children[2]!, frame.x0, ym, xm, frame.y1));
          }
        }
      }
    }
  }

  void visitAfter(QuadTreeVisitor<T> visitor) {
    if (_root == null) return;

    final List<_StackFrame<T>> stack = [_StackFrame(_root!, _x0, _y0, _x1, _y1)];

    while (stack.isNotEmpty) {
      final frame = stack.removeLast();
      final node = frame.node;

      if (frame.visited) {
        final result = visitor(node, frame.x0, frame.y0, frame.x1, frame.y1);
        if (result == VisitResult.stop) return;
        continue;
      }

      stack.add(_StackFrame.of(node, frame.x0, frame.y0, frame.x1, frame.y1, true));

      if (node.isInternal) {
        final result = visitor(node, frame.x0, frame.y0, frame.x1, frame.y1);

        if (result == VisitResult.stop) return;
        if (result == VisitResult.skipChildren) continue;

        double xm = (frame.x0 + frame.x1) / 2;
        double ym = (frame.y0 + frame.y1) / 2;
        final children = node.children;
        if (children[3] != null) {
          stack.add(_StackFrame(children[3]!, xm, ym, frame.x1, frame.y1));
        }
        if (children[2] != null) {
          stack.add(_StackFrame(children[2]!, frame.x0, ym, xm, frame.y1));
        }
        if (children[1] != null) {
          stack.add(_StackFrame(children[1]!, xm, frame.y0, frame.x1, ym));
        }
        if (children[0] != null) {
          stack.add(_StackFrame(children[0]!, frame.x0, frame.y0, xm, ym));
        }
      }
    }
  }

  void visitBFS(QuadTreeVisitor<T> visitor) {
    if (_root == null) return;
    final List<_StackFrame<T>> queue = [_StackFrame(_root!, _x0, _y0, _x1, _y1)];
    int head = 0;
    while (head < queue.length) {
      final frame = queue[head++];
      final node = frame.node;
      final res = visitor(node, frame.x0, frame.y0, frame.x1, frame.y1);
      if (res == VisitResult.stop) {
        return;
      }
      if (res == VisitResult.skipChildren) {
        continue;
      }
      if (node.isInternal) {
        double xm = (frame.x0 + frame.x1) / 2;
        double ym = (frame.y0 + frame.y1) / 2;
        if (node.children[0] != null) {
          queue.add(_StackFrame(node.children[0]!, frame.x0, frame.y0, xm, ym));
        }
        if (node.children[1] != null) {
          queue.add(_StackFrame(node.children[1]!, xm, frame.y0, frame.x1, ym));
        }
        if (node.children[2] != null) {
          queue.add(_StackFrame(node.children[2]!, frame.x0, ym, xm, frame.y1));
        }
        if (node.children[3] != null) {
          queue.add(_StackFrame(node.children[3]!, xm, ym, frame.x1, frame.y1));
        }
      }
    }
  }

  T? find(double x, double y, [double radius = double.infinity]) {
    if (_root == null) return null;

    T? data;
    double minDistanceSq = radius * radius;

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
              _pushCords(stackCoords, j, x0, y0, xm, ym, x1, y1);
            }
          }
        }
        final child = node.children[targetIndex];
        if (child != null) {
          stackNodes.add(child);
          _pushCords(stackCoords, targetIndex, x0, y0, xm, ym, x1, y1);
        }
      }
    }
    return data;
  }

  List<T> search(Rect rect) {
    List<T> results = [];
    double rL = rect.left, rT = rect.top, rR = rect.right, rB = rect.bottom;

    visit((node, x0, y0, x1, y1) {
      if (x0 >= rR || x1 < rL || y0 >= rB || y1 < rT) {
        return VisitResult.skipChildren;
      }

      if (!node.isInternal) {
        QuadNode<T>? leaf = node;
        while (leaf != null) {
          if (leaf.x >= rL && leaf.x < rR && leaf.y >= rT && leaf.y < rB) {
            results.add(leaf.data as T);
          }
          leaf = leaf.next;
        }
      }
      return VisitResult.continueVisit;
    });
    return results;
  }

  QuadTree<T> copy() {
    QuadTree<T> copy = QuadTree(xFun, yFun, _x0, _y0, _x1, _y1);
    if (_root != null) {
      copy._root = _copyNode(_root!);
      copy._size = _size;
    }
    return copy;
  }

  QuadNode<T> _copyNode(QuadNode<T> node) {
    if (node.isInternal) {
      var newNode = QuadNode<T>.internal();
      for (int i = 0; i < 4; i++) {
        if (node.children[i] != null) {
          newNode.children[i] = _copyNode(node.children[i]!);
        }
      }
      return newNode;
    } else {
      var newNode = QuadNode<T>.leaf(node.data, node.x, node.y);
      var currentOld = node.next;
      var currentNew = newNode;
      while (currentOld != null) {
        currentNew.next = QuadNode<T>.leaf(currentOld.data, currentOld.x, currentOld.y);
        currentNew = currentNew.next!;
        currentOld = currentOld.next;
      }
      return newNode;
    }
  }

  Rect? get extent {
    if (_x0.isNaN) {
      return null;
    }
    return Rect.fromLTRB(_x0, _y0, _x1, _y1);
  }

  void extend(double x0, double y0, double x1, double y1) {
    if (x0.isNaN || y0.isNaN || x1.isNaN || y1.isNaN) {
      throw ArgumentError('Extent contains NaN');
    }
    if (x1 < x0) {
      final t = x0;
      x0 = x1;
      x1 = t;
    }
    if (y1 < y0) {
      final t = y0;
      y0 = y1;
      y1 = t;
    }
    if (_root == null) {
      _x0 = x0;
      _y0 = y0;
      _x1 = x1;
      _y1 = y1;
      return;
    }
    final List<T> all = [];
    visit((node, _, __, ___, ____) {
      if (!node.isInternal) {
        QuadNode<T>? leaf = node;
        while (leaf != null) {
          all.add(leaf.data as T);
          leaf = leaf.next;
        }
      }
      return VisitResult.continueVisit;
    });
    clear();
    _x0 = x0;
    _y0 = y0;
    _x1 = x1;
    _y1 = y1;
    addAll(all);
  }

  int get size => _size;

  bool get isEmpty => _root == null;
}

class QuadNode<T> with ValueExtraMixin {
  final T? data;
  late final List<QuadNode<T>?> children;
  final bool isInternal;
  QuadNode<T>? next;

  double x = 0;
  double y = 0;
  double value = 0;

  QuadNode.internal() : data = null, isInternal = true {
    children = List.filled(4, null);
  }

  QuadNode.leaf(this.data, this.x, this.y) : isInternal = false {
    children = const [];
  }

  QuadNode<T>? operator [](int index) => children[index];
}

final class _StackFrame<T> {
  final QuadNode<T> node;
  final double x0, y0, x1, y1;
  int stage = 0;
  bool visited = false;

  _StackFrame(this.node, this.x0, this.y0, this.x1, this.y1);

  _StackFrame.of(this.node, this.x0, this.y0, this.x1, this.y1, [this.visited = false]);
}
