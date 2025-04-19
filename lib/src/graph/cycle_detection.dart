import 'graph.dart';

///循环检测
extension CycleDetection<T> on Graph<T> {
  bool isCycle() {
    if (type != GraphType.undirected) throw "Graph is needs to be Undirected.";

    final Set<Vertex<T>> visitedVerticies = {};
    final Set<Edge<T>> visitedEdges = {};

    final List<Vertex<T>> verticies = vertices;
    if (verticies.isEmpty) {
      return false;
    }

    final Vertex<T> root = verticies[0];
    return _depthFirstSearch(root, visitedVerticies, visitedEdges);
  }

  static bool _depthFirstSearch<T>(Vertex<T> vertex, Set<Vertex<T>> visitedVerticies, Set<Edge<T>> visitedEdges) {
    if (visitedVerticies.contains(vertex)) {
      return true;
    }

    visitedVerticies.add(vertex);
    final List<Edge<T>> edges = vertex.edges;
    for (Edge<T> edge in edges) {
      final Vertex<T> to = edge.to;
      bool result = false;
      if (!visitedEdges.contains(edge)) {
        visitedEdges.add(edge);
        final Edge<T> recip = Edge<T>(edge.cost, edge.to, edge.from);
        visitedEdges.add(recip);
        result = _depthFirstSearch(to, visitedVerticies, visitedEdges);
      }
      if (result == true) return true;
    }
    return false;
  }
}
