import 'dart:collection';

import 'package:dart_graph/dart_graph.dart';

import 'graph.dart';

/// 基于邻接表遍历，性能为 O(V+E)
extension BFSExtension<V, E> on Graph<V, E> {
  List<Vertex<V>> bfs(Vertex<V> start) {
    if (!hasVertex(start.id)) return [];

    final Set<String> visited = {};
    final List<Vertex<V>> result = [];
    final Queue<Vertex<V>> queue = Queue();
    visited.add(start.id);
    queue.add(start);
    result.add(start);
    while (queue.isNotEmpty) {
      final Vertex<V> current = queue.removeFirst();
      for (final edge in traversableEdges(current.id)) {
        final String neighborId = (edge.from == current.id)
            ? edge.to
            : edge.from;
        if (!visited.contains(neighborId)) {
          final neighbor = vertexOfNull(neighborId);
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
