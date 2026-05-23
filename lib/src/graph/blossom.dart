import 'dart:collection';

import 'graph.dart';
import 'utils.dart';

/// 一般图最大匹配算法 (Edmonds' Blossom Algorithm)
/// 时间复杂度: O(V^3)
extension BlossomAlgorithm<V, E> on Graph<V, E> {
  MatchingResult<V> maxMatchingGeneral() {
    final vertices = vertexIterator.toList();
    final int n = vertices.length;

    final Map<String, int> idToIndex = {};
    for (int i = 0; i < n; i++) {
      idToIndex[vertices[i].id] = i;
    }

    final List<int> match = List.filled(n, -1);
    final List<int> p = List.filled(n, -1);
    final List<int> base = List.filled(n, 0);
    final List<int> used = List.filled(n, 0);

    final List<bool> blossom = List.filled(n, false);
    final List<int> stateList = List.filled(n, 0);

    final Queue<int> q = Queue<int>();

    int getLCA(int u, int v) {
      final List<int> path = [];
      int curr = u;
      while (true) {
        curr = base[curr];
        path.add(curr);
        used[curr] = 1;
        if (match[curr] == -1) break;
        curr = p[match[curr]];
      }

      curr = v;
      while (true) {
        curr = base[curr];
        if (used[curr] == 1) return curr; // 找到 LCA
        curr = p[match[curr]];
      }
    }

    void markBlossom(int u, int v, int lca) {
      while (base[u] != lca) {
        final int partner = match[u];
        blossom[base[u]] = true;
        blossom[base[partner]] = true;

        u = partner;
        if (base[u] != lca) {
          p[u] = v;
        }
        v = u;
        u = p[match[u]];
      }
    }

    void contract(int u, int v) {
      for (int i = 0; i < n; i++) {
        used[i] = 0;
      }

      final int lca = getLCA(u, v);

      blossom.fillRange(0, n, false);
      markBlossom(u, v, lca);
      markBlossom(v, u, lca);

      for (int i = 0; i < n; i++) {
        if (blossom[base[i]]) {
          base[i] = lca;
          if (stateList[i] == 2) {
            stateList[i] = 1;
            q.add(i);
          }
        }
      }
    }

    bool findAugmentingPath(int root) {
      stateList.fillRange(0, n, 0);
      p.fillRange(0, n, -1);
      for (int i = 0; i < n; i++) {
        base[i] = i;
      }

      stateList[root] = 1;
      q.clear();
      q.add(root);

      while (q.isNotEmpty) {
        final int u = q.removeFirst();
        final Vertex<V> uVertex = vertices[u];
        final neighbors = _getNeighborsIndices(this, uVertex, idToIndex);

        for (final int v in neighbors) {
          if (base[u] == base[v] || match[u] == v) continue;
          if (v == root || (match[v] != -1 && p[match[v]] != -1)) {
            // 这种判断方式比较隐晦，更标准的判断是 state[v] == 1
          }

          if (stateList[v] == 1) {
            contract(u, v);
          } else if (stateList[v] == 0) {
            p[v] = u;
            stateList[v] = 2;

            if (match[v] == -1) {
              int cur = v;
              while (cur != -1) {
                final int prev = p[cur];
                final int next = match[prev];
                match[cur] = prev;
                match[prev] = cur;
                cur = next;
              }
              return true;
            } else {
              final int partner = match[v];
              stateList[partner] = 1;
              q.add(partner);
            }
          }
        }
      }
      return false;
    }

    for (int i = 0; i < n; i++) {
      if (match[i] == -1) {
        findAugmentingPath(i);
      }
    }

    final Map<Vertex<V>, Vertex<V>> mateResult = {};
    for (int i = 0; i < n; i++) {
      if (match[i] != -1) {
        mateResult[vertices[i]] = vertices[match[i]];
      }
    }

    return MatchingResult(mateResult);
  }

  Iterable<int> _getNeighborsIndices(
    Graph<V, E> g,
    Vertex<V> v,
    Map<String, int> idToIndex,
  ) sync* {
    final seen = <int>{};
    for (final edge in g.connectedEdges(v.id)) {
      final neighborId = (edge.from == v.id) ? edge.to : edge.from;
      if (neighborId == v.id) continue;
      final idx = idToIndex[neighborId];
      if (idx != null && seen.add(idx)) yield idx;
    }
  }
}
