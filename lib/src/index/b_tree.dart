import 'dart:collection';
import 'dart:core';

import 'package:d_util/d_util.dart';

import 'i_tree.dart';

class BTree<T extends Comparable<T>> extends ITree<T> {
  late final int _minKeySize;

  late final int _minChildrenSize;

  late final int _maxKeySize;

  late final int _maxChildrenSize;

  _Node<T>? _root;
  int _size = 0;

  BTree([int order = 1]) {
    _minKeySize = order;
    _minChildrenSize = _minKeySize + 1;
    _maxKeySize = 2 * _minKeySize;
    _maxChildrenSize = _maxKeySize + 1;
  }

  @override
  bool add(T value) {
    if (_root == null) {
      _root = _Node<T>(null, _maxKeySize, _maxChildrenSize);
      _root!.addKey(value);
    } else {
      _Node<T>? node = _root;
      while (node != null) {
        if (node.numberOfChildren() == 0) {
          node.addKey(value);
          if (node.numberOfKeys() <= _maxKeySize) {
            // A-OK
            break;
          }
          _split(node);
          break;
        }
        T lesser = node.getKey(0);
        if (value.compareTo(lesser) <= 0) {
          node = node.getChild(0);
          continue;
        }

        // Greater
        int numberOfKeys = node.numberOfKeys();
        int last = numberOfKeys - 1;
        T greater = node.getKey(last);
        if (value.compareTo(greater) > 0) {
          node = node.getChild(numberOfKeys);
          continue;
        }

        for (int i = 1; i < node!.numberOfKeys(); i++) {
          T prev = node.getKey(i - 1);
          T next = node.getKey(i);
          if (value.compareTo(prev) > 0 && value.compareTo(next) <= 0) {
            node = node.getChild(i);
            break;
          }
        }
      }
    }
    _size++;
    return true;
  }

  void _split(_Node<T> nodeToSplit) {
    _Node<T> node = nodeToSplit;
    int numberOfKeys = node.numberOfKeys();
    int medianIndex = numberOfKeys ~/ 2;
    T medianValue = node.getKey(medianIndex);

    _Node<T> left = _Node<T>(null, _maxKeySize, _maxChildrenSize);
    for (int i = 0; i < medianIndex; i++) {
      left.addKey(node.getKey(i));
    }
    if (node.numberOfChildren() > 0) {
      for (int j = 0; j <= medianIndex; j++) {
        _Node<T> c = node.getChild(j)!;
        left.addChild(c);
      }
    }

    _Node<T> right = _Node<T>(null, _maxKeySize, _maxChildrenSize);
    for (int i = medianIndex + 1; i < numberOfKeys; i++) {
      right.addKey(node.getKey(i));
    }
    if (node.numberOfChildren() > 0) {
      for (int j = medianIndex + 1; j < node.numberOfChildren(); j++) {
        _Node<T> c = node.getChild(j)!;
        right.addChild(c);
      }
    }

    if (node.parent == null) {
      _Node<T> newRoot = _Node<T>(null, _maxKeySize, _maxChildrenSize);
      newRoot.addKey(medianValue);
      node.parent = newRoot;
      _root = newRoot;
      node = _root!;
      node.addChild(left);
      node.addChild(right);
    } else {
      _Node<T> parent = node.parent!;
      parent.addKey(medianValue);
      parent.removeChild(node);
      parent.addChild(left);
      parent.addChild(right);

      if (parent.numberOfKeys() > _maxKeySize) _split(parent);
    }
  }

  @override
  T? remove(T value) {
    T? removed;
    _Node<T>? node = _getNode(value)!;
    removed = _remove(value, node);
    return removed;
  }

  T? _remove(T value, _Node<T>? node) {
    if (node == null) return null;

    T? removed;
    int index = node.indexOf(value);
    removed = node.removeKey(value);
    if (node.numberOfChildren() == 0) {
      // leaf node
      if (node.parent != null && node.numberOfKeys() < _minKeySize) {
        _combined(node);
      } else if (node.parent == null && node.numberOfKeys() == 0) {
        // Removing root node with no keys or children
        _root = null;
      }
    } else {
      // internal node
      _Node<T> lesser = node.getChild(index)!;
      _Node<T> greatest = _getGreatestNode(lesser);
      T replaceValue = _removeGreatestValue(greatest)!;
      node.addKey(replaceValue);
      if (greatest.parent != null && greatest.numberOfKeys() < _minKeySize) {
        _combined(greatest);
      }
      if (greatest.numberOfChildren() > _maxChildrenSize) {
        _split(greatest);
      }
    }

    _size--;

    return removed;
  }

  T? _removeGreatestValue(_Node<T> node) {
    T? value;
    if (node.numberOfKeys() > 0) {
      value = node.removeKey2(node.numberOfKeys() - 1);
    }
    return value;
  }

  @override
  void clear() {
    _root = null;
    _size = 0;
  }

  @override
  bool contains(T value) {
    _Node<T>? node = _getNode(value);
    return (node != null);
  }

  _Node<T>? _getNode(T value) {
    _Node<T>? node = _root;
    while (node != null) {
      T lesser = node.getKey(0);
      if (value.compareTo(lesser) < 0) {
        if (node.numberOfChildren() > 0)
          node = node.getChild(0);
        else
          node = null;
        continue;
      }

      int numberOfKeys = node.numberOfKeys();
      int last = numberOfKeys - 1;
      T greater = node.getKey(last);
      if (value.compareTo(greater) > 0) {
        if (node.numberOfChildren() > numberOfKeys)
          node = node.getChild(numberOfKeys);
        else
          node = null;
        continue;
      }
      for (int i = 0; i < numberOfKeys; i++) {
        T currentValue = node!.getKey(i);
        if (currentValue.compareTo(value) == 0) {
          return node;
        }
        int next = i + 1;
        if (next <= last) {
          T nextValue = node.getKey(next);
          if (currentValue.compareTo(value) < 0 && nextValue.compareTo(value) > 0) {
            if (next < node.numberOfChildren()) {
              node = node.getChild(next);
              break;
            }
            return null;
          }
        }
      }
    }
    return null;
  }

  _Node<T> _getGreatestNode(_Node<T> nodeToGet) {
    _Node<T> node = nodeToGet;
    while (node.numberOfChildren() > 0) {
      node = node.getChild(node.numberOfChildren() - 1)!;
    }
    return node;
  }

  bool _combined(_Node<T> node) {
    _Node<T> parent = node.parent!;
    int index = parent.indexOf2(node);
    int indexOfLeftNeighbor = index - 1;
    int indexOfRightNeighbor = index + 1;

    _Node<T>? rightNeighbor;
    int rightNeighborSize = -_minChildrenSize;
    if (indexOfRightNeighbor < parent.numberOfChildren()) {
      rightNeighbor = parent.getChild(indexOfRightNeighbor);
      rightNeighborSize = rightNeighbor!.numberOfKeys();
    }

    if (rightNeighbor != null && rightNeighborSize > _minKeySize) {
      // Try to borrow from right neighbor
      T removeValue = rightNeighbor.getKey(0);
      int prev = _getIndexOfPreviousValue(parent, removeValue);
      T parentValue = parent.removeKey2(prev)!;
      T neighborValue = rightNeighbor.removeKey2(0)!;
      node.addKey(parentValue);
      parent.addKey(neighborValue);
      if (rightNeighbor.numberOfChildren() > 0) {
        node.addChild(rightNeighbor.removeChild2(0)!);
      }
    } else {
      _Node<T>? leftNeighbor;
      int leftNeighborSize = -_minChildrenSize;
      if (indexOfLeftNeighbor >= 0) {
        leftNeighbor = parent.getChild(indexOfLeftNeighbor);
        leftNeighborSize = leftNeighbor!.numberOfKeys();
      }
      if (leftNeighbor != null && leftNeighborSize > _minKeySize) {
        T removeValue = leftNeighbor.getKey(leftNeighbor.numberOfKeys() - 1);
        int prev = _getIndexOfNextValue(parent, removeValue);
        T parentValue = parent.removeKey2(prev)!;
        T neighborValue = leftNeighbor.removeKey2(leftNeighbor.numberOfKeys() - 1)!;
        node.addKey(parentValue);
        parent.addKey(neighborValue);
        if (leftNeighbor.numberOfChildren() > 0) {
          node.addChild(leftNeighbor.removeChild2(leftNeighbor.numberOfChildren() - 1)!);
        }
      } else if (rightNeighbor != null && parent.numberOfKeys() > 0) {
        T removeValue = rightNeighbor.getKey(0);
        int prev = _getIndexOfPreviousValue(parent, removeValue);
        T parentValue = parent.removeKey2(prev)!;
        parent.removeChild(rightNeighbor);
        node.addKey(parentValue);
        for (int i = 0; i < rightNeighbor._keysSize; i++) {
          T v = rightNeighbor.getKey(i);
          node.addKey(v);
        }
        for (int i = 0; i < rightNeighbor._childrenSize; i++) {
          _Node<T> c = rightNeighbor.getChild(i)!;
          node.addChild(c);
        }

        if (parent.parent != null && parent.numberOfKeys() < _minKeySize) {
          // removing key made parent too small, combined up tree
          _combined(parent);
        } else if (parent.numberOfKeys() == 0) {
          // parent no longer has keys, make this node the new root
          // which decreases the height of the tree
          node.parent = null;
          _root = node;
        }
      } else if (leftNeighbor != null && parent.numberOfKeys() > 0) {
        // Can't borrow from neighbors, try to combined with left neighbor
        T removeValue = leftNeighbor.getKey(leftNeighbor.numberOfKeys() - 1);
        int prev = _getIndexOfNextValue(parent, removeValue);
        T parentValue = parent.removeKey2(prev)!;
        parent.removeChild(leftNeighbor);
        node.addKey(parentValue);
        for (int i = 0; i < leftNeighbor._keysSize; i++) {
          T v = leftNeighbor.getKey(i);
          node.addKey(v);
        }
        for (int i = 0; i < leftNeighbor._childrenSize; i++) {
          _Node<T> c = leftNeighbor.getChild(i)!;
          node.addChild(c);
        }

        if (parent.parent != null && parent.numberOfKeys() < _minKeySize) {
          _combined(parent);
        } else if (parent.numberOfKeys() == 0) {
          node.parent = null;
          _root = node;
        }
      }
    }
    return true;
  }

  int _getIndexOfPreviousValue(_Node<T> node, T value) {
    for (int i = 1; i < node.numberOfKeys(); i++) {
      T t = node.getKey(i);
      if (t.compareTo(value) >= 0) {
        return i - 1;
      }
    }
    return node.numberOfKeys() - 1;
  }

  int _getIndexOfNextValue(_Node<T> node, T value) {
    for (int i = 0; i < node.numberOfKeys(); i++) {
      T t = node.getKey(i);
      if (t.compareTo(value) >= 0) {
        return i;
      }
    }
    return node.numberOfKeys() - 1;
  }

  @override
  int get size {
    return _size;
  }

  @override
  bool validate() {
    if (_root == null) return true;
    return _validateNode(_root!);
  }

  bool _validateNode(_Node<T> node) {
    int keySize = node.numberOfKeys();
    if (keySize > 1) {
      for (int i = 1; i < keySize; i++) {
        T p = node.getKey(i - 1);
        T n = node.getKey(i);
        if (p.compareTo(n) > 0) {
          return false;
        }
      }
    }
    int childrenSize = node.numberOfChildren();
    if (node.parent == null) {
      if (keySize > _maxKeySize) {
        return false;
      } else if (childrenSize == 0) {
        return true;
      } else if (childrenSize < 2) {
        return false;
      } else if (childrenSize > _maxChildrenSize) {
        return false;
      }
    } else {
      if (keySize < _minKeySize) {
        return false;
      } else if (keySize > _maxKeySize) {
        return false;
      } else if (childrenSize == 0) {
        return true;
      } else if (keySize != (childrenSize - 1)) {
        return false;
      } else if (childrenSize < _minChildrenSize) {
        return false;
      } else if (childrenSize > _maxChildrenSize) {
        return false;
      }
    }

    _Node<T> first = node.getChild(0)!;
    if (first.getKey(first.numberOfKeys() - 1).compareTo(node.getKey(0)) > 0) {
      return false;
    }

    _Node<T> last = node.getChild(node.numberOfChildren() - 1)!;
    if (last.getKey(0).compareTo(node.getKey(node.numberOfKeys() - 1)) < 0) {
      return false;
    }

    for (int i = 1; i < node.numberOfKeys(); i++) {
      T p = node.getKey(i - 1);
      T n = node.getKey(i);
      _Node<T> c = node.getChild(i)!;
      if (p.compareTo(c.getKey(0)) > 0) {
        return false;
      }
      if (n.compareTo(c.getKey(c.numberOfKeys() - 1)) < 0) {
        return false;
      }
    }

    for (int i = 0; i < node._childrenSize; i++) {
      _Node<T> c = node.getChild(i)!;
      if (!_validateNode(c)) {
        return false;
      }
    }
    return true;
  }

  @override
  Iterable<T> toCollection() {
    return JavaCompatibleBTree<T>(this);
  }
}

class _Node<T extends Comparable<T>> {
  late Array<T?> keys;

  int _keysSize = 0;

  late Array<_Node<T>?> children;

  int _childrenSize = 0;

  final Comparator<_Node<T>?> _comparator = (a, b) {
    return a!.getKey(0).compareTo(b!.getKey(0));
  };

  _Node<T>? parent;

  _Node(this.parent, int maxKeySize, int maxChildrenSize) {
    keys = Array(maxKeySize + 1);
    this._keysSize = 0;
    children = Array(maxChildrenSize + 1);
    _childrenSize = 0;
  }

  T getKey(int index) {
    return keys[index]!;
  }

  int indexOf(T value) {
    for (int i = 0; i < _keysSize; i++) {
      if (keys[i] == value) return i;
    }
    return -1;
  }

  void addKey(T value) {
    keys[_keysSize++] = value;
    keys.sort();
  }

  T? removeKey(T value) {
    T? removed;
    bool found = false;
    if (_keysSize == 0) return null;
    for (int i = 0; i < _keysSize; i++) {
      if (keys[i] == value) {
        found = true;
        removed = keys[i];
      } else if (found) {
        keys[i - 1] = keys[i];
      }
    }
    if (found) {
      _keysSize--;
      keys[_keysSize] = null;
    }
    return removed;
  }

  T? removeKey2(int index) {
    if (index >= _keysSize) {
      return null;
    }
    T value = keys[index]!;
    for (int i = index + 1; i < _keysSize; i++) {
      keys[i - 1] = keys[i];
    }
    _keysSize--;
    keys[_keysSize] = null;
    return value;
  }

  int numberOfKeys() {
    return _keysSize;
  }

  _Node<T>? getChild(int index) {
    if (index >= _childrenSize) {
      return null;
    }
    return children[index];
  }

  int indexOf2(_Node<T> child) {
    for (int i = 0; i < _childrenSize; i++) {
      if (children[i] == child) {
        return i;
      }
    }
    return -1;
  }

  bool addChild(_Node<T> child) {
    child.parent = this;
    children[_childrenSize++] = child;
    Array.sortRange(children, 0, _childrenSize, _comparator);
    return true;
  }

  bool removeChild(_Node<T> child) {
    bool found = false;
    if (_childrenSize == 0) {
      return found;
    }
    for (int i = 0; i < _childrenSize; i++) {
      if (children[i] == child) {
        found = true;
      } else if (found) {
        children[i - 1] = children[i];
      }
    }
    if (found) {
      _childrenSize--;
      children[_childrenSize] = null;
    }
    return found;
  }

  _Node<T>? removeChild2(int index) {
    if (index >= _childrenSize) {
      return null;
    }
    _Node<T> value = children[index]!;
    children[index] = null;
    for (int i = index + 1; i < _childrenSize; i++) {
      children[i - 1] = children[i];
    }
    _childrenSize--;
    children[_childrenSize] = null;
    return value;
  }

  int numberOfChildren() {
    return _childrenSize;
  }
}

class JavaCompatibleBTree<T extends Comparable<T>> extends Iterable<T> {
  BTree<T> tree;

  JavaCompatibleBTree(this.tree);

  bool add(T value) {
    return tree.add(value);
  }

  bool remove(Object value) {
    if (value is! T) {
      return false;
    }
    return (tree.remove(value) != null);
  }

  @override
  bool contains(Object? element) {
    if (element is! T) {
      return false;
    }
    return tree.contains(element);
  }

  int get size {
    return tree.size;
  }

  @override
  Iterator<T> get iterator {
    return _BTreeIterator<T>(this.tree);
  }
}

class _BTreeIterator<C extends Comparable<C>> implements Iterator<C> {
  BTree<C> tree;

  _Node<C>? lastNode;

  C? lastValue;

  int index = 0;

  Queue<_Node<C>> toVisit = DoubleLinkedQueue<_Node<C>>();

  _BTreeIterator(this.tree) {
    if (tree._root != null && tree._root!._keysSize > 0) {
      toVisit.add(tree._root!);
    }
  }

  bool hasNext() {
    if ((lastNode != null && index < lastNode!._keysSize) || (toVisit.isNotEmpty)) return true;
    return false;
  }

  C? next() {
    if (lastNode != null && (index < lastNode!._keysSize)) {
      lastValue = lastNode!.getKey(index++);
      return lastValue!;
    }
    while (toVisit.isNotEmpty) {
      _Node<C> n = toVisit.removeFirst();
      for (int i = 0; i < n._childrenSize; i++) {
        toVisit.add(n.getChild(i)!);
      }
      index = 0;
      lastNode = n;
      lastValue = lastNode!.getKey(index++);
      return lastValue;
    }
    return null;
  }

  void remove() {
    if (lastNode != null && lastValue != null) {
      // On remove, reset the iterator (very inefficient, I know)
      tree._remove(lastValue!, lastNode!);

      lastNode = null;
      lastValue = null;
      index = 0;
      toVisit.clear();
      if (tree._root != null && tree._root!._keysSize > 0) {
        toVisit.add(tree._root!);
      }
    }
  }

  @override
  C get current {
    return next()!;
  }

  @override
  bool moveNext() {
    if (hasNext()) {
      return true;
    }
    return false;
  }
}
