import 'graph.dart';
import 'utils.dart';

/// 最大匹配算法扩展
/// 注意：此算法主要适用于 [二分图]。
/// 对于一般图（包含奇数长度循环的图），此算法可能无法找到最大匹配。
extension TurboMatching<V, E> on Graph<V, E> {
  MatchingResult<V> maxMatching() {
    final Map<Vertex<V>, Vertex<V>> mate = {};
    while (_findAugmentingPathsPhase(this, mate)) {}
    return MatchingResult(mate);
  }

  bool _findAugmentingPathsPhase(
    Graph<V, E> graph,
    Map<Vertex<V>, Vertex<V>> mate,
  ) {
    final Set<String> visited = {};
    bool phaseResult = false;
    for (final vertex in graph.vertexIterator) {
      if (!mate.containsKey(vertex)) {
        if (_dfs(graph, mate, visited, vertex)) {
          phaseResult = true;
        }
      }
    }
    return phaseResult;
  }

  bool _dfs(
    Graph<V, E> graph,
    Map<Vertex<V>, Vertex<V>> mate,
    Set<String> visited,
    Vertex<V> u,
  ) {
    if (visited.contains(u.id)) {
      return false;
    }
    visited.add(u.id);

    for (final v in _getNeighbors(graph, u)) {
      if (!mate.containsKey(v)) {
        mate[u] = v;
        mate[v] = u;
        return true;
      } else {
        final w = mate[v]!;
        if (_dfs(graph, mate, visited, w)) {
          mate[u] = v;
          mate[v] = u;
          return true;
        }
      }
    }
    return false;
  }

  /// 辅助方法：获取邻居 (兼容有向/无向图逻辑)
  /// 在匹配算法中，通常将图视为无向来处理连接性
  Iterable<Vertex<V>> _getNeighbors(Graph<V, E> g, Vertex<V> v) =>
      g.neighborVertices(v.id);
}
