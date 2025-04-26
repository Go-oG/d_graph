import 'dart:collection';
import 'dart:core';
import 'dart:math';

import 'package:d_util/d_util.dart';

interface class BinaryHeap<T> {
  List<T> getHeap() {
    return [];
  }

  bool add(T value) {
    throw UnimplementedError();
  }

  void clear() {}

  bool contains(T value) {
    throw UnimplementedError();
  }

  T? getHeadValue() {
    throw UnimplementedError();
  }

  T? remove(T value) {
    throw UnimplementedError();
  }

  T? removeHead() {
    throw UnimplementedError();
  }

  int get size => throw UnimplementedError();

  Iterable<T> toCollection() {
    throw UnimplementedError();
  }

  bool validate() {
    throw UnimplementedError();
  }
}

class BinaryHeapArray<T> implements BinaryHeap<T> {
  static const int minSize = 1024;
  late final HeapType type;
  final CompareFun<T> compareFun;

  int _size = 0;
  Array<T> _array = Array(minSize);

  static int _getParentIndex(int index) {
    if (index > 0) {
      return ((index - 1) / 2).floor();
    }
    return Integer.minValue;
  }

  static int _getLeftIndex(int index) {
    return 2 * index + 1;
  }

  static int _getRightIndex(int index) {
    return 2 * index + 2;
  }

  BinaryHeapArray(this.compareFun, [this.type = HeapType.min]) {
    _size = 0;
  }

  @override
  int get size {
    return _size;
  }

  @override
  bool add(T value) {
    if (size >= _array.length) {
      _grow();
    }
    _array[size] = value;

    heapUp(_size++);
    return true;
  }

  @override
  T? remove(T value) {
    if (_array.isEmpty) return null;
    for (int i = 0; i < size; i++) {
      T node = _array[i]!;
      if (node == value) return _remove(i);
    }
    return null;
  }

  T? _remove(int index) {
    if (index < 0 || index >= size) return null;

    T t = _array[index];
    _array[index] = _array[--_size];
    _array[size] = null;

    heapDown(index);

    int shrinkSize = _array.length >> 1;
    if (shrinkSize >= minSize && size < shrinkSize) {
      _shrink();
    }
    return t;
  }

  void heapUp(int idx) {
    int nodeIndex = idx;
    T value = _array[nodeIndex];
    if (value == null) {
      return;
    }

    while (nodeIndex >= 0) {
      int parentIndex = _getParentIndex(nodeIndex);
      if (parentIndex < 0) {
        return;
      }

      T parent = _array[parentIndex];

      if ((type == HeapType.min && compareFun(value, parent) < 0) ||
          (type == HeapType.max && compareFun(value, parent) > 0)) {
        _array[parentIndex] = value;
        _array[nodeIndex] = parent;
      } else {
        return;
      }
      nodeIndex = parentIndex;
    }
  }

  void heapDown(int index) {
    T? value = _array[index];
    if (value == null) {
      return;
    }

    int leftIndex = _getLeftIndex(index);
    int rightIndex = _getRightIndex(index);
    T? left = (leftIndex != Integer.minValue && leftIndex < size) ? _array[leftIndex] : null;
    T? right = (rightIndex != Integer.minValue && rightIndex < size) ? _array[rightIndex] : null;

    if (left == null && right == null) {
      return;
    }
    T? nodeToMove;
    int nodeToMoveIndex = -1;

    if ((type == HeapType.min &&
            left != null &&
            right != null &&
            compareFun(value, left) > 0 &&
            compareFun(value, right) > 0) ||
        (type == HeapType.max &&
            left != null &&
            right != null &&
            compareFun(value, left) < 0 &&
            compareFun(value, right) < 0)) {
      if ((right != null) &&
          ((type == HeapType.min && (compareFun(right, left) < 0)) ||
              ((type == HeapType.max && compareFun(right, left) > 0)))) {
        nodeToMove = right;
        nodeToMoveIndex = rightIndex;
      } else if ((left != null) &&
          ((type == HeapType.min && compareFun(left, right) < 0) ||
              (type == HeapType.max && compareFun(left, right) > 0))) {
        nodeToMove = left;
        nodeToMoveIndex = leftIndex;
      } else {
        nodeToMove = right;
        nodeToMoveIndex = rightIndex;
      }
    } else if ((type == HeapType.min && right != null && compareFun(value, right) > 0) ||
        (type == HeapType.max && right != null && compareFun(value, right) < 0)) {
      nodeToMove = right;
      nodeToMoveIndex = rightIndex;
    } else if ((type == HeapType.min && left != null && compareFun(value, left) > 0) ||
        (type == HeapType.max && left != null && compareFun(value, left) < 0)) {
      nodeToMove = left;
      nodeToMoveIndex = leftIndex;
    }

    if (nodeToMove == null) {
      return;
    }
    _array[nodeToMoveIndex] = value;
    _array[index] = nodeToMove;
    heapDown(nodeToMoveIndex);
  }

  void _grow() {
    int growSize = size + (size << 1);
    Array<T> old = _array.copy();
    _array = Array(growSize);
    _array.setAll(0,old);
  }

  void _shrink() {
    int shrinkSize = _array.length >> 1;
    var old = _array;
    _array = Array(shrinkSize);
    for (var i = 0; i < shrinkSize; i++) {
      _array[i] = old[i];
    }
  }

  @override
  void clear() {
    _size = 0;
  }

  @override
  bool contains(T value) {
    if (_array.isEmpty) return false;
    for (int i = 0; i < size; i++) {
      T t = _array[i];
      if (t == value) return true;
    }
    return false;
  }

  @override
  bool validate() {
    if (_array.isEmpty) return true;
    return _validateNode(0);
  }

  bool _validateNode(int index) {
    T value = _array[index];
    int leftIndex = _getLeftIndex(index);
    int rightIndex = _getRightIndex(index);

    if (rightIndex != Integer.minValue && leftIndex == Integer.minValue) return false;

    if (leftIndex != Integer.minValue && leftIndex < size) {
      T left = _array[leftIndex];
      if ((type == HeapType.min && compareFun(value, left) < 0) ||
          (type == HeapType.max && compareFun(value, left) > 0)) {
        return _validateNode(leftIndex);
      }
      return false;
    }
    if (rightIndex != Integer.minValue && rightIndex < size) {
      T right = _array[rightIndex];
      if ((type == HeapType.min && compareFun(value, right) < 0) ||
          (type == HeapType.max && compareFun(value, right) > 0)) {
        return _validateNode(rightIndex);
      }
      return false;
    }

    return true;
  }

  @override
  List<T> getHeap() {
    Array<T> nodes = Array(size);
    if (_array.isEmpty) return nodes.toList();
    for (int i = 0; i < size; i++) {
      T node = _array[i];
      nodes[i] = node;
    }
    return nodes.toList();
  }

  @override
  T? getHeadValue() {
    if (size == 0 || _array.isEmpty) return null;
    return _array[0];
  }

  @override
  T? removeHead() {
    return remove(getHeadValue()!);
  }

  @override
  Iterable<T> toCollection() {
    return _JavaCompatibleBinaryHeapArray<T>(compareFun, this);
  }
}

class BinaryHeapTree<T> implements BinaryHeap<T> {
  final HeapType type;
  final CompareFun<T> compareFun;
  int _size = 0;
  _Node<T>? _root;

  BinaryHeapTree(this.compareFun, {this.type = HeapType.min}) {
    _root = null;
    _size = 0;
  }

  @override
  int get size => _size;

  static Array<int>? _getDirections(int idx) {
    int index = idx;
    int directionsSize = ((log(index + 1) / log(10)) / (log(2) / log(10)) - 1).toInt();
    Array<int>? directions;
    if (directionsSize > 0) {
      directions = Array(directionsSize);
      int i = directionsSize - 1;
      while (i >= 0) {
        index = (index - 1) ~/ 2;
        directions[i--] = (index > 0 && index % 2 == 0) ? 1 : 0; // 0=left, 1=right
      }
    }
    return directions;
  }

  @override
  bool add(T value) {
    return _add(_Node<T>(null, value));
  }

  bool _add(_Node<T> newNode) {
    if (_root == null) {
      _root = newNode;
      _size++;
      return true;
    }
    _Node<T>? node = _root!;
    Array<int>? directions = _getDirections(size); // size == index of new node
    if (directions != null && directions.length > 0) {
      for (var d in directions) {
        if (d == 0) {
          node = node?.left;
        } else {
          node = node?.right;
        }
      }
    }
    if (node!.left == null) {
      node.left = newNode;
    } else {
      node.right = newNode;
    }
    newNode.parent = node;
    _size++;
    _heapUp(newNode);
    return true;
  }

  void _removeRoot() {
    _replaceNode(_root!);
  }

  _Node<T>? _getLastNode() {
    Array<int>? directions = _getDirections(size - 1);
    _Node<T>? lastNode = _root!;
    if (directions != null && directions.length > 0) {
      for (int d in directions) {
        if (d == 0) {
          lastNode = lastNode?.left;
        } else {
          lastNode = lastNode?.right;
        }
      }
    }
    if (lastNode!.right != null) {
      lastNode = lastNode.right;
    } else if (lastNode.left != null) {
      lastNode = lastNode.left;
    }
    return lastNode;
  }

  void _replaceNode(_Node<T> node) {
    _Node<T> lastNode = _getLastNode()!;

    // Remove lastNode from tree
    _Node<T>? lastNodeParent = lastNode.parent;
    if (lastNodeParent != null) {
      if (lastNodeParent.right != null) {
        lastNodeParent.right = null;
      } else {
        lastNodeParent.left = null;
      }
      lastNode.parent = null;
    }

    if (node.parent != null) {
      if (node.parent!.left == null) {
        node.parent!.left = lastNode;
      } else {
        node.parent!.right = lastNode;
      }
    }
    lastNode.parent = node.parent;

    lastNode.left = node.left;
    if (node.left != null) node.left!.parent = lastNode;

    lastNode.right = node.right;
    if (node.right != null) node.right!.parent = lastNode;

    if (node == _root) {
      if (lastNode != _root) {
        _root = lastNode;
      } else {
        _root = null;
      }
    }

    _size--;

    if (lastNode == node) return;

    if (lastNode == _root) {
      _heapDown(lastNode);
    } else {
      _heapDown(lastNode);
      _heapUp(lastNode);
    }
  }

  _Node<T>? getNode(_Node<T>? startingNode, T value) {
    _Node<T>? result;
    if (startingNode != null && startingNode.value == value) {
      result = startingNode;
    } else if (startingNode != null && startingNode.value != value) {
      _Node<T>? left = startingNode.left;
      _Node<T>? right = startingNode.right;
      if (left != null &&
          ((type == HeapType.min && compareFun(left.value!, value) <= 0) ||
              (type == HeapType.max && compareFun(left.value!, value) >= 0))) {
        result = getNode(left, value);
        if (result != null) return result;
      }
      if (right != null &&
          ((type == HeapType.min && compareFun(right.value!, value) <= 0) ||
              (type == HeapType.max && compareFun(right.value!, value) >= 0))) {
        result = getNode(right, value);
        if (result != null) return result;
      }
    }
    return result;
  }

  @override
  void clear() {
    _root = null;
    _size = 0;
  }

  @override
  bool contains(T value) {
    if (_root == null) return false;
    _Node<T>? node = getNode(_root, value);
    return (node != null);
  }

  @override
  T? remove(T value) {
    if (_root == null) return null;
    _Node<T>? node = getNode(_root, value);
    if (node != null) {
      T t = node.value;
      _replaceNode(node);
      return t;
    }
    return null;
  }

  void _heapUp(_Node<T> nodeToHeapUp) {
    _Node<T>? node = nodeToHeapUp;
    while (node != null) {
      _Node<T> heapNode = node;
      _Node<T>? parent = heapNode.parent;

      if ((parent != null) &&
          ((type == HeapType.min && compareFun(node.value, parent.value) < 0) ||
              (type == HeapType.max && compareFun(node.value, parent.value) > 0))) {
        // Node is less than parent, switch node with parent
        _Node<T>? grandParent = parent.parent;
        _Node<T>? parentLeft = parent.left;
        _Node<T>? parentRight = parent.right;

        parent.left = heapNode.left;
        if (parent.left != null) parent.left!.parent = parent;
        parent.right = heapNode.right;
        if (parent.right != null) parent.right!.parent = parent;

        if (parentLeft != null && parentLeft == node) {
          heapNode.left = parent;
          heapNode.right = parentRight;
          if (parentRight != null) parentRight.parent = heapNode;
        } else {
          heapNode.right = parent;
          heapNode.left = parentLeft;
          if (parentLeft != null) parentLeft.parent = heapNode;
        }
        parent.parent = heapNode;

        if (grandParent == null) {
          // New root.
          heapNode.parent = null;
          _root = heapNode;
        } else {
          _Node<T>? grandLeft = grandParent.left;
          if (grandLeft != null && grandLeft == parent) {
            grandParent.left = heapNode;
          } else {
            grandParent.right = heapNode;
          }
          heapNode.parent = grandParent;
        }
      } else {
        node = heapNode.parent;
      }
    }
  }

  void _heapDown(_Node<T>? nodeToHeapDown) {
    if (nodeToHeapDown == null) return;

    _Node<T> node = nodeToHeapDown;
    _Node<T> heapNode = node;
    _Node<T>? left = heapNode.left;
    _Node<T>? right = heapNode.right;

    if (left == null && right == null) {
      // Nothing to do here
      return;
    }

    _Node<T>? nodeToMove;

    if ((left != null && right != null) &&
        ((type == HeapType.min && compareFun(node.value, left.value) > 0 && compareFun(node.value, right.value) > 0) ||
            (type == HeapType.max &&
                compareFun(node.value, left.value) < 0 &&
                compareFun(node.value, right.value) < 0))) {
      if ((type == HeapType.min && compareFun(right.value, left.value) < 0) ||
          (type == HeapType.max && compareFun(right.value, left.value) > 0)) {
        nodeToMove = right;
      } else if ((type == HeapType.min && compareFun(left.value, right.value) < 0) ||
          (type == HeapType.max && compareFun(left.value, right.value) > 0)) {
        nodeToMove = left;
      } else {
        nodeToMove = right;
      }
    } else if ((type == HeapType.min && right != null && compareFun(node.value, right.value) > 0) ||
        (type == HeapType.max && right != null && compareFun(node.value, right.value) < 0)) {
      nodeToMove = right;
    } else if ((type == HeapType.min && left != null && compareFun(node.value, left.value) > 0) ||
        (type == HeapType.max && left != null && compareFun(node.value, left.value) < 0)) {
      nodeToMove = left;
    }
    if (nodeToMove == null) return;

    _Node<T>? nodeParent = heapNode.parent;
    if (nodeParent == null) {
      _root = nodeToMove;
      _root!.parent = null;
    } else {
      if (nodeParent.left != null && nodeParent.left == node) {
        nodeParent.left = nodeToMove;
        nodeToMove.parent = nodeParent;
      } else {
        nodeParent.right = nodeToMove;
        nodeToMove.parent = nodeParent;
      }
    }

    _Node<T>? nodeLeft = heapNode.left;
    _Node<T>? nodeRight = heapNode.right;
    _Node<T>? nodeToMoveLeft = nodeToMove.left;
    _Node<T>? nodeToMoveRight = nodeToMove.right;
    if (nodeLeft != null && nodeLeft == nodeToMove) {
      nodeToMove.right = nodeRight;
      if (nodeRight != null) nodeRight.parent = nodeToMove;

      nodeToMove.left = heapNode;
    } else {
      nodeToMove.left = nodeLeft;
      if (nodeLeft != null) nodeLeft.parent = nodeToMove;

      nodeToMove.right = heapNode;
    }
    heapNode.parent = nodeToMove;

    heapNode.left = nodeToMoveLeft;
    if (nodeToMoveLeft != null) nodeToMoveLeft.parent = heapNode;

    heapNode.right = nodeToMoveRight;
    if (nodeToMoveRight != null) nodeToMoveRight.parent = heapNode;

    _heapDown(node);
  }

  @override
  bool validate() {
    if (_root == null) return true;
    return _validateNode(_root!);
  }

  bool _validateNode(_Node<T> node) {
    _Node<T>? left = node.left;
    _Node<T>? right = node.right;

    if (right != null && left == null) {
      return false;
    }

    if (left != null) {
      if ((type == HeapType.min && compareFun(node.value, left.value) < 0) ||
          (type == HeapType.max && compareFun(node.value, left.value) > 0)) {
        return _validateNode(left);
      }
      return false;
    }
    if (right != null) {
      if ((type == HeapType.min && compareFun(node.value, right.value) < 0) ||
          (type == HeapType.max && compareFun(node.value, right.value) > 0)) {
        return _validateNode(right);
      }
      return false;
    }
    return true;
  }

  void _getNodeValue(_Node<T> node, int idx, Array<T> array) {
    int index = idx;
    array[index] = node.value;
    index = (index * 2) + 1;

    _Node<T>? left = node.left;
    if (left != null) {
      _getNodeValue(left, index, array);
    }
    _Node<T>? right = node.right;
    if (right != null) {
      _getNodeValue(right, index + 1, array);
    }
  }

  @override
  List<T> getHeap() {
    Array<T> nodes = Array(size);
    if (_root != null) {
      _getNodeValue(_root!, 0, nodes);
    }
    return nodes.toList();
  }

  @override
  T? getHeadValue() {
    T? result;
    if (_root != null) {
      result = _root!.value;
    }
    return result;
  }

  @override
  T? removeHead() {
    T? result;
    if (_root != null) {
      result = _root!.value;
      _removeRoot();
    }
    return result;
  }

  @override
  Iterable<T> toCollection() {
    return _JavaCompatibleBinaryHeapTree<T>(compareFun, this);
  }
}

class _Node<T> {
  late T value;
  _Node<T>? parent;
  _Node<T>? left;
  _Node<T>? right;

  _Node(this.parent, T this.value);
}

class _JavaCompatibleBinaryHeapArray<T> extends Iterable<T> {
  late BinaryHeapArray<T> heap;

  _JavaCompatibleBinaryHeapArray(CompareFun<T> compareFun, [BinaryHeapArray<T>? heap]) {
    this.heap = heap ?? BinaryHeapArray(compareFun);
  }

  bool add(T value) {
    return heap.add(value);
  }

  bool remove(Object? value) {
    if (value is! T) {
      return false;
    }
    return (heap.remove(value) != null);
  }

  @override
  bool contains(Object? value) {
    if (value is! T) {
      return false;
    }
    return heap.contains(value);
  }

  int get size => heap.size;

  @override
  Iterator<T> get iterator {
    return _BinaryHeapArrayIterator<T>(heap);
  }
}

class _BinaryHeapArrayIterator<T> implements Iterator<T> {
  BinaryHeapArray<T> heap;

  int last = -1;
  int index = -1;

  _BinaryHeapArrayIterator(this.heap);

  T? _current;

  @override
  T get current => _current!;

  @override
  bool moveNext() {
    if (heap.size <= 0) {
      return false;
    }

    index += 1;
    while (index < heap.size) {
      _current = heap._array[index];
      return true;
    }
    return false;
  }
}

class _JavaCompatibleBinaryHeapTree<T> extends Iterable<T> {
  final CompareFun<T> compareFun;
  late BinaryHeapTree<T> heap;

  _JavaCompatibleBinaryHeapTree(this.compareFun, [BinaryHeapTree<T>? heap]) {
    this.heap = heap ?? BinaryHeapTree(compareFun);
  }

  bool add(T value) {
    return heap.add(value);
  }

  bool remove(Object? value) {
    if (value is! T) {
      return false;
    }
    return (heap.remove(value) != null);
  }

  @override
  bool contains(Object? value) {
    if (value is! T) {
      return false;
    }
    return heap.contains(value);
  }

  int get size {
    return heap.size;
  }

  @override
  Iterator<T> get iterator => _BinaryHeapTreeIterator<T>(heap);
}

class _BinaryHeapTreeIterator<C> implements Iterator<C> {
  late BinaryHeapTree<C> heap;

  _Node<C>? last;

  Queue<_Node<C>> toVisit = DoubleLinkedQueue();

  _BinaryHeapTreeIterator(this.heap) {
    if (heap._root != null) {
      toVisit.add(heap._root!);
    }
  }

  bool hasNext() {
    if (toVisit.isNotEmpty) return true;
    return false;
  }

  C? next() {
    while (toVisit.isNotEmpty) {
      _Node<C> n = toVisit.removeFirst();

      if (n.left != null) toVisit.add(n.left!);
      if (n.right != null) toVisit.add(n.right!);
      last = n;
      return n.value;
    }
    return null;
  }

  void remove() {
    heap._replaceNode(last!);
  }

  @override
  C get current {
    return next()!;
  }

  @override
  bool moveNext() {
    return hasNext();
  }
}

enum HeapType { min, max }
