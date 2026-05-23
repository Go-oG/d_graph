import 'package:dart_graph/dart_graph.dart';

extension DFSExtension<V, E> on Graph<V, E> {
  List<Vertex<V>> dfs(Vertex<V> source) {
    if (!vertexMap.containsKey(source.id)) {
      throw ArgumentError(
        'Source vertex ${source.id} does not exist in the graph.',
      );
    }

    final List<Vertex<V>> result = [];
    final Set<String> visited = {};
    final List<Vertex<V>> stack = [];
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

  Iterable<Vertex<V>> _getNeighbors(Vertex<V> v) =>
      neighborVertices(v.id, includeIncoming: false);
}
