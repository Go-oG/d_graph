class _BTreeNode<T> {
  final List<T?> keys;
  final List<_BTreeNode<T>?> children;
  int count = 0;
  bool isLeaf = true;

  _BTreeNode(int maxKeys)
    : keys = List<T?>.filled(maxKeys, null),
      children = List<_BTreeNode<T>?>.filled(maxKeys + 1, null);

  /// 在节点内部使用二分查找
  /// 返回 index: 如果 >= 0，表示找到；如果 < 0，表示 -(插入点) - 1
  int search(T value, Comparator<T> compare) {
    int low = 0;
    int high = count - 1;
    while (low <= high) {
      int mid = (low + high) >>> 1;
      int cmp = compare(keys[mid] as T, value);
      if (cmp < 0) {
        low = mid + 1;
      } else if (cmp > 0) {
        high = mid - 1;
      } else {
        return mid;
      }
    }
    return -(low + 1);
  }

  @override
  String toString() => 'Node(count: $count, keys: ${keys.sublist(0, count)})';
}

class BTree<T extends Comparable<T>> extends Iterable<T> {
  final int order;
  final int _maxKeys;
  final int _maxChildren;
  final int _minKeys;

  _BTreeNode<T>? _root;
  int _length = 0;

  BTree([this.order = 2])
    : _maxKeys = 2 * order - 1,
      _maxChildren = 2 * order,
      _minKeys = order - 1 {
    if (order < 2) throw ArgumentError("Order must be at least 2");
  }

  @override
  bool get isEmpty => _length == 0;

  @override
  int get length => _length;

  void clear() {
    _root = null;
    _length = 0;
  }

  int _compare(T a, T b) => a.compareTo(b);

  @override
  bool contains(Object? element) {
    if (element is! T) return false;
    _BTreeNode<T>? x = _root;
    while (x != null) {
      int i = x.search(element, _compare);
      if (i >= 0) return true;
      i = -(i + 1);
      if (x.isLeaf) return false;
      x = x.children[i];
    }
    return false;
  }

  bool add(T value) {
    if (_root == null) {
      _root = _BTreeNode<T>(_maxKeys);
      _root!.keys[0] = value;
      _root!.count = 1;
      _length++;
      return true;
    }

    _BTreeNode<T> root = _root!;
    if (root.count == _maxKeys) {
      _BTreeNode<T> s = _BTreeNode<T>(_maxKeys);
      _root = s;
      s.isLeaf = false;
      s.children[0] = root;
      _splitChild(s, 0, root);
      _insertNonFull(s, value);
    } else {
      _insertNonFull(root, value);
    }
    return true;
  }

  void _insertNonFull(_BTreeNode<T> node, T value) {
    _BTreeNode<T>? curr = node;
    while (true) {
      int i = curr!.count - 1;
      if (curr.isLeaf) {
        while (i >= 0 && _compare(curr.keys[i] as T, value) > 0) {
          curr.keys[i + 1] = curr.keys[i];
          i--;
        }
        if (i >= 0 && _compare(curr.keys[i] as T, value) == 0) {
          return;
        }
        curr.keys[i + 1] = value;
        curr.count++;
        _length++;
        return;
      }

      while (i >= 0 && _compare(curr.keys[i] as T, value) > 0) {
        i--;
      }
      i++;
      if (i > 0 && _compare(curr.keys[i - 1] as T, value) == 0) return;
      _BTreeNode<T> child = curr.children[i]!;
      if (child.count == _maxKeys) {
        _splitChild(curr, i, child);
        int cmp = _compare(curr.keys[i] as T, value);
        if (cmp == 0) return;
        if (cmp < 0) {
          curr = curr.children[i + 1];
        } else {
          curr = curr.children[i];
        }
      } else {
        curr = child;
      }
    }
  }

  void _splitChild(_BTreeNode<T> parent, int i, _BTreeNode<T> y) {
    _BTreeNode<T> z = _BTreeNode<T>(_maxKeys);
    z.isLeaf = y.isLeaf;
    z.count = _minKeys;
    List.copyRange(z.keys, 0, y.keys, order, _maxKeys);
    if (!y.isLeaf) {
      List.copyRange(z.children, 0, y.children, order, _maxChildren);
    }

    y.count = _minKeys;
    y.keys.fillRange(order, _maxKeys, null);

    // Shift children right (from the end to avoid overlap issues)
    for (int j = parent.count; j > i; j--) {
      parent.children[j + 1] = parent.children[j];
    }
    parent.children[i + 1] = z;

    // Shift keys right
    for (int j = parent.count - 1; j >= i; j--) {
      parent.keys[j + 1] = parent.keys[j];
    }
    parent.keys[i] = y.keys[order - 1];
    parent.count++;

    y.keys[order - 1] = null;
  }

  bool remove(Object? value) {
    if (value is! T) return false;
    if (_root == null) return false;

    bool found = _delete(_root!, value);
    if (found) {
      _length--;
      if (_root!.count == 0) {
        if (_root!.isLeaf) {
          _root = null;
        } else {
          _root = _root!.children[0];
        }
      }
    }
    return found;
  }

  bool _delete(_BTreeNode<T> node, T key) {
    int idx = node.search(key, _compare);
    if (idx >= 0) {
      if (node.isLeaf) {
        _arrayRemoveAt(node.keys, idx, node.count);
        node.count--;
        return true;
      } else {
        _BTreeNode<T> left = node.children[idx]!;
        _BTreeNode<T> right = node.children[idx + 1]!;

        if (left.count >= order) {
          T pred = _getPredecessor(left);
          node.keys[idx] = pred;
          return _delete(left, pred);
        } else if (right.count >= order) {
          T succ = _getSuccessor(right);
          node.keys[idx] = succ;
          return _delete(right, succ);
        } else {
          _merge(node, idx);
          return _delete(left, key);
        }
      }
    } else {
      if (node.isLeaf) return false;
      idx = -(idx + 1);
      _BTreeNode<T> child = node.children[idx]!;

      if (child.count == _minKeys) {
        _BTreeNode<T>? leftSib = (idx > 0) ? node.children[idx - 1] : null;
        _BTreeNode<T>? rightSib = (idx < node.count)
            ? node.children[idx + 1]
            : null;

        if (leftSib != null && leftSib.count >= order) {
          _borrowFromLeft(node, idx, child, leftSib);
        } else if (rightSib != null && rightSib.count >= order) {
          _borrowFromRight(node, idx, child, rightSib);
        } else {
          if (leftSib != null) {
            _merge(node, idx - 1);
            child = leftSib;
          } else {
            _merge(node, idx);
            child = node.children[idx]!;
          }
        }
      }
      return _delete(child, key);
    }
  }

  void _arrayRemoveAt(List<T?> list, int index, int length) {
    List.copyRange(list, index, list, index + 1, length);
    list[length - 1] = null;
  }

  void _merge(_BTreeNode<T> parent, int idx) {
    _BTreeNode<T> left = parent.children[idx]!;
    _BTreeNode<T> right = parent.children[idx + 1]!;
    T median = parent.keys[idx]!;
    left.keys[left.count] = median;
    List.copyRange(left.keys, left.count + 1, right.keys, 0, right.count);

    if (!left.isLeaf) {
      List.copyRange(
        left.children,
        left.count + 1,
        right.children,
        0,
        right.count + 1,
      );
    }

    left.count += right.count + 1;
    _arrayRemoveAt(parent.keys, idx, parent.count);
    List.copyRange(
      parent.children,
      idx + 1,
      parent.children,
      idx + 2,
      parent.count + 1,
    );
    parent.children[parent.count] = null;
    parent.keys[parent.count - 1] = null;
    parent.count--;
  }

  void _borrowFromLeft(
    _BTreeNode<T> parent,
    int idx,
    _BTreeNode<T> child,
    _BTreeNode<T> left,
  ) {
    List.copyRange(child.keys, 1, child.keys, 0, child.count);
    if (!child.isLeaf) {
      List.copyRange(child.children, 1, child.children, 0, child.count + 1);
    }

    child.keys[0] = parent.keys[idx - 1];
    parent.keys[idx - 1] = left.keys[left.count - 1];

    if (!left.isLeaf) {
      child.children[0] = left.children[left.count];
      left.children[left.count] = null;
    }

    left.keys[left.count - 1] = null;
    child.count++;
    left.count--;
  }

  void _borrowFromRight(
    _BTreeNode<T> parent,
    int idx,
    _BTreeNode<T> child,
    _BTreeNode<T> right,
  ) {
    child.keys[child.count] = parent.keys[idx];
    parent.keys[idx] = right.keys[0];

    if (!right.isLeaf) {
      child.children[child.count + 1] = right.children[0];
    }

    List.copyRange(right.keys, 0, right.keys, 1, right.count);
    if (!right.isLeaf) {
      List.copyRange(right.children, 0, right.children, 1, right.count + 1);
    }
    right.children[right.count] = null;
    right.keys[right.count - 1] = null;

    child.count++;
    right.count--;
  }

  T _getPredecessor(_BTreeNode<T> node) {
    while (!node.isLeaf) {
      node = node.children[node.count]!;
    }
    return node.keys[node.count - 1]!;
  }

  T _getSuccessor(_BTreeNode<T> node) {
    while (!node.isLeaf) {
      node = node.children[0]!;
    }
    return node.keys[0]!;
  }

  @override
  Iterator<T> get iterator => _BTreeIterator(_root);

  bool validate() => _validateNode(_root, null, null);

  bool _validateNode(_BTreeNode<T>? node, T? min, T? max) {
    if (node == null) return true;

    if (node != _root) {
      if (node.count < _minKeys || node.count > _maxKeys) return false;
    }

    for (int i = 0; i < node.count; i++) {
      final k = node.keys[i]!;
      if (min != null && _compare(k, min) <= 0) return false;
      if (max != null && _compare(k, max) >= 0) return false;
    }

    if (!node.isLeaf) {
      for (int i = 0; i <= node.count; i++) {
        final left = i == 0 ? min : node.keys[i - 1];
        final right = i == node.count ? max : node.keys[i];
        if (!_validateNode(node.children[i], left, right)) return false;
      }
    }
    return true;
  }
}

class _BTreeIterator<T> implements Iterator<T> {
  final List<_BTreeNode<T>> nodeStack = [];
  final List<int> indexStack = [];
  T? _currentValue;

  _BTreeIterator(_BTreeNode<T>? root) {
    if (root != null) {
      _pushLeftmost(root);
    }
  }

  void _pushLeftmost(_BTreeNode<T> node) {
    _BTreeNode<T>? curr = node;
    while (curr != null) {
      nodeStack.add(curr);
      indexStack.add(0);
      if (curr.isLeaf) break;
      curr = curr.children[0];
    }
  }

  @override
  T get current => _currentValue as T;

  @override
  bool moveNext() {
    if (nodeStack.isEmpty) return false;

    _BTreeNode<T> node = nodeStack.last;
    int idx = indexStack.last;

    if (idx < node.count) {
      _currentValue = node.keys[idx];
      indexStack[indexStack.length - 1] = idx + 1;
      if (!node.isLeaf) {
        _pushLeftmost(node.children[idx + 1]!);
      }
      return true;
    } else {
      nodeStack.removeLast();
      indexStack.removeLast();
      return moveNext();
    }
  }
}
