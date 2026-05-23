import 'package:collection/collection.dart';

import 'graph.dart';

typedef HeuristicCallback<V> =
    double Function(Vertex<V> current, Vertex<V> goal);

extension AStarExtension<V, E> on Graph<V, E> {
  /// A* 路径查找算法
  /// [heuristic] 启发函数。如果省略，算法退化为 Dijkstra。
  List<Edge<E>>? aStar(
    Vertex<V> start,
    Vertex<V> goal, {
    HeuristicCallback<V>? heuristic,
  }) {
    if (!vertexMap.containsKey(start.id) || !vertexMap.containsKey(goal.id)) {
      return null;
    }

    final h = heuristic ?? (a, b) => 0.0;
    final PriorityQueue<_NodeRank> openSet = PriorityQueue();
    final Map<String, double> gScore = {};
    final Map<String, Edge<E>> cameFromEdge = {};

    gScore[start.id] = 0.0;
    double startF = h(start, goal);
    openSet.add(_NodeRank(start.id, 0.0, startF));

    while (openSet.isNotEmpty) {
      final _NodeRank currentRank = openSet.removeFirst();
      final String currentId = currentRank.vertexId;
      if (currentRank.gScore > (gScore[currentId] ?? double.infinity)) {
        continue;
      }
      if (currentId == goal.id) {
        return _reconstructPath(cameFromEdge, currentId);
      }
      final Vertex<V>? currentVertex = vertexMap[currentId];
      if (currentVertex == null) continue;
      for (final edge in traversableEdges(currentVertex.id)) {
        final String neighborId = (edge.from == currentId)
            ? edge.to
            : edge.from;
        final Vertex<V>? neighbor = vertexMap[neighborId];
        if (neighbor == null) continue;
        final double tentativeG =
            (gScore[currentId] ?? double.infinity) + edge.weight;
        if (tentativeG < (gScore[neighborId] ?? double.infinity)) {
          cameFromEdge[neighborId] = edge;
          gScore[neighborId] = tentativeG;
          final double f = tentativeG + h(neighbor, goal);
          openSet.add(_NodeRank(neighborId, tentativeG, f));
        }
      }
    }
    return null;
  }

  List<Edge<E>> _reconstructPath(
    Map<String, Edge<E>> cameFromEdge,
    String currentId,
  ) {
    final List<Edge<E>> path = [];
    String curr = currentId;

    while (cameFromEdge.containsKey(curr)) {
      final Edge<E> edge = cameFromEdge[curr]!;
      path.add(edge);
      curr = (edge.to == curr) ? edge.from : edge.to;
    }
    return path.reversed.toList();
  }
}

class _NodeRank implements Comparable<_NodeRank> {
  final String vertexId;
  final double gScore;
  final double fScore;

  _NodeRank(this.vertexId, this.gScore, this.fScore);

  @override
  int compareTo(_NodeRank other) => fScore.compareTo(other.fScore);
}
