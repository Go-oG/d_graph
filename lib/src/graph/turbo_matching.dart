import 'graph.dart';
import 'utils.dart';

/// 最大匹配算法扩展
/// 注意：此算法主要适用于 [二分图]。
/// 对于一般图（包含奇数长度循环的图），此算法可能无法找到最大匹配。
extension TurboMatching on Graph {
  MatchingResult maxMatching() {
    final Map<Vertex, Vertex> mate = {};
    while (_findAugmentingPathsPhase(this, mate)) {}
    return MatchingResult(mate);
  }

  static bool _findAugmentingPathsPhase(Graph graph, Map<Vertex, Vertex> mate) {
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

  static bool _dfs(Graph graph, Map<Vertex, Vertex> mate, Set<String> visited, Vertex u) {
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
  static Iterable<Vertex> _getNeighbors(Graph g, Vertex v) sync* {
    final out = g.outEdges(v.id);
    for (final edge in out.values) {
      final neighborId = (edge.from == v.id) ? edge.to : edge.from;
      if (neighborId == v.id) continue;

      final neighbor = g.vertexMap[neighborId];
      if (neighbor != null) yield neighbor;
    }
  }
}
