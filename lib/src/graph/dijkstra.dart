import 'package:collection/collection.dart';

import '../../dart_graph.dart';

extension Dijkstra<T> on Graph<T> {
  Map<Vertex<T>, CostPath<T>> shortestPathsByDijkstra(Vertex<T> start) {
    final Map<Vertex<T>, List<Edge<T>>> paths = {};
    final Map<Vertex<T>, CostVertex<T>> costs = {};
    _getShortestPath2(this, start, null, paths, costs);

    final Map<Vertex<T>, CostPath<T>> map = {};
    for (CostVertex<T> pair in costs.values) {
      int cost = pair.cost;
      Vertex<T> vertex = pair.vertex;
      List<Edge<T>> path = paths[vertex]!;
      map[vertex] = CostPath(cost, path);
    }
    return map;
  }

  CostPath<T>? shortestPathsByDijkstra2(Vertex<T> start, Vertex<T> end) {
    final bool hasNegativeEdge = _checkForNegativeEdges(vertices);
    if (hasNegativeEdge) {
      throw "Negative cost Edges are not allowed.";
    }

    final Map<Vertex<T>, List<Edge<T>>> paths = {};
    final Map<Vertex<T>, CostVertex<T>> costs = {};
    return _getShortestPath2(this, start, end, paths, costs);
  }

  static CostPath<T>? _getShortestPath2<T>(
    Graph<T> graph,
    Vertex<T> start,
    Vertex<T>? end,
    Map<Vertex<T>, List<Edge<T>>> paths,
    Map<Vertex<T>, CostVertex<T>> costs,
  ) {
    bool hasNegativeEdge = _checkForNegativeEdges(graph.vertices);
    if (hasNegativeEdge) {
      throw "Negative cost Edges are not allowed.";
    }

    for (var v in graph.vertices) {
      paths[v] = [];
    }

    for (var v in graph.vertices) {
      if (v == start) {
        costs[v] = CostVertex(0, v);
      } else {
        costs[v] = CostVertex(Integer.maxValue, v);
      }
    }

    final PriorityQueue<CostVertex<T>> unvisited = PriorityQueue();
    unvisited.add(costs[start]!);

    while (unvisited.isNotEmpty) {
      final CostVertex<T> pair = unvisited.removeFirst();
      final Vertex<T> vertex = pair.vertex;
      for (Edge<T> e in vertex.edges) {
        final CostVertex<T> toPair = costs[e.to]!; // O(1)
        final CostVertex<T> lowestCostToThisVertex = costs[vertex]!; // O(1)
        final int cost = lowestCostToThisVertex.cost + e.cost;
        if (toPair.cost == Integer.maxValue) {
          unvisited.remove(toPair);
          toPair.cost = cost;
          unvisited.add(toPair);
          List<Edge<T>> set = paths[e.to]!;
          set.addAll(paths[e.from]!);
          set.add(e);
        } else if (cost < toPair.cost) {
          unvisited.remove(toPair);
          toPair.cost = cost;
          unvisited.add(toPair);

          List<Edge<T>> set = paths[e.to]!;
          set.clear();
          set.addAll(paths[e.from]!);
          set.add(e);
        }
      }

      if (end != null && vertex == end) {
        // We are looking for shortest path to a specific vertex, we found it.
        break;
      }
    }

    if (end != null) {
      final CostVertex<T> pair = costs[end]!;
      final List<Edge<T>> set = paths[end]!;
      return CostPath<T>(pair.cost, set);
    }
    return null;
  }

  static bool _checkForNegativeEdges<T>(Iterable<Vertex<T>> vertices) {
    for (Vertex<T> v in vertices) {
      for (Edge<T> e in v.edges) {
        if (e.cost < 0) {
          return true;
        }
      }
    }
    return false;
  }
}
