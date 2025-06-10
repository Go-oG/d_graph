import 'package:collection/collection.dart';

import 'graph.dart';

/// Prim 的最小生成树。仅适用于无向图。它找到一个
/// 边的子集，该子集形成一个包含每个顶点的树，其中
/// 树中所有边的总重量最小化。
extension Prim<T> on Graph<T> {
  CostPath<T> minSpanningTreeByPrim(Vertex<T> start) {
    if (type == GraphType.directed) {
      throw "Undirected graphs only.";
    }
    int cost = 0;
    final Set<Vertex<T>> unvisited = <Vertex<T>>{};
    unvisited.addAll(vertices);
    unvisited.remove(start);
    final List<Edge<T>> path = [];
    final PriorityQueue<Edge<T>> edgesAvailable = PriorityQueue();
    Vertex<T> vertex = start;
    while (unvisited.isNotEmpty) {
      for (Edge<T> e in vertex.edges) {
        if (unvisited.contains(e.to)) {
          edgesAvailable.add(e);
        }
      }
      final Edge<T> e = edgesAvailable.removeFirst();
      cost += e.cost;
      path.add(e); // O(1)

      vertex = e.to;
      unvisited.remove(vertex); // O(1)
    }
    return CostPath<T>(cost, path);
  }
}
