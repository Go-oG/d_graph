import 'package:d_util/d_util.dart';

import 'graph.dart';

/// 在图论学科中，匹配或独立的边集在图中是一组没有公共顶点的边。
/// 在某些匹配中，所有顶点可能会与匹配的某些边缘发生冲突，但这不是必需的，并且只会发生在顶点数为偶数。
extension TurboMatching on Graph {
  MatchingResult maxMatching() {
    final Map<Vertex, Vertex> mate = {};
    while (_pathSet(this, mate));
    return MatchingResult(mate);
  }

  static bool _pathSet(Graph graph, Map<Vertex, Vertex> mate) {
    final Set<Vertex> visited = <Vertex>{};

    bool result = false;
    for (Vertex vertex in graph.vertexIterator) {
      if (mate.containsKey(vertex) == false) {
        if (_path(graph, mate, visited, vertex)) {
          result = true;
        }
      }
    }
    return result;
  }

  static bool _path(Graph graph, Map<Vertex, Vertex> mate, Set<Vertex> visited, Vertex vertex) {
    if (visited.contains(vertex)) {
      return false;
    }

    visited.add(vertex);
    for (Edge edge in graph.edges(vertex.id)) {
      final Vertex neighbour = graph.getVertex(edge.from == vertex.id ? edge.to : edge.from);
      if (mate.containsKey(neighbour) == false || _path(graph, mate, visited, mate.get(neighbour)!)) {
        mate.set(vertex, neighbour);
        mate.set(neighbour, vertex);
        return true;
      }
    }
    return false;
  }
}

final class MatchingResult {
  final Map<Vertex, Vertex> mate;
  late final int size;

  MatchingResult(this.mate) {
    this.size = mate.length ~/ 2;
  }
}
