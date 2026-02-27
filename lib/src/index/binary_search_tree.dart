import 'dart:collection';
import 'dart:math';

import 'package:dart_graph/src/util/extra_mixin.dart';
import 'package:flutter/foundation.dart';

import 'i_tree.dart';

class BinarySearchTree<T> extends ITree<T> {
  @protected
  static final Random random = Random();

  late final int Function(T a, T b) compareFun;

  @protected
  late INodeCreator<T> creator;

  BinarySearchTree(this.compareFun) {
    creator = (parent, id) {
      return BSNode(parent, id);
    };
  }

  BinarySearchTree.of(this.compareFun, this.creator);

  int modifications = 0;

  @protected
  BSNode<T>? root;

  @protected
  int mSize = 0;

  @override
  bool add(T value) {
    return addValue(value) != null;
  }

  @protected
  BSNode<T>? addValue(T value) {
    final newNode = creator.call(null, value);
    if (root == null) {
      root = newNode;
      mSize++;
      return newNode;
    }

    BSNode<T>? node = root;
    while (node != null) {
      if (compareFun.call(newNode.data, node.data) <= 0) {
        if (node.left == null) {
          node.left = newNode;
          newNode.parent = node;
          mSize++;
          return newNode;
        }
        node = node.left;
      } else {
        // Greater than goes right
        if (node.right == null) {
          // New right node
          node.right = newNode;
          newNode.parent = node;
          mSize++;
          return newNode;
        }
        node = node.right;
      }
    }
    return newNode;
  }

  @override
  bool contains(T value) {
    BSNode<T>? node = getNode(value);
    return (node != null);
  }

  BSNode<T>? getNode(T value) {
    BSNode<T>? node = root;
    while (node != null && node.data != null) {
      final cc = compareFun.call(value, node.data);
      if (cc < 0) {
        node = node.left;
      } else if (cc > 0) {
        node = node.right;
      } else if (cc == 0) {
        return node;
      }
    }
    return null;
  }

  void rotateLeft(BSNode<T> node) {
    BSNode<T>? parent = node.parent;
    BSNode<T>? greater = node.right;
    BSNode<T>? lesser = greater?.left;

    greater?.left = node;
    node.parent = greater;
    node.right = lesser;
    if (lesser != null) {
      lesser.parent = node;
    }

    if (parent != null) {
      if (node == parent.left) {
        parent.left = greater;
      } else if (node == parent.right) {
        parent.right = greater;
      } else {
        throw ("Yikes! I'm not related to my parent. $node");
      }
      greater?.parent = parent;
    } else {
      root = greater;
      root?.parent = null;
    }
  }

  void rotateRight(BSNode<T> node) {
    BSNode<T>? parent = node.parent;
    BSNode<T> lesser = node.left!;
    BSNode<T>? greater = lesser.right;

    lesser.right = node;
    node.parent = lesser;
    node.left = greater;

    if (greater != null) {
      greater.parent = node;
    }

    if (parent != null) {
      if (node == parent.left) {
        parent.left = lesser;
      } else if (node == parent.right) {
        parent.right = lesser;
      } else {
        throw ("Yikes! I'm not related to my parent. $node");
      }
      lesser.parent = parent;
    } else {
      root = lesser;
      root?.parent = null;
    }
  }

  BSNode<T>? getGreatest(BSNode<T>? startingNode) {
    if (startingNode == null) {
      return null;
    }

    BSNode<T>? greater = startingNode.right;
    while (greater != null && greater.data != null) {
      BSNode<T>? node = greater.right;
      if (node != null && node.data != null) {
        greater = node;
      } else {
        break;
      }
    }
    return greater;
  }

  BSNode<T>? getLeast(BSNode<T>? startingNode) {
    if (startingNode == null) {
      return null;
    }

    BSNode<T>? lesser = startingNode.left;
    while (lesser != null && lesser.data != null) {
      BSNode<T>? node = lesser.left;
      if (node != null && node.data != null) {
        lesser = node;
      } else {
        break;
      }
    }
    return lesser;
  }

  @override
  T? remove(T value) {
    BSNode<T>? nodeToRemove = removeValue(value);
    return ((nodeToRemove != null) ? nodeToRemove.data : null);
  }

  BSNode<T>? removeValue(T value) {
    BSNode<T>? nodeToRemoved = getNode(value);
    if (nodeToRemoved != null) {
      nodeToRemoved = removeNode(nodeToRemoved);
    }
    return nodeToRemoved;
  }

  BSNode<T>? removeNode(BSNode<T>? nodeToRemoved) {
    if (nodeToRemoved != null) {
      BSNode<T>? replacementNode = getReplacementNode(nodeToRemoved);
      replaceNodeWithNode(nodeToRemoved, replacementNode);
    }
    return nodeToRemoved;
  }

  BSNode<T>? getReplacementNode(BSNode<T> nodeToRemoved) {
    BSNode<T>? replacement;
    if (nodeToRemoved.right != null && nodeToRemoved.left != null) {
      if (modifications % 2 != 0) {
        replacement = getGreatest(nodeToRemoved.left);
        replacement ??= nodeToRemoved.left;
      } else {
        replacement = getLeast(nodeToRemoved.right);
        replacement ??= nodeToRemoved.right;
      }
      modifications++;
    } else if (nodeToRemoved.left != null && nodeToRemoved.right == null) {
      replacement = nodeToRemoved.left;
    } else if (nodeToRemoved.right != null && nodeToRemoved.left == null) {
      replacement = nodeToRemoved.right;
    }
    return replacement;
  }

  void replaceNodeWithNode(BSNode<T> nodeToRemoved, BSNode<T>? replacementNode) {
    if (replacementNode != null) {
      // Save for later
      BSNode<T>? replacementNodeLesser = replacementNode.left;
      BSNode<T>? replacementNodeGreater = replacementNode.right;

      // Replace replacementNode's branches with nodeToRemove's branches
      BSNode<T>? nodeToRemoveLesser = nodeToRemoved.left;
      if (nodeToRemoveLesser != null && nodeToRemoveLesser != replacementNode) {
        replacementNode.left = nodeToRemoveLesser;
        nodeToRemoveLesser.parent = replacementNode;
      }
      BSNode<T>? nodeToRemoveGreater = nodeToRemoved.right;
      if (nodeToRemoveGreater != null && nodeToRemoveGreater != replacementNode) {
        replacementNode.right = nodeToRemoveGreater;
        nodeToRemoveGreater.parent = replacementNode;
      }

      // Remove link from replacementNode's parent to replacement
      BSNode<T>? replacementParent = replacementNode.parent;
      if (replacementParent != null && replacementParent != nodeToRemoved) {
        BSNode<T>? replacementParentLesser = replacementParent.left;
        BSNode<T>? replacementParentGreater = replacementParent.right;
        if (replacementParentLesser != null && replacementParentLesser == replacementNode) {
          replacementParent.left = replacementNodeGreater;
          if (replacementNodeGreater != null) {
            replacementNodeGreater.parent = replacementParent;
          }
        } else if (replacementParentGreater != null && replacementParentGreater == replacementNode) {
          replacementParent.right = replacementNodeLesser;
          if (replacementNodeLesser != null) {
            replacementNodeLesser.parent = replacementParent;
          }
        }
      }
    }

    BSNode<T>? parent = nodeToRemoved.parent;
    if (parent == null) {
      root = replacementNode;
      if (root != null) {
        root!.parent = null;
      }
    } else if (parent.left != null && (compareFun.call(parent.left!.data, nodeToRemoved.data) == 0)) {
      parent.left = replacementNode;
      if (replacementNode != null) {
        replacementNode.parent = parent;
      }
    } else if (parent.right != null && (compareFun.call(parent.right!.data, nodeToRemoved.data) == 0)) {
      parent.right = replacementNode;
      if (replacementNode != null) {
        replacementNode.parent = parent;
      }
    }
    mSize--;
  }

  @override
  void clear() {
    root = null;
    mSize = 0;
  }

  @override
  int get size => mSize;

  @override
  bool validate() {
    if (root == null) return true;
    return validateNode(root!);
  }

  @protected
  bool validateNode(BSNode<T> node) {
    BSNode<T>? lesser = node.left;
    BSNode<T>? greater = node.right;
    bool lesserCheck = true;
    if (lesser != null && lesser.data != null) {
      lesserCheck = (compareFun.call(lesser.data, node.data) <= 0);
      if (lesserCheck) {
        lesserCheck = validateNode(lesser);
      }
    }
    if (!lesserCheck) {
      return false;
    }

    bool greaterCheck = true;
    if (greater != null && greater.data != null) {
      greaterCheck = (compareFun.call(greater.data, node.data) > 0);
      if (greaterCheck) {
        greaterCheck = validateNode(greater);
      }
    }
    return greaterCheck;
  }

  List<T> getBFS() {
    return getBFSStatic(root, size, compareFun);
  }

  static List<T> getBFSStatic<T>(BSNode<T>? start, int size, int Function(T a, T b) compareFun) {
    final Queue<BSNode<T>> queue = Queue();
    final Map<int, T> values = {};

    int count = 0;
    BSNode<T>? node = start;
    while (node != null) {
      values[count++] = node.data;
      if (node.left != null) {
        queue.add(node.left!);
      }
      if (node.right != null) {
        queue.add(node.right!);
      }
      if (queue.isNotEmpty) {
        node = queue.removeFirst();
      } else {
        node = null;
      }
    }

    final keyList = values.keys.toList();
    keyList.sort((a, b) => a.compareTo(b));
    return keyList.map((e) => values[e]!).toList();
  }

  List<T> getLevelOrder() {
    return getBFS();
  }

  List<T> getDFS(DepthFirstSearchOrder order) {
    return getDFSStatic(order, root, size, compareFun);
  }

  static List<T> getDFSStatic<T>(
      DepthFirstSearchOrder order, BSNode<T>? start, int size, int Function(T a, T b) compareFun) {
    final Set<BSNode<T>> added = <BSNode<T>>{};
    final Map<int, T> nodes = {};

    int index = 0;
    BSNode<T>? node = start;
    while (index < size && node != null) {
      BSNode<T>? parent = node.parent;
      BSNode<T>? lesser = (node.left != null && !added.contains(node.left)) ? node.left : null;
      BSNode<T>? greater = (node.right != null && !added.contains(node.right)) ? node.right : null;

      if (parent == null && lesser == null && greater == null) {
        if (!added.contains(node)) {
          nodes[index++] = node.data;
        }
        break;
      }

      if (order == DepthFirstSearchOrder.inOrder) {
        if (lesser != null) {
          node = lesser;
        } else {
          if (!added.contains(node)) {
            nodes[index++] = node.data;
            added.add(node);
          }
          if (greater != null) {
            node = greater;
          } else if (added.contains(node)) {
            node = parent;
          } else {
            node = null;
          }
        }
      } else if (order == DepthFirstSearchOrder.preOrder) {
        if (!added.contains(node)) {
          nodes[index++] = node.data;
          added.add(node);
        }
        if (lesser != null) {
          node = lesser;
        } else if (greater != null) {
          node = greater;
        } else if (added.contains(node)) {
          node = parent;
        } else {
          node = null;
        }
      } else {
        if (lesser != null) {
          node = lesser;
        } else {
          if (greater != null) {
            node = greater;
          } else {
            nodes[index++] = node.data;
            added.add(node);
            node = parent;
          }
        }
      }
    }

    final keyList = nodes.keys.toList();
    keyList.sort((a, b) => a.compareTo(b));
    return keyList.map((e) => nodes[e]!).toList();
  }

  List<T> getSorted() {
    return getDFS(DepthFirstSearchOrder.inOrder);
  }

  @override
  Iterable<T> toCollection() {
    return (_JavaCompatibleBinarySearchTree<T>(this));
  }
}

enum DepthFirstSearchOrder { inOrder, preOrder, postOrder }

class BinarySearchTreeIterator<T> implements Iterator<T> {
  final List<BSNode<T>> _stack = [];
  BSNode<T>? _current;

  BinarySearchTreeIterator(BinarySearchTree<T> tree) {
    _pushLeft(tree.root);
  }

  void _pushLeft(BSNode<T>? node) {
    while (node != null) {
      _stack.add(node);
      node = node.left;
    }
  }

  @override
  T get current => _current!.data;

  @override
  bool moveNext() {
    if (_stack.isEmpty) return false;

    _current = _stack.removeLast();
    // 访问当前节点后，尝试处理其右子树
    if (_current!.right != null) {
      _pushLeft(_current!.right);
    }

    return true;
  }
}

class _JavaCompatibleBinarySearchTree<T> extends Iterable<T> {
  @protected
  late BinarySearchTree<T> tree;

  _JavaCompatibleBinarySearchTree(this.tree);

  bool add(T value) {
    return tree.add(value);
  }

  bool remove(T value) {
    return (tree.remove(value) != null);
  }

  @override
  bool contains(Object? element) {
    if (element == null || element is! T) {
      return false;
    }

    return tree.contains(element as T);
  }

  int size() {
    return tree.size;
  }

  @override
  Iterator<T> get iterator => BinarySearchTreeIterator(tree);
}

typedef INodeCreator<T> = BSNode<T> Function(BSNode<T>? parent, T id);

class BSNode<T> with ValueExtraMixin {
  late T data;

  BSNode<T>? parent;

  BSNode<T>? left;

  BSNode<T>? right;

  BSNode(this.parent, this.data);
}
