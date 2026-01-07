
import 'package:d_util/d_util.dart';
import 'graph.dart';

/// Kruskal 的最小生成树。仅适用于无向图。它找到一个
/// 边的子集，该子集形成一个包含每个顶点的树，其中
/// 树中所有边的总重量最小化。
extension Kruskal on Graph {
  CostPath minSpanningTreeByKruskal() {
    if (directed) {
      throw "Undirected graphs only.";
    }
    double cost = 0;
    final List<Edge> path = [];
    Map<Vertex, Set<Vertex>> membershipMap = {};
    for (Vertex v in vertexIterator) {
      Set<Vertex> set = <Vertex>{};
      set.add(v);
      membershipMap.put(v, set);
    }

    PriorityQueue<Edge> edgeQueue = PriorityQueue();
    edgeQueue.addAll(edgeIterator);

    while (edgeQueue.isNotEmpty) {
      Edge edge = edgeQueue.removeFirst();
      final efv= getVertex(edge.from);
      final etv= getVertex(edge.to);

      if (!_isTheSamePart(efv, etv, membershipMap)) {
        _union(efv, etv, membershipMap);
        path.add(edge);
        cost += edge.value;
      }
    }

    return CostPath(cost, path);
  }

  static bool _isTheSamePart(Vertex v1, Vertex v2, Map<Vertex, Set<Vertex>> membershipMap) {
    return membershipMap.get(v1) == membershipMap.get(v2);
  }

  static void _union(Vertex v1, Vertex v2, Map<Vertex, Set<Vertex>> membershipMap) {
    Set<Vertex> firstSet = membershipMap.get(v1)!;
    Set<Vertex> secondSet = membershipMap.get(v2)!;
    if (secondSet.length > firstSet.length) {
      Set<Vertex> tempSet = firstSet;
      firstSet = secondSet;
      secondSet = tempSet;
    }
    for (Vertex v in secondSet) {
      membershipMap.put(v, firstSet);
    }
    firstSet.addAll(secondSet);
  }
}
