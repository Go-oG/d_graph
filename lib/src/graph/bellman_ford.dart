import 'package:d_util/d_util.dart';

import 'graph.dart';

/// 贝尔曼-福特的最短路径。
/// 适用于负加权和正加权边。还可以检测负权重循环。返回最短路径和路径。
extension BellmanFord on Graph {
  Map<Vertex, CostPath> shortestPathsByBellmanFord(Vertex start) {
    final Map<Vertex, List<Edge>> paths = {};
    final Map<Vertex, CostVertex> costs = {};

    _getShortestPath2(this, start, paths, costs);

    final Map<Vertex, CostPath> map = {};
    for (CostVertex pair in costs.values) {
      final cost = pair.cost;
      final Vertex vertex = pair.vertex;
      final List<Edge> path = paths[vertex]!;
      map.put(vertex, CostPath(cost, path));
    }
    return map;
  }

  CostPath shortestPathsByBellmanFord2(Vertex start, Vertex end) {
    final Map<Vertex, List<Edge>> paths = {};
    final Map<Vertex, CostVertex> costs = {};
    return _getShortestPath(this, start, end, paths, costs);
  }

  static CostPath _getShortestPath(
    Graph graph,
    Vertex start,
    Vertex end,
    Map<Vertex, List<Edge>> paths,
    Map<Vertex, CostVertex> costs,
  ) {
    _getShortestPath2(graph, start, paths, costs);
    final CostVertex pair = costs.get(end)!;
    final List<Edge> list = paths.get(end)!;
    return CostPath(pair.cost, list);
  }

  static void _getShortestPath2(
    Graph graph,
    Vertex start,
    Map<Vertex, List<Edge>> paths,
    Map<Vertex, CostVertex> costs,
  ) {
    for (Vertex v in graph.vertexIterator) {
      paths.put(v, []);
    }

    for (Vertex v in graph.vertexIterator) {
      if (v == start) {
        costs.put(v, CostVertex(0, v));
      } else {
        costs.put(v, CostVertex(Double.maxValue, v));
      }
    }

    final verticesList = graph.vertexIterator.toList();
    bool negativeCycleCheck = false;
    for (int i = 0; i < verticesList.length; i++) {
      if (i == (verticesList.length - 1)) {
        negativeCycleCheck = true;
      }

      for (Edge e in graph.edgeIterator) {
        final CostVertex pair = costs.get(graph.getVertex(e.to))!;
        final CostVertex lowestCostToThisVertex = costs.get(graph.getVertex(e.from))!;

        if (lowestCostToThisVertex.cost == Integer.maxValue) {
          continue;
        }

        final cost = lowestCostToThisVertex.cost + e.value;
        if (cost < pair.cost) {
          pair.cost = cost;
          if (negativeCycleCheck) {
            throw "Graph contains a negative weight cycle.";
          }
          final List<Edge> list = paths.get(graph.getVertex(e.to))!;
          list.clear();
          list.addAll(paths.get(graph.getVertex(e.from))!);
          list.add(e);
        }
      }
    }
  }
}
