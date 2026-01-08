import 'dart:math' as math;

import 'binary_search_tree.dart';

class AVLNode<T> extends BSNode<T> {
  int _height = 1;

  AVLNode(T value, {AVLNode<T>? parent}) : super(parent, value);

  AVLNode<T>? get leftNode => left as AVLNode<T>?;

  set leftNode(AVLNode<T>? node) => left = node;

  AVLNode<T>? get rightNode => right as AVLNode<T>?;

  set rightNode(AVLNode<T>? node) => right = node;

  AVLNode<T>? get parentNode => parent as AVLNode<T>?;

  set parentNode(AVLNode<T>? node) => parent = node;

  int get height => _height;

  void updateHeight() {
    int leftH = leftNode?.height ?? 0;
    int rightH = rightNode?.height ?? 0;
    _height = 1 + math.max(leftH, rightH);
  }

  int get balanceFactor {
    int leftH = leftNode?.height ?? 0;
    int rightH = rightNode?.height ?? 0;
    return rightH - leftH;
  }
}

class AVLTree<T extends Comparable<T>> extends BinarySearchTree<T> {
  AVLTree([Comparator<T>? compareFun]) : super(compareFun ?? (a, b) => a.compareTo(b));

  @override
  AVLNode<T>? get root => super.root as AVLNode<T>?;

  @override
  bool add(T value) {
    if (root == null) {
      super.root = AVLNode<T>(value);
      return true;
    }
    super.root = _insert(root!, value);
    return true;
  }

  @override
  T? remove(T value) {
    if (root == null) return null;
    AVLNode<T>? current = root;
    while (current != null) {
      int cmp = value.compareTo(current.value);
      if (cmp == 0) break;
      current = cmp < 0 ? current.leftNode : current.rightNode;
    }
    if (current == null) return null;
    T removedValue = current.value;
    super.root = _delete(root!, value);
    return removedValue;
  }

  AVLNode<T> _insert(AVLNode<T> node, T value) {
    int cmp = value.compareTo(node.value);

    if (cmp < 0) {
      if (node.leftNode == null) {
        node.leftNode = AVLNode<T>(value, parent: node);
      } else {
        node.leftNode = _insert(node.leftNode!, value);
        node.leftNode!.parentNode = node;
      }
    } else if (cmp > 0) {
      if (node.rightNode == null) {
        node.rightNode = AVLNode<T>(value, parent: node);
      } else {
        node.rightNode = _insert(node.rightNode!, value);
        node.rightNode!.parentNode = node;
      }
    } else {
      node.value = value;
      return node;
    }

    return _rebalance(node);
  }

  AVLNode<T>? _delete(AVLNode<T> node, T value) {
    int cmp = value.compareTo(node.value);

    if (cmp < 0) {
      if (node.leftNode != null) {
        node.leftNode = _delete(node.leftNode!, value);
        if (node.leftNode != null) node.leftNode!.parentNode = node;
      }
    } else if (cmp > 0) {
      if (node.rightNode != null) {
        node.rightNode = _delete(node.rightNode!, value);
        if (node.rightNode != null) node.rightNode!.parentNode = node;
      }
    } else {
      if (node.leftNode != null && node.rightNode != null) {
        AVLNode<T> successor = _getMin(node.rightNode!);
        node.value = successor.value;
        node.rightNode = _delete(node.rightNode!, successor.value);
        if (node.rightNode != null) node.rightNode!.parentNode = node;
      } else {
        AVLNode<T>? child = node.leftNode ?? node.rightNode;
        if (child == null) {
          return null;
        } else {
          child.parentNode = node.parentNode;
          return child;
        }
      }
    }
    return _rebalance(node);
  }

  AVLNode<T> _rebalance(AVLNode<T> node) {
    node.updateHeight();
    int balance = node.balanceFactor;

    if (balance < -1) {
      if (node.leftNode!.balanceFactor > 0) {
        node.leftNode = _rotateLeft(node.leftNode!);
        node.leftNode!.parentNode = node;
      }
      return _rotateRight(node);
    }

    if (balance > 1) {
      if (node.rightNode!.balanceFactor < 0) {
        node.rightNode = _rotateRight(node.rightNode!);
        node.rightNode!.parentNode = node;
      }
      return _rotateLeft(node);
    }
    return node;
  }


  AVLNode<T> _rotateLeft(AVLNode<T> node) {
    AVLNode<T> newRoot = node.rightNode!;
    node.rightNode = newRoot.leftNode;

    if (newRoot.leftNode != null) {
      newRoot.leftNode!.parentNode = node;
    }
    newRoot.leftNode = node;
    newRoot.parentNode = node.parentNode;
    node.parentNode = newRoot;
    node.updateHeight();
    newRoot.updateHeight();

    return newRoot;
  }

  AVLNode<T> _rotateRight(AVLNode<T> node) {
    AVLNode<T> newRoot = node.leftNode!;
    node.leftNode = newRoot.rightNode;

    if (newRoot.rightNode != null) {
      newRoot.rightNode!.parentNode = node;
    }

    newRoot.rightNode = node;
    newRoot.parentNode = node.parentNode;
    node.parentNode = newRoot;

    node.updateHeight();
    newRoot.updateHeight();
    return newRoot;
  }

  AVLNode<T> _getMin(AVLNode<T> node) {
    while (node.leftNode != null) {
      node = node.leftNode!;
    }
    return node;
  }

  @override
  bool validate() {
    if (root == null) return true;
    return _validateNode(root!);
  }

  bool _validateNode(AVLNode<T> node) {
    int bf = node.balanceFactor;
    if (bf > 1 || bf < -1) return false;

    int h = node.height;
    int lh = node.leftNode?.height ?? 0;
    int rh = node.rightNode?.height ?? 0;
    if (h != 1 + math.max(lh, rh)) return false;

    // 验证父指针一致性 (Debug用)
    if (node.leftNode != null && node.leftNode!.parentNode != node) return false;
    if (node.rightNode != null && node.rightNode!.parentNode != node) return false;

    bool lOk = node.leftNode == null || _validateNode(node.leftNode!);
    bool rOk = node.rightNode == null || _validateNode(node.rightNode!);
    return lOk && rOk;
  }
}
