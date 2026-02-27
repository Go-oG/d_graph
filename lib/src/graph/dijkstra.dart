import 'package:collection/collection.dart';

import 'graph.dart';

final class PathResult {
  final double cost;
  final List<Edge> path;

  PathResult(this.cost, this.path);

  @override
  String toString() => 'Cost: $cost, Path: ${path.map((e) => e.id).toList()}';
}

class _NodeCost implements Comparable<_NodeCost> {
  final String vertexId;
  final double cost;

  _NodeCost(this.vertexId, this.cost);

  @override
  int compareTo(_NodeCost other) => cost.compareTo(other.cost);
}

extension DijkstraExtension on Graph {
  Map<String, PathResult> shortestPaths(Vertex start) {
    _checkNegativeEdges();

    final Map<String, double> distances = {};
    final Map<String, Edge> predecessors = {};

    for (final v in vertexIterator) {
      distances[v.id] = double.infinity;
    }
    distances[start.id] = 0;

    final PriorityQueue<_NodeCost> pq = PriorityQueue();
    pq.add(_NodeCost(start.id, 0));

    while (pq.isNotEmpty) {
      final _NodeCost current = pq.removeFirst();
      final uId = current.vertexId;
      final currentCost = current.cost;

      if (currentCost > distances[uId]!) continue;

      final u = vertexMap[uId];
      if (u == null) continue;

      for (final edge in _getOutEdges(u)) {
        final vId = edge.to == uId ? edge.from : edge.to;
        final newDist = currentCost + edge.weight;
        if (newDist < distances[vId]!) {
          distances[vId] = newDist;
          predecessors[vId] = edge;
          pq.add(_NodeCost(vId, newDist));
        }
      }
    }

    final Map<String, PathResult> results = {};
    for (final vId in distances.keys) {
      if (distances[vId] == double.infinity) continue;
      results[vId] = _buildPath(start.id, vId, predecessors, distances[vId]!);
    }

    return results;
  }

  PathResult? shortestPathTo(Vertex start, Vertex end) {
    _checkNegativeEdges();

    final Map<String, double> distances = {};
    final Map<String, Edge> predecessors = {};

    distances[start.id] = 0;

    final pq = PriorityQueue<_NodeCost>();
    pq.add(_NodeCost(start.id, 0));

    while (pq.isNotEmpty) {
      final current = pq.removeFirst();
      final uId = current.vertexId;
      final currentCost = current.cost;

      if (uId == end.id) {
        return _buildPath(start.id, end.id, predecessors, currentCost);
      }

      if (currentCost > (distances[uId] ?? double.infinity)) continue;

      final u = vertexMap[uId];
      if (u == null) continue;

      for (final edge in _getOutEdges(u)) {
        final vId = edge.to == uId ? edge.from : edge.to;
        final newDist = currentCost + edge.weight;

        if (newDist < (distances[vId] ?? double.infinity)) {
          distances[vId] = newDist;
          predecessors[vId] = edge;
          pq.add(_NodeCost(vId, newDist));
        }
      }
    }

    return null;
  }

  PathResult _buildPath(String startId, String endId, Map<String, Edge> predecessors, double totalCost) {
    final List<Edge> path = [];
    String? currentId = endId;

    while (currentId != startId && currentId != null) {
      final edge = predecessors[currentId];
      if (edge == null) break;
      path.add(edge);
      currentId = (edge.to == currentId) ? edge.from : edge.to;
    }

    return PathResult(totalCost, path.reversed.toList());
  }

  Iterable<Edge> _getOutEdges(Vertex v) => outEdges(v.id).values;

  void _checkNegativeEdges() {
    for (final edge in edgeIterator) {
      if (edge.weight < 0) {
        throw StateError("Dijkstra algorithm does not support negative weight edges. Edge ID: ${edge.id}");
      }
    }
  }
}
