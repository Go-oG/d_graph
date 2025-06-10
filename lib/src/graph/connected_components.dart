import 'package:dart_graph/dart_graph.dart';

/// 在图论中，无向图的连通分量（或只是分量）是一个子图，其中任意两个顶点都连接到每个
/// other by path 的 PATHS，并且它不连接到超图中的其他顶点。没有入射边的顶点本身就是 connected
///元件。本身连通的图恰好有一个连通分量，由整个图组成
extension CCEG<T> on Graph<T> {
  List<List<Vertex<T>>> connectedComponents() {
    if (type != GraphType.directed) {
      throw "Cannot perform a connected components search on a non-directed graph";
    }
    final Map<Vertex<T>, int> map = {};
    final List<List<Vertex<T>>> list = [];

    int c = 0;
    for (Vertex<T> v in vertices) {
      if (map[v] == null) _visit(map, list, v, c++);
    }
    return list;
  }

  static void _visit<T>(Map<Vertex<T>, int> map, List<List<Vertex<T>>> list, Vertex<T> v, int c) {
    map.put(v, c);

    List<Vertex<T>>? r;
    if (c == list.size) {
      r = [];
      list.add(r);
    } else {
      r = list.get(c);
    }
    r.add(v);

    if (v.edges.isNotEmpty) {
      bool found = false;
      for (Edge<T> e in v.edges) {
        final Vertex<T> to = e.to;
        if (map[to] == null) {
          _visit(map, list, to, c);
          found = true;
        }
        if (found) {
          break;
        }
      }
    }
  }
}
