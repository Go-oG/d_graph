import 'package:d_util/d_util.dart';

import 'bellman_ford.dart';
import 'dijkstra.dart';
import 'graph.dart';

/// Johnson 算法是一种查找所有稀疏有向图中的顶点。
/// 它允许一些边权重为负数，但不存在负权重循环.
extension Johnson on Graph {
  Map<Vertex, Map<Vertex, List<Edge>>> shortestPathsByJohnson(Object maxData) {
    final Graph graph = Graph.of(this);
    final Vertex connector = Vertex(data: maxData, id: "\$connector_${maxData.hashCode}\$");

    for (Vertex v in graph.vertexIterator) {
      final Edge edge = Edge(value: 0, from: connector.id, to: v.id, id: "\$id${connector.id}_${v.id}\$");
      graph.addEdge(edge);
    }

    graph.addVertex(connector);

    final Map<Vertex, CostPath> costs = graph.shortestPathsByBellmanFord(connector);

    for (Edge e in graph.edgeIterator) {
      final weight = e.value;
      final Vertex u = graph.getVertex(e.from);
      final Vertex v = graph.getVertex(e.to);
      if (u == connector || v == connector) {
        continue;
      }

      final uCost = costs.get(u)!.cost;
      final vCost = costs.get(v)!.cost;
      final newWeight = weight + uCost - vCost;
      e.value = newWeight;
    }

    graph.removeVertex(connector);

    final Map<Vertex, Map<Vertex, List<Edge>>> allShortestPaths = {};

    for (Vertex v in graph.vertexIterator) {
      final Map<Vertex, CostPath> costPaths = graph.shortestPathsByDijkstra(v);
      final Map<Vertex, List<Edge>> paths = {};
      for (Vertex v2 in costPaths.keys) {
        final CostPath pair = costPaths.get(v2)!;
        paths.put(v2, pair.path);
      }
      allShortestPaths.put(v, paths);
    }
    return allShortestPaths;
  }
}
