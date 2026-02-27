import 'package:collection/collection.dart';

import 'graph.dart';

typedef HeuristicCallback = double Function(Vertex current, Vertex goal);

extension AStarExtension on Graph {
  /// A* 路径查找算法
  /// [heuristic] 启发函数。如果省略，算法退化为 Dijkstra。
  List<Edge>? aStar(Vertex start, Vertex goal, {HeuristicCallback? heuristic}) {
    if (!vertexMap.containsKey(start.id) || !vertexMap.containsKey(goal.id)) {
      return null;
    }

    final h = heuristic ?? (a, b) => 0.0;
    final PriorityQueue<_NodeRank> openSet = PriorityQueue();
    final Map<String, double> gScore = {};
    final Map<String, Edge> cameFromEdge = {};

    gScore[start.id] = 0.0;
    double startF = h(start, goal);
    openSet.add(_NodeRank(start.id, startF));

    while (openSet.isNotEmpty) {
      final _NodeRank currentRank = openSet.removeFirst();
      final String currentId = currentRank.vertexId;
      if (currentId == goal.id) {
        return _reconstructPath(cameFromEdge, currentId);
      }
      final Vertex? currentVertex = vertexMap[currentId];
      if (currentVertex == null) continue;
      for (final edge in outEdges(currentVertex.id).values) {
        final String neighborId = (edge.from == currentId) ? edge.to : edge.from;
        final Vertex? neighbor = vertexMap[neighborId];
        if (neighbor == null) continue;
        final double tentativeG = (gScore[currentId] ?? double.infinity) + edge.weight;
        if (tentativeG < (gScore[neighborId] ?? double.infinity)) {
          cameFromEdge[neighborId] = edge;
          gScore[neighborId] = tentativeG;
          final double f = tentativeG + h(neighbor, goal);
          openSet.add(_NodeRank(neighborId, f));
        }
      }
    }
    return null;
  }

  List<Edge> _reconstructPath(Map<String, Edge> cameFromEdge, String currentId) {
    final List<Edge> path = [];
    String curr = currentId;

    while (cameFromEdge.containsKey(curr)) {
      final Edge edge = cameFromEdge[curr]!;
      path.add(edge);
      curr = (edge.to == curr) ? edge.from : edge.to;
    }
    return path.reversed.toList();
  }
}

class _NodeRank implements Comparable<_NodeRank> {
  final String vertexId;
  final double fScore;

  _NodeRank(this.vertexId, this.fScore);

  @override
  int compareTo(_NodeRank other) => fScore.compareTo(other.fScore);
}
