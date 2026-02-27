import 'package:collection/collection.dart';

import 'graph.dart';
import 'utils.dart';

/// Prim 的最小生成树。仅适用于无向图。它找到一个
/// 边的子集，该子集形成一个包含每个顶点的树，其中
/// 树中所有边的总重量最小化。
/// 时间复杂度: O(E log E)
extension PrimExtension on Graph {

  MSTResult minSpanningTreeByPrim(Vertex start) {
    if (directed) {
      throw StateError("Prim's algorithm strictly requires an undirected graph.");
    }
    if (!vertexMap.containsKey(start.id)) {
      throw ArgumentError("Start vertex not found in graph.");
    }
    double totalCost = 0.0;
    final List<Edge> mstEdges = [];
    final Set<String> visited = {};
    final PriorityQueue<Edge> pq = PriorityQueue((a, b) => a.weight.compareTo(b.weight));
    _visit(start, visited, pq);

    while (pq.isNotEmpty) {
      final Edge edge = pq.removeFirst();
      if (visited.contains(edge.to)) {
        continue;
      }
      mstEdges.add(edge);
      totalCost += edge.weight;

      final nextVertex = vertexMap[edge.to];
      if (nextVertex != null) {
        _visit(nextVertex, visited, pq);
      }
    }
    return MSTResult(totalCost, mstEdges);
  }

  ///标记节点为已访问，并将其连接到未访问节点的边加入队列
  void _visit(Vertex v, Set<String> visited, PriorityQueue<Edge> pq) {
    visited.add(v.id);
    for (final edge in outEdges(v.id).values) {
      if (!visited.contains(edge.to)) {
        pq.add(edge);
      }
    }
  }
}
