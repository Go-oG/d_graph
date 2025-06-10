import '../../dart_graph.dart';

/// Floyd-Warshall 算法是用于查找所有的最短路径的
/// 加权图中的路径（具有正或负边缘权重）
extension FloydWarshall<T> on Graph<T> {
  Map<Vertex<T>, Map<Vertex<T>, int>> shortestPathsByFloydWarshall() {
    final vertices = this.vertices;

    final Array<Array<int>> sums = Array(vertices.length);
    for (var i = 0; i < vertices.length; i++) {
      sums[i] = Array(vertices.length);
    }

    for (int i = 0; i < sums.length; i++) {
      for (int j = 0; j < sums[i].length; j++) {
        sums[i][j] = Integer.maxValue;
      }
    }

    final List<Edge<T>> edges = this.edges;

    for (Edge<T> e in edges) {
      final int indexOfFrom = vertices.indexOf(e.from);
      final int indexOfTo = vertices.indexOf(e.to);
      sums[indexOfFrom][indexOfTo] = e.cost;
    }

    for (int k = 0; k < vertices.length; k++) {
      for (int i = 0; i < vertices.length; i++) {
        for (int j = 0; j < vertices.length; j++) {
          if (i == j) {
            sums[i][j] = 0;
          } else {
            final int ijCost = sums[i][j];
            final int ikCost = sums[i][k];
            final int kjCost = sums[k][j];
            final int summed = (ikCost != maxInt && kjCost != maxInt) ? (ikCost + kjCost) : maxInt;
            if (ijCost > summed) {
              sums[i][j] = summed;
            }
          }
        }
      }
    }

    final Map<Vertex<T>, Map<Vertex<T>, int>> allShortestPaths = {};

    for (int i = 0; i < sums.length; i++) {
      for (int j = 0; j < sums[i].length; j++) {
        final Vertex<T> from = vertices[i];
        final Vertex<T> to = vertices[j];
        Map<Vertex<T>, int>? map = allShortestPaths[from];
        map ??= {};
        final int cost = sums[i][j];
        if (cost != maxInt) {
          map.put(to, cost);
        }
        allShortestPaths.put(from, map);
      }
    }
    return allShortestPaths;
  }
}
