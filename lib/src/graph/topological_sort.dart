import 'dart:collection';

import 'package:dart_graph/dart_graph.dart';

import 'graph.dart';

///拓扑排序 (Kahn's Algorithm) 返回拓扑排序后的顶点列表。
/// 如果检测到环 (Cycle)，则返回 null。
/// 时间复杂度: O(V + E)
extension TopologicalSortExtension on Graph {
  List<Vertex>? topologicalSort() {
    if (!directed) {
      throw StateError("Topological sort can only be performed on directed graphs.");
    }

    final Map<String, int> inDegrees = {};
    for (final v in vertexIterator) {
      inDegrees[v.id] =degreeOf(v.id).inDegree;
    }

    final Queue<Vertex> queue = ListQueue();
    for (final v in vertexIterator) {
      if (inDegrees[v.id] == 0) {
        queue.add(v);
      }
    }

    final List<Vertex> sortedResult = [];

    while (queue.isNotEmpty) {
      final Vertex u = queue.removeFirst();
      sortedResult.add(u);
      final outEdgesMap = outEdges(u);

      for (final edge in outEdgesMap.values) {
        final String vId = edge.to;

        final int currentInDegree = inDegrees[vId]! - 1;
        inDegrees[vId] = currentInDegree;
        if (currentInDegree == 0) {
          final v = vertexMap[vId];
          if (v != null) {
            queue.add(v);
          }
        }
      }
    }

    if (sortedResult.length != vertexMap.length) {
      return null;
    }
    return sortedResult;
  }
}
