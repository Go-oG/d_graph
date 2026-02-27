import 'graph.dart';

/// 最短路径：贝尔曼-福特算法
/// 适用于负加权和正加权边。还可以检测负权重循环。返回最短路径和路径。
extension BellmanFordExtension on Graph {
  /// Map<VertexId, CostPath>
  Map<String, CostPath> shortestPathsByBellmanFord(String start) {
    if (!hasVertex(start)) return {};

    final Map<String, double> dist = {};
    final Map<String, Edge> cameFrom = {};

    for (final v in vertexIterator) {
      dist[v.id] = double.infinity;
    }
    dist[start] = 0.0;

    final int vertexCount = vertexMap.length;

    for (int i = 0; i < vertexCount - 1; i++) {
      bool changed = false;
      for (final edge in edgeIterator) {
        if (_relax(edge, edge.from, edge.to, dist, cameFrom)) {
          changed = true;
        }
        if (!edge.directed) {
          if (_relax(edge, edge.to, edge.from, dist, cameFrom)) {
            changed = true;
          }
        }
      }
      if (!changed) break;
    }

    for (final edge in edgeIterator) {
      bool hasCycle = false;
      if (_canRelax(edge, edge.from, edge.to, dist)) hasCycle = true;
      if (!edge.directed && _canRelax(edge, edge.to, edge.from, dist)) hasCycle = true;

      if (hasCycle) {
        throw StateError("Graph contains a negative weight cycle.");
      }
    }
    final Map<String, CostPath> result = {};
    for (final v in vertexIterator) {
      if (dist[v.id] != double.infinity) {
        result[v.id] = CostPath(
          dist[v.id]!,
          _reconstructPath(cameFrom, start, v.id),
        );
      }
    }
    return result;
  }

  /// 计算从 [start] 到 [end] 的最短路径
  CostPath? shortestPathByBellmanFord(Vertex start, Vertex end) {
    final allPaths = shortestPathsByBellmanFord(start.id);
    return allPaths[end.id];
  }

  /// 执行松弛操作 return true 表示距离被更新了
  bool _relax(Edge edge, String sourceId, String targetId, Map<String, double> dist, Map<String, Edge> cameFrom) {
    final double distU = dist[sourceId] ?? double.infinity;
    final double distV = dist[targetId] ?? double.infinity;

    if (distU.isInfinite) return false;

    if (distV > distU + edge.weight) {
      dist[targetId] = distU + edge.weight;
      cameFrom[targetId] = edge;
      return true;
    }
    return false;
  }

  /// 检查是否还可以松弛（用于检测负环）
  bool _canRelax(Edge edge, String uId, String vId, Map<String, double> dist) {
    final double distU = dist[uId] ?? double.infinity;
    final double distV = dist[vId] ?? double.infinity;
    if (distU == double.infinity) return false;
    return distV > distU + edge.weight;
  }

  List<Edge> _reconstructPath(Map<String, Edge> cameFrom, String startId, String endId) {
    if (startId == endId) return [];

    final List<Edge> path = [];
    String currentId = endId;

    int safeGuard = 0;
    final int maxSteps = cameFrom.length + 10;

    while (currentId != startId) {
      final edge = cameFrom[currentId];
      if (edge == null) {
        return [];
      }
      path.add(edge);
      currentId = (edge.to == currentId) ? edge.from : edge.to;

      safeGuard++;
      if (safeGuard > maxSteps) {
        throw StateError("Path reconstruction failed (infinite loop detected)");
      }
    }
    return path.reversed.toList();
  }
}
