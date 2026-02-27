import 'bellman_ford.dart';
import 'dijkstra.dart';
import 'graph.dart';

/// Johnson 算法
/// 用于在包含负权边（但无负权环）的稀疏图中，计算所有顶点对之间的最短路径。
/// 返回: Map<起点, Map<终点, 路径列表>>
extension JohnsonExt on Graph {
  Map<Vertex, Map<Vertex, List<Edge>>> shortestPathsByJohnson() {
    final String connectorId = "\$_johnson_\$";

    final List<String> tempEdges = [];
    final Map<Edge, double> originalWeights = {};

    try {
      addVertex(connectorId);
      final existingVertices = vertexIterator.toList();
      for (final v in existingVertices) {
        if (v.id == connectorId) continue;
        String eid="\$${connectorId}_${v.id}\$";
        addEdge(id: eid, fromVid: connectorId, toVid: v.id, weight: 0, direct: true);
        tempEdges.add(eid);
      }
      final Map<String, double> h = _runBellmanFordSafe(connectorId);

      for (final edge in edgeIterator) {
        originalWeights[edge] = edge.weight;
        final u = vertexMap[edge.from];
        final v = vertexMap[edge.to];

        if (u != null && v != null) {
          final hU = h[u.id] ?? 0.0;
          final hV = h[v.id] ?? 0.0;
          edge.weight = edge.weight + hU - hV;
        }
      }

      final Map<Vertex, Map<Vertex, List<Edge>>> allShortestPaths = {};

      for (final u in existingVertices) {
        final dijkstraResults = shortestPaths(u);
        final Map<Vertex, List<Edge>> pathsFromU = {};
        dijkstraResults.forEach((targetId, result) {
          final targetVertex = vertexMap[targetId];
          if (targetVertex != null) {
            pathsFromU[targetVertex] = result.path;
          }
        });
        allShortestPaths[u] = pathsFromU;
      }

      return allShortestPaths;
    } finally {
      for (final entry in originalWeights.entries) {
        entry.key.weight = entry.value;
      }
      for (final edge in tempEdges) {
        removeEdge(edge);
      }
      removeVertex(connectorId);
    }
  }

  Map<String, double> _runBellmanFordSafe(String start) {
    final result = shortestPathsByBellmanFord(start);
    final Map<String, double> costs = {};
    for (final entry in result.entries) {
      costs[entry.key] = entry.value.cost;
    }
    return costs;
  }
}
