import 'dart:collection';

import 'package:dart_graph/dart_graph.dart';

import 'graph.dart';

/// 基于邻接表遍历，性能为 O(V+E)
extension BFSExtension on Graph {
  List<Vertex> bfs(Vertex start) {
    if (!hasVertex(start)) return [];

    final Set<String> visited = {};
    final List<Vertex> result = [];
    final Queue<Vertex> queue = Queue();
    visited.add(start.id);
    queue.add(start);
    result.add(start);
    while (queue.isNotEmpty) {
      final Vertex current = queue.removeFirst();
      final edgeMap = outEdges(current);

      for (final edge in edgeMap.values) {
        final String neighborId = (edge.from == current.id) ? edge.to : edge.from;
        if (!visited.contains(neighborId)) {
          final neighbor = getVertexOrNull(neighborId);
          if (neighbor != null) {
            visited.add(neighborId);
            queue.add(neighbor);
            result.add(neighbor);
          }
        }
      }
    }
    return result;
  }
}
