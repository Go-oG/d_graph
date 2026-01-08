import '../../dart_graph.dart';

/// Floyd-Warshall 算法
/// 计算图中所有顶点对之间的最短路径。
/// 支持负权边，但不支持负权环。
/// 时间复杂度: O(V^3)
extension FloydWarshallExtension on Graph {

  Map<Vertex, Map<Vertex, double>> getVertexAllShortestPaths() {
    final vertices = vertexIterator.toList();
    final int n = vertices.length;

    final Map<String, int> idToIndex = {};
    for (int i = 0; i < n; i++) {
      idToIndex[vertices[i].id] = i;
    }

    final List<List<double>> dist = List.generate(n, (_) => List.filled(n, double.infinity));

    for (int i = 0; i < n; i++) {
      dist[i][i] = 0.0;
    }

    for (final edge in edgeIterator) {
      final u = idToIndex[edge.from];
      final v = idToIndex[edge.to];

      if (u != null && v != null) {
        if (edge.weight < dist[u][v]) {
          dist[u][v] = edge.weight;
        }

        if (!edge.isDirected(directed)) {
          if (edge.weight < dist[v][u]) {
            dist[v][u] = edge.weight;
          }
        }
      }
    }

    for (int k = 0; k < n; k++) {
      for (int i = 0; i < n; i++) {
        if (dist[i][k] == double.infinity) continue;
        for (int j = 0; j < n; j++) {
          if (dist[k][j] == double.infinity) continue;
          final newDist = dist[i][k] + dist[k][j];
          if (newDist < dist[i][j]) {
            dist[i][j] = newDist;
          }
        }
      }
    }

    for (int i = 0; i < n; i++) {
      if (dist[i][i] < 0) {
        throw StateError("Graph contains a negative weight cycle. Floyd-Warshall cannot yield reliable results.");
      }
    }

    final Map<Vertex, Map<Vertex, double>> result = {};
    for (int i = 0; i < n; i++) {
      final vFrom = vertices[i];
      final Map<Vertex, double> pathsFromV = {};
      for (int j = 0; j < n; j++) {
        if (dist[i][j] != double.infinity) {
          pathsFromV[vertices[j]] = dist[i][j];
        }
      }
      result[vFrom] = pathsFromV;
    }
    return result;
  }

}
