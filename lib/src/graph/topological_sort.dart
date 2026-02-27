import 'dart:collection';

import 'package:dart_graph/dart_graph.dart';

import 'graph.dart';

///拓扑排序 (Kahn's Algorithm) 返回拓扑排序后的顶点列表
extension TopologicalSortExtension on Graph {
  /// 普通拓扑排序
  /// - 成功时返回拓扑序
  /// - 如果图中存在环，返回 null
  List<Vertex>? topologicalSort() {
    if (!directed) {
      throw StateError(
        'Topological sort can only be performed on directed graphs.',
      );
    }
    final vertices = vertexIterator.toList();
    final inDegrees = <String, int>{};
    for (final v in vertices) {
      inDegrees[v.id] = 0;
    }
    for (final v in vertices) {
      final edges = outEdges(v.id);
      for (final edge in edges.values) {
        final to = edge.to;
        final old = inDegrees[to];
        if (old == null) {
          throw StateError('Edge points to missing vertex: $to');
        }
        inDegrees[to] = old + 1;
      }
    }
    final queue = ListQueue<Vertex>();
    for (final v in vertices) {
      if (inDegrees[v.id] == 0) {
        queue.add(v);
      }
    }
    final result = <Vertex>[];
    while (queue.isNotEmpty) {
      final u = queue.removeFirst();
      result.add(u);

      final edges = outEdges(u.id);
      for (final edge in edges.values) {
        final to = edge.to;
        final nextInDegree = inDegrees[to]! - 1;
        inDegrees[to] = nextInDegree;
        if (nextInDegree == 0) {
          final nextVertex = vertexMap[to];
          if (nextVertex == null) {
            throw StateError('Edge points to missing vertex: $to');
          }
          queue.add(nextVertex);
        }
      }
    }
    return result.length == vertices.length ? result : null;
  }

  /// 按层次划分的拓扑排序
  /// - 成功时返回按层分组的结果，key 为层级，从 0 开始
  /// - 如果图中存在环，返回 null
  /// 层级定义：
  /// - 第 0 层：初始入度为 0 的所有点
  /// - 第 1 层：移除第 0 层后，入度变为 0 的所有点
  Map<int, List<Vertex>>? topologicalLevelSort() {
    if (!directed) {
      throw StateError(
        'Topological sort can only be performed on directed graphs.',
      );
    }

    final vertices = vertexIterator.toList();
    final inDegrees = <String, int>{};
    for (final v in vertices) {
      inDegrees[v.id] = 0;
    }
    for (final v in vertices) {
      final edges = outEdges(v.id);
      for (final edge in edges.values) {
        final to = edge.to;
        final old = inDegrees[to];
        if (old == null) {
          throw StateError('Edge points to missing vertex: $to');
        }
        inDegrees[to] = old + 1;
      }
    }

    final currentQueue = ListQueue<Vertex>();
    for (final v in vertices) {
      if (inDegrees[v.id] == 0) {
        currentQueue.add(v);
      }
    }

    final result = <int, List<Vertex>>{};
    int level = 0;
    int visitedCount = 0;
    while (currentQueue.isNotEmpty) {
      final levelSize = currentQueue.length;
      final levelNodes = <Vertex>[];

      for (var i = 0; i < levelSize; i++) {
        final u = currentQueue.removeFirst();
        levelNodes.add(u);
        visitedCount++;

        final edges = outEdges(u.id);
        for (final edge in edges.values) {
          final to = edge.to;
          final nextInDegree = inDegrees[to]! - 1;
          inDegrees[to] = nextInDegree;
          if (nextInDegree == 0) {
            final nextVertex = vertexMap[to];
            if (nextVertex == null) {
              throw StateError('Edge points to missing vertex: $to');
            }
            currentQueue.add(nextVertex);
          }
        }
      }
      result[level] = levelNodes;
      level++;
    }
    return visitedCount == vertices.length ? result : null;
  }
}
