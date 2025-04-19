import 'dart:ui';

class KdTree<T> {
  static List<Offset> toCoordinates<T>(List<KdNode<T>> nodes, [bool includeRepeated = false]) {
    List<Offset> coordList = [];
    for (var node in nodes) {
      int count = (includeRepeated) ? node.getCount() : 1;
      for (int i = 0; i < count; i++) {
        coordList.add(node.coordinate);
      }
    }
    return coordList;
  }

  KdNode<T>? _root;
  int _numberOfNodes = 0;
  double tolerance;

  KdTree([this.tolerance = 0]);

  KdNode<T>? getRoot() {
    return _root;
  }

  bool isEmpty() {
    if (_root == null) {
      return true;
    }
    return false;
  }

  KdNode<T> insert(Offset p, [T? data]) {
    if (_root == null) {
      _root = KdNode.of(p, data);
      return _root!;
    }
    if (tolerance > 0) {
      final matchNode = findBestMatchNode(p);
      if (matchNode != null) {
        matchNode.increment();
        return matchNode;
      }
    }
    return insertExact(p, data);
  }

  KdNode<T>? findBestMatchNode(Offset p) {
    final visitor = BestMatchVisitor<T>(p, tolerance);
    query3(visitor.queryEnvelope(), visitor);
    return visitor.getNode();
  }

  KdNode<T> insertExact(Offset p, [T? data]) {
    KdNode<T>? currentNode = _root;
    KdNode<T>? leafNode = _root;
    bool isXLevel = true;
    bool isLessThan = true;
    while (currentNode != null) {
      bool isInTolerance = (p - currentNode.coordinate).distance <= tolerance;
      if (isInTolerance) {
        currentNode.increment();
        return currentNode;
      }
      double splitValue = currentNode.splitValue(isXLevel);
      if (isXLevel) {
        isLessThan = p.dx < splitValue;
      } else {
        isLessThan = p.dy < splitValue;
      }
      leafNode = currentNode;
      if (isLessThan) {
        currentNode = currentNode.left;
      } else {
        currentNode = currentNode.right;
      }
      isXLevel = !isXLevel;
    }
    _numberOfNodes = _numberOfNodes + 1;
    KdNode<T> node = KdNode.of(p, data);
    if (isLessThan) {
      leafNode!._left = (node);
    } else {
      leafNode!._right = (node);
    }
    return node;
  }

  void query3(Rect queryEnv, KdNodeVisitor visitor) {
    List<_QueryStackFrame<T>> queryStack = [];
    KdNode<T>? currentNode = _root;
    bool isXLevel = true;
    while (true) {
      if (currentNode != null) {
        queryStack.add(_QueryStackFrame(currentNode, isXLevel));
        bool searchLeft = currentNode.isRangeOverLeft(isXLevel, queryEnv);
        if (searchLeft) {
          currentNode = currentNode.left;
          if (currentNode != null) {
            isXLevel = !isXLevel;
          }
        } else {
          currentNode = null;
        }
      } else if (queryStack.isNotEmpty) {
        final frame = queryStack.removeAt(0);
        currentNode = frame.node;
        isXLevel = frame.isXLevel;
        if (queryEnv.contains(currentNode.coordinate)) {
          visitor.visit(currentNode);
        }
        bool searchRight = currentNode.isRangeOverRight(isXLevel, queryEnv);
        if (searchRight) {
          currentNode = currentNode.right;
          if (currentNode != null) {
            isXLevel = !isXLevel;
          }
        } else {
          currentNode = null;
        }
      } else {
        return;
      }
    }
  }

  List<KdNode<T>> query2(Rect queryEnv) {
    final List<KdNode<T>> result = [];
    query4(queryEnv, result);
    return result;
  }

  void query4(Rect queryEnv, final List<KdNode<T>> result) {
    query3(
      queryEnv,
      KdNodeVisitor2<T>((node) {
        result.add(node);
      }),
    );
  }

  KdNode<T>? query(Offset queryPt) {
    KdNode<T>? currentNode = _root;
    bool isXLevel = true;
    while (currentNode != null) {
      if (currentNode.coordinate == queryPt) {
        return currentNode;
      }

      bool searchLeft = currentNode.isPointOnLeft(isXLevel, queryPt);
      if (searchLeft) {
        currentNode = currentNode.left;
      } else {
        currentNode = currentNode.right;
      }
      isXLevel = !isXLevel;
    }
    return null;
  }

  int depth() {
    return depthNode(_root);
  }

  int depthNode(KdNode? currentNode) {
    if (currentNode == null) {
      return 0;
    }

    int dL = depthNode(currentNode.left);
    int dR = depthNode(currentNode.right);
    return 1 + (dL > dR ? dL : dR);
  }

  int size() {
    return sizeNode(_root);
  }

  int sizeNode(KdNode<T>? currentNode) {
    if (currentNode == null) {
      return 0;
    }

    int sizeL = sizeNode(currentNode.left);
    int sizeR = sizeNode(currentNode.right);
    return (1 + sizeL) + sizeR;
  }
}

class BestMatchVisitor<T> implements KdNodeVisitor<T> {
  final Offset p;
  final double tolerance;
  KdNode<T>? _matchNode;
  double _matchDist = 0.0;

  BestMatchVisitor(this.p, this.tolerance);

  Rect queryEnvelope() {
    Rect queryEnv = Rect.fromCircle(center: p, radius: 0);
    queryEnv = queryEnv.inflate(tolerance);
    return queryEnv;
  }

  KdNode<T>? getNode() {
    return _matchNode;
  }

  @override
  void visit(KdNode<T> node) {
    final dOff = node.coordinate - p;
    double dist = dOff.distance;
    bool isInTolerance = dist <= tolerance;
    if (!isInTolerance) {
      return;
    }

    bool update = false;
    if (((_matchNode == null) || (dist < _matchDist)) ||
        (((_matchNode != null) && (dist == _matchDist)) && _compareTo(node.coordinate, _matchNode!.coordinate) < 1)) {
      update = true;
    }
    if (update) {
      _matchNode = node;
      _matchDist = dist;
    }
  }
}

int _compareTo(Offset a, Offset other) {
  if (a.dx < other.dx) {
    return -1;
  }

  if (a.dx > other.dx) {
    return 1;
  }

  if (a.dy < other.dy) {
    return -1;
  }

  if (a.dy > other.dy) {
    return 1;
  }
  return 0;
}

class KdNode<T> {
  late Offset _p;

  final T? _data;

  KdNode<T>? _left;

  KdNode<T>? _right;

  int _count = 0;

  KdNode(double x, double y, this._data) {
    _p = Offset(x, y);
    _count = 1;
  }

  KdNode.of(Offset p, this._data) {
    _p = p;
    _count = 1;
  }

  double getX() => _p.dx;

  double getY() => _p.dy;

  double splitValue(bool isSplitOnX) {
    if (isSplitOnX) {
      return _p.dx;
    }
    return _p.dy;
  }

  Offset get coordinate => _p;

  T? getData() {
    return _data;
  }

  KdNode<T>? get left {
    return _left;
  }

  KdNode<T>? get right {
    return _right;
  }

  void increment() {
    _count = _count + 1;
  }

  int getCount() {
    return _count;
  }

  bool isRepeated() {
    return _count > 1;
  }

  bool isRangeOverLeft(bool isSplitOnX, Rect env) {
    double envMin;
    if (isSplitOnX) {
      envMin = env.left;
    } else {
      envMin = env.top;
    }
    bool isInRange = envMin < splitValue(isSplitOnX);
    return isInRange;
  }

  bool isRangeOverRight(bool isSplitOnX, Rect env) {
    double envMax;
    if (isSplitOnX) {
      envMax = env.right;
    } else {
      envMax = env.bottom;
    }

    return splitValue(isSplitOnX) <= envMax;
  }

  bool isPointOnLeft(bool isSplitOnX, Offset pt) {
    double ptOrdinate;
    if (isSplitOnX) {
      ptOrdinate = pt.dx;
    } else {
      ptOrdinate = pt.dy;
    }
    return ptOrdinate < splitValue(isSplitOnX);
  }
}

abstract interface class KdNodeVisitor<T> {
  void visit(KdNode<T> node);
}

class KdNodeVisitor2<T> implements KdNodeVisitor<T> {
  final void Function(KdNode<T> node) visitFun;

  KdNodeVisitor2(this.visitFun);

  @override
  void visit(KdNode<T> node) {
    visitFun.call(node);
  }
}

class _QueryStackFrame<T> {
  final KdNode<T> node;

  final bool isXLevel;

  const _QueryStackFrame(this.node, this.isXLevel);
}
