
import 'package:d_util/d_util.dart';

import 'graph.dart';

/// 在图论学科中，匹配或独立的边集在图中是一组没有公共顶点的边。
/// 在某些匹配中，所有顶点可能会与匹配的某些边缘发生冲突，但这不是必需的，并且只会发生在顶点数为偶数。
extension TurboMatching<T> on Graph<T> {
  MatchingResult<T> maxMatching() {
    final Map<Vertex<T>, Vertex<T>> mate = {};
    while (_pathSet(this, mate));
    return MatchingResult<T>(mate);
  }

  static bool _pathSet<T>(Graph<T> graph, Map<Vertex<T>, Vertex<T>> mate) {
    final Set<Vertex<T>> visited = <Vertex<T>>{};

    bool result = false;
    for (Vertex<T> vertex in graph.vertices) {
      if (mate.containsKey(vertex) == false) {
        if (_path(graph, mate, visited, vertex)) {
          result = true;
        }
      }
    }
    return result;
  }

  static bool _path<T>(
      Graph<T> graph, Map<Vertex<T>, Vertex<T>> mate, Set<Vertex<T>> visited, Vertex<T> vertex) {
    if (visited.contains(vertex)) {
      return false;
    }

    visited.add(vertex);
    for (Edge<T> edge in vertex.edges) {
      final Vertex<T> neighbour = edge.from == vertex ? edge.to : edge.from;
      if (mate.containsKey(neighbour) == false ||
          _path(graph, mate, visited, mate.get(neighbour)!)) {
        mate.set(vertex, neighbour);
        mate.set(neighbour, vertex);
        return true;
      }
    }
    return false;
  }
}

final class MatchingResult<T> {
  final Map<Vertex<T>, Vertex<T>> mate;
  late final int size;

  MatchingResult(this.mate) {
    this.size = mate.length ~/ 2;
  }
}
