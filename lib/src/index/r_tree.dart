import 'dart:math' as math;
import 'dart:ui';

import '../fast_select.dart';
import '../random_id.dart';
import '../types.dart';

class RTree<T> {
  late final int maxEntries;
  late final int minEntries;
  late RNode<T> _root;
  late Fun2<T, double> minXFun;
  late Fun2<T, double> minYFun;
  late Fun2<T, double> maxXFun;
  late Fun2<T, double> maxYFun;

  RTree(this.minXFun, this.minYFun, this.maxXFun, this.maxYFun, [int maxEntries = 9]) {
    this.maxEntries = math.max(4, maxEntries);
    minEntries = math.max(2, (this.maxEntries * 0.4).ceil());
    this._root = _createNode([]);
  }

  RTree.from(Rect Function<T, Rect>(T) fun, [int maxEntries = 9]) {
    this.maxEntries = math.max(4, maxEntries);
    minEntries = math.max(2, (this.maxEntries * 0.4).ceil());
    this._root = _createNode([]);
    this.minXFun = (T t) => fun.call(t).left;
    this.minYFun = (T t) => fun.call(t).top;
    this.maxXFun = (T t) => fun.call(t).right;
    this.maxYFun = (T t) => fun.call(t).bottom;
  }

  List<T> all() {
    List<T> result = [];
    each((p) {
      if (p.value != null) {
        result.add(p.value as T);
      }
      return false;
    });
    return result;
  }

  List<T> search(Rect rect) {
    RNode<T>? node = _root;
    if (!_intersects(rect, node)) {
      return [];
    }
    List<T> result = [];
    List<RNode<T>> next = [_root];
    while (next.isNotEmpty) {
      var node = next.removeLast();
      for (var child in node.children) {
        if (!_intersects(rect, child)) {
          continue;
        }
        if (node.leaf) {
          var d = child.value;
          if (d != null) {
            result.add(d);
          }
          continue;
        }
        if (_contains2(rect, child)) {
          _eachData(child, result);
        } else {
          next.add(child);
        }
      }
    }
    return result;
  }

  List<T> search2(Rect rect) {
    if (!_intersects(rect, _root)) {
      return [];
    }
    List<T> result = [];
    List<RNode<T>> list = [_root];
    List<RNode<T>> next = [];
    while (list.isNotEmpty) {
      for (var node in list) {
        for (var child in node.children) {
          if (!_intersects(rect, child)) {
            continue;
          }
          if (node.leaf) {
            var d = child.value;
            if (d != null) {
              result.add(d);
            }
            continue;
          }
          if (_contains2(rect, child)) {
            _eachData(child, result);
          } else {
            next.add(child);
          }
        }
      }
      list = next;
      next = [];
    }
    return result;
  }

  T? searchSingle(Rect rect, bool Function(T node) testFun) {
    if (!_intersects(rect, _root)) {
      return null;
    }
    List<RNode<T>> list = [_root];
    List<RNode<T>> next = [];
    while (list.isNotEmpty) {
      for (var node in list) {
        for (var child in node.children) {
          if (!_intersects(rect, child)) {
            continue;
          }
          if (node.leaf) {
            var d = child.value;
            if (d != null && testFun.call(d)) {
              return d;
            }
            continue;
          }
          if (_contains2(rect, child)) {
            var res = _eachSingleData(child, testFun);
            if (res != null) {
              return res;
            }
          } else {
            next.add(child);
          }
        }
      }
      list = next;
      next = [];
    }
    return null;
  }

  void _eachData(RNode<T>? node, List<T> result) {
    List<RNode<T>> next = [];
    while (node != null) {
      if (node.leaf) {
        for (var c in node.children) {
          var d = c.value;
          if (d == null) {
            continue;
          }
          result.add(d);
        }
      } else {
        next.addAll(node.children);
      }
      node = next.isEmpty ? null : next.removeLast();
    }
  }

  T? _eachSingleData(RNode<T>? node, bool Function(T node) testFun) {
    List<RNode<T>> next = [];
    while (node != null) {
      if (node.leaf) {
        for (var c in node.children) {
          var d = c.value;
          if (d != null && testFun.call(d)) {
            return d;
          }
        }
      } else {
        next.addAll(node.children);
      }
      if (next.isEmpty) {
        break;
      }
      node = next.removeLast();
    }
    return null;
  }

  ///遍历节点(层序遍历)
  ///如果返回为 true 则停止遍历
  ///[minX,minY,maxX,maxY,leaf,height,value,childCount]
  RTree<T> each(EachCallback<T> test, [bool stopAll = false]) {
    List<RNode<T>> next = [_root];
    while (next.isNotEmpty) {
      var node = next.removeAt(0);
      if (test.call(node)) {
        if (stopAll) {
          break;
        }
        continue;
      }
      next.addAll(node.children);
    }
    return this;
  }

  ///先序遍历
  RTree<T> eachBefore(EachCallback<T> test, [bool stopAll = false]) {
    List<RNode<T>> nodes = [_root];
    while (nodes.isNotEmpty) {
      var node = nodes.removeLast();
      if (test.call(node)) {
        if (stopAll) {
          break;
        }
        continue;
      }
      nodes.addAll(node.children.reversed);
    }
    return this;
  }

  ///后序遍历
  RTree<T> eachAfter(EachCallback<T> test, [bool stopAll = false]) {
    List<RNode<T>> nodes = [_root];
    List<RNode<T>> next = [];
    while (nodes.isNotEmpty) {
      var node = nodes.removeLast();
      next.add(node);
      nodes.addAll(node.children);
    }

    while (next.isNotEmpty) {
      var node = next.removeLast();
      if (test.call(node)) {
        if (stopAll) {
          break;
        }
        continue;
      }
    }
    return this;
  }

  ///如果有任何数据项与给定边界框相交，则返回 true，否则 false
  bool hasCollides(Rect rect) {
    if (!_intersects(rect, _root)) return false;
    List<RNode<T>> next = [_root];
    while (next.isNotEmpty) {
      var node = next.removeAt(0);
      for (var child in node.children) {
        if (_intersects(rect, child)) {
          if (node.leaf || _contains2(rect, child)) {
            return true;
          }
          next.add(child);
        }
      }
    }
    return false;
  }

  RTree<T> addAll(Iterable<T> data) {
    if (data.isEmpty) {
      return this;
    }

    if (data.length < minEntries) {
      for (var item in data) {
        add(item);
      }
      return this;
    }

    // 使用OMT算法从头开始用给定的数据递归地构建树
    List<RNode<T>> buildList = [];
    for (var p0 in data) {
      var node = RNode(value: p0);
      node.left = minXFun.call(p0);
      node.top = minYFun.call(p0);
      node.right = maxXFun.call(p0);
      node.bottom = maxYFun.call(p0);
      buildList.add(node);
    }
    var node = _build(buildList, 0, buildList.length - 1, 0);

    if (_root.children.isEmpty) {
      _root = node;
      return this;
    }
    if (_root.height == node.height) {
      // 如果树的高度相同，则分开生根
      _splitRoot(this._root, node);
      return this;
    }

    //如果树的高度相同，则分开生根
    if (_root.height < node.height) {
      var tmpNode = _root;
      _root = node;
      node = tmpNode;
    }
    _insert(node, _root.height - node.height - 1);
    return this;
  }

  RTree<T> add(T item) {
    var node = RNode(value: item);
    node.left = minXFun.call(item);
    node.top = minYFun.call(item);
    node.right = maxXFun.call(item);
    node.bottom = maxYFun.call(item);
    _insert(node, _root.height - 1);
    return this;
  }

  RTree<T> clear() {
    _root = _createNode([]);
    return this;
  }

  RTree<T> remove(T item) {
    List<RNode> path = [];
    List<int> indexes = [];
    int i = 0;

    ///标识查找方向
    bool goingUp = false;
    RNode? parent;
    RNode? tmpNode = _root;
    // 深度优先遍历树
    while (tmpNode != null || path.isNotEmpty) {
      if (tmpNode == null) {
        tmpNode = path.removeLast();
        parent = path[path.length - 1];
        i = indexes.removeLast();
        goingUp = true;
      }
      if (tmpNode.leaf) {
        int index = _findItem2(item, tmpNode.children);
        if (index != -1) {
          //如果被找到了，则删除该项并向上压缩树
          tmpNode.children.removeRange(index, index + 1);
          path.add(tmpNode);
          _condense(path);
          return this;
        }
      }

      ///没有找到继续查找
      /// 向下查找
      if (!goingUp && !tmpNode.leaf && _contains3(tmpNode, item)) {
        path.add(tmpNode);
        indexes.add(i);
        i = 0;
        parent = tmpNode;
        tmpNode = tmpNode.children[0];
        continue;
      }

      ///向右查找
      if (parent != null) {
        i++;
        tmpNode = parent.children[i];
        goingUp = false;
        continue;
      }
      //未找到
      tmpNode = null;
    }
    return this;
  }

  int compareMinX(RNode a, RNode b) {
    return a.left.compareTo(b.left);
  }

  int compareMinY(RNode a, RNode b) {
    return a.top.compareTo(b.top);
  }

  RNode<T> _build(List<RNode<T>> items, int left, int right, int height) {
    int N = right - left + 1;
    int M = maxEntries;
    RNode<T>? node;

    if (N <= M) {
      node = _createNode(List.from(items.getRange(left, right + 1)));
      _calcBBox(node);
      return node;
    }

    if (height == 0) {
      ///树的目标高度
      height = (math.log(N) / math.log(M)).ceil();

      ///根条目以最大限度地提高存储利用率
      M = (N / math.pow(M, height - 1)).ceil();
    }

    node = _createNode([]);
    node.leaf = false;
    node.height = height;

    ///将物品分成M块，大部分为正方形
    int n2 = (N / M).ceil();
    int n1 = n2 * math.sqrt(M).ceil();
    _multiSelect(items, left, right, n1, this.compareMinX);
    for (int i = left; i <= right; i += n1) {
      int right2 = math.min(i + n1 - 1, right);
      _multiSelect(items, i, right2, n2, this.compareMinY);
      for (int j = i; j <= right2; j += n2) {
        int right3 = math.min(j + n2 - 1, right2);

        ///递归打包每个条目
        node.children.add(_build(items, j, right3, height - 1));
      }
    }
    _calcBBox(node);
    return node;
  }

  RNode _chooseSubtree(RNode bbox, RNode node, int level, List<RNode> path) {
    while (true) {
      path.add(node);
      if (node.leaf || path.length - 1 == level) break;

      num minArea = double.infinity;
      num minEnlargement = double.infinity;
      RNode? targetNode;
      for (int i = 0; i < node.children.length; i++) {
        var child = node.children[i];
        var area = _bboxArea(child);
        var enlargement = _enlargedArea(bbox, child) - area;

        // 选择放大面积最小的条目
        if (enlargement < minEnlargement) {
          minEnlargement = enlargement;
          minArea = area < minArea ? area : minArea;
          targetNode = child;
        } else if (enlargement == minEnlargement) {
          // 否则选择面积最小的
          if (area < minArea) {
            minArea = area;
            targetNode = child;
          }
        }
      }
      if (targetNode != null) {
        node = targetNode;
      } else {
        node = node.children[0];
      }
    }
    return node;
  }

  void _insert(RNode<T> item, int level) {
    var bbox = item;
    List<RNode<T>> insertPath = [];
    var node = _chooseSubtree(bbox, _root, level, insertPath);
    node.children.add(item);
    _extend(node, bbox);
    while (level >= 0) {
      if (insertPath[level].children.length > maxEntries) {
        _split(insertPath, level);
        level--;
        continue;
      }
      break;
    }
    _adjustParentBBoxes(bbox, insertPath, level);
  }

  ///将溢出节点一分为二
  void _split(List<RNode<T>> insertPath, int level) {
    var node = insertPath[level];
    int M = node.children.length;
    int m = minEntries;
    _chooseSplitAxis(node, m, M);
    int splitIndex = _chooseSplitIndex(node, m, M);

    List<RNode<T>> removeList = List.from(node.children.getRange(splitIndex, node.children.length));
    node.children.removeRange(splitIndex, node.children.length);
    var newNode = _createNode(removeList);

    newNode.height = node.height;
    newNode.leaf = node.leaf;

    _calcBBox(node);
    _calcBBox(newNode);

    if (level != 0) {
      insertPath[level - 1].children.add(newNode);
    } else {
      _splitRoot(node, newNode);
    }
  }

  ///划分根节点
  void _splitRoot(RNode<T> node, RNode<T> newNode) {
    _root = _createNode([node, newNode]);
    _root.height = node.height + 1;
    _root.leaf = false;
    _calcBBox(_root);
  }

  int _chooseSplitIndex(RNode node, int m, int M) {
    int index = 0;
    num minOverlap = double.infinity;
    num minArea = double.infinity;
    for (int i = m; i <= M - m; i++) {
      var bbox1 = _distBBox(node, 0, i);
      var bbox2 = _distBBox(node, i, M);

      var overlap = _intersectionArea(bbox1, bbox2);
      var area = _bboxArea(bbox1) + _bboxArea(bbox2);

      // 选择重叠最小的
      if (overlap < minOverlap) {
        minOverlap = overlap;
        index = i;
        minArea = area < minArea ? area : minArea;
      } else if (overlap == minOverlap && area < minArea) {
        // 否则选择面积最小的
        minArea = area;
        index = i;
      }
    }
    if (index != 0) {
      return index;
    }
    return M - m;
  }

  // 按要拆分的最佳轴对节点子级进行排序
  void _chooseSplitAxis(RNode node, int m, int M) {
    var compareMinX = node.leaf ? this.compareMinX : _compareNodeMinX;
    var compareMinY = node.leaf ? this.compareMinY : _compareNodeMinY;
    var xMargin = _allDistMargin(node, m, M, compareMinX);
    var yMargin = _allDistMargin(node, m, M, compareMinY);

    //如果x的总分布裕度值最小，则按minX排序，否则按minY排序
    if (xMargin < yMargin) node.children.sort(compareMinX);
  }

  // 所有可能的分裂分布的总裕度，其中每个节点至少满m
  double _allDistMargin(RNode node, int m, int M, compare) {
    node.children.sort(compare);

    var leftBBox = _distBBox(node, 0, m);
    var rightBBox = _distBBox(node, M - m, M);
    num margin = _bboxMargin(leftBBox) + _bboxMargin(rightBBox);

    for (int i = m; i < M - m; i++) {
      var child = node.children[i];
      _extend(leftBBox, child);
      margin += _bboxMargin(leftBBox);
    }
    for (int i = M - m - 1; i >= m; i--) {
      var child = node.children[i];
      _extend(rightBBox, child);
      margin += _bboxMargin(rightBBox);
    }
    return margin.toDouble();
  }

  ///沿着给定的树路径调整区域范围
  void _adjustParentBBoxes(RNode bbox, List<RNode> path, int level) {
    for (int i = level; i >= 0; i--) {
      _extend(path[i], bbox);
    }
  }

  /// 遍历路径，删除空节点并更新区域范围(相当于收缩树范围)
  _condense(List<RNode> path) {
    List<RNode> siblings;
    for (int i = path.length - 1; i >= 0; i--) {
      if (path[i].children.isNotEmpty) {
        _calcBBox(path[i]);
        continue;
      }

      if (i > 0) {
        siblings = path[i - 1].children;
        int index = siblings.indexOf(path[i]);
        siblings.removeRange(index, index + 1);
      } else {
        clear();
      }
    }
  }

  int _findItem2(T item, List<RNode> items) {
    return items.indexWhere((e) => item == e.value);
  }

  //=========================
  ///计算从节点的孩子节点中计算bbox
  void _calcBBox(RNode node) {
    _distBBox(node, 0, node.children.length, node);
  }

  ///计算从k到p-1节点子节点的最小边界矩形
  RNode _distBBox(RNode node, int k, int p, [RNode? destNode]) {
    destNode ??= _createNode([]);
    destNode.left = double.infinity;
    destNode.top = double.infinity;
    destNode.right = -double.infinity;
    destNode.bottom = -double.infinity;
    for (int i = k; i < p; i++) {
      var child = node.children[i];
      _extend(destNode, child);
    }
    return destNode;
  }

  RNode _extend(RNode a, RNode b) {
    a.left = math.min(a.left, b.left);
    a.top = math.min(a.top, b.top);
    a.right = math.max(a.right, b.right);
    a.bottom = math.max(a.bottom, b.bottom);
    return a;
  }

  int _compareNodeMinX(RNode a, RNode b) {
    return a.left.compareTo(b.left);
  }

  int _compareNodeMinY(RNode a, RNode b) {
    return a.top.compareTo(b.top);
  }

  double _bboxArea(RNode a) {
    return (a.right - a.left) * (a.bottom - a.top);
  }

  double _bboxMargin(RNode a) {
    return (a.right - a.left) + (a.bottom - a.top);
  }

  double _enlargedArea(RNode a, RNode b) {
    return (math.max(b.right, a.right) - math.min(b.left, a.left)) *
        (math.max(b.bottom, a.bottom) - math.min(b.top, a.top));
  }

  double _intersectionArea(RNode a, RNode b) {
    var minX = math.max(a.left, b.left);
    var minY = math.max(a.top, b.top);
    var maxX = math.min(a.right, b.right);
    var maxY = math.min(a.bottom, b.bottom);

    return math.max(0, maxX - minX) * math.max(0, maxY - minY);
  }

  ///判断 矩形a 是否包含节点 b;
  bool _contains2(Rect a, RNode b) {
    return a.left <= b.left && a.top <= b.top && b.right <= a.right && b.bottom <= a.bottom;
  }

  bool _contains3(RNode a, T b) {
    return a.left <= minXFun.call(b) &&
        a.top <= minYFun.call(b) &&
        maxXFun.call(b) <= a.right &&
        maxYFun.call(b) <= a.bottom;
  }

  bool _intersects(Rect a, RNode b) {
    return b.left <= a.right && b.top <= a.bottom && b.right >= a.left && b.bottom >= a.top;
  }

  RNode<T> _createNode(List<RNode<T>>? children) {
    return RNode(
      height: 1,
      leaf: true,
      left: double.infinity,
      top: double.infinity,
      right: double.negativeInfinity,
      bottom: double.negativeInfinity,
      children: children,
    );
  }

  void _multiSelect(List<RNode> arr, int left, int right, int n, int Function(RNode, RNode) compare) {
    List<int> stack = [left, right];
    while (stack.isNotEmpty) {
      right = stack.removeLast();
      left = stack.removeLast();
      if (right - left <= n) continue;
      int mid = left + ((right - left) / n / 2).ceil() * n;
      FastSelect.fastSelect(arr, mid, left, right, compare);
      stack.addAll([left, mid, mid, right]);
    }
  }
}

class RNode<T> {
  late final String id;
  List<RNode<T>> children = [];
  int height;
  bool leaf;

  late double left;
  late double top;
  late double right;
  late double bottom;

  T? value;

  RNode({
    this.height = 1,
    this.leaf = true,
    this.left = double.infinity,
    this.top = double.infinity,
    this.right = double.negativeInfinity,
    this.bottom = double.negativeInfinity,
    List<RNode<T>>? children,
    this.value,
    String? id,
  }) {
    if (id == null || id.isEmpty) {
      this.id = randomId();
    } else {
      this.id = id;
    }
    if (children != null) {
      this.children = children;
    }
  }

  RNode.fromRect(Rect rect, {this.height = 1, this.leaf = true, this.value, String? id}) {
    if (id == null || id.isEmpty) {
      this.id = randomId();
    } else {
      this.id = id;
    }
    children = [];
    left = rect.left;
    top = rect.top;
    right = rect.right;
    bottom = rect.bottom;
  }

  @override
  int get hashCode {
    if (value != null) {
      return value.hashCode;
    }
    return id.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (other is! RNode) {
      return false;
    }

    if (other.value != null && value != null) {
      return other.value == value;
    }
    if (other.value == null && value == null) {
      return other.id == id;
    }
    return false;
  }
}

typedef EachCallback<T> = bool Function(RNode<T> node);
