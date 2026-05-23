import 'package:dart_graph/dart_graph.dart';

/// 计算图的连通分量
/// 如果图是有向的，该算法将其视为无向图处理（即计算弱连通分量）。
/// 返回一个列表，其中每个元素都是一个连通分量（由 Vertex 组成的列表）。
extension ConnectedComponentsExtension<V, E> on Graph<V, E> {
  List<List<Vertex<V>>> connectedComponents() {
    final Set<String> visited = {};
    final List<List<Vertex<V>>> components = [];
    for (final vertex in vertexIterator) {
      if (!visited.contains(vertex.id)) {
        final List<Vertex<V>> currentComponent = [];
        _dfsVisit(this, vertex, visited, currentComponent);
        components.add(currentComponent);
      }
    }

    return components;
  }

  void _dfsVisit(
    Graph<V, E> g,
    Vertex<V> currentVertex,
    Set<String> visited,
    List<Vertex<V>> currentComponent,
  ) {
    visited.add(currentVertex.id);
    currentComponent.add(currentVertex);
    final neighbors = _getNeighbors(g, currentVertex);

    for (final neighborVertex in neighbors) {
      if (!visited.contains(neighborVertex.id)) {
        _dfsVisit(g, neighborVertex, visited, currentComponent);
      }
    }
  }

  Iterable<Vertex<V>> _getNeighbors(Graph<V, E> g, Vertex<V> v) =>
      g.neighborVertices(v.id);
}
