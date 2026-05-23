import '../../dart_graph.dart';

/// Floyd-Warshall 算法
/// 计算图中所有顶点对之间的最短路径。
/// 支持负权边，但不支持负权环。
/// 时间复杂度: O(V^3)
extension FloydWarshallExtension<V, E> on Graph<V, E> {
  Map<Vertex<V>, Map<Vertex<V>, double>> getVertexAllShortestPaths() {
    final vertices = vertexIterator.toList();
    final int n = vertices.length;

    final Map<String, int> idToIndex = {};
    for (int i = 0; i < n; i++) {
      idToIndex[vertices[i].id] = i;
    }

    final List<double> dist = List.filled(n * n, double.infinity);

    for (int i = 0; i < n; i++) {
      dist[i * n + i] = 0.0;
    }

    for (final edge in edgeIterator) {
      final u = idToIndex[edge.from];
      final v = idToIndex[edge.to];

      if (u != null && v != null) {
        final uv = u * n + v;
        if (edge.weight < dist[uv]) {
          dist[uv] = edge.weight;
        }

        if (!edge.directed) {
          final vu = v * n + u;
          if (edge.weight < dist[vu]) {
            dist[vu] = edge.weight;
          }
        }
      }
    }

    for (int k = 0; k < n; k++) {
      final kOffset = k * n;
      for (int i = 0; i < n; i++) {
        final ik = dist[i * n + k];
        if (ik.isInfinite) continue;
        final iOffset = i * n;
        for (int j = 0; j < n; j++) {
          final kj = dist[kOffset + j];
          if (kj.isInfinite) continue;
          final newDist = ik + kj;
          final ij = iOffset + j;
          if (newDist < dist[ij]) {
            dist[ij] = newDist;
          }
        }
      }
    }

    for (int i = 0; i < n; i++) {
      if (dist[i * n + i] < 0) {
        throw StateError(
          "Graph contains a negative weight cycle. Floyd-Warshall cannot yield reliable results.",
        );
      }
    }

    final Map<Vertex<V>, Map<Vertex<V>, double>> result = {};
    for (int i = 0; i < n; i++) {
      final vFrom = vertices[i];
      final Map<Vertex<V>, double> pathsFromV = {};
      final iOffset = i * n;
      for (int j = 0; j < n; j++) {
        final distance = dist[iOffset + j];
        if (!distance.isInfinite) {
          pathsFromV[vertices[j]] = distance;
        }
      }
      result[vFrom] = pathsFromV;
    }
    return result;
  }
}
