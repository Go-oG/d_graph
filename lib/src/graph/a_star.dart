import 'package:d_util/d_util.dart';

import 'graph.dart';

///路径查找
extension AStar on Graph {
  List<Edge>? aStar(Vertex start, Vertex goal) {
    final Set<Vertex> closedSet = <Vertex>{};
    final List<Vertex> openSet = [];
    openSet.add(start);
    final Map<Vertex, Vertex> cameFrom = {};

    final Map<Vertex, double> gScore = {};
    gScore[start] = 0;
    final Map<Vertex, double> fScore = {};
    for (Vertex v in vertexIterator) {
      fScore[v] = Double.minValue;
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
      final Vertex current = openSet[0];
      if (current == goal) {
        return _reconstructPath(cameFrom, goal);
      }
      openSet.removeAt(0);
      closedSet.add(current);
      for (Edge edge in edges2(current)) {
        final Vertex neighbor = getVertex(edge.to);
        if (closedSet.contains(neighbor)) {
          continue;
        }

        final tenativeGScore = gScore[current]! + _distanceBetween(current, neighbor);
        if (!openSet.contains(neighbor)) {
          openSet.add(neighbor);
        } else if (tenativeGScore >= gScore[neighbor]!) {
          continue;
        }

        cameFrom[neighbor] = current;

        gScore[neighbor] = tenativeGScore;

        fScore[neighbor] = gScore[neighbor]! + _heuristicCostEstimate(neighbor, goal);

        openSet.sort(comparator);
      }
    }

    return null;
  }

  double _distanceBetween(Vertex start, Vertex next) {
    for (var e in edges2(start)) {
      if (e.to == next.id) return e.value;
    }
    return Double.maxValue;
  }

  double _heuristicCostEstimate(Vertex start, Vertex goal) {
    return 1;
  }

  List<Edge> _reconstructPath(Map<Vertex, Vertex> cameFrom, Vertex? current) {
    final List<Edge> totalPath = [];

    while (current != null) {
      final Vertex previous = current;
      current = cameFrom[current];
      if (current != null) {
        final Edge edge = getEdge2(current.id, previous.id)!;
        totalPath.add(edge);
      }
    }
    return totalPath.reversed.toList();
  }
}
