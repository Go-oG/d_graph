import 'package:dart_graph/dart_graph.dart';

/// 在图论中，无向图的连通分量（或只是分量）是一个子图，其中任意两个顶点都连接到每个
/// other by path 的 PATHS，并且它不连接到超图中的其他顶点。没有入射边的顶点本身就是 connected
///元件。本身连通的图恰好有一个连通分量，由整个图组成
extension CCEG on Graph {
  List<List<Vertex>> connectedComponents() {
    if (!directed) {
      throw "Cannot perform a connected components search on a non-directed graph";
    }
    final Map<Vertex, int> map = {};
    final List<List<Vertex>> list = [];

    int c = 0;
    for (Vertex v in vertexIterator) {
      if (map[v] == null) _visit(this, map, list, v, c++);
    }
    return list;
  }

  static void _visit(Graph g, Map<Vertex, int> map, List<List<Vertex>> list, Vertex v, int c) {
    map.put(v, c);

    List<Vertex>? r;
    if (c == list.size) {
      r = [];
      list.add(r);
    } else {
      r = list.get(c);
    }
    r.add(v);
    bool found = false;
    for (Edge e in g.edges2(v)) {
      final Vertex to = g.getVertex(e.to);
      if (map[to] == null) {
        _visit(g, map, list, to, c);
        found = true;
      }
      if (found) {
        break;
      }
    }
  }
}
