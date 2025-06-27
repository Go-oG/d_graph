
import 'package:d_util/d_util.dart';

import 'graph.dart';

/// 贝尔曼-福特的最短路径。
/// 适用于负加权和正加权边。还可以检测负权重循环。返回最短路径和路径。
extension BellmanFord<T> on Graph<T> {
  Map<Vertex<T>, CostPath<T>> shortestPathsByBellmanFord(Vertex<T> start) {
    final Map<Vertex<T>, List<Edge<T>>> paths = {};
    final Map<Vertex<T>, CostVertex<T>> costs = {};

    _getShortestPath2(this, start, paths, costs);

    final Map<Vertex<T>, CostPath<T>> map = {};
    for (CostVertex<T> pair in costs.values) {
      final int cost = pair.cost;
      final Vertex<T> vertex = pair.vertex;
      final List<Edge<T>> path = paths[vertex]!;
      map.put(vertex, CostPath(cost, path));
    }
    return map;
  }

  CostPath<T> shortestPathsByBellmanFord2(Vertex<T> start, Vertex<T> end) {
    final Map<Vertex<T>, List<Edge<T>>> paths = {};
    final Map<Vertex<T>, CostVertex<T>> costs = {};
    return _getShortestPath(this, start, end, paths, costs);
  }

  static CostPath<T> _getShortestPath<T>(
    Graph<T> graph,
    Vertex<T> start,
    Vertex<T> end,
    Map<Vertex<T>, List<Edge<T>>> paths,
    Map<Vertex<T>, CostVertex<T>> costs,
  ) {
    _getShortestPath2(graph, start, paths, costs);
    final CostVertex<T> pair = costs.get(end)!;
    final List<Edge<T>> list = paths.get(end)!;
    return CostPath(pair.cost, list);
  }

  static void _getShortestPath2<T>(
    Graph<T> graph,
    Vertex<T> start,
    Map<Vertex<T>, List<Edge<T>>> paths,
    Map<Vertex<T>, CostVertex<T>> costs,
  ) {
    for (Vertex<T> v in graph.vertices) {
      paths.put(v, []);
    }

    for (Vertex<T> v in graph.vertices) {
      if (v == start) {
        costs.put(v, CostVertex(0, v));
      } else {
        costs.put(v, CostVertex(Integer.maxValue, v));
      }
    }

    bool negativeCycleCheck = false;
    for (int i = 0; i < graph.vertices.length; i++) {
      if (i == (graph.vertices.length - 1)) {
        negativeCycleCheck = true;
      }

      for (Edge<T> e in graph.edges) {
        final CostVertex<T> pair = costs.get(e.to)!;
        final CostVertex<T> lowestCostToThisVertex = costs.get(e.from)!;

        if (lowestCostToThisVertex.cost == Integer.maxValue) {
          continue;
        }

        final int cost = lowestCostToThisVertex.cost + e.cost;
        if (cost < pair.cost) {
          pair.cost = cost;
          if (negativeCycleCheck) {
            throw "Graph contains a negative weight cycle.";
          }
          final List<Edge<T>> list = paths.get(e.to)!;
          list.clear();
          list.addAll(paths.get(e.from)!);
          list.add(e);
        }
      }
    }
  }
}
