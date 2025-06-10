import 'graph.dart';

///循环检测
extension CycleDetection<T> on Graph<T> {
  bool isCycle() {
    if (type != GraphType.undirected) throw "Graph is needs to be Undirected.";

    final Set<Vertex<T>> visitedVertices = {};
    final Set<Edge<T>> visitedEdges = {};

    final vertices = this.vertices;
    if (vertices.isEmpty) {
      return false;
    }

    final Vertex<T> root = vertices[0];
    return _depthFirstSearch(root, visitedVertices, visitedEdges);
  }

  static bool _depthFirstSearch<T>(
      Vertex<T> vertex, Set<Vertex<T>> visitedVertices, Set<Edge<T>> visitedEdges) {
    if (visitedVertices.contains(vertex)) {
      return true;
    }

    visitedVertices.add(vertex);
    for (Edge<T> edge in vertex.edges) {
      final Vertex<T> to = edge.to;
      bool result = false;
      if (!visitedEdges.contains(edge)) {
        visitedEdges.add(edge);
        final Edge<T> recip = Edge<T>(edge.cost, edge.to, edge.from);
        visitedEdges.add(recip);
        result = _depthFirstSearch(to, visitedVertices, visitedEdges);
      }
      if (result == true) return true;
    }
    return false;
  }
}
