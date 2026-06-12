import 'dart:collection';
import 'dart:math';

import 'package:dart_graph/src/index/common.dart';

typedef TreeVisitor<T> = VisitResult Function(TreeNode<T> node);

class Tree<T> {
  TreeNode<T>? _root;

  ///存放全部的节点
  final Map<T, LinkedHashSet<TreeNode<T>>> _nodeMap = {};

  ///存放叶子节点
  final Map<T, LinkedHashSet<TreeNode<T>>> _leafMap = {};

  ///按深度存放节点
  final Map<int, Set<TreeNode<T>>> _depthNodeMap = {};

  TreeNode<T>? get root => _root;

  Iterable<T> get allData => _nodes.map((node) => node.data);

  Iterable<TreeNode<T>> get leaves => _leafMap.values.expand((nodes) => nodes);

  bool get isEmpty => _nodeMap.isEmpty;

  bool get isNotEmpty => _nodeMap.isNotEmpty;

  Tree();

  Iterable<TreeNode<T>> get _nodes => _nodeMap.values.expand((nodes) => nodes);

  TreeNode<T>? getNode(T data) => _firstNode(_nodeMap[data]);

  List<TreeNode<T>> getNodes(T data) => _nodeMap[data]?.toList() ?? [];

  TreeNode<T>? getParent(T value) => getNode(value)?.parent;

  /// [parentValue] 父节点数据。如果为 null，且树为空，则设为根节点。
  /// [data] 新节点数据。
  /// return: 新创建的节点
  TreeNode<T> add(T? parentValue, T data) {
    TreeNode<T>? parentNode;

    if (parentValue != null) {
      parentNode = getNode(parentValue);
      if (parentNode == null) {
        throw StateError('Parent node not found: $parentValue');
      }
    } else {
      if (_root != null) {
        throw StateError('Root already exists.');
      }
    }

    return _addNode(parentNode, data);
  }

  TreeNode<T> _addNode(TreeNode<T>? parentNode, T data) {
    final depth = parentNode == null ? 0 : parentNode.depth + 1;
    final newNode = TreeNode._(data, depth);
    newNode._tree = this;
    newNode._parent = parentNode;
    newNode._descendantCount = 0;
    newNode._height = 0;
    if (parentNode != null) {
      parentNode._addChild(newNode);
      _removeLeafIndex(parentNode);
      _increaseDescendantCount(parentNode, 1);
      _invalidateHeightOnly(parentNode);
    } else {
      _root = newNode;
    }
    _addNodeIndex(newNode);
    _addLeafIndex(newNode);
    _depthNodeMap.putIfAbsent(depth, () => <TreeNode<T>>{}).add(newNode);

    return newNode;
  }

  void addAll(T parentValue, Iterable<T> values) {
    for (var value in values) {
      add(parentValue, value);
    }
  }

  /// 将节点 [data] 移动到新的父节点 [newParentData] 下
  void moveNode(T data, T newParentData) {
    final node = getNode(data);
    final newParent = getNode(newParentData);
    final oldParent = node?.parent;

    if (node == null || newParent == null || oldParent == null) {
      throw StateError('Node or target parent not found');
    }

    if (node == newParent) return;
    if (oldParent == newParent) return;

    TreeNode<T>? tmp = newParent;
    while (tmp != null) {
      if (tmp == node) {
        throw StateError('Cannot move node into its own descendant');
      }
      tmp = tmp.parent;
    }

    _removeLeafIndex(newParent);

    oldParent._removeChild(node);
    newParent._addChild(node);
    node._parent = newParent;

    if (oldParent.isLeaf) {
      _addLeafIndex(oldParent);
    }

    _invalidateAncestors(oldParent);
    _invalidateAncestors(newParent);
    _reindexDepth(node, newParent.depth + 1);
  }

  void _reindexDepth(TreeNode<T> node, int newDepth) {
    _depthNodeMap[node.depth]?.remove(node);
    if (_depthNodeMap[node.depth]?.isEmpty ?? false) {
      _depthNodeMap.remove(node.depth);
    }

    node._depth = newDepth;
    _depthNodeMap.putIfAbsent(newDepth, () => <TreeNode<T>>{}).add(node);
    for (final child in node.children) {
      _reindexDepth(child, newDepth + 1);
    }
  }

  /// 移除节点及其所有后代
  void remove(T data) {
    final node = getNode(data);
    if (node == null) return;
    _removeNode(node);
  }

  void _removeNode(TreeNode<T> node) {
    final int removedCount = 1 + node.descendantCount;
    final parent = node.parent;

    if (parent != null) {
      parent._removeChild(node);
      if (parent.isLeaf) {
        _addLeafIndex(parent);
      }
      _increaseDescendantCount(parent, -removedCount);
      _invalidateHeightOnly(parent);
    } else if (node == _root) {
      _root = null;
    }

    recursiveCleanup(TreeNode<T> node) {
      _removeNodeIndex(node);
      _depthNodeMap[node.depth]?.remove(node);
      if (_depthNodeMap[node.depth]?.isEmpty ?? false) {
        _depthNodeMap.remove(node.depth);
      }

      if (node.isLeaf) {
        _removeLeafIndex(node);
      }
      node._tree = null;
      if (!node.isLeaf) {
        for (final child in node._children) {
          recursiveCleanup(child);
        }
      }
    }

    recursiveCleanup(node);
  }

  /// 根据条件移除子树 [where] 返回 true 则移除该节点及其子树
  void removeSubtreesWhere(bool Function(TreeNode<T>) where) {
    List<TreeNode<T>> toRemove = [];
    final queue = Queue<TreeNode<T>>();
    if (_root != null) queue.add(_root!);
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      if (where(node)) {
        toRemove.add(node);
      } else {
        queue.addAll(node.children);
      }
    }

    for (var node in toRemove) {
      if (node._tree == this) {
        _removeNode(node);
      }
    }
  }

  /// 仅移除满足条件的叶子节点 (修剪边缘) 循环执行直到没有节点被移除（因为移除叶子可能产生新的叶子）
  void pruneLeavesWhere(bool Function(TreeNode<T>) where) {
    bool changed = true;
    while (changed) {
      changed = false;
      final currentLeaves = _leafMap.values.toList();
      for (var leaves in currentLeaves) {
        for (var leaf in leaves.toList()) {
          if (leaf._tree != this) {
            continue;
          }
          if (where(leaf)) {
            _removeNode(leaf);
            changed = true;
          }
        }
      }
    }
  }

  void clear() {
    _root = null;
    _nodeMap.clear();
    _leafMap.clear();
    _depthNodeMap.clear();
  }

  int get maxDepth {
    if (_root == null) return 0;
    int maxD = 0;
    for (var leaf in leaves) {
      maxD = max(maxD, leaf.depth);
    }
    return maxD;
  }

  int get childrenCount => _nodes.length;

  bool contains(T data) => _nodeMap[data]?.isNotEmpty ?? false;

  List<TreeNode<T>> getNodesAtDepth(int depth, {bool needOrder = false}) {
    if (!needOrder) {
      return _nodes.where((n) => n.depth == depth).toList();
    }

    List<TreeNode<T>> result = [];
    if (_root == null) return result;
    final queue = Queue<_NodeDepthPair<T>>();
    queue.add(_NodeDepthPair(_root!, 0));

    while (queue.isNotEmpty) {
      final pair = queue.removeFirst();
      if (pair.depth == depth) {
        result.add(pair.node);
      } else if (pair.depth < depth) {
        for (var child in pair.node.children) {
          queue.add(_NodeDepthPair(child, pair.depth + 1));
        }
      }
    }
    return result;
  }

  Iterable<TreeNode<T>> getNodesAtDepthFast(int depth) =>
      _depthNodeMap[depth] ?? <TreeNode<T>>{};

  Tree<T> copySubtree(T rootData) {
    final startNode = getNode(rootData);
    if (startNode == null) throw StateError('Node not found');

    Tree<T> newTree = Tree<T>();

    final queue = Queue<(TreeNode<T>, TreeNode<T>)>();

    final newRoot = newTree._addNode(null, startNode.data);
    queue.add((startNode, newRoot));

    while (queue.isNotEmpty) {
      final (source, targetParent) = queue.removeFirst();

      for (var child in source.children) {
        final copiedChild = newTree._addNode(targetParent, child.data);
        queue.add((child, copiedChild));
      }
    }
    return newTree;
  }

  TreeNode<T>? minCommonAncestor(T dataA, T dataB) {
    final nodeA = getNode(dataA);
    final nodeB = getNode(dataB);
    if (nodeA == null || nodeB == null) return null;

    return _minCommonAncestorOf(nodeA, nodeB);
  }

  TreeNode<T>? _minCommonAncestorOf(TreeNode<T> nodeA, TreeNode<T> nodeB) {
    TreeNode<T>? p1 = nodeA;
    TreeNode<T>? p2 = nodeB;
    int d1 = p1.depth;
    int d2 = p2.depth;

    while (d1 > d2) {
      p1 = p1!.parent;
      d1--;
    }
    while (d2 > d1) {
      p2 = p2!.parent;
      d2--;
    }
    while (p1 != p2 && p1 != null && p2 != null) {
      p1 = p1.parent;
      p2 = p2.parent;
    }
    return p1;
  }

  TreeNode<T>? _firstNode(LinkedHashSet<TreeNode<T>>? nodes) {
    if (nodes == null || nodes.isEmpty) {
      return null;
    }
    return nodes.first;
  }

  void _addNodeIndex(TreeNode<T> node) {
    _nodeMap
        .putIfAbsent(node.data, () => LinkedHashSet<TreeNode<T>>.identity())
        .add(node);
  }

  void _removeNodeIndex(TreeNode<T> node) {
    final nodes = _nodeMap[node.data];
    if (nodes == null) {
      return;
    }
    nodes.remove(node);
    if (nodes.isEmpty) {
      _nodeMap.remove(node.data);
    }
  }

  void _addLeafIndex(TreeNode<T> node) {
    _leafMap
        .putIfAbsent(node.data, () => LinkedHashSet<TreeNode<T>>.identity())
        .add(node);
  }

  void _removeLeafIndex(TreeNode<T> node) {
    final nodes = _leafMap[node.data];
    if (nodes == null) {
      return;
    }
    nodes.remove(node);
    if (nodes.isEmpty) {
      _leafMap.remove(node.data);
    }
  }

  List<TreeNode<T>> findPath(T sourceData, T targetData) {
    final startNode = getNode(sourceData);
    final endNode = getNode(targetData);

    if (startNode == null || endNode == null) return [];

    return _findPathBetween(startNode, endNode);
  }

  List<TreeNode<T>> _findPathBetween(
    TreeNode<T> startNode,
    TreeNode<T> endNode,
  ) {
    if (startNode == endNode) return [startNode];

    final lca = _minCommonAncestorOf(startNode, endNode);

    if (lca == null) return [];

    final List<TreeNode<T>> pathUp = [];
    TreeNode<T>? curr = startNode;
    while (curr != lca) {
      pathUp.add(curr!);
      curr = curr.parent;
    }
    pathUp.add(lca);

    final List<TreeNode<T>> pathDown = [];
    curr = endNode;
    while (curr != lca) {
      pathDown.add(curr!);
      curr = curr.parent;
    }
    return [...pathUp, ...pathDown.reversed];
  }

  void visit(TreeVisitor<T> visitor) => visitBFS(visitor);

  void visitBFS(TreeVisitor<T> visitor) {
    _root?.visitBFS(visitor);
  }

  void visitBefore(TreeVisitor<T> visitor) {
    _root?.visitBefore(visitor);
  }

  void visitAfter(TreeVisitor<T> visitor) {
    _root?.visitAfter(visitor);
  }

  List<TreeNode<T>> search(bool Function(TreeNode<T>) where) {
    return _nodes.where(where).toList();
  }

  TreeNode<T>? find(bool Function(TreeNode<T>) where) => _root?.find(where);

  TreeNode<T>? findFirst(bool Function(TreeNode<T>) where) {
    for (var node in _nodes) {
      if (where(node)) return node;
    }
    return null;
  }

  List<TreeNode<T>> findWhere(
    bool Function(TreeNode<T>) where, {
    bool iterator = true,
    int limit = -1,
  }) {
    if (_root == null) return [];
    return _root!.findWhere(where, iterator: iterator, limit: limit);
  }

  void _increaseDescendantCount(TreeNode<T>? node, int delta) {
    while (node != null) {
      if (node._descendantCount >= 0) {
        node._descendantCount += delta;
      }
      node = node.parent;
    }
  }

  void _invalidateHeightOnly(TreeNode<T>? node) {
    while (node != null) {
      if (node._height == -1) break;
      node._height = -1;
      node = node.parent;
    }
  }

  void _invalidateAncestors(TreeNode<T>? node) {
    while (node != null) {
      node._height = -1;
      node._descendantCount = -1;
      node = node.parent;
    }
  }

  void sort(int Function(TreeNode<T> a, TreeNode<T> b) compare) {
    final root = _root;
    if (root == null) {
      return;
    }
    sortSubtree(root.data, compare);
  }

  void sortChildren(
    T parentData,
    Comparator<TreeNode<T>> compare, {
    bool recursive = false,
  }) {
    final parent = getNode(parentData);
    if (parent == null) {
      throw StateError('Node not found: $parentData');
    }

    void sortNode(TreeNode<T> node) {
      node._children.sortWithIndex(compare);

      if (recursive) {
        for (final child in node._children) {
          sortNode(child);
        }
      }
    }

    sortNode(parent);
  }

  void sortSubtree(
    T parentData,
    int Function(TreeNode<T> a, TreeNode<T> b) compare,
  ) {
    final parent = getNode(parentData);
    if (parent == null) {
      throw StateError('Node not found: $parentData');
    }
    void dfs(TreeNode<T> node) {
      if (node._children.length > 1) {
        node._children.sortWithIndex(compare); // 修复点
      }
      for (final child in node._children) {
        dfs(child);
      }
    }

    dfs(parent);
  }
}

class TreeNode<T> {
  final T data;
  late final _children = _ChildList<T>();
  Tree<T>? _tree;
  TreeNode<T>? _parent;

  int _index = -1;
  int _height = -1;
  int _descendantCount = -1;
  int _depth;

  bool expand = true;

  TreeNode._(this.data, this._depth);

  TreeNode<T>? get parent => _parent;

  List<TreeNode<T>> get children => _children;

  Iterable<TreeNode<T>> get childrenReverse => _children.reversed;

  bool get isLeaf => _children.isEmpty;

  bool get isRoot => _parent == null;

  int get childCount => _children.length;

  bool get hasChildren => _children.isNotEmpty;

  bool get isNotChildren => _children.isEmpty;

  TreeNode<T> childAt(int index) => _children[index];

  TreeNode<T> get firstChild => _children[0];

  TreeNode<T> get lastChild => _children[_children.length - 1];

  int get depth => _depth;

  int get height {
    if (_height < 0) {
      _computeHeight();
    }
    return _height;
  }

  int get descendantCount {
    if (_descendantCount < 0) {
      _computeDescendantCount();
    }
    return _descendantCount;
  }

  int get indexInParent => _index;

  void _addChild(TreeNode<T> node) => _children.add(node);

  void _removeChild(TreeNode<T> node) => _children.remove(node);

  int _computeHeight() {
    if (isLeaf) {
      _height = 0;
    } else {
      int maxH = -1;
      for (var child in _children) {
        int h = child.height; // 递归调用 getter
        if (h > maxH) maxH = h;
      }
      _height = maxH + 1;
    }
    return _height;
  }

  int _computeDescendantCount() {
    int sum = 0;
    for (var child in _children) {
      sum += 1 + child.descendantCount;
    }
    _descendantCount = sum;
    return _descendantCount;
  }

  /// 获取所有祖先节点 [父, 爷, ..., 根]
  List<TreeNode<T>> get ancestors {
    List<TreeNode<T>> list = [];
    var p = _parent;
    while (p != null) {
      list.add(p);
      p = p.parent;
    }
    return list;
  }

  /// 获取所有后代 (DFS 前序)
  /// 返回的是新列表，不影响树结构
  List<TreeNode<T>> get descendants {
    final result = <TreeNode<T>>[];
    final stack = List<TreeNode<T>>.from(_children);
    while (stack.isNotEmpty) {
      final n = stack.removeLast();
      result.add(n);
      stack.addAll(n._children);
    }
    return result;
  }

  /// 查找子树中最短路径
  List<TreeNode<T>> findPathTo(TreeNode<T> target) {
    if (_tree == null || target._tree != _tree) {
      return [];
    }
    return _tree!._findPathBetween(this, target);
  }

  @override
  String toString() {
    return 'TreeNode(data: $data, depth: $depth, children: $childCount)';
  }

  Tree<T>? get tree => _tree;

  void visit(TreeVisitor<T> visitor) => visitBFS(visitor);

  void visitBFS(TreeVisitor<T> visitor) {
    final queue = Queue<TreeNode<T>>();
    queue.add(this);
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      final res = visitor(node);
      if (res == VisitResult.stop) {
        return;
      }
      if (res == VisitResult.skipChildren) {
        continue;
      }
      queue.addAll(node._children);
    }
  }

  void visitBefore(TreeVisitor<T> visitor) {
    final stack = [this];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      final res = visitor(node);
      if (res == VisitResult.stop) {
        return;
      }
      if (res == VisitResult.skipChildren) {
        continue;
      }
      // 倒序入栈，保证出栈时是正序 (0, 1, 2...)
      final children = node._children;
      for (var i = children.length - 1; i >= 0; i--) {
        stack.add(children[i]);
      }
    }
  }

  ///后序遍历中只支持stop ，不支持skipChildren和Continue
  void visitAfter(VisitResult Function(TreeNode<T> node) visitor) {
    if (_children.isEmpty) {
      visitor(this);
      return;
    }
    final stack = <_StackFrame<T>>[_StackFrame(this)];
    while (stack.isNotEmpty) {
      final frame = stack.last;
      final node = frame.node;

      if (frame.childIndex < node._children.length) {
        final child = node._children[frame.childIndex];
        frame.childIndex++;
        stack.add(_StackFrame(child));
      } else {
        stack.removeLast();
        final res = visitor(node);
        if (res == VisitResult.stop) {
          return;
        }
      }
    }
  }

  List<TreeNode<T>> findWhere(
    bool Function(TreeNode<T>) where, {
    bool iterator = true,
    int limit = -1,
  }) {
    final result = <TreeNode<T>>[];
    final maxCount = limit <= 0 ? 2147483647 : limit;

    if (!iterator) {
      if (where(this)) {
        result.add(this);
        if (result.length >= maxCount) return result;
      }
      for (final child in _children) {
        if (where(child)) {
          result.add(child);
          if (result.length >= maxCount) return result;
        }
      }
      return result;
    }
    visitBefore((node) {
      if (where(node)) {
        result.add(node);
      }
      if (result.length >= maxCount) {
        return VisitResult.stop;
      }
      return VisitResult.continueVisit;
    });
    return result;
  }

  TreeNode<T>? find(bool Function(TreeNode<T>) where) {
    TreeNode<T>? found;
    visitBefore((node) {
      if (where(node)) {
        found = node;
        return VisitResult.stop;
      }
      return VisitResult.continueVisit;
    });
    return found;
  }

  void sum(
    double Function(TreeNode<T> data) valueFun,
    void Function(TreeNode<T> node, double value) setFun, {
    ValueConflictStrategy strategy = ValueConflictStrategy.sum,
    double selfWeight = 0.5,
  }) {
    final valueCache = <TreeNode<T>, double>{};
    visitAfter((e) {
      final own = valueFun(e);
      if (e.isLeaf) {
        valueCache[e] = own;
        setFun(e, own);
        return VisitResult.continueVisit;
      }

      double childrenSum = 0;
      for (final c in e.children) {
        childrenSum += valueCache[c]!;
      }

      double result;
      switch (strategy) {
        case ValueConflictStrategy.sum:
          result = childrenSum;
          break;
        case ValueConflictStrategy.preferSelf:
          result = own;
          break;
        case ValueConflictStrategy.max:
          result = own > childrenSum ? own : childrenSum;
          break;
        case ValueConflictStrategy.min:
          result = own < childrenSum ? own : childrenSum;
          break;
        case ValueConflictStrategy.average:
          result = (own + childrenSum) / 2.0;
          break;
        case ValueConflictStrategy.weighted:
          result = own * selfWeight + childrenSum * (1 - selfWeight);
          break;
      }
      valueCache[e] = result;
      setFun(e, result);
      return VisitResult.continueVisit;
    });
  }

  TreeNode<T> leafLeft() {
    List<TreeNode<T>> children = [];
    TreeNode<T> node = this;
    while ((children = node.children).isNotEmpty) {
      node = children[0];
    }
    return node;
  }

  TreeNode<T> leafRight() {
    List<TreeNode<T>> children = [];
    TreeNode<T> node = this;
    while ((children = node.children).isNotEmpty) {
      node = children[children.length - 1];
    }
    return node;
  }
}

class _StackFrame<T> {
  final TreeNode<T> node;
  int childIndex = 0;

  _StackFrame(this.node);
}

class _NodeDepthPair<T> {
  final TreeNode<T> node;
  final int depth;

  _NodeDepthPair(this.node, this.depth);
}

class _ChildList<T> extends ListBase<TreeNode<T>> {
  final List<TreeNode<T>> _inner = [];

  _ChildList();

  @override
  int get length => _inner.length;

  @override
  set length(int newLength) {
    if (newLength < _inner.length) {
      for (int i = newLength; i < _inner.length; i++) {
        _inner[i]._index = -1;
      }
    }
    _inner.length = newLength;
  }

  @override
  TreeNode<T> operator [](int index) => _inner[index];

  @override
  void operator []=(int index, TreeNode<T> value) {
    TreeNode<T> old = _inner[index];
    old._index = -1;

    _inner[index] = value;
    value._index = index;
  }

  @override
  void add(TreeNode<T> element) {
    element._index = _inner.length;
    _inner.add(element);
  }

  @override
  void addAll(Iterable<TreeNode<T>> iterable) {
    int i = _inner.length;
    for (var element in iterable) {
      element._index = i++;
      _inner.add(element);
    }
  }

  @override
  bool remove(Object? element) {
    if (element is! TreeNode<T>) return false;
    final int idx = element._index;

    if (idx < 0 || idx >= _inner.length || _inner[idx] != element) {
      return false;
    }

    removeAt(idx);
    return true;
  }

  @override
  TreeNode<T> removeAt(int index) {
    final removedNode = _inner.removeAt(index);
    removedNode._index = -1;
    for (int i = index; i < _inner.length; i++) {
      _inner[i]._index = i;
    }
    return removedNode;
  }

  @override
  void clear() {
    for (var node in _inner) {
      node._index = -1;
    }
    _inner.clear();
  }

  @override
  void sort([int Function(TreeNode<T> a, TreeNode<T> b)? compare]) {
    sortWithIndex(
      compare ?? (a, b) => (a.data as Comparable).compareTo(b.data),
    );
  }

  void sortWithIndex(Comparator<TreeNode<T>> compare) {
    if (_inner.length <= 1) return;
    _inner.sort(compare);
    for (int i = 0; i < _inner.length; i++) {
      _inner[i]._index = i;
    }
  }
}

enum ValueConflictStrategy {
  sum, // 使用子节点和
  preferSelf, // 使用自身值
  max, // max(self, sum(children))
  min, // min(self, sum(children))
  average, // (self + sum(children)) / 2
  weighted, // 权重混合
}

extension TreeExt<T> on Tree<T> {
  void sum(
    double Function(TreeNode<T> data) valueFun,
    void Function(TreeNode<T> node, double value) setFun, {
    ValueConflictStrategy strategy = ValueConflictStrategy.sum,
    double selfWeight = 0.5,
  }) {
    _root?.sum(valueFun, setFun, strategy: strategy, selfWeight: selfWeight);
  }

  /// 将当前树从根节点处分裂为两棵新树。
  /// [leftCount] 指定归入左侧树的根节点子节点数量。
  /// 返回一个包含两棵新树的 List [leftTree, rightTree]。
  List<Tree<T>> split(int leftCount) {
    if (_root == null) return [Tree<T>(), Tree<T>()];

    final children = _root!.children.toList();
    if (leftCount < 0 || leftCount > children.length) {
      throw RangeError('leftCount out of range: 0 to ${children.length}');
    }

    Tree<T> leftTree = Tree<T>();
    Tree<T> rightTree = Tree<T>();
    final leftRoot = leftTree._addNode(null, _root!.data);
    final rightRoot = rightTree._addNode(null, _root!.data);

    for (int i = 0; i < children.length; i++) {
      final targetTree = (i < leftCount) ? leftTree : rightTree;
      final targetRoot = (i < leftCount) ? leftRoot : rightRoot;
      _copyBranchTo(children[i], targetTree, targetRoot);
    }

    return [leftTree, rightTree];
  }

  void _copyBranchTo(
    TreeNode<T> sourceNode,
    Tree<T> targetTree,
    TreeNode<T> targetParent,
  ) {
    final copiedNode = targetTree._addNode(targetParent, sourceNode.data);
    for (var child in sourceNode.children) {
      _copyBranchTo(child, targetTree, copiedNode);
    }
  }

  List<Tree<T>> splitBy(bool Function(TreeNode<T>) belongsToLeft) {
    if (_root == null) return [Tree<T>(), Tree<T>()];
    Tree<T> leftTree = Tree<T>();
    Tree<T> rightTree = Tree<T>();
    final leftRoot = leftTree._addNode(null, _root!.data);
    final rightRoot = rightTree._addNode(null, _root!.data);

    for (var child in _root!.children) {
      final useLeft = belongsToLeft(child);
      final targetTree = useLeft ? leftTree : rightTree;
      final targetRoot = useLeft ? leftRoot : rightRoot;
      _copyBranchTo(child, targetTree, targetRoot);
    }
    return [leftTree, rightTree];
  }
}
