import 'package:d_util/d_util.dart';

import 'graph.dart';

/// 在计算机科学中，拓扑排序（有时缩写为 topSort）或有向图的拓扑排序
/// 对于每个顶点 使得对于每个边 UV，u 在排序中位于 v 之前。
extension TopologicalSort on Graph {
  ///对有向图执行拓扑排序。如果检测到循环，则返回 NULL.
  List<Vertex>? sort() {
    if (!directed) {
      throw "Cannot perform a topological sort on a non-directed graph. graph type = ";
    }

    final Graph clone = Graph.of(this);
    final List<Vertex> sorted = [];
    final List<Vertex> noOutgoing = [];

    final List<Edge> edges = [];
    edges.addAll(clone.edgeIterator);

    for (Vertex v in clone.vertexIterator) {
      if (clone.edges(v.id).isEmpty) {
        noOutgoing.add(v);
      }
    }

    while (noOutgoing.isNotEmpty) {
      final Vertex current = noOutgoing.removeAt(0);
      sorted.add(current);

      int i = 0;
      while (i < edges.length) {
        final Edge e = edges.get(i);
        final Vertex from = clone.getVertex(e.from);
        final Vertex to = clone.getVertex(e.to);
        if (to == current) {
          edges.remove(e);
          clone.removeEdge(e);
        } else {
          i++;
        }
        if (clone.edges(from.id).isEmpty) {
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
