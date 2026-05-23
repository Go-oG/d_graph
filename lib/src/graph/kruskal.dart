import 'package:collection/collection.dart';
import 'graph.dart';
import 'utils.dart';

/// Kruskal 最小生成树算法
/// 仅适用于无向图 时间复杂度: O(E log E)
extension KruskalExtension<V, E> on Graph<V, E> {
  MSTResult<E> minSpanningTreeByKruskal() {
    if (directed) {
      throw StateError(
        "Kruskal's algorithm typically requires an undirected graph.",
      );
    }

    final List<Edge<E>> mstEdges = [];
    double totalCost = 0.0;

    final unionFind = _UnionFind(vertexMap.keys);
    final edgeQueue = PriorityQueue<Edge<E>>(
      (a, b) => a.weight.compareTo(b.weight),
    );

    edgeQueue.addAll(edgeIterator);

    while (edgeQueue.isNotEmpty) {
      final edge = edgeQueue.removeFirst();

      if (unionFind.find(edge.from) != unionFind.find(edge.to)) {
        unionFind.union(edge.from, edge.to);
        mstEdges.add(edge);
        totalCost += edge.weight;
      }
    }

    return MSTResult(totalCost, mstEdges);
  }
}

/// 辅助类：优化的并查集 (Disjoint Set Union)
/// 实现了 "路径压缩" 和 "按秩合并"
class _UnionFind {
  final Map<String, String> _parent = {};
  final Map<String, int> _rank = {};

  _UnionFind(Iterable<String> elements) {
    for (final e in elements) {
      _parent[e] = e;
      _rank[e] = 0;
    }
  }

  String find(String item) {
    if (_parent[item] == item) {
      return item;
    }
    _parent[item] = find(_parent[item]!);
    return _parent[item]!;
  }

  void union(String item1, String item2) {
    final root1 = find(item1);
    final root2 = find(item2);

    if (root1 != root2) {
      if (_rank[root1]! < _rank[root2]!) {
        _parent[root1] = root2;
      } else if (_rank[root1]! > _rank[root2]!) {
        _parent[root2] = root1;
      } else {
        _parent[root2] = root1;
        _rank[root1] = _rank[root1]! + 1;
      }
    }
  }
}
