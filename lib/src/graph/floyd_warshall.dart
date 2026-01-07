import '../../dart_graph.dart';

/// Floyd-Warshall 算法是用于查找所有的最短路径的
/// 加权图中的路径（具有正或负边缘权重）
extension FloydWarshall on Graph {
  Map<Vertex, Map<Vertex, double>> shortestPathsByFloydWarshall() {
    final vertices = vertexIterator.toList();

    final Array<Array<double>> sums = Array(vertices.length);
    for (var i = 0; i < vertices.length; i++) {
      sums[i] = Array(vertices.length);
    }

    for (int i = 0; i < sums.length; i++) {
      for (int j = 0; j < sums[i].length; j++) {
        sums[i][j] = Double.maxValue;
      }
    }

    final List<Edge> edges = edgeIterator.toList();

    for (Edge e in edges) {
      final int indexOfFrom = vertices.indexOf(getVertex(e.from));
      final int indexOfTo = vertices.indexOf(getVertex(e.to));
      sums[indexOfFrom][indexOfTo] = e.value;
    }

    for (int k = 0; k < vertices.length; k++) {
      for (int i = 0; i < vertices.length; i++) {
        for (int j = 0; j < vertices.length; j++) {
          if (i == j) {
            sums[i][j] = 0;
          } else {
            final ijCost = sums[i][j];
            final ikCost = sums[i][k];
            final kjCost = sums[k][j];
            final summed = (ikCost != maxInt && kjCost != maxInt) ? (ikCost + kjCost) : maxInt;
            if (ijCost > summed) {
              sums[i][j] = summed.toDouble();
            }
          }
        }
      }
    }

    final Map<Vertex, Map<Vertex, double>> allShortestPaths = {};

    for (int i = 0; i < sums.length; i++) {
      for (int j = 0; j < sums[i].length; j++) {
        final Vertex from = vertices[i];
        final Vertex to = vertices[j];
        Map<Vertex, double>? map = allShortestPaths[from];
        map ??= {};
        final double cost = sums[i][j];
        if (cost != maxInt) {
          map.put(to, cost);
        }
        allShortestPaths.put(from, map);
      }
    }
    return allShortestPaths;
  }
}
