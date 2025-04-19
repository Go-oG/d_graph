import 'package:collection/collection.dart';
import 'package:d_util/d_util.dart';

import 'graph.dart';

/// Kruskal 的最小生成树。仅适用于无向图。它找到一个
/// 边的子集，该子集形成一个包含每个顶点的树，其中
/// 树中所有边的总重量最小化。
extension Kruskal<T> on Graph<T> {
  CostPath<T> getMinimumSpanningTree() {
    if (type == GraphType.directed) {
      throw "Undirected graphs only.";
    }

    int cost = 0;
    final List<Edge<T>> path = [];

    // Prepare data to store information which part of tree given vertex is
    Map<Vertex<T>, Set<Vertex<T>>> membershipMap = {};
    for (Vertex<T> v in vertices) {
      Set<Vertex<T>> set = <Vertex<T>>{};
      set.add(v);
      membershipMap.put(v, set);
    }

    PriorityQueue<Edge<T>> edgeQueue = PriorityQueue();
    edgeQueue.addAll(edges);

    while (edgeQueue.isNotEmpty) {
      Edge<T> edge = edgeQueue.removeFirst();
      if (!_isTheSamePart(edge.from, edge.to, membershipMap)) {
        _union(edge.from, edge.to, membershipMap);
        path.add(edge);
        cost += edge.cost;
      }
    }

    return CostPath<T>(cost, path);
  }

  static bool _isTheSamePart<T>(Vertex<T> v1, Vertex<T> v2, Map<Vertex<T>, Set<Vertex<T>>> membershipMap) {
    return membershipMap.get(v1) == membershipMap.get(v2);
  }

  static void _union<T>(Vertex<T> v1, Vertex<T> v2, Map<Vertex<T>, Set<Vertex<T>>> membershipMap) {
    Set<Vertex<T>> firstSet = membershipMap.get(v1)!;
    Set<Vertex<T>> secondSet = membershipMap.get(v2)!;
    if (secondSet.length > firstSet.length) {
      Set<Vertex<T>> tempSet = firstSet;
      firstSet = secondSet;
      secondSet = tempSet;
    }
    for (Vertex<T> v in secondSet) {
      membershipMap.put(v, firstSet);
    }
    firstSet.addAll(secondSet);
  }
}
