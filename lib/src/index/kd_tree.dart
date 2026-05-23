import 'dart:math' as math;
import 'dart:ui';

class KdTree<T> {
  KdNode<T>? _root;
  int _numberOfNodes = 0;

  final double tolerance;
  final double _toleranceSq;

  KdTree({this.tolerance = 1e-9}) : _toleranceSq = tolerance * tolerance;

  factory KdTree.fromNodes(List<KdNode<T>> nodes, {double tolerance = 0}) {
    final tree = KdTree<T>(tolerance: tolerance);
    if (nodes.isNotEmpty) {
      tree._root = tree._buildBalanced(nodes, 0);
      tree._numberOfNodes = tree._countNodes(tree._root);
    }
    return tree;
  }

  KdNode<T>? _buildBalanced(List<KdNode<T>> nodes, int depth) {
    if (nodes.isEmpty) return null;
    return _buildBalancedRange(nodes, 0, nodes.length, depth);
  }

  KdNode<T>? _buildBalancedRange(
    List<KdNode<T>> nodes,
    int start,
    int end,
    int depth,
  ) {
    if (start >= end) return null;
    final axis = depth % 2;
    final mid = start + (end - start) ~/ 2;
    _selectByAxis(nodes, start, end - 1, mid, axis);
    final node = nodes[mid];

    node._left = _buildBalancedRange(nodes, start, mid, depth + 1);
    node._right = _buildBalancedRange(nodes, mid + 1, end, depth + 1);

    return node;
  }

  void _selectByAxis(
    List<KdNode<T>> nodes,
    int left,
    int right,
    int target,
    int axis,
  ) {
    while (left < right) {
      final pivotIndex = (left + right) >> 1;
      final pivotNewIndex = _partition(nodes, left, right, pivotIndex, axis);
      if (target == pivotNewIndex) {
        return;
      }
      if (target < pivotNewIndex) {
        right = pivotNewIndex - 1;
      } else {
        left = pivotNewIndex + 1;
      }
    }
  }

  int _partition(
    List<KdNode<T>> nodes,
    int left,
    int right,
    int pivotIndex,
    int axis,
  ) {
    final pivotValue = _axisValue(nodes[pivotIndex], axis);
    _swap(nodes, pivotIndex, right);
    int storeIndex = left;
    for (int i = left; i < right; i++) {
      if (_axisValue(nodes[i], axis) < pivotValue) {
        _swap(nodes, storeIndex, i);
        storeIndex++;
      }
    }
    _swap(nodes, right, storeIndex);
    return storeIndex;
  }

  double _axisValue(KdNode<T> node, int axis) =>
      axis == 0 ? node.coordinate.dx : node.coordinate.dy;

  void _swap(List<KdNode<T>> nodes, int a, int b) {
    if (a == b) return;
    final temp = nodes[a];
    nodes[a] = nodes[b];
    nodes[b] = temp;
  }

  int _countNodes(KdNode<T>? node) {
    if (node == null) return 0;
    return 1 + _countNodes(node.left) + _countNodes(node.right);
  }

  KdNode<T>? get root => _root;

  bool get isEmpty => _root == null;

  int get size => _numberOfNodes;

  KdNode<T> insert(Offset p, [T? data]) {
    if (_root == null) {
      _root = KdNode(p, data);
      _numberOfNodes++;
      return _root!;
    }

    if (tolerance > 0) {
      final nearest = _nearest(_root, p, _root!, double.infinity, 0);
      if (nearest != null) {
        final distSq = (nearest.node.coordinate - p).distanceSquared;
        if (distSq <= _toleranceSq) {
          nearest.node.increment();
          return nearest.node;
        }
      }
    }
    return _insertExact(p, data);
  }

  KdNode<T> _insertExact(Offset p, [T? data]) {
    KdNode<T>? curr = _root;
    if (curr == null) throw StateError("Root should not be null here");

    bool isX = true;
    while (true) {
      if ((curr!.coordinate - p).distanceSquared <= _toleranceSq) {
        curr.increment();
        return curr;
      }

      final double val = isX ? p.dx : p.dy;
      final double currVal = isX ? curr.coordinate.dx : curr.coordinate.dy;

      final bool goLeft = val < currVal;

      if (goLeft) {
        if (curr.left == null) {
          final newNode = KdNode(p, data);
          curr._left = newNode;
          _numberOfNodes++;
          return newNode;
        }
        curr = curr.left;
      } else {
        if (curr.right == null) {
          final newNode = KdNode(p, data);
          curr._right = newNode;
          _numberOfNodes++;
          return newNode;
        }
        curr = curr.right;
      }
      isX = !isX;
    }
  }

  List<KdNode<T>> queryRect(Rect range) {
    final List<KdNode<T>> results = [];
    _queryRectRecursive(_root, range, 0, results);
    return results;
  }

  KdNode<T>? nearest(Offset target) {
    if (_root == null) return null;
    return _nearest(_root, target, _root!, double.infinity, 0)?.node;
  }

  void _queryRectRecursive(
    KdNode<T>? node,
    Rect range,
    int depth,
    List<KdNode<T>> results,
  ) {
    if (node == null) return;
    if (range.contains(node.coordinate)) {
      results.add(node);
    }
    final int axis = depth % 2;
    final double nodeVal = axis == 0 ? node.coordinate.dx : node.coordinate.dy;
    final double minVal = axis == 0 ? range.left : range.top;
    final double maxVal = axis == 0 ? range.right : range.bottom;
    if (minVal < nodeVal) {
      _queryRectRecursive(node.left, range, depth + 1, results);
    }
    if (maxVal >= nodeVal) {
      _queryRectRecursive(node.right, range, depth + 1, results);
    }
  }

  _BestNode<T>? _nearest(
    KdNode<T>? node,
    Offset target,
    KdNode<T> currentBestNode,
    double currentMinDistSq,
    int depth,
  ) {
    if (node == null) return null;
    double dSq = (node.coordinate - target).distanceSquared;
    KdNode<T> bestNode = currentBestNode;
    double minDistSq = currentMinDistSq;

    if (dSq < minDistSq) {
      minDistSq = dSq;
      bestNode = node;
    }
    final int axis = depth % 2;
    final double targetVal = axis == 0 ? target.dx : target.dy;
    final double nodeVal = axis == 0 ? node.coordinate.dx : node.coordinate.dy;
    final double diff = targetVal - nodeVal;

    KdNode<T>? near = diff < 0 ? node.left : node.right;
    KdNode<T>? far = diff < 0 ? node.right : node.left;

    var bestResult = _nearest(near, target, bestNode, minDistSq, depth + 1);
    if (bestResult != null) {
      bestNode = bestResult.node;
      minDistSq = bestResult.distSq;
    }

    if (diff * diff < minDistSq) {
      var farResult = _nearest(far, target, bestNode, minDistSq, depth + 1);
      if (farResult != null) {
        bestNode = farResult.node;
        minDistSq = farResult.distSq;
      }
    }

    return _BestNode(bestNode, minDistSq);
  }

  int get depth => _maxDepth(_root);

  int _maxDepth(KdNode<T>? node) {
    if (node == null) return 0;
    return 1 + math.max(_maxDepth(node.left), _maxDepth(node.right));
  }

  static List<Offset> toCoordinates<T>(
    List<KdNode<T>> nodes, [
    bool includeRepeated = false,
  ]) {
    if (!includeRepeated) {
      return nodes.map((e) => e.coordinate).toList();
    }
    List<Offset> list = [];
    for (var node in nodes) {
      for (int i = 0; i < node.count; i++) {
        list.add(node.coordinate);
      }
    }
    return list;
  }

  void clear() {
    _root = null;
    _numberOfNodes = 0;
  }
}

class _BestNode<T> {
  final KdNode<T> node;
  final double distSq;

  _BestNode(this.node, this.distSq);
}

class KdNode<T> {
  final Offset coordinate;
  final T? data;
  KdNode<T>? _left;
  KdNode<T>? _right;

  int _count = 1;

  KdNode(this.coordinate, this.data);

  KdNode.of(Offset p, this.data) : coordinate = p;

  KdNode<T>? get left => _left;

  KdNode<T>? get right => _right;

  int get count => _count;

  void increment() => _count++;

  @override
  String toString() => 'KdNode($coordinate, count: $_count)';
}
