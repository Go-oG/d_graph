import 'package:dart_graph/dart_graph.dart';

/// 计算图的连通分量
/// 如果图是有向的，该算法将其视为无向图处理（即计算弱连通分量）。
/// 返回一个列表，其中每个元素都是一个连通分量（由 Vertex 组成的列表）。
extension ConnectedComponentsExtension on Graph {
  List<List<Vertex>> connectedComponents() {
    final Set<String> visited = {};
    final List<List<Vertex>> components = [];
    for (final vertex in vertexIterator) {
      if (!visited.contains(vertex.id)) {
        final List<Vertex> currentComponent = [];
        _dfsVisit(this, vertex, visited, currentComponent);
        components.add(currentComponent);
      }
    }

    return components;
  }

  void _dfsVisit(Graph g, Vertex currentVertex, Set<String> visited, List<Vertex> currentComponent) {
    visited.add(currentVertex.id);
    currentComponent.add(currentVertex);
    final neighbors = _getNeighbors(g, currentVertex);

    for (final neighborVertex in neighbors) {
      if (!visited.contains(neighborVertex.id)) {
        _dfsVisit(g, neighborVertex, visited, currentComponent);
      }
    }
  }

  Iterable<Vertex> _getNeighbors(Graph g, Vertex v) sync* {
    final outEdges = g.outEdges(v.id);
    for (final edge in outEdges.values) {
      final neighborId = edge.to;
      if (neighborId == v.id) continue;
      final neighbor = g.vertexMap[neighborId];
      if (neighbor != null) yield neighbor;
    }

    final inEdges = g.inEdges(v.id);
    for (final edge in inEdges.values) {
      final neighborId = edge.from;
      if (neighborId == v.id) continue;
      final neighbor = g.vertexMap[neighborId];
      if (neighbor != null) yield neighbor;
    }
  }
}
