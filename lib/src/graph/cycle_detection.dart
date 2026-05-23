import 'graph.dart';

///循环检测
extension CycleDetection<V, E> on Graph<V, E> {
  bool hasCycle() {
    if (directed) {
      throw StateError(
        "Current implementation only supports Undirected Graphs.",
      );
    }

    final Set<String> visited = {};

    for (final vertex in vertexIterator) {
      if (!visited.contains(vertex.id)) {
        if (_dfsDetectCycle(this, vertex, null, visited)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _dfsDetectCycle(
    Graph<V, E> g,
    Vertex<V> current,
    Vertex<V>? parent,
    Set<String> visited,
  ) {
    visited.add(current.id);
    final neighbors = _getNeighbors(g, current);

    for (final neighbor in neighbors) {
      if (neighbor.id == parent?.id) {
        continue;
      }
      if (visited.contains(neighbor.id)) {
        return true;
      }
      if (_dfsDetectCycle(g, neighbor, current, visited)) {
        return true;
      }
    }
    return false;
  }

  Iterable<Vertex<V>> _getNeighbors(Graph<V, E> g, Vertex<V> v) =>
      g.neighborVertices(v.id, includeIncoming: false);
}
