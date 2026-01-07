import 'graph.dart';

///循环检测
extension CycleDetection on Graph {
  bool isCycle() {
    if (directed) throw "Graph is needs to be Undirected.";

    final Set<Vertex> visitedVertices = {};
    final Set<Edge> visitedEdges = {};

    final vertices = vertexIterator.toList();
    if (vertices.isEmpty) {
      return false;
    }
    return _depthFirstSearch(this, vertices[0], visitedVertices, visitedEdges);
  }

  static bool _depthFirstSearch(Graph g, Vertex vertex, Set<Vertex> visitedVertices, Set<Edge> visitedEdges) {
    if (visitedVertices.contains(vertex)) {
      return true;
    }

    visitedVertices.add(vertex);
    for (Edge edge in g.edges2(vertex)) {
      final Vertex to = g.getVertex(edge.to);
      bool result = false;
      if (!visitedEdges.contains(edge)) {
        visitedEdges.add(edge);
        final recip = Edge(value: edge.value, from: edge.to, to: edge.from, id: "\$eid:${edge.value.hashCode}\$");
        visitedEdges.add(recip);
        result = _depthFirstSearch(g, to, visitedVertices, visitedEdges);
      }
      if (result == true) return true;
    }
    return false;
  }
}
