import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:d_util/d_util.dart';
import 'i_tree.dart';

class BinarySearchTree<T> extends ITree<T> {
  @protected
  static final Random random = Random();

  late final CompareFun<T> compareFun;

  @protected
  late INodeCreator<T> creator;

  BinarySearchTree(this.compareFun) {
    this.creator = (parent, id) {
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
    return this.addValue(value) != null;
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
      if (compareFun.call(newNode.id, node.id) <= 0) {
        if (node.lesser == null) {
          node.lesser = newNode;
          newNode.parent = node;
          mSize++;
          return newNode;
        }
        node = node.lesser;
      } else {
        // Greater than goes right
        if (node.greater == null) {
          // New right node
          node.greater = newNode;
          newNode.parent = node;
          mSize++;
          return newNode;
        }
        node = node.greater;
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
    while (node != null && node.id != null) {
      final cc = compareFun.call(value, node.id);
      if (cc < 0) {
        node = node.lesser;
      } else if (cc > 0) {
        node = node.greater;
      } else if (cc == 0) {
        return node;
      }
    }
    return null;
  }

  void rotateLeft(BSNode<T> node) {
    BSNode<T>? parent = node.parent;
    BSNode<T>? greater = node.greater;
    BSNode<T>? lesser = greater?.lesser;

    greater?.lesser = node;
    node.parent = greater;
    node.greater = lesser;
    if (lesser != null) {
      lesser.parent = node;
    }

    if (parent != null) {
      if (node == parent.lesser) {
        parent.lesser = greater;
      } else if (node == parent.greater) {
        parent.greater = greater;
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
    BSNode<T> lesser = node.lesser!;
    BSNode<T>? greater = lesser.greater;

    lesser.greater = node;
    node.parent = lesser;
    node.lesser = greater;

    if (greater != null) {
      greater.parent = node;
    }

    if (parent != null) {
      if (node == parent.lesser) {
        parent.lesser = lesser;
      } else if (node == parent.greater) {
        parent.greater = lesser;
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

    BSNode<T>? greater = startingNode.greater;
    while (greater != null && greater.id != null) {
      BSNode<T>? node = greater.greater;
      if (node != null && node.id != null) {
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

    BSNode<T>? lesser = startingNode.lesser;
    while (lesser != null && lesser.id != null) {
      BSNode<T>? node = lesser.lesser;
      if (node != null && node.id != null) {
        lesser = node;
      } else {
        break;
      }
    }
    return lesser;
  }

  @override
  T? remove(T value) {
    BSNode<T>? nodeToRemove = this.removeValue(value);
    return ((nodeToRemove != null) ? nodeToRemove.id : null);
  }

  BSNode<T>? removeValue(T value) {
    BSNode<T>? nodeToRemoved = this.getNode(value);
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
    if (nodeToRemoved.greater != null && nodeToRemoved.lesser != null) {
      if (modifications % 2 != 0) {
        replacement = this.getGreatest(nodeToRemoved.lesser);
        replacement ??= nodeToRemoved.lesser;
      } else {
        replacement = this.getLeast(nodeToRemoved.greater);
        replacement ??= nodeToRemoved.greater;
      }
      modifications++;
    } else if (nodeToRemoved.lesser != null && nodeToRemoved.greater == null) {
      replacement = nodeToRemoved.lesser;
    } else if (nodeToRemoved.greater != null && nodeToRemoved.lesser == null) {
      replacement = nodeToRemoved.greater;
    }
    return replacement;
  }

  void replaceNodeWithNode(BSNode<T> nodeToRemoved, BSNode<T>? replacementNode) {
    if (replacementNode != null) {
      // Save for later
      BSNode<T>? replacementNodeLesser = replacementNode.lesser;
      BSNode<T>? replacementNodeGreater = replacementNode.greater;

      // Replace replacementNode's branches with nodeToRemove's branches
      BSNode<T>? nodeToRemoveLesser = nodeToRemoved.lesser;
      if (nodeToRemoveLesser != null && nodeToRemoveLesser != replacementNode) {
        replacementNode.lesser = nodeToRemoveLesser;
        nodeToRemoveLesser.parent = replacementNode;
      }
      BSNode<T>? nodeToRemoveGreater = nodeToRemoved.greater;
      if (nodeToRemoveGreater != null && nodeToRemoveGreater != replacementNode) {
        replacementNode.greater = nodeToRemoveGreater;
        nodeToRemoveGreater.parent = replacementNode;
      }

      // Remove link from replacementNode's parent to replacement
      BSNode<T>? replacementParent = replacementNode.parent;
      if (replacementParent != null && replacementParent != nodeToRemoved) {
        BSNode<T>? replacementParentLesser = replacementParent.lesser;
        BSNode<T>? replacementParentGreater = replacementParent.greater;
        if (replacementParentLesser != null && replacementParentLesser == replacementNode) {
          replacementParent.lesser = replacementNodeGreater;
          if (replacementNodeGreater != null) {
            replacementNodeGreater.parent = replacementParent;
          }
        } else if (replacementParentGreater != null && replacementParentGreater == replacementNode) {
          replacementParent.greater = replacementNodeLesser;
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
    } else if (parent.lesser != null && (compareFun.call(parent.lesser!.id, nodeToRemoved.id) == 0)) {
      parent.lesser = replacementNode;
      if (replacementNode != null) {
        replacementNode.parent = parent;
      }
    } else if (parent.greater != null && (compareFun.call(parent.greater!.id, nodeToRemoved.id) == 0)) {
      parent.greater = replacementNode;
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
    BSNode<T>? lesser = node.lesser;
    BSNode<T>? greater = node.greater;
    bool lesserCheck = true;
    if (lesser != null && lesser.id != null) {
      lesserCheck = (compareFun.call(lesser.id, node.id) <= 0);
      if (lesserCheck) {
        lesserCheck = validateNode(lesser);
      }
    }
    if (!lesserCheck) {
      return false;
    }

    bool greaterCheck = true;
    if (greater != null && greater.id != null) {
      greaterCheck = (compareFun.call(greater.id, node.id) > 0);
      if (greaterCheck) {
        greaterCheck = validateNode(greater);
      }
    }
    return greaterCheck;
  }

  List<T> getBFS() {
    return getBFSStatic(root, this.size, compareFun);
  }

  static List<T> getBFSStatic<T>(BSNode<T>? start, int size, CompareFun<T> compareFun) {
    final Queue<BSNode<T>> queue = Queue();
    final Map<int, T> values = {};

    int count = 0;
    BSNode<T>? node = start;
    while (node != null) {
      values[count++] = node.id;
      if (node.lesser != null) {
        queue.add(node.lesser!);
      }
      if (node.greater != null) {
        queue.add(node.greater!);
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
    return getDFSStatic(order, root, this.size, compareFun);
  }

  static List<T> getDFSStatic<T>(DepthFirstSearchOrder order, BSNode<T>? start, int size, CompareFun<T> compareFun) {
    final Set<BSNode<T>> added = <BSNode<T>>{};
    final Map<int, T> nodes = {};

    int index = 0;
    BSNode<T>? node = start;
    while (index < size && node != null) {
      BSNode<T>? parent = node.parent;
      BSNode<T>? lesser = (node.lesser != null && !added.contains(node.lesser)) ? node.lesser : null;
      BSNode<T>? greater = (node.greater != null && !added.contains(node.greater)) ? node.greater : null;

      if (parent == null && lesser == null && greater == null) {
        if (!added.contains(node)) {
          nodes[index++] = node.id;
        }
        break;
      }

      if (order == DepthFirstSearchOrder.inOrder) {
        if (lesser != null) {
          node = lesser;
        } else {
          if (!added.contains(node)) {
            nodes[index++] = node.id;
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
          nodes[index++] = node.id;
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
            nodes[index++] = node.id;
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

class BinarySearchTreeIterator<C> implements Iterator<C> {
  late BinarySearchTree<C> tree;

  BSNode<C>? last;

  Queue<BSNode<C>> toVisit = DoubleLinkedQueue<BSNode<C>>();

  BinarySearchTreeIterator(this.tree) {
    if (tree.root != null) toVisit.add(tree.root!);
  }

  bool hasNext() {
    if (toVisit.isNotEmpty) return true;
    return false;
  }

  C? next() {
    while (toVisit.isNotEmpty) {
      BSNode<C> n = toVisit.removeFirst();
      if (n.lesser != null) toVisit.add(n.lesser!);
      if (n.greater != null) toVisit.add(n.greater!);
      last = n;
      return n.id;
    }
    return null;
  }

  void remove() {
    tree.removeNode(last);
  }

  @override
  C get current => last!.id;

  @override
  bool moveNext() {
    if (toVisit.isEmpty) {
      return false;
    }
    next();
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

class BSNode<T> {
  late T id;

  BSNode<T>? parent;

  BSNode<T>? lesser;

  BSNode<T>? greater;

  BSNode(this.parent, this.id);
}
