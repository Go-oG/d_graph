import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../types.dart';

///四叉树
class QuadTree<T> {
  //用于返回指定数据的X坐标和Y坐标
  final Fun2<T, double> xFun;
  final Fun2<T, double> yFun;
  QuadNode2<T>? _root;

  ///表示区域范围
  late double _left;
  late double _top;
  late double _right;
  late double _bottom;

  QuadTree(this.xFun, this.yFun, this._left, this._top, this._right, this._bottom) {
    _root = null;
  }

  QuadTree.fromRect(this.xFun, this.yFun, Rect rect) {
    _root = null;
    _left = rect.left;
    _top = rect.top;
    _right = rect.right;
    _bottom = rect.bottom;
  }

  static QuadTree<T> simple<T>(Fun2<T, double> xFun, Fun2<T, double> yFun, List<T> nodes) {
    QuadTree<T> tree = QuadTree(xFun, yFun, double.nan, double.nan, double.nan, double.nan);
    if (nodes.isNotEmpty) {
      tree.addAll(nodes);
    }
    return tree;
  }

  QuadNode2<T> leafCopy(QuadNode2<T> leaf) {
    QuadNode2<T> copy = QuadNode2.leaf(leaf.data);
    QuadNode2<T>? next = copy;

    QuadNode2<T>? leftTmp = leaf;
    while ((leftTmp = leftTmp?.next) != null) {
      next!.next = QuadNode2.leaf(leftTmp!.data);
      next = next.next;
    }
    return copy;
  }

  QuadTree add(T data) {
    final x = xFun.call(data);
    final y = yFun.call(data);
    return _addInner(cover(x, y), x, y, data);
  }

  QuadTree<T> addAll(List<T> data) {
    int n = data.length;
    Float64List xz = Float64List(n);
    Float64List yz = Float64List(n);
    double x0 = double.infinity;
    double y0 = x0;
    double x1 = -x0;
    double y1 = x1;

    T d;
    double x, y;
    for (int i = 0; i < n; ++i) {
      d = data[i];
      x = xFun.call(d);
      y = yFun.call(d);
      if (x.isNaN || y.isNaN) {
        continue;
      }
      xz[i] = x;
      yz[i] = y;
      if (x < x0) x0 = x;
      if (x > x1) x1 = x;
      if (y < y0) y0 = y;
      if (y > y1) y1 = y;
    }

    // 如果没有（有效）点，则中止
    if (x0 > x1 || y0 > y1) {
      return this;
    }

    // 拓展树范围以覆盖新点
    cover(x0, y0).cover(x1, y1);

    // 添加新的点.
    for (int i = 0; i < n; ++i) {
      _addInner(this, xz[i], yz[i], data[i]);
    }
    return this;
  }

  QuadTree<T> _addInner(QuadTree<T> tree, double x, double y, T data) {
    if (x.isNaN || y.isNaN) {
      return tree;
    }

    QuadNode2<T> leaf = QuadNode2<T>.leaf(data);
    if (tree._root == null) {
      tree._root = leaf;
      return tree;
    }

    double x0 = tree._left, y0 = tree._top, x1 = tree._right, y1 = tree._bottom;

    QuadNode2<T>? parent;
    QuadNode2<T>? node = tree._root!;
    double xm, ym;
    double xp;
    double yp;
    int right;
    int bottom;
    int i = 0;
    int j = 0;

    // Find the existing leaf for the new point, or add it.
    while (node!.hasChild) {
      if ((right = _toInt(x >= (xm = ((x0 + x1) / 2)))) != 0) {
        x0 = xm;
      } else {
        x1 = xm;
      }
      if ((bottom = _toInt(y >= (ym = ((y0 + y1) / 2)))) != 0) {
        y0 = ym;
      } else {
        y1 = ym;
      }
      parent = node;

      if ((node = node[i = bottom << 1 | right]) == null) {
        parent[i] = leaf;
        return tree;
      }
    }

    // 新的点和存在的点完全重合
    xp = xFun.call(node.data as T);
    yp = yFun.call(node.data as T);

    if (x == xp && y == yp) {
      leaf.next = node;
      if (parent != null) {
        parent[i] = leaf;
      } else {
        tree._root = leaf;
      }
      return tree;
    }

    //否则，拆分叶节点，直到新旧点分离
    do {
      if (parent != null) {
        parent = parent[i] = QuadNode2.of();
      } else {
        parent = tree._root = QuadNode2.of();
      }
      if ((right = _toInt(x >= (xm = ((x0 + x1) / 2)))) != 0) {
        x0 = xm;
      } else {
        x1 = xm;
      }
      if ((bottom = _toInt(y >= (ym = ((y0 + y1) / 2)))) != 0) {
        y0 = ym;
      } else {
        y1 = ym;
      }
    } while ((i = bottom << 1 | right) == (j = (_toInt(yp >= ym) << 1 | _toInt(xp >= xm))));

    parent[j] = node;
    parent[i] = leaf;
    return tree;
  }

  /// 拓展四叉树范围到指定矩形范围 并返回四叉树。
  QuadTree<T> extent(Rect rect) {
    cover(rect.left, rect.top).cover(rect.right, rect.bottom);
    return this;
  }

  ///展开四叉树以覆盖指定的点位置
  QuadTree<T> cover(double x, double y) {
    if (x.isNaN || y.isNaN) {
      return this;
    }
    num x0 = _left, y0 = _top, x1 = _right, y1 = _bottom;
    if (x0.isNaN) {
      x1 = (x0 = x.floor()) + 1;
      y1 = (y0 = y.floor()) + 1;
    } else {
      // 否则，重复覆盖
      num z = (x1 - x0) == 0 ? 1 : (x1 - x0);
      QuadNode2<T>? node = _root;
      QuadNode2<T>? parent;
      int i;
      while (x0 > x || x >= x1 || y0 > y || y >= y1) {
        i = _toInt(y < y0) << 1 | _toInt(x < x0);
        parent = QuadNode2.of();
        parent[i] = node;
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
      if (_root != null && _root!.hasChild) {
        _root = node;
      }
    }

    _left = x0.toDouble();
    _top = y0.toDouble();
    _right = x1.toDouble();
    _bottom = y1.toDouble();
    return this;
  }

  QuadTree<T> remove(T d) {
    final pointX = xFun.call(d), pointY = yFun.call(d);
    if (pointX.isNaN || pointX.isNaN) {
      return this;
    }

    QuadNode2<T>? parent;
    QuadNode2<T>? node = _root;
    QuadNode2<T>? retainer;
    QuadNode2<T>? previous;
    QuadNode2<T>? next;
    num x0 = _left;
    num y0 = _top;
    num x1 = _right;
    num y1 = _bottom;
    int xm = 0, ym = 0;
    int right = 0, bottom = 0;
    int i = 0;
    int j = 0;
    // 如果树为空则将叶子节点初始化为根节点
    if (node == null) {
      return this;
    }
    //查找该点的叶节点。
    //当下降时，还保留最深的父级和未删除的同级
    if (node.hasChild) {
      while (true) {
        int a = xm = ((x0 + x1) / 2).round();
        int b = ym = ((y0 + y1) / 2).round();
        if ((right = _toInt(pointX >= a)) != 0) {
          x0 = xm;
        } else {
          x1 = xm;
        }
        if ((bottom = _toInt(pointY >= b)) != 0) {
          y0 = ym;
        } else {
          y1 = ym;
        }
        parent = node;
        if ((node = node![i = bottom << 1 | right]) == null) {
          return this;
        }
        if (!node!.hasChild) {
          break;
        }
        if ((parent![(i + 1) & 3]) != null || (parent[(i + 2) & 3]) != null || (parent[(i + 3) & 3]) != null) {
          retainer = parent;
          j = i;
        }
      }
    }

    // Find the point to remove.
    while (node!.data != d) {
      previous = node;
      node = node.next;
      if (node == null) {
        return this;
      }
    }

    if ((next = node.next) != null) {
      node.next = null;
    }

    // If there are multiple coincident points, remove just the point.
    if (previous != null) {
      previous.next = next;
      return this;
    }

    // If this is the root point, remove it.
    if (parent == null) {
      _root = next;
      return this;
    }
    // Remove this leaf.
    parent[i] = next;

    // If the parent now contains exactly one leaf, collapse superfluous parents.
    QuadNode2<T>? tmpNode = parent[0];
    tmpNode ??= parent[1];
    tmpNode ??= parent[2];
    tmpNode ??= parent[3];

    QuadNode2<T>? tmpNode2 = parent[3];
    tmpNode2 ??= parent[2];
    tmpNode2 ??= parent[1];
    tmpNode2 ??= parent[0];

    if ((node = tmpNode) != null && node == tmpNode2 && !node!.hasChild) {
      if (retainer != null) {
        retainer[j] = node;
      } else {
        _root = node;
      }
    }
    return this;
  }

  QuadTree<T> removeAll(List<T> data) {
    for (var i = 0, n = data.length; i < n; ++i) {
      remove(data[i]);
    }
    return this;
  }

  QuadTree<T> each(VisitCallback<T> callback) {
    List<_InnerQuad<T>> quads = [];
    QuadNode2<T>? node = _root;
    QuadNode2<T>? child;
    num x0;
    num y0;
    num x1;
    num y1;
    if (node != null) {
      quads.add(_InnerQuad(node, _left, _top, _right, _bottom));
    }
    while (quads.isNotEmpty) {
      _InnerQuad<T> q = quads.removeLast();
      node = q.node;
      if (!callback.call(node, x0 = q.left, y0 = q.top, x1 = q.right, y1 = q.bottom) && node.hasChild) {
        int xm = ((x0 + x1) / 2).round(), ym = ((y0 + y1) / 2).round();
        if ((child = node[3]) != null) quads.add(_InnerQuad(child!, xm, ym, x1, y1));
        if ((child = node[2]) != null) quads.add(_InnerQuad(child!, x0, ym, xm, y1));
        if ((child = node[1]) != null) quads.add(_InnerQuad(child!, xm, y0, x1, ym));
        if ((child = node[0]) != null) quads.add(_InnerQuad(child!, x0, y0, xm, ym));
      }
    }
    return this;
  }

  QuadTree<T> eachAfter(VisitCallback<T> callback) {
    List<_InnerQuad<T>> quads = [];
    List<_InnerQuad<T>> next = [];
    _InnerQuad<T> q;
    if (_root != null) {
      quads.add(_InnerQuad(_root!, _left, _top, _right, _bottom));
    }

    while (quads.isNotEmpty) {
      q = quads.removeLast();
      QuadNode2<T>? node = q.node;
      if (node.hasChild) {
        num x0 = q.left, y0 = q.top, x1 = q.right, y1 = q.bottom;
        num xm = ((x0 + x1) / 2);
        num ym = ((y0 + y1) / 2);
        QuadNode2<T>? child;
        if ((child = node[0]) != null) quads.add(_InnerQuad(child!, x0, y0, xm, ym));
        if ((child = node[1]) != null) quads.add(_InnerQuad(child!, xm, y0, x1, ym));
        if ((child = node[2]) != null) quads.add(_InnerQuad(child!, x0, ym, xm, y1));
        if ((child = node[3]) != null) quads.add(_InnerQuad(child!, xm, ym, x1, y1));
      }
      next.add(q);
    }

    while (next.isNotEmpty) {
      q = next.removeLast();
      callback(q.node, q.left, q.top, q.right, q.bottom);
    }
    return this;
  }

  ///返回离给定搜索半径的位置⟨x,y⟩最近的点。
  ///如果没有指定半径，默认为无穷大。
  ///如果在搜索范围内没有基准点，则返回未定义
  T? find(double x, double y, [double? r]) {
    T? data;
    double x0 = _left;
    double y0 = _top;
    double x1 = 0, y1 = 0, x2 = 0, y2 = 0;
    double x3 = _right;
    double y3 = _bottom;
    List<_InnerQuad> quads = [];

    QuadNode2? node = _root;
    int i = 0;
    if (node != null) {
      quads.add(_InnerQuad(node, x0, y0, x3, y3));
    }

    double radius;
    if (r == null) {
      radius = double.infinity;
    } else {
      x0 = (x - r);
      y0 = (y - r);
      x3 = (x + r);
      y3 = (y + r);
      radius = r * r;
    }

    while (quads.isNotEmpty) {
      _InnerQuad q = quads.removeLast();
      // 如果此象限不能包含更近的节点，请停止搜索
      node = q.node;
      if ((x1 = q.left) > x3 || (y1 = q.top) > y3 || (x2 = q.right) < x0 || (y2 = q.bottom) < y0) {
        continue;
      }
      //将当前象限一分为二.
      if (node.hasChild) {
        int xm = ((x1 + x2) / 2).round(), ym = ((y1 + y2) / 2).round();
        if (node[3] != null) {
          quads.add(_InnerQuad(node[3]!, xm.toDouble(), ym.toDouble(), x2, y2));
        }
        if (node[2] != null) {
          quads.add(_InnerQuad(node[2]!, x1, ym.toDouble(), xm.toDouble(), y2));
        }
        if (node[1] != null) {
          quads.add(_InnerQuad(node[1]!, xm.toDouble(), y1, x2, ym.toDouble()));
        }
        if (node[0] != null) {
          quads.add(_InnerQuad(node[0]!, x1, y1, xm, ym));
        }

        //首先访问最近的象限
        if ((i = _toInt(y >= ym) << 1 | _toInt(x >= xm)) != 0) {
          q = quads[quads.length - 1];
          quads[quads.length - 1] = quads[quads.length - 1 - i];
          quads[quads.length - 1 - i] = q;
        }
      } else {
        // 访问此点（不需要访问重合点！）
        var dx = x - xFun(node.data), dy = y - yFun(node.data);
        double d2 = (dx * dx + dy * dy);
        if (d2 < radius) {
          radius = d2;
          var d = sqrt(radius);
          x0 = x - d;
          y0 = y - d;
          x3 = x + d;
          y3 = y + d;
          data = node.data!;
        }
      }
    }
    return data;
  }

  ///搜索矩形范围内的所有节点数据
  List<T> search(Rect rect) {
    List<T> results = [];
    var xmin = rect.left;
    var ymin = rect.top;
    var xmax = rect.right;
    var ymax = rect.bottom;
    each((node, x1, y1, x2, y2) {
      if (!node.hasChild) {
        QuadNode2<T>? tmpNode = node;
        do {
          var d = node.data;
          if (d != null) {
            var dx = xFun.call(d);
            var dy = yFun.call(d);
            if (dx >= xmin && dx < xmax && dy >= ymin && dy < ymax) {
              results.add(d);
            }
          }
        } while ((tmpNode = tmpNode?.next) != null);
      }
      return x1 >= xmax || y1 >= ymax || x2 < xmin || y2 < ymin;
    });
    return results;
  }

  ///搜索圆形范围内的所有节点数据
  List<T> searchInCircle(Offset center, double radius) {
    List<T> results = search(Rect.fromCircle(center: center, radius: radius.toDouble()));
    num dis2 = radius * radius;
    results.removeWhere((e) {
      var dx = center.dx - xFun.call(e);
      var dy = center.dy - yFun.call(e);
      var dis = dx * dx + dy * dy;
      return dis > dis2;
    });
    return results;
  }

  QuadTree<T> copy() {
    QuadTree<T> copy = QuadTree(xFun, yFun, _left, _top, _right, _bottom);
    QuadNode2<T>? node = _root;

    List<Map<String, dynamic>> nodes = [];
    QuadNode2<T>? child;

    if (node == null) {
      return copy;
    }

    if (!node.hasChild) {
      copy._root = leafCopy(node);
      return copy;
    }

    copy._root = QuadNode2.of();
    nodes = [
      {'source': node, 'target': copy._root},
    ];

    Map<String, dynamic> nodeTmp;
    while (nodes.isNotEmpty) {
      nodeTmp = nodes.removeLast();
      for (int i = 0; i < 4; ++i) {
        child = nodeTmp['source'][i];
        if (child == null) {
          continue;
        }
        if (child.hasChild) {
          var tmp = {'source': child, 'target': nodeTmp['target'][i] = QuadNode2.of()};
          nodes.add(tmp);
        } else {
          nodeTmp['target'][i] = leafCopy(child);
        }
      }
    }

    return copy;
  }

  QuadNode2? get root => _root;

  int get size {
    int sizeTmp = 0;
    each((node, p1, p2, p3, p4) {
      QuadNode2? nodeTmp = node;
      if (nodeTmp.hasChild) {
        do {
          ++sizeTmp;
        } while ((nodeTmp = nodeTmp!.next) != null);
      }
      return true;
    });
    return sizeTmp;
  }

  List<T> get data {
    List<T> list = [];
    each((node, x0, y0, x1, y1) {
      QuadNode2? nodeTmp = node;
      if (!nodeTmp.hasChild) {
        do {
          list.add(nodeTmp!.data!);
        } while ((nodeTmp = nodeTmp.next) != null);
      }
      return true;
    });
    return list;
  }

  Rect get boundRect => Rect.fromLTRB(_left.toDouble(), _top.toDouble(), _right.toDouble(), _bottom.toDouble());

  @override
  String toString() {
    return 'left:$_left top:$_top right:$_right bottom:$_bottom';
  }
}

class _InnerQuad<T> {
  final QuadNode2<T> node;
  late final double left;
  late final double top;
  late final double right;
  late final double bottom;

  _InnerQuad(this.node, num left, num top, num right, num bottom) {
    this.left = left.toDouble();
    this.top = top.toDouble();
    this.right = right.toDouble();
    this.bottom = bottom.toDouble();
  }
}

class QuadNode2<T> {
  ///作为left节点时使用的属性
  late final T? data;

  ///当该对象类型为父节点时 则存在下列属性
  final Map<int, QuadNode2<T>> _childMap = {};

  //下一个节点(存在相同的点)
  QuadNode2<T>? next;

  QuadNode2.leaf(this.data) {
    _childMap.clear();
  }

  QuadNode2.of() {
    data = null;
  }

  void operator []=(int index, QuadNode2<T>? node) {
    if (index < 0 || index >= 4) {
      throw '违法参数：只能传入0-3';
    }
    if (node != null) {
      _childMap[index] = node;
    }
  }

  void delete(int index) {
    _childMap.remove(index);
  }

  QuadNode2<T>? operator [](int index) {
    if (index < 0 || index >= 4) {
      throw '违法参数：只能传入0-3';
    }
    return _childMap[index];
  }

  int get childCount => data == null ? _childMap.length : 0;

  bool get hasChild => data == null ? _childMap.isNotEmpty : false;

  List<T> get dataList {
    List<T> list = [];
    var d = data;
    if (d != null) {
      list.add(d);
    }
    var p = next;
    while (p != null) {
      d = p.data;
      if (d != null) {
        list.add(d);
      }
      p = p.next;
    }
    return list;
  }
}

int _toInt(bool a) {
  return a ? 1 : 0;
}

typedef VisitCallback<T> = bool Function(QuadNode2<T> node, double left, double top, double right, double bottom);
