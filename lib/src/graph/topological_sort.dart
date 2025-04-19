
import 'package:d_util/d_util.dart';

import 'graph.dart';

/// 在计算机科学中，拓扑排序（有时缩写为 topsort 或
/// toposort） 或有向图的拓扑排序是
/// 其顶点，使得对于每个边 UV，u 在排序中位于 v 之前。
extension TopologicalSort<T> on Graph<T> {
  ///对有向图执行拓扑排序。如果检测到循环，则返回 NULL.
  List<Vertex<T>>? sort() {
    if (type != GraphType.directed) {
      throw "Cannot perform a topological sort on a non-directed graph. graph type = ";
    }

    final Graph<T> clone = Graph.of(this);
    final List<Vertex<T>> sorted = [];
    final List<Vertex<T>> noOutgoing = [];

    final List<Edge<T>> edges = [];
    edges.addAll(clone.edges);

    for (Vertex<T> v in clone.vertices) {
      if (v.edges.isEmpty) {
        noOutgoing.add(v);
      }
    }

    while (noOutgoing.isNotEmpty) {
      final Vertex<T> current = noOutgoing.removeAt(0);
      sorted.add(current);

      int i = 0;
      while (i < edges.length) {
        final Edge<T> e = edges.get(i);
        final Vertex<T> from = e.from;
        final Vertex<T> to = e.to;
        if (to == current) {
          edges.remove(e);
          from.edges.remove(e);
        } else {
          i++;
        }
        if (from.edges.isEmpty) {
          noOutgoing.add(from);
        }
      }
    }
    if (edges.isNotEmpty) {
      return null;
    }
    return sorted;
  }
}
