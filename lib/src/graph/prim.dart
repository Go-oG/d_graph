import 'package:collection/collection.dart';

import 'graph.dart';

/// Prim 的最小生成树。仅适用于无向图。它找到一个
/// 边的子集，该子集形成一个包含每个顶点的树，其中
/// 树中所有边的总重量最小化。
extension Prim on Graph {
  CostPath minSpanningTreeByPrim(Vertex start) {
    if (directed) {
      throw "Undirected graphs only.";
    }
    double cost = 0;
    final Set<Vertex> unvisited = <Vertex>{};
    unvisited.addAll(vertexIterator);
    unvisited.remove(start);
    final List<Edge> path = [];
    final PriorityQueue<Edge> edgesAvailable = PriorityQueue();
    Vertex vertex = start;
    while (unvisited.isNotEmpty) {
      for (Edge e in edges(vertex.id)) {
        if (unvisited.contains(getVertexOrNull(e.to))) {
          edgesAvailable.add(e);
        }
      }
      final Edge e = edgesAvailable.removeFirst();
      cost += e.value;
      path.add(e);
      vertex = getVertex(e.to);
      unvisited.remove(vertex);
    }
    return CostPath(cost, path);
  }
}
