import 'dart:collection';
import 'dart:math';
import 'package:d_util/d_util.dart';

/// Edmonds-Karp 算法是 Ford-Fulkerson 方法的一种实现，用于
/// 计算流网络中以 O（V*E^2） 时间内的最大流量。

final class EdmondsKarp {
  late final int n, m;
  late final Array<Array<int>> flow;
  late final Array<Array<int>> capacity;
  late final Array<int> parent;
  late final Array<bool> visited;

  EdmondsKarp(int numOfVertices, int numOfEdges) {
    n = numOfVertices;
    m = numOfEdges;
    flow = Array.matrix(n);
    capacity = Array.matrix(n);
    parent = Array(n);
    visited = Array(n);
  }

  void addEdge(int from, int to, int capacity) {
    assert(capacity >= 0);

    this.capacity[from][to] += capacity;
  }

  int getMaxFlow(int s, int t) {
    while (true) {
      final Queue<int> Q = Queue();
      Q.add(s);

      for (int i = 0; i < n; ++i) {
        visited[i] = false;
      }
      visited[s] = true;

      bool check = false;
      int current;
      while (Q.isNotEmpty) {
        current = Q.first;
        if (current == t) {
          check = true;
          break;
        }
        Q.removeFirst();
        for (int i = 0; i < n; ++i) {
          if (!visited[i] && capacity[current][i] > flow[current][i]) {
            visited[i] = true;
            Q.add(i);
            parent[i] = current;
          }
        }
      }
      if (check == false) {
        break;
      }

      int temp = capacity[parent[t]][t] - flow[parent[t]][t];
      for (int i = t; i != s; i = parent[i]) {
        temp = min(temp, (capacity[parent[i]][i] - flow[parent[i]][i]));
      }

      for (int i = t; i != s; i = parent[i]) {
        flow[parent[i]][i] += temp;
        flow[i][parent[i]] -= temp;
      }
    }

    int result = 0;
    for (int i = 0; i < n; ++i) {
      result += flow[s][i];
    }
    return result;
  }
}
