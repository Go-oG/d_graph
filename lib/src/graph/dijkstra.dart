import '../../dart_graph.dart';

extension Dijkstra on Graph {
  Map<Vertex, CostPath> shortestPathsByDijkstra(Vertex start) {
    final Map<Vertex, List<Edge>> paths = {};
    final Map<Vertex, CostVertex> costs = {};
    _getShortestPath2(this, start, null, paths, costs);

    final Map<Vertex, CostPath> map = {};
    for (CostVertex pair in costs.values) {
      double cost = pair.cost;
      Vertex vertex = pair.vertex;
      List<Edge> path = paths[vertex]!;
      map[vertex] = CostPath(cost, path);
    }
    return map;
  }

  CostPath? shortestPathsByDijkstra2(Vertex start, Vertex end) {
    final bool hasNegativeEdge = _checkForNegativeEdges(this, vertexIterator);
    if (hasNegativeEdge) {
      throw "Negative cost Edges are not allowed.";
    }

    final Map<Vertex, List<Edge>> paths = {};
    final Map<Vertex, CostVertex> costs = {};
    return _getShortestPath2(this, start, end, paths, costs);
  }

  static CostPath? _getShortestPath2(
    Graph graph,
    Vertex start,
    Vertex? end,
    Map<Vertex, List<Edge>> paths,
    Map<Vertex, CostVertex> costs,
  ) {
    bool hasNegativeEdge = _checkForNegativeEdges(graph, graph.vertexIterator);
    if (hasNegativeEdge) {
      throw "Negative cost Edges are not allowed.";
    }

    for (var v in graph.vertexIterator) {
      paths[v] = [];
    }

    for (var v in graph.vertexIterator) {
      if (v == start) {
        costs[v] = CostVertex(0, v);
      } else {
        costs[v] = CostVertex(Double.maxValue, v);
      }
    }

    final PriorityQueue<CostVertex> unvisited = PriorityQueue();
    unvisited.add(costs[start]!);

    while (unvisited.isNotEmpty) {
      final CostVertex pair = unvisited.removeFirst();
      final Vertex vertex = pair.vertex;
      for (Edge e in graph.edges2(vertex)) {
        final CostVertex toPair = costs[graph.getVertex(e.to)]!;
        final CostVertex lowestCostToThisVertex = costs[vertex]!;
        final cost = lowestCostToThisVertex.cost + e.value;
        if (toPair.cost == Integer.maxValue) {
          unvisited.remove(toPair);
          toPair.cost = cost;
          unvisited.add(toPair);
          List<Edge> set = paths[graph.getVertex(e.to)]!;
          set.addAll(paths[graph.getVertex(e.from)]!);
          set.add(e);
        } else if (cost < toPair.cost) {
          unvisited.remove(toPair);
          toPair.cost = cost;
          unvisited.add(toPair);

          List<Edge> set = paths[graph.getVertex(e.to)]!;
          set.clear();
          set.addAll(paths[graph.getVertex(e.from)]!);
          set.add(e);
        }
      }

      if (end != null && vertex == end) {
        break;
      }
    }

    if (end != null) {
      final CostVertex pair = costs[end]!;
      final List<Edge> set = paths[end]!;
      return CostPath(pair.cost, set);
    }
    return null;
  }

  static bool _checkForNegativeEdges(Graph g, Iterable<Vertex> vertices) {
    for (Vertex v in vertices) {
      for (Edge e in g.edges(v.id)) {
        if (e.value < 0) {
          return true;
        }
      }
    }
    return false;
  }
}
