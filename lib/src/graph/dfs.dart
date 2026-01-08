import 'package:dart_graph/dart_graph.dart';

extension DFSExtension on Graph {
  List<Vertex> dfs(Vertex source) {
    if (!vertexMap.containsKey(source.id)) {
      throw ArgumentError('Source vertex ${source.id} does not exist in the graph.');
    }

    final List<Vertex> result = [];
    final Set<String> visited = {};
    final List<Vertex> stack = [];
    stack.add(source);
    visited.add(source.id);

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      result.add(current);
      final neighbors = _getNeighbors(current).toList();
      for (var i = neighbors.length - 1; i >= 0; i--) {
        final neighbor = neighbors[i];
        if (!visited.contains(neighbor.id)) {
          visited.add(neighbor.id);
          stack.add(neighbor);
        }
      }
    }
    return result;
  }

  Iterable<Vertex> _getNeighbors(Vertex v) sync* {
    final out = outEdges(v);
    if (out.isNotEmpty) {
      for (final edge in out.values) {
        final targetId = edge.to;
        if (targetId == v.id && !allowSelfLoop) continue;
        final target = vertexMap[targetId];
        if (target != null) yield target;
      }
    }
  }
}
