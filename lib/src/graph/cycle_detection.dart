import 'graph.dart';

///循环检测
extension CycleDetection on Graph {

  bool hasCycle() {
    if (directed) {
      throw StateError("Current implementation only supports Undirected Graphs.");
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

  static bool _dfsDetectCycle(Graph g, Vertex current, Vertex? parent, Set<String> visited) {
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

  static Iterable<Vertex> _getNeighbors(Graph g, Vertex v) sync* {
    final outEdges = g.outEdges(v);
    for (final edge in outEdges.values) {
      final neighborId = (edge.from == v.id) ? edge.to : edge.from;
      if (neighborId == v.id) continue;
      final neighbor = g.vertexMap[neighborId];
      if (neighbor != null) yield neighbor;
    }
  }
}
