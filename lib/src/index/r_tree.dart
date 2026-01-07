import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:d_util/d_util.dart';

enum VisitResult { continueTree, skipChildren, stopAll }

typedef NodeVisitor<T> = VisitResult Function(RNode<T> node);

final class RTree<E> {
  final Map<E, Rect> _rectCacheMap = HashMap.identity();
  final Rect Function(E value) boundsFun;

  late final int maxEntries;
  late final int minEntries;
  late RNode<E> _root;

  RTree(this.boundsFun, [int maxEntries = 9]) {
    this.maxEntries = math.max(4, maxEntries);
    minEntries = math.max(2, (this.maxEntries * 0.4).ceil());
    clear();
  }

  Rect? getBounds(E value) => _rectCacheMap[value];

  List<E> all() => _rectCacheMap.keys.toList();

  List<E> search(Rect rect) {
    if (!_intersectsRect(rect, _root)) {
      return [];
    }
    final List<E> result = [];
    final double rLeft = rect.left;
    final double rTop = rect.top;
    final double rRight = rect.right;
    final double rBottom = rect.bottom;

    final List<RNode<E>> stack = [_root];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      if (node.left >= rLeft && node.right <= rRight && node.top >= rTop && node.bottom <= rBottom) {
        _collectAll(node, result);
        continue;
      }

      for (var child in node.children) {
        if (child.left <= rRight && child.right >= rLeft && child.top <= rBottom && child.bottom >= rTop) {
          if (node.leaf) {
            if (child.value != null) {
              result.add(child.value as E);
            }
          } else {
            stack.add(child);
          }
        }
      }
    }
    return result;
  }

  void _collectAll(RNode<E> node, List<E> result) {
    final List<RNode<E>> stack = [node];
    while (stack.isNotEmpty) {
      final n = stack.removeLast();
      if (n.leaf) {
        for (var child in n.children) {
          if (child.value != null) result.add(child.value as E);
        }
      } else {
        stack.addAll(n.children);
      }
    }
  }

  E? searchSingle(Rect rect, bool Function(E node) testFun) {
    if (!_intersectsRect(rect, _root)) {
      return null;
    }

    final double rLeft = rect.left;
    final double rTop = rect.top;
    final double rRight = rect.right;
    final double rBottom = rect.bottom;

    final List<RNode<E>> stack = [_root];

    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      if (node.left >= rLeft && node.right <= rRight && node.top >= rTop && node.bottom <= rBottom) {
        final res = _searchSingleInSubtree(node, testFun);
        if (res != null) return res;
        continue;
      }

      for (var child in node.children) {
        if (child.left <= rRight && child.right >= rLeft && child.top <= rBottom && child.bottom >= rTop) {
          if (node.leaf) {
            final d = child.value;
            if (d != null && testFun(d)) {
              return d;
            }
          } else {
            stack.add(child);
          }
        }
      }
    }
    return null;
  }

  E? _searchSingleInSubtree(RNode<E> node, bool Function(E node) testFun) {
    final List<RNode<E>> stack = [node];
    while (stack.isNotEmpty) {
      final n = stack.removeLast();
      if (n.leaf) {
        for (var c in n.children) {
          final d = c.value;
          if (d != null && testFun(d)) return d;
        }
      } else {
        stack.addAll(n.children);
      }
    }
    return null;
  }

  RTree<E> each(NodeVisitor<E> test) {
    final List<RNode<E>> next = [_root];
    while (next.isNotEmpty) {
      var node = next.removeAt(0);
      switch (test(node)) {
        case VisitResult.stopAll:
          return this;
        case VisitResult.skipChildren:
          continue;
        case VisitResult.continueTree:
          next.addAll(node.children);
      }
    }
    return this;
  }

  RTree<E> eachBefore(NodeVisitor<E> test) {
    final List<RNode<E>> nodes = [_root];
    while (nodes.isNotEmpty) {
      var node = nodes.removeLast();
      switch (test(node)) {
        case VisitResult.stopAll:
          return this;
        case VisitResult.skipChildren:
          continue;
        case VisitResult.continueTree:
          nodes.addAll(node.children);
      }
    }
    return this;
  }

  RTree<E> eachAfter(NodeVisitor<E> visit) {
    final List<(RNode<E>, bool)> stack = [(_root, false)];

    while (stack.isNotEmpty) {
      final (node, visited) = stack.removeLast();

      if (visited) {
        switch (visit(node)) {
          case VisitResult.stopAll:
            return this;
          case VisitResult.skipChildren:
          case VisitResult.continueTree:
            break;
        }
        continue;
      }
      stack.add((node, true));
      final decision = visit(node);
      if (decision == VisitResult.stopAll) {
        return this;
      }
      if (decision == VisitResult.skipChildren) {
        continue;
      }
      final children = node.children;
      for (int i = children.length - 1; i >= 0; i--) {
        stack.add((children[i], false));
      }
    }

    return this;
  }

  bool hasCollides(Rect rect) {
    if (!_intersectsRect(rect, _root)) return false;

    final double rLeft = rect.left;
    final double rTop = rect.top;
    final double rRight = rect.right;
    final double rBottom = rect.bottom;

    final List<RNode<E>> stack = [_root];
    while (stack.isNotEmpty) {
      var node = stack.removeLast();
      for (var child in node.children) {
        if (child.left <= rRight && child.right >= rLeft && child.top <= rBottom && child.bottom >= rTop) {
          if (node.leaf ||
              (child.left >= rLeft && child.right <= rRight && child.top >= rTop && child.bottom <= rBottom)) {
            return true;
          }
          stack.add(child);
        }
      }
    }
    return false;
  }

  RTree<E> addAll(Iterable<E> data, {int? optThreshold}) {
    if (data.isEmpty) return this;

    int threshold = maxEntries;
    if (optThreshold != null && optThreshold > 0) {
      threshold = optThreshold;
    }

    if (data.length <= threshold) {
      for (var item in data) {
        add(item);
      }
      return this;
    }

    // OMT 算法构建
    List<RNode<E>> buildList = [];
    for (var value in data) {
      final rect = boundsFun(value);
      _rectCacheMap[value] = rect;
      buildList.add(RNode(value: value, left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom));
    }

    var node = _build(buildList, 0, buildList.length - 1, 0);

    if (_root.children.isEmpty) {
      _root = node;
    } else if (_root.height == node.height) {
      _splitRoot(_root, node);
    } else {
      if (_root.height < node.height) {
        var tmp = _root;
        _root = node;
        node = tmp;
      }
      _insert(node, _root.height - node.height - 1);
    }
    return this;
  }

  RTree<E> add(E value) {
    final rect = boundsFun(value);
    _rectCacheMap[value] = rect;
    final node = RNode(value: value, left: rect.left, top: rect.top, right: rect.right, bottom: rect.bottom);
    _insert(node, _root.height - 1);
    return this;
  }

  RTree<E> clear() {
    _rectCacheMap.clear();
    _root = _createNode([]);
    return this;
  }

  RTree<E> update(E value) {
    final oldRect = _rectCacheMap[value];
    final newRect = boundsFun(value);

    if (oldRect == null) {
      add(value);
      return this;
    }
    if (oldRect == newRect) return this;
    _rectCacheMap[value] = newRect;

    remove(value);
    add(value);
    return this;
  }

  RTree<E> remove(E item) {
    final targetRect = _rectCacheMap[item];
    if (targetRect == null) {
      return this;
    }
    final List<RNode<E>> path = [];
    if (_removeRecursive(_root, item, targetRect, path)) {
      _rectCacheMap.remove(item);
      _condense(path);
      if (!_root.leaf && _root.children.length == 1) {
        _root = _root.children[0];
      }
    }
    return this;
  }

  RTree<E> removeAll(Iterable<E> items) {
    if (items.isEmpty || _rectCacheMap.isEmpty) return this;

    final Set<E> targets = items is Set<E> ? items : items.toSet();
    if (targets.isEmpty) return this;
    final int total = _rectCacheMap.length;

    if (targets.length > total * 0.4) {
      final remaining = _rectCacheMap.keys.where((e) => !targets.contains(e));
      clear();
      addAll(remaining);
      return this;
    }

    final List<RNode<E>> condensePath = [];
    bool removedAny = false;
    for (final item in targets) {
      final rect = _rectCacheMap[item];
      if (rect == null) continue;
      final List<RNode<E>> path = [];
      if (_removeRecursive(_root, item, rect, path)) {
        _rectCacheMap.remove(item);
        condensePath.addAll(path);
        removedAny = true;
      }
    }
    if (!removedAny) return this;
    final seen = <RNode<E>>{};
    final uniquePath = <RNode<E>>[];
    for (final n in condensePath) {
      if (seen.add(n)) uniquePath.add(n);
    }
    _condense(uniquePath);
    if (!_root.leaf && _root.children.length == 1) {
      _root = _root.children[0];
    }
    return this;
  }

  bool _removeRecursive(RNode<E> node, E item, Rect targetRect, List<RNode<E>> path) {
    if (node.left > targetRect.left ||
        node.right < targetRect.right ||
        node.top > targetRect.top ||
        node.bottom < targetRect.bottom) {
      return false;
    }
    if (node.leaf) {
      final index = _findItem(item, node.children);
      if (index != -1) {
        node.children.removeAt(index);
        path.add(node);
        return true;
      }
      return false;
    }
    for (int i = 0; i < node.children.length; i++) {
      final child = node.children[i];
      if (_removeRecursive(child, item, targetRect, path)) {
        path.add(node);
        return true;
      }
    }
    return false;
  }

  void _condense(List<RNode<E>> path) {
    for (int i = 0; i < path.length; i++) {
      final node = path[i];
      if (node.children.isEmpty) {
        if (i + 1 < path.length) {
          final parent = path[i + 1];
          parent.children.remove(node);
        } else {
          clear();
        }
      } else {
        _calcBBox(node);
      }
    }
  }

  static int compareMinX(RNode a, RNode b) => a.left.compareTo(b.left);

  static int compareMinY(RNode a, RNode b) => a.top.compareTo(b.top);

  RNode<E> _build(List<RNode<E>> items, int left, int right, int height) {
    int N = right - left + 1;
    int M = maxEntries;

    if (N <= M) {
      var node = _createNode(items.sublist(left, right + 1));
      _calcBBox(node);
      return node;
    }

    if (height == 0) {
      height = (math.log(N) / math.log(M)).ceil();
      M = (N / math.pow(M, height - 1)).ceil();
    }

    var node = _createNode([]);
    node.leaf = false;
    node.height = height;

    int n2 = (N / M).ceil();
    int n1 = n2 * math.sqrt(M).ceil();

    _multiSelect(items, left, right, n1, compareMinX);

    for (int i = left; i <= right; i += n1) {
      int right2 = math.min(i + n1 - 1, right);
      _multiSelect(items, i, right2, n2, compareMinY);

      for (int j = i; j <= right2; j += n2) {
        int right3 = math.min(j + n2 - 1, right2);
        node.children.add(_build(items, j, right3, height - 1));
      }
    }
    _calcBBox(node);
    return node;
  }

  RNode<E> _chooseSubtree(RNode<E> bbox, RNode<E> node, int level, List<RNode<E>> path) {
    while (true) {
      path.add(node);
      if (node.leaf || path.length - 1 == level) break;

      double minArea = double.infinity;
      double minEnlargement = double.infinity;
      RNode<E>? targetNode;

      final double bLeft = bbox.left;
      final double bTop = bbox.top;
      final double bRight = bbox.right;
      final double bBottom = bbox.bottom;

      for (int i = 0; i < node.children.length; i++) {
        var child = node.children[i];
        double area = (child.right - child.left) * (child.bottom - child.top);

        double enlargedRight = child.right > bRight ? child.right : bRight;
        double enlargedLeft = child.left < bLeft ? child.left : bLeft;
        double enlargedBottom = child.bottom > bBottom ? child.bottom : bBottom;
        double enlargedTop = child.top < bTop ? child.top : bTop;
        double enlargement = ((enlargedRight - enlargedLeft) * (enlargedBottom - enlargedTop)) - area;

        if (enlargement < minEnlargement) {
          minEnlargement = enlargement;
          minArea = area < minArea ? area : minArea;
          targetNode = child;
        } else if (enlargement == minEnlargement) {
          if (area < minArea) {
            minArea = area;
            targetNode = child;
          }
        }
      }

      node = targetNode ?? node.children[0];
    }
    return node;
  }

  void _insert(RNode<E> item, int level) {
    List<RNode<E>> insertPath = [];
    var node = _chooseSubtree(item, _root, level, insertPath);
    node.children.add(item);
    _extend(node, item);

    while (level >= 0) {
      if (insertPath[level].children.length > maxEntries) {
        _split(insertPath, level);
        level--;
      } else {
        break;
      }
    }
    _adjustParentBBoxes(item, insertPath, level);
  }

  void _split(List<RNode<E>> insertPath, int level) {
    var node = insertPath[level];
    int M = node.children.length;
    int m = minEntries;

    _chooseSplitAxis(node, m, M);
    int splitIndex = _chooseSplitIndex(node, m, M);

    List<RNode<E>> newChildren = node.children.sublist(splitIndex);
    node.children.length = splitIndex;

    var newNode = _createNode(newChildren);
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

  void _splitRoot(RNode<E> node, RNode<E> newNode) {
    _root = _createNode([node, newNode]);
    _root.height = node.height + 1;
    _root.leaf = false;
    _calcBBox(_root);
  }

  int _chooseSplitIndex(RNode<E> node, int m, int M) {
    int index = M - m;
    double minOverlap = double.infinity;
    double minArea = double.infinity;

    for (int i = m; i <= M - m; i++) {
      double b1L = double.infinity, b1T = double.infinity, b1R = double.negativeInfinity, b1B = double.negativeInfinity;
      for (int k = 0; k < i; k++) {
        var c = node.children[k];
        if (c.left < b1L) b1L = c.left;
        if (c.top < b1T) b1T = c.top;
        if (c.right > b1R) b1R = c.right;
        if (c.bottom > b1B) b1B = c.bottom;
      }
      double area1 = (b1R - b1L) * (b1B - b1T);

      // BBox2 [i...M]
      double b2L = double.infinity, b2T = double.infinity, b2R = double.negativeInfinity, b2B = double.negativeInfinity;
      for (int k = i; k < M; k++) {
        var c = node.children[k];
        if (c.left < b2L) b2L = c.left;
        if (c.top < b2T) b2T = c.top;
        if (c.right > b2R) b2R = c.right;
        if (c.bottom > b2B) b2B = c.bottom;
      }
      double area2 = (b2R - b2L) * (b2B - b2T);

      // Overlap
      double ovL = b1L > b2L ? b1L : b2L;
      double ovT = b1T > b2T ? b1T : b2T;
      double ovR = b1R < b2R ? b1R : b2R;
      double ovB = b1B < b2B ? b1B : b2B;
      double overlap = math.max(0, ovR - ovL) * math.max(0, ovB - ovT);

      double totalArea = area1 + area2;

      if (overlap < minOverlap) {
        minOverlap = overlap;
        index = i;
        minArea = totalArea < minArea ? totalArea : minArea;
      } else if (overlap == minOverlap && totalArea < minArea) {
        minArea = totalArea;
        index = i;
      }
    }
    return index;
  }

  void _chooseSplitAxis(RNode<E> node, int m, int M) {
    var compareMinXF = node.leaf ? compareMinX : _compareNodeMinX;
    var compareMinYF = node.leaf ? compareMinY : _compareNodeMinY;
    double xMargin = _calcMargin(node, m, M, compareMinXF);
    double yMargin = _calcMargin(node, m, M, compareMinYF);

    if (xMargin < yMargin) node.children.sort(compareMinXF);
  }

  double _calcMargin(RNode<E> node, int m, int M, int Function(RNode, RNode) compare) {
    node.children.sort(compare);

    // 左侧边界
    double leftL = double.infinity,
        leftT = double.infinity,
        leftR = double.negativeInfinity,
        leftB = double.negativeInfinity;
    // 右侧边界
    double rightL = double.infinity,
        rightT = double.infinity,
        rightR = double.negativeInfinity,
        rightB = double.negativeInfinity;

    // init left [0...m]
    for (int i = 0; i < m; i++) {
      var c = node.children[i];
      if (c.left < leftL) leftL = c.left;
      if (c.top < leftT) leftT = c.top;
      if (c.right > leftR) leftR = c.right;
      if (c.bottom > leftB) leftB = c.bottom;
    }

    // init right [M-m...M]
    for (int i = M - m; i < M; i++) {
      var c = node.children[i];
      if (c.left < rightL) rightL = c.left;
      if (c.top < rightT) rightT = c.top;
      if (c.right > rightR) rightR = c.right;
      if (c.bottom > rightB) rightB = c.bottom;
    }

    double margin = (leftR - leftL) + (leftB - leftT) + (rightR - rightL) + (rightB - rightT);

    // 增量计算 margin
    for (int i = m; i < M - m; i++) {
      var child = node.children[i];
      if (child.left < leftL) leftL = child.left;
      if (child.top < leftT) leftT = child.top;
      if (child.right > leftR) leftR = child.right;
      if (child.bottom > leftB) leftB = child.bottom;
      margin += (leftR - leftL) + (leftB - leftT);
    }

    for (int i = M - m - 1; i >= m; i--) {
      var child = node.children[i];
      if (child.left < rightL) rightL = child.left;
      if (child.top < rightT) rightT = child.top;
      if (child.right > rightR) rightR = child.right;
      if (child.bottom > rightB) rightB = child.bottom;
      margin += (rightR - rightL) + (rightB - rightT);
    }

    return margin;
  }

  void _adjustParentBBoxes(RNode<E> bbox, List<RNode<E>> path, int level) {
    for (int i = level; i >= 0; i--) {
      _extend(path[i], bbox);
    }
  }

  int _findItem(E item, List<RNode<E>> items) {
    for (int i = items.length - 1; i >= 0; i--) {
      if (items[i].value == item) return i;
    }
    return -1;
  }

  void _calcBBox(RNode<E> node) {
    if (node.children.isEmpty) {
      return;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var child in node.children) {
      if (child.left < minX) minX = child.left;
      if (child.top < minY) minY = child.top;
      if (child.right > maxX) maxX = child.right;
      if (child.bottom > maxY) maxY = child.bottom;
    }
    node.left = minX;
    node.top = minY;
    node.right = maxX;
    node.bottom = maxY;
  }

  void _extend(RNode<E> a, RNode<E> b) {
    if (b.left < a.left) a.left = b.left;
    if (b.top < a.top) a.top = b.top;
    if (b.right > a.right) a.right = b.right;
    if (b.bottom > a.bottom) a.bottom = b.bottom;
  }

  int _compareNodeMinX(RNode a, RNode b) => a.left.compareTo(b.left);

  int _compareNodeMinY(RNode a, RNode b) => a.top.compareTo(b.top);

  bool _intersectsRect(Rect a, RNode b) {
    return b.left <= a.right && b.top <= a.bottom && b.right >= a.left && b.bottom >= a.top;
  }

  RNode<E> _createNode(List<RNode<E>> children) {
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
      int step = ((right - left) / n / 2).ceil() * n;
      int mid = left + step;
      if (mid >= right) mid = right - 1;
      if (mid <= left) mid = left + 1;
      FastSelect.fastSelect(arr, mid, left, right, compare);
      stack.add(left);
      stack.add(mid);
      stack.add(mid);
      stack.add(right);
    }
  }
}

final class RNode<E> {
  List<RNode<E>> children;
  int height;
  bool leaf;
  double left;
  double top;
  double right;
  double bottom;

  E? value;

  RNode({
    this.height = 1,
    this.leaf = true,
    this.left = double.infinity,
    this.top = double.infinity,
    this.right = double.negativeInfinity,
    this.bottom = double.negativeInfinity,
    List<RNode<E>>? children,
    this.value,
  }) : children = children ?? [];
}
