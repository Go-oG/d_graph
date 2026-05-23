import 'dart:collection';
import 'dart:math';

/// Edmonds-Karp 算法实现
/// 使用邻接矩阵存储容量和流量
/// 时间复杂度: O(V * E^2)
final class EdmondsKarp {
  late final int n;
  late final List<List<int>> flow;
  late final List<List<int>> capacity;
  late final List<int> parent;
  late final List<bool> visited;

  EdmondsKarp(int numOfVertices) {
    n = numOfVertices;
    flow = List.generate(n, (_) => List.filled(n, 0));
    capacity = List.generate(n, (_) => List.filled(n, 0));
    parent = List.filled(n, -1);
    visited = List.filled(n, false);
  }

  /// 添加有向边
  /// [from]: 起点下标 (0 到 n-1)
  /// [to]: 终点下标 (0 到 n-1)
  /// [cap]: 容量
  void addEdge(int from, int to, int cap) {
    if (cap < 0) {
      throw ArgumentError('Capacity must be non-negative, got $cap');
    }
    // 如果是多重边（两点间多条边），容量累加
    capacity[from][to] += cap;
    // 注意：如果是无向图，通常这里也需要 capacity[to][from] += cap;
    // Edmonds-Karp 处理反向流是基于 flow[to][from] 的负值，
    // 但初始容量矩阵通常是有向的。
  }

  /// 计算从源点 [s] 到汇点 [t] 的最大流
  int getMaxFlow(int s, int t) {
    if (s == t) return 0;

    int maxFlow = 0;

    while (true) {
      final Queue<int> q = Queue();
      q.add(s);

      visited.fillRange(0, n, false);
      parent.fillRange(0, n, -1);

      visited[s] = true;
      parent[s] = -1;

      bool pathFound = false;

      while (q.isNotEmpty) {
        final int current = q.removeFirst();
        if (current == t) {
          pathFound = true;
          break;
        }
        for (int i = 0; i < n; ++i) {
          if (!visited[i] && (capacity[current][i] - flow[current][i] > 0)) {
            visited[i] = true;
            parent[i] = current;
            q.add(i);
          }
        }
      }
      if (!pathFound) {
        break;
      }

      int pathFlow = 0x7FFFFFFF;

      for (int v = t; v != s; v = parent[v]) {
        int u = parent[v];
        int residualCapacity = capacity[u][v] - flow[u][v];
        pathFlow = min(pathFlow, residualCapacity);
      }

      for (int v = t; v != s; v = parent[v]) {
        int u = parent[v];
        flow[u][v] += pathFlow;
        flow[v][u] -= pathFlow;
      }
      maxFlow += pathFlow;
    }

    return maxFlow;
  }
}
