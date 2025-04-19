import 'dart:math';

import 'package:d_util/d_util.dart';
import 'package:quiver/collection.dart';

class Tree<T> {
  TreeNode<T>? _root;

  ///双向映射
  final BiMap<T, TreeNode<T>> _nodeMap = BiMap();

  ///存储所有的叶子结点
  final BiMap<T, TreeNode<T>> _leafMap = BiMap();

  TreeNode<T>? get root => _root;

  TreeNode<T> add(T? parent, T value) {
    TreeNode<T>? parentNode;
    if (parent != null) {
      parentNode = _nodeMap.get2(parent, () => TreeNode(null, parent));
    }

    final node = TreeNode(parentNode, value);
    _nodeMap[value] = node;
    _leafMap[value] = node;
    parentNode?.add(node);
    final root = _root;
    if (root == null) {
      _root = parentNode ?? node;
    }
    if (parentNode != null) {
      _leafMap.remove(parentNode.data);
    }
    return node;
  }

  void addAll(T? parent, Iterable<T> values) {
    for (var item in values) {
      add(parent, item);
    }
  }

  ///当删除该节点时会导致节点的子节点也会被删除
  TreeNode<T>? remove(T value) {
    final node = _nodeMap.remove(value);
    if (node == null) {
      return null;
    }
    if (node.isLeaf) {
      _leafMap.remove(node.data);
    }
    final parent = node.parent;
    if (parent != null) {
      parent.remove(node);
      if (parent.isLeaf) {
        _leafMap[parent.data] = parent;
      }
    }
    return node;
  }

  void removeAll(Iterable<T> values) {
    for (var item in values) {
      remove(item);
    }
  }

  void clear() {
    _root = null;
    _nodeMap.clear();
    _leafMap.clear();
  }

  TreeNode<T>? get(T value) {
    return _nodeMap[value];
  }

  TreeNode<T>? getParent(T value) {
    return _nodeMap[value]?.parent;
  }

  void sort(Fun3<TreeNode<T>, TreeNode<T>, int> sortFun) {
    _root?.sort(sortFun, true);
  }

  ///返回从当前节点到指定节点的最短路径
  List<TreeNode<T>> findPath(T source, T target) {
    TreeNode<T>? start = get(source);
    TreeNode<T>? end = get(target);
    if (start == null || end == null) {
      return [];
    }
    return start.findPath(end);
  }

  ///返回 节点 a,b的最小公共祖先
  TreeNode<T>? minCommonAncestor(T aValue, T bValue) {
    if (aValue == bValue) return get(aValue);
    var a = get(aValue);
    var b = get(bValue);
    if (a == null || b == null) {
      return null;
    }
    var aNodes = a.ancestors();
    var bNodes = b.ancestors();
    TreeNode<T>? c;
    a = aNodes.removeLast();
    b = bNodes.removeLast();
    while (a == b) {
      c = a;
      a = aNodes.removeLast();
      b = bNodes.removeLast();
    }
    return c;
  }

  int get maxHeight {
    return maxDeep;
  }

  int get maxDeep {
    int c = -1;
    for (var item in _leafMap.keys) {
      var t = getDeep(item);
      if (t > c) {
        t = c;
      }
    }
    return c;
  }

  TreeNode<T>? get maxDeepNode {
    int c = -1;
    TreeNode<T>? result;
    for (var item in _leafMap.entries) {
      var t = getDeep(item.key);
      if (t > c) {
        t = c;
        result = item.value;
      }
    }
    return result;
  }

  ///节点的深度(从0开始)
  int getDeep(T value) {
    TreeNode<T>? node = _nodeMap[value];
    if (node == null) {
      return -1;
    }
    int c = -1;
    while (node != null) {
      c++;
      node = node.parent;
    }
    return c;
  }

  ///节点的高度(从0开始)
  int getHeight(T value) {
    TreeNode<T>? node = _nodeMap[value];
    if (node == null) {
      return -1;
    }
    if (node.isLeaf) {
      return 0;
    }

    int c = -1;
    List<TreeNode<T>> childList = List.from(node.children);
    while (childList.isNotEmpty) {
      List<TreeNode<T>> nextList = [];
      for (var item in childList) {
        nextList.addAll(item.children);
      }
      childList = nextList;
      c++;
    }
    return c;
  }

  bool contains(T? value) {
    if (value == null) {
      return false;
    }
    return _nodeMap.containsKey(value);
  }

  /// 返回其所有的叶子结点
  Iterable<TreeNode<T>> get leaves {
    return _leafMap.values;
  }

  void bfsEach(Fun3<TreeNode<T>, int, bool> call) {
    var r = _root;
    if (r == null) {
      return;
    }
    int i = 0;
    List<TreeNode<T>> list = [r];
    while (list.isNotEmpty) {
      var f = list.removeAt(0);
      if (call(f, i)) {
        break;
      }
      i++;
    }
  }

  void each(TreeEachFun<T> callback) {
    _root?.each(callback);
  }

  void eachBefore(TreeEachFun<T> callback) {
    _root?.eachBefore(callback);
  }

  void eachAfter(TreeEachFun<T> callback) {
    _root?.eachAfter(callback);
  }

  TreeNode<T>? find(TreeEachFun<T> where) {
    return IterableExt(findWhere(where)).firstOrNull;
  }

  List<TreeNode<T>> findWhere(TreeEachFun<T> where) {
    List<TreeNode<T>> list = [];
    for (var item in _nodeMap.entries) {
      if (where.call(item.value)) {
        list.add(item.value);
      }
    }
    return list;
  }
}

class TreeNode<T> {
  T data;
  TreeNode<T>? parent;
  List<TreeNode<T>> _childrenList = [];
  bool _expand = true;
  int _deep = -1;
  int _height = -1;

  double value = 0;

  TreeNode(this.parent, this.data, [Iterable<TreeNode<T>>? children]) {
    if (children != null) {
      _childrenList.addAll(children);
    }
  }

  List<TreeNode<T>> get children {
    return _childrenList;
  }

  List<TreeNode<T>> get childrenReverse => List.from(_childrenList.reversed);

  bool get hasChild {
    return _childrenList.isNotEmpty;
  }

  bool get notChild {
    return _childrenList.isEmpty;
  }

  int get childCount => _childrenList.length;

  bool get isLeaf => notChild;

  int get treeHeight => _height;

  int get deep => _deep;

  /// 自身在父节点中的索引 如果为-1表示没有父节点
  int get inParentIndex {
    var p = parent;
    if (p == null) {
      return -1;
    }
    return p._childrenList.indexOf(this);
  }

  ///计算后代节点数
  ///后代节点数(包括子孙节点数)
  int _descendantCount = -1;

  int get descendantCount {
    if (_descendantCount < 0) {
      computeDescendantCount();
    }
    return _descendantCount;
  }

  TreeNode<T> get root {
    TreeNode<T>? tmpRoot = this;
    while (tmpRoot != null) {
      if (tmpRoot.parent == null) {
        return tmpRoot;
      }
      tmpRoot = tmpRoot.parent;
    }

    throw "tree status error";
  }

  TreeNode<T> childAt(int index) {
    return _childrenList[index];
  }

  TreeNode<T> get firstChild {
    return childAt(0);
  }

  TreeNode<T> get lastChild {
    return childAt(_childrenList.length - 1);
  }

  void add(TreeNode<T> node) {
    if (node.parent != null && node.parent != this) {
      throw '当前要添加的节点其父节点不为空';
    }
    node.parent = this;
    if (_childrenList.contains(node)) {
      return;
    }
    _childrenList.add(node);
    _descendantCount = -1;
  }

  void addAll(Iterable<TreeNode<T>> nodes) {
    for (var node in nodes) {
      add(node);
    }
  }

  void remove(TreeNode<T> node, [bool resetParent = true]) {
    if (_childrenList.remove(node)) {
      _descendantCount = -1;
      if (resetParent) {
        node.parent = null;
      }
    }
  }

  TreeNode<T> removeFirst([bool resetParent = true]) {
    return removeAt(0, resetParent: resetParent);
  }

  TreeNode<T> removeLast([bool resetParent = true]) {
    return removeAt(_childrenList.length - 1, resetParent: resetParent);
  }

  TreeNode<T> removeAt(int i, {bool resetParent = true}) {
    var node = _childrenList.removeAt(i);
    if (resetParent) {
      node.parent = null;
    }
    _descendantCount = -1;
    return node;
  }

  void removeChild(bool Function(TreeNode<T>) where, [bool resetParent = true]) {
    Set<TreeNode> removeSet = <TreeNode>{};
    _childrenList.removeWhere((e) {
      if (where.call(e)) {
        removeSet.add(e);
        return true;
      }
      return false;
    });
    if (resetParent) {
      for (var item in removeSet) {
        item.parent = null;
      }
    }
  }

  void removeWhere(bool Function(TreeNode<T>) where, {bool iterator = false, bool resetParent = true}) {
    List<TreeNode<T>> nodeList = [this];
    while (nodeList.isNotEmpty) {
      TreeNode<T> first = nodeList.removeAt(0);
      first.removeChild(where, resetParent);
      if (iterator) {
        nodeList.addAll(first.children);
      }
    }
  }

  void clear() {
    var cs = _childrenList;
    _childrenList = [];
    for (var c in cs) {
      c.parent = null;
    }
  }

  /// 返回其所有的叶子结点
  List<TreeNode<T>> leaves() {
    List<TreeNode<T>> resultList = [];
    eachBefore((TreeNode<T> a) {
      if (a.notChild) {
        resultList.add(a);
      }
      return false;
    });
    return resultList;
  }

  /// 返回其所有后代节点
  List<TreeNode<T>> descendants() {
    return iterator();
  }

  ///返回其后代所有节点(按照拓扑结构)
  List<TreeNode<T>> iterator() {
    List<TreeNode<T>> resultList = [];
    TreeNode<T>? node = this;
    List<TreeNode<T>> current = [];
    List<TreeNode<T>> next = [node];
    List<TreeNode<T>> children = [];
    do {
      current = List.from(next.reversed);
      next = [];
      while (current.isNotEmpty) {
        node = current.removeLast();
        resultList.add(node);
        children = node.children;
        if (children.isNotEmpty) {
          for (int i = 0, n = children.length; i < n; ++i) {
            next.add(children[i]);
          }
        }
      }
    } while (next.isNotEmpty);

    return resultList;
  }

  /// 返回从当前节点开始的祖先节点
  List<TreeNode<T>> ancestors() {
    List<TreeNode<T>> resultList = [this];
    TreeNode<T>? node = this;
    while ((node = node?.parent) != null) {
      resultList.add(node!);
    }
    return resultList;
  }

  ///层序遍历
  List<List<TreeNode<T>>> levelEach([int maxLevel = -1]) {
    List<List<TreeNode<T>>> resultList = [];
    List<TreeNode<T>> list = [this];
    List<TreeNode<T>> next = [];
    if (maxLevel <= 0) {
      maxLevel = 2 ^ 16;
    }
    while (list.isNotEmpty && maxLevel > 0) {
      resultList.add(list);
      for (var c in list) {
        next.addAll(c.children);
      }
      list = next;
      next = [];
      maxLevel--;
    }
    return resultList;
  }

  void bfsEach(void Function(TreeNode<T>, int) f, [int maxLevel = -1]) {
    if (maxLevel <= 0) {
      maxLevel = 2 ^ 53;
    }
    List<Pair<TreeNode<T>, int>> queue = [Pair(this, 0)];
    while (queue.isNotEmpty) {
      var tmp = queue.removeAt(0);
      var node = tmp.first;
      int depth = tmp.second;
      f.call(node, depth);
      if (depth < maxLevel) {
        for (var child in node.children) {
          queue.add(Pair(child, depth + 1));
        }
      }
    }
  }

  TreeNode<T> each(TreeEachFun<T> callback) {
    for (var node in iterator()) {
      if (callback.call(node)) {
        break;
      }
    }
    return this;
  }

  ///先序遍历
  TreeNode<T> eachBefore(TreeEachFun<T> callback) {
    List<TreeNode<T>> nodes = [this];
    List<TreeNode<T>> children;
    while (nodes.isNotEmpty) {
      TreeNode<T> node = nodes.removeLast();
      if (callback.call(node)) {
        break;
      }
      children = node._childrenList;
      nodes.addAll(children.reversed);
    }
    return this;
  }

  ///后序遍历
  TreeNode<T> eachAfter(TreeEachFun<T> callback) {
    List<TreeNode<T>> nodes = [this];
    List<TreeNode<T>> next = [];
    List<TreeNode<T>> children;
    while (nodes.isNotEmpty) {
      TreeNode<T> node = nodes.removeAt(nodes.length - 1);
      next.add(node);
      children = node._childrenList;
      nodes.addAll(children);
    }
    while (next.isNotEmpty) {
      TreeNode<T> node = next.removeAt(next.length - 1);
      if (callback.call(node)) {
        break;
      }
    }
    return this;
  }

  ///在子节点中查找对应节点
  TreeNode<T>? findInChildren(TreeEachFun<T> where) {
    return IterableExt(findWhere(where, iterator: false, limit: 1)).firstOrNull;
  }

  TreeNode<T>? find(TreeEachFun<T> where) {
    return IterableExt(findWhere(where, iterator: true)).firstOrNull;
  }

  List<TreeNode<T>> findWhere(TreeEachFun<T> where, {bool iterator = true, int limit = -1}) {
    if (limit <= 0) {
      limit = 2 << 53;
    }

    List<TreeNode<T>> list = [];
    if (!iterator) {
      for (var item in _childrenList) {
        if (where.call(item)) {
          list.add(item);
        }
        if (list.length >= limit) {
          break;
        }
      }
      return list;
    }

    each((node) {
      if (where.call(node)) {
        list.add(node);
      }
      if (list.length >= limit) {
        return true;
      }
      return false;
    });
    return list;
  }

  /// 从当前节点开始查找深度等于给定深度的节点
  /// 广度优先遍历 [only]==true 只返回对应层次的,否则返回<=
  List<TreeNode<T>> depthNode(int depth, [bool only = true]) {
    if (_deep > depth) {
      return [];
    }
    List<TreeNode<T>> resultList = [];
    List<TreeNode<T>> tmp = [this];
    List<TreeNode<T>> next = [];
    while (tmp.isNotEmpty) {
      for (var node in tmp) {
        if (only) {
          if (node._deep == depth) {
            resultList.add(node);
          } else {
            next.addAll(node._childrenList);
          }
        } else {
          resultList.add(node);
          next.addAll(node._childrenList);
        }
      }
      tmp = next;
      next = [];
    }
    return resultList;
  }

  ///返回当前节点的后续的所有Link
  List<Link<TreeNode<T>>> links() {
    List<Link<TreeNode<T>>> links = [];
    each((node) {
      if (node != this && node.parent != null) {
        links.add(Link(node.parent!, node));
      }
      return false;
    });
    return links;
  }

  ///返回从当前节点到指定节点的最短路径
  List<TreeNode<T>> findPath(TreeNode<T> target) {
    TreeNode<T>? start = this;
    TreeNode<T>? end = target;
    TreeNode<T>? ancestor = minCommonAncestor(start, end);
    List<TreeNode<T>> nodes = [start];
    while (ancestor != start) {
      start = start?.parent;
      if (start != null) {
        nodes.add(start);
      }
    }
    var k = nodes.length;
    while (end != ancestor) {
      nodes.insert(k, end!);
      end = end.parent;
    }
    return nodes;
  }

  TreeNode<T> sort(Fun3<TreeNode<T>, TreeNode<T>, int> sortFun, [bool iterator = true]) {
    if (iterator) {
      eachBefore((node) {
        if (node.childCount > 1) {
          node._childrenList.sort(sortFun);
        }
        return false;
      });
      return this;
    }
    _childrenList.sort(sortFun);
    return this;
  }

  ///统计并计算一些信息
  ///计算节点value、深度、高度
  void compute({
    Fun3<TreeNode<T>, TreeNode<T>, int>? sortFun,
    bool sortIterator = true,
    bool computeDepth = true,
    int currentDepth = 0,
    int initHeight = 0,
  }) {
    if (sortFun != null) {
      sort(sortFun, sortIterator);
    }
    if (computeDepth) {
      setDeep(currentDepth, true);
      computeHeight(initHeight);
    }
  }

  ///计算当前节点的后代数
  int computeDescendantCount() {
    eachAfter((TreeNode<T> node) {
      int sum = 0;
      List<TreeNode> children = node._childrenList;
      int i = children.length;
      if (i == 0) {
        sum = 1;
      } else {
        while (--i >= 0) {
          sum += children[i]._descendantCount;
        }
      }
      node._descendantCount = sum;
      return false;
    });
    return _descendantCount;
  }

  /// 计算树的高度
  void computeHeight([int initHeight = 0]) {
    List<List<TreeNode<T>>> levelList = [];
    List<TreeNode<T>> tmp = [this];
    List<TreeNode<T>> next = [];
    while (tmp.isNotEmpty) {
      levelList.add(tmp);
      next = [];
      for (var c in tmp) {
        next.addAll(c.children);
      }
      tmp = next;
    }
    int c = levelList.length;
    for (int i = 0; i < c; i++) {
      for (var node in levelList[i]) {
        node._height = c - i - 1;
      }
    }
  }

  ///计算当前节点值
  ///如果给定了回调,那么将使用给定的回调进行值统计
  ///否则直接使用 _value 统计
  TreeNode<T> sum(num Function(TreeNode<T>) valueCallback, [bool throwError = true]) {
    return eachAfter((TreeNode<T> node) {
      num sum = valueCallback(node);
      if (sum.isNaN || sum.isInfinite) {
        if (throwError) {
          throw "Sum is NaN or Infinite";
        }
        sum = 0;
      }
      List<TreeNode> children = node._childrenList;
      int i = children.length;
      while (--i >= 0) {
        sum += children[i].data;
      }
      node.value = sum.toDouble();
      return false;
    });
  }

  ///设置深度
  void setDeep(int deep, [bool iterator = true]) {
    this._deep = deep;
    if (iterator) {
      for (var node in _childrenList) {
        node.setDeep(deep + 1, true);
      }
    }
  }

  void setTreeHeight(int height, [bool iterator = true]) {
    _height = height;
    if (iterator) {
      for (var node in _childrenList) {
        node.setTreeHeight(height - 1, true);
      }
    }
  }

  ///返回当前节点下最左边的叶子节点
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

  int findMaxDeep() {
    int i = 0;
    leaves().forEach((element) {
      i = max(i, element._deep);
    });
    return i;
  }

  ///从复制当前节点及其后代
  ///复制后的节点没有parent
  TreeNode<T> copy(TreeNode<T> Function(TreeNode<T>?, TreeNode<T>) build, [int deep = 0]) {
    return _innerCopy(build, null, deep);
  }

  TreeNode<T> _innerCopy(TreeNode<T> Function(TreeNode<T>?, TreeNode<T>) build, TreeNode<T>? parent, int deep) {
    TreeNode<T> node = build.call(parent, this);
    node.parent = parent;
    node._deep = deep;
    node.data = data;
    node._height = _height;
    node._descendantCount = _descendantCount;
    node._expand = _expand;
    for (var ele in _childrenList) {
      node.add(ele._innerCopy(build, node, deep + 1));
    }
    return node;
  }

  set expand(bool b) {
    _expand = b;
    for (var element in _childrenList) {
      element.expand = b;
    }
  }

  void setExpand(bool e, [bool iterator = true]) {
    _expand = e;
    if (iterator) {
      for (var element in _childrenList) {
        element.setExpand(e, iterator);
      }
    }
  }

  bool get expand => _expand;

  @override
  String toString() {
    return "$runtimeType:\ndeep:$_deep height:$_height\nchildCount:$childCount\n";
  }

  ///返回 节点 a,b的最小公共祖先
  static TreeNode<T>? minCommonAncestor<T>(TreeNode<T> a, TreeNode<T> b) {
    if (a == b) return a;
    var aNodes = a.ancestors();
    var bNodes = b.ancestors();
    TreeNode<T>? c;
    a = aNodes.removeLast();
    b = bNodes.removeLast();
    while (a == b) {
      c = a;
      a = aNodes.removeLast();
      b = bNodes.removeLast();
    }
    return c;
  }
}

typedef TreeEachFun<T> = bool Function(TreeNode<T> node);

typedef Link<T> = Pair<T, T>;
