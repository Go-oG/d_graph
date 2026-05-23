import 'dart:collection';
import 'dart:core';
import 'dart:math';

abstract interface class BinaryHeap<T> {
  List<T> getHeap();

  bool add(T value);

  void clear();

  bool contains(T value);

  T? getHeadValue();

  T? remove(T value);

  T? removeHead();

  int get size;

  Iterable<T> toCollection();

  bool validate();
}

enum HeapType { min, max }

class BinaryHeapArray<T> implements BinaryHeap<T> {
  static const int minSize = 1024;
  late final HeapType type;
  final int Function(T a, T b) compareFun;

  int _size = 0;
  List<T?> _array = List.filled(minSize, null);

  BinaryHeapArray(this.compareFun, [this.type = HeapType.min]);

  static int _getParentIndex(int index) => (index - 1) ~/ 2;

  static int _getLeftIndex(int index) => 2 * index + 1;

  static int _getRightIndex(int index) => 2 * index + 2;

  @override
  int get size => _size;

  @override
  bool add(T value) {
    if (_size >= _array.length) _grow();
    _array[_size] = value;
    _heapUp(_size++);
    return true;
  }

  @override
  T? remove(T value) {
    if (_size == 0) return null;
    int index = -1;
    for (int i = 0; i < _size; i++) {
      if (_array[i] == value) {
        index = i;
        break;
      }
    }
    if (index == -1) return null;
    return _removeAt(index);
  }

  T? _removeAt(int index) {
    if (index < 0 || index >= _size) return null;
    T? removed = _array[index];
    T? last = _array[--_size];
    _array[_size] = null;

    if (index != _size) {
      _array[index] = last;
      _heapDown(index);
      _heapUp(index);
    }

    if (_array.length > minSize && _size < (_array.length >> 2)) {
      _shrink();
    }
    return removed;
  }

  void _heapUp(int index) {
    int curr = index;
    T? value = _array[curr];
    while (curr > 0) {
      int parentIdx = _getParentIndex(curr);
      T? parent = _array[parentIdx];

      if (_compare(value as T, parent as T) < 0) {
        _array[curr] = parent;
        curr = parentIdx;
      } else {
        break;
      }
    }
    _array[curr] = value;
  }

  void _heapDown(int index) {
    int curr = index;
    T value = _array[curr] as T;
    int half = _size ~/ 2;

    while (curr < half) {
      int leftIdx = _getLeftIndex(curr);
      int rightIdx = _getRightIndex(curr);
      int bestChildIdx = leftIdx;
      T bestChild = _array[leftIdx] as T;
      if (rightIdx < _size) {
        T rightChild = _array[rightIdx] as T;
        if (_compare(rightChild, bestChild) < 0) {
          bestChildIdx = rightIdx;
          bestChild = rightChild;
        }
      }
      if (_compare(value, bestChild) <= 0) {
        break;
      }
      _array[curr] = bestChild;
      curr = bestChildIdx;
    }
    _array[curr] = value;
  }

  int _compare(T a, T b) {
    int res = compareFun(a, b);
    return type == HeapType.min ? res : -res;
  }

  void _grow() {
    int newSize = _array.length + (_array.length >> 1);
    List<T?> newArr = List.filled(newSize, null);
    newArr.setAll(0, _array);
    _array = newArr;
  }

  void _shrink() {
    int newSize = _array.length >> 1;
    List<T?> newArr = List.filled(max(newSize, minSize), null);
    for (int i = 0; i < _size; i++) {
      newArr[i] = _array[i];
    }
    _array = newArr;
  }

  @override
  void clear() {
    _size = 0;
    _array = List.filled(minSize, null);
  }

  @override
  bool contains(T value) {
    for (int i = 0; i < _size; i++) {
      if (_array[i] == value) return true;
    }
    return false;
  }

  @override
  T? getHeadValue() => _size > 0 ? _array[0] : null;

  @override
  T? removeHead() => _removeAt(0);

  @override
  bool validate() => true;

  @override
  Iterable<T> toCollection() =>
      _JavaCompatibleBinaryHeapArray(compareFun, this);

  @override
  List<T> getHeap() {
    List<T> list = [];
    for (int i = 0; i < size; i++) {
      list.add(_array[i] as T);
    }
    return list;
  }
}

class BinaryHeapTree<T> implements BinaryHeap<T> {
  final HeapType type;
  final int Function(T a, T b) compareFun;
  int _size = 0;
  _Node<T>? _root;
  final Map<T, Set<_Node<T>>> _nodeIndex = HashMap();

  BinaryHeapTree(this.compareFun, {this.type = HeapType.min});

  @override
  int get size => _size;

  @override
  bool add(T value) {
    if (_root == null) {
      _root = _Node(null, value);
      _addNodeIndex(value, _root!);
      _size++;
      return true;
    }

    _size++;
    _Node<T> parent = _findNodeByIndex(_size ~/ 2)!;

    _Node<T> newNode = _Node(parent, value);
    if ((_size & 1) == 0) {
      parent.left = newNode;
    } else {
      parent.right = newNode;
    }
    _addNodeIndex(value, newNode);
    _heapUp(newNode);
    return true;
  }

  @override
  T? remove(T value) {
    if (_root == null) return null;
    final targetNodes = _nodeIndex[value];
    if (targetNodes == null || targetNodes.isEmpty) return null;
    _Node<T> target = targetNodes.first;

    T removedData = target.value;
    _Node<T> lastNode = _findNodeByIndex(_size)!;
    T lastValue = lastNode.value;
    if (lastNode == _root) {
      _root = null;
      _size = 0;
      _removeNodeIndex(removedData, lastNode);
      return removedData;
    }

    _removeNodeIndex(lastValue, lastNode);
    _Node<T> lastParent = lastNode.parent!;
    if (lastParent.left == lastNode) {
      lastParent.left = null;
    } else {
      lastParent.right = null;
    }
    _size--;
    if (target != lastNode) {
      _removeNodeIndex(removedData, target);
      target.value = lastValue;
      _addNodeIndex(lastValue, target);
      _heapDown(target);
      _heapUp(target);
    }

    return removedData;
  }

  _Node<T>? _findNodeByIndex(int index) {
    if (index == 0) return null;
    if (index == 1) return _root;

    int mask = 1;
    while (mask <= index) {
      mask <<= 1;
    }
    mask >>= 2;

    _Node<T>? curr = _root;
    while (mask > 0) {
      if ((index & mask) == 0) {
        curr = curr?.left;
      } else {
        curr = curr?.right;
      }
      mask >>= 1;
    }
    return curr;
  }

  void _heapUp(_Node<T> node) {
    while (node.parent != null) {
      if (_compare(node.value, node.parent!.value) < 0) {
        _swapValue(node, node.parent!);
        node = node.parent!;
      } else {
        break;
      }
    }
  }

  void _heapDown(_Node<T> node) {
    while (node.left != null) {
      _Node<T> bestChild = node.left!;
      if (node.right != null) {
        if (_compare(node.right!.value, bestChild.value) < 0) {
          bestChild = node.right!;
        }
      }
      if (_compare(bestChild.value, node.value) < 0) {
        _swapValue(node, bestChild);
        node = bestChild;
      } else {
        break;
      }
    }
  }

  void _swapValue(_Node<T> a, _Node<T> b) {
    _removeNodeIndex(a.value, a);
    _removeNodeIndex(b.value, b);
    T temp = a.value;
    a.value = b.value;
    b.value = temp;
    _addNodeIndex(a.value, a);
    _addNodeIndex(b.value, b);
  }

  void _addNodeIndex(T value, _Node<T> node) {
    _nodeIndex.putIfAbsent(value, () => HashSet.identity()).add(node);
  }

  void _removeNodeIndex(T value, _Node<T> node) {
    final nodes = _nodeIndex[value];
    if (nodes == null) return;
    nodes.remove(node);
    if (nodes.isEmpty) {
      _nodeIndex.remove(value);
    }
  }

  int _compare(T a, T b) {
    int res = compareFun(a, b);
    return type == HeapType.min ? res : -res;
  }

  @override
  T? getHeadValue() => _root?.value;

  @override
  T? removeHead() {
    if (_root == null) return null;
    return remove(_root!.value);
  }

  @override
  void clear() {
    _root = null;
    _size = 0;
    _nodeIndex.clear();
  }

  @override
  bool contains(T value) => _nodeIndex[value]?.isNotEmpty ?? false;

  @override
  bool validate() => true;

  @override
  Iterable<T> toCollection() => _JavaCompatibleBinaryHeapTree(compareFun, this);

  @override
  List<T> getHeap() {
    List<T?> nodes = List.filled(size, null);
    if (_root != null) {
      _getNodeValue(_root!, 0, nodes);
    }
    List<T> rl = [];
    for (var n in nodes) {
      if (n != null) {
        rl.add(n);
      }
    }
    return rl;
  }

  void _getNodeValue(_Node<T> node, int idx, List<T?> array) {
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
}

class _Node<T> {
  late T value;
  _Node<T>? parent;
  _Node<T>? left;
  _Node<T>? right;

  _Node(this.parent, this.value);
}

class _JavaCompatibleBinaryHeapArray<T> extends Iterable<T> {
  late BinaryHeapArray<T> heap;

  _JavaCompatibleBinaryHeapArray(
    int Function(T a, T b) compareFun, [
    BinaryHeapArray<T>? heap,
  ]) {
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
  final int Function(T a, T b) compareFun;
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
  C? _current;

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
      _current = n.value;
      return _current;
    }
    return null;
  }

  void remove() => heap.remove(last!.value);

  @override
  C get current {
    return _current as C;
  }

  @override
  bool moveNext() {
    return next() != null;
  }
}
