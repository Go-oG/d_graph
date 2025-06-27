import 'package:d_util/d_util.dart';

import 'graph.dart';

///路径查找
extension AStar<T> on Graph<T> {
  List<Edge<T>>? aStar(Vertex<T> start, Vertex<T> goal) {
    final Set<Vertex<T>> closedSet = <Vertex<T>>{};
    final List<Vertex<T>> openSet = [];
    openSet.add(start);
    final Map<Vertex<T>, Vertex<T>> cameFrom = {};

    final Map<Vertex<T>, int> gScore = {};
    gScore[start] = 0;
    final Map<Vertex<T>, int> fScore = {};
    for (Vertex<T> v in vertices) {
      fScore[v] = Integer.minValue;
    }
    fScore[start] = _heuristicCostEstimate(start, goal);

    comparator(o1, o2) {
      if (fScore[o1]! < fScore[o2]!) {
        return -1;
      }
      if (fScore[o2]! < fScore[o1]!) {
        return 1;
      }
      return 0;
    }

    while (openSet.isNotEmpty) {
      final Vertex<T> current = openSet[0];
      if (current == goal) {
        return _reconstructPath(cameFrom, goal);
      }
      openSet.removeAt(0);
      closedSet.add(current);
      for (Edge<T> edge in current.edges) {
        final Vertex<T> neighbor = edge.to;
        if (closedSet.contains(neighbor)) {
          continue;
        }

        final int tenativeGScore = gScore[current]! + _distanceBetween(current, neighbor);
        if (!openSet.contains(neighbor)) {
          openSet.add(neighbor);
        } else if (tenativeGScore >= gScore[neighbor]!) {
          continue;
        }

        cameFrom[neighbor] = current;

        gScore[neighbor] = tenativeGScore;

        final int estimatedFScore = gScore[neighbor]! + _heuristicCostEstimate(neighbor, goal);
        fScore[neighbor] = estimatedFScore;

        openSet.sort(comparator);
      }
    }

    return null;
  }

  int _distanceBetween(Vertex<T> start, Vertex<T> next) {
    for (Edge<T> e in start.edges) {
      if (e.to == next) return e.cost;
    }
    return Integer.maxValue;
  }

  int _heuristicCostEstimate(Vertex<T> start, Vertex<T> goal) {
    return 1;
  }

  List<Edge<T>> _reconstructPath(Map<Vertex<T>, Vertex<T>> cameFrom, Vertex<T>? current) {
    final List<Edge<T>> totalPath = [];

    while (current != null) {
      final Vertex<T> previous = current;
      current = cameFrom[current];
      if (current != null) {
        final Edge<T> edge = current.getEdge(previous)!;
        totalPath.add(edge);
      }
    }
    return totalPath.reversed.toList();
  }
}
