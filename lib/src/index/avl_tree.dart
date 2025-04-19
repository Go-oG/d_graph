import 'package:flutter/cupertino.dart';

import 'binary_search_tree.dart';

class AVLTree<T> extends BinarySearchTree<T> {
  AVLTree.of(super.compareFun, super.creator) : super.of();

  AVLTree(super.compareFun) {
    creator = (p, id) {
      return (AVLNode<T>(p, id));
    };
  }

  @override
  BSNode<T> addValue(T value) {
    BSNode<T>? nodeToReturn = super.addValue(value);
    AVLNode<T>? nodeAdded = nodeToReturn as AVLNode<T>;
    nodeAdded.updateHeight();
    _balanceAfterInsert(nodeAdded);
    nodeAdded = nodeAdded.parent as AVLNode<T>?;
    while (nodeAdded != null) {
      int h1 = nodeAdded.height;

      nodeAdded.updateHeight();
      _balanceAfterInsert(nodeAdded);

      int h2 = nodeAdded.height;
      if (h1 == h2) {
        break;
      }
      nodeAdded = nodeAdded.parent as AVLNode<T>?;
    }
    return nodeToReturn;
  }

  void _balanceAfterInsert(AVLNode<T> node) {
    int balanceFactor = node.getBalanceFactor();
    if (balanceFactor > 1 || balanceFactor < -1) {
      AVLNode<T>? child;
      _Balance? balance;
      if (balanceFactor < 0) {
        child = node.lesser as AVLNode<T>;
        balanceFactor = child.getBalanceFactor();
        if (balanceFactor < 0) {
          balance = _Balance.leftLeft;
        } else {
          balance = _Balance.leftRight;
        }
      } else {
        child = node.greater as AVLNode<T>;
        balanceFactor = child.getBalanceFactor();
        if (balanceFactor < 0) {
          balance = _Balance.rightLeft;
        } else {
          balance = _Balance.rightRight;
        }
      }

      if (balance == _Balance.leftRight) {
        // Left-Right (Left rotation, right rotation)
        rotateLeft(child);
        rotateRight(node);
      } else if (balance == _Balance.rightLeft) {
        // Right-Left (Right rotation, left rotation)
        rotateRight(child);
        rotateLeft(node);
      } else if (balance == _Balance.leftLeft) {
        // Left-Left (Right rotation)
        rotateRight(node);
      } else {
        // Right-Right (Left rotation)
        rotateLeft(node);
      }

      child.updateHeight();
      node.updateHeight();
    }
  }

  @override
  BSNode<T>? removeValue(T value) {
    BSNode<T>? nodeToRemoved = getNode(value);
    if (nodeToRemoved == null) {
      return null;
    }

    BSNode<T>? replacementNode = getReplacementNode(nodeToRemoved);

    AVLNode<T>? nodeToRefactor;
    if (replacementNode != null) {
      nodeToRefactor = replacementNode.parent as AVLNode<T>?;
    }
    nodeToRefactor ??= nodeToRemoved.parent as AVLNode<T>;
    if (nodeToRefactor == nodeToRemoved) {
      nodeToRefactor = replacementNode as AVLNode<T>;
    }

    // Replace the node
    replaceNodeWithNode(nodeToRemoved, replacementNode);

    // Re-balance the tree all the way up the tree
    while (nodeToRefactor != null) {
      nodeToRefactor.updateHeight();
      _balanceAfterDelete(nodeToRefactor);
      nodeToRefactor = nodeToRefactor.parent as AVLNode<T>?;
    }

    return nodeToRemoved;
  }

  void _balanceAfterDelete(AVLNode<T> node) {
    int balanceFactor = node.getBalanceFactor();
    if (balanceFactor == -2 || balanceFactor == 2) {
      if (balanceFactor == -2) {
        AVLNode<T>? ll = node.lesser?.lesser as AVLNode<T>?;
        int lesser = (ll != null) ? ll.height : 0;

        AVLNode<T>? lr = node.lesser?.greater as AVLNode<T>?;
        int greater = (lr != null) ? lr.height : 0;

        if (lesser >= greater) {
          rotateRight(node);
          node.updateHeight();
          if (node.parent != null) {
            (node.parent as AVLNode<T>).updateHeight();
          }
        } else {
          rotateLeft(node.lesser!);
          rotateRight(node);

          AVLNode<T> p = node.parent as AVLNode<T>;
          (p.lesser as AVLNode<T>?)?.updateHeight();
          (p.greater as AVLNode<T>?)?.updateHeight();
          p.updateHeight();
        }
      } else if (balanceFactor == 2) {
        AVLNode<T>? rr = node.greater?.greater as AVLNode<T>?;
        int greater = (rr != null) ? rr.height : 0;

        AVLNode<T>? rl = node.greater?.lesser as AVLNode<T>?;
        int lesser = (rl != null) ? rl.height : 0;
        if (greater >= lesser) {
          rotateLeft(node);
          node.updateHeight();
          if (node.parent != null) {
            (node.parent as AVLNode<T>).updateHeight();
          }
        } else {
          rotateRight(node.greater!);
          rotateLeft(node);
          AVLNode<T> p = node.parent as AVLNode<T>;
          (p.lesser as AVLNode<T>?)?.updateHeight();
          (p.greater as AVLNode<T>?)?.updateHeight();
          p.updateHeight();
        }
      }
    }
  }

  @override
  bool validateNode(BSNode<T> node) {
    bool bst = super.validateNode(node);
    if (!bst) {
      return false;
    }

    AVLNode<T> avlNode = node as AVLNode<T>;
    int balanceFactor = avlNode.getBalanceFactor();
    if (balanceFactor > 1 || balanceFactor < -1) {
      return false;
    }
    if (avlNode.isLeaf()) {
      if (avlNode.height != 1) {
        return false;
      }
    } else {
      AVLNode<T>? avlNodeLesser = avlNode.lesser as AVLNode<T>?;
      int lesserHeight = 1;
      if (avlNodeLesser != null) {
        lesserHeight = avlNodeLesser.height;
      }

      AVLNode<T>? avlNodeGreater = avlNode.greater as AVLNode<T>?;
      int greaterHeight = 1;
      if (avlNodeGreater != null) {
        greaterHeight = avlNodeGreater.height;
      }

      if (avlNode.height == (lesserHeight + 1) || avlNode.height == (greaterHeight + 1)) {
        return true;
      }
      return false;
    }

    return true;
  }

}

class AVLNode<T> extends BSNode<T> {
  @protected
  int height = 1;

  AVLNode(super.parent, super.value);

  bool isLeaf() {
    return ((lesser == null) && (greater == null));
  }

  int updateHeight() {
    int lesserHeight = 0;
    if (lesser != null) {
      AVLNode<T> lesserAVLNode = lesser as AVLNode<T>;
      lesserHeight = lesserAVLNode.height;
    }
    int greaterHeight = 0;
    if (greater != null) {
      AVLNode<T> greaterAVLNode = greater as AVLNode<T>;
      greaterHeight = greaterAVLNode.height;
    }

    if (lesserHeight > greaterHeight) {
      height = lesserHeight + 1;
    } else {
      height = greaterHeight + 1;
    }
    return height;
  }

  int getBalanceFactor() {
    int lesserHeight = 0;
    if (lesser != null) {
      AVLNode<T> lesserAVLNode = lesser as AVLNode<T>;
      lesserHeight = lesserAVLNode.height;
    }
    int greaterHeight = 0;
    if (greater != null) {
      AVLNode<T> greaterAVLNode = greater as AVLNode<T>;
      greaterHeight = greaterAVLNode.height;
    }
    return greaterHeight - lesserHeight;
  }
}

enum _Balance { leftLeft, leftRight, rightLeft, rightRight }
