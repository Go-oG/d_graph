import 'dart:collection';
import 'dart:math';

import 'graph.dart' as g;

/// Push-Relabel 算法实现 (FIFO Vertex Selection Rule)
/// 包含 Gap Heuristic 和 Global Relabeling 优化
final class PushRelabel {
  final Queue<_Vertex> _activeNodes = Queue();
  final List<_Vertex> _allVertices = [];
  int _relabelCounter = 0;
  late int _n;
  late final _Vertex _source;
  late final _Vertex _sink;

  static int getMaximumFlow(g.Graph graph, Map<g.Edge, int> edgesToCapacities, g.Vertex source, g.Vertex sink) {
    if (source == sink) return double.maxFinite.toInt();

    final Map<String, _Vertex> vertexMap = {};

    _Vertex getOrAdd(g.Vertex v) {
      return vertexMap.putIfAbsent(v.id, () => _Vertex(id: v.id));
    }

    final s = getOrAdd(source);
    final t = getOrAdd(sink);

    for (final edge in edgesToCapacities.keys) {
      final u = getOrAdd(graph.vertexMap[edge.from]!);
      final v = getOrAdd(graph.vertexMap[edge.to]!);
      _addEdge(u, v, edgesToCapacities[edge]!);
    }

    final pushRelabel = PushRelabel._(vertexMap.values, s, t);
    return pushRelabel._computeMaxFlow();
  }

  PushRelabel._(Iterable<_Vertex> vertices, this._source, this._sink) {
    _allVertices.addAll(vertices);
    _n = _allVertices.length;
  }

  static void _addEdge(_Vertex from, _Vertex to, int capacity) {
    _Edge? existingEdge;
    for (final e in from.edges) {
      if (e.to == to) {
        existingEdge = e;
        break;
      }
    }

    if (existingEdge == null) {
      final forward = _Edge(from, to, capacity, 0);
      final backward = _Edge(to, from, 0, 0);
      forward.reverse = backward;
      backward.reverse = forward;

      from.edges.add(forward);
      to.edges.add(backward);
    } else {
      existingEdge.capacity += capacity;
    }
  }

  /// 全局重标记 (Global Relabeling / Backward BFS)
  void _globalRelabel() {
    for (final v in _allVertices) {
      v.height = _n;
    }
    final Queue<_Vertex> queue = Queue();
    _sink.height = 0;
    queue.add(_sink);

    while (queue.isNotEmpty) {
      final u = queue.removeFirst();
      for (final edge in u.edges) {
        final reversed = edge.reverse;
        final v = edge.to;
        if (v.height == _n && reversed.residualCapacity > 0) {
          v.height = u.height + 1;
          queue.add(v);
        }
      }
    }
    // 源点高度固定为 n (除非不可达，但也设为 n 以触发 push)
     _source.height = _n;
  }

  /// 推流操作
  void _push(_Vertex u, _Edge e) {
    final int delta = min(u.excess, e.residualCapacity);
    e.flow += delta;
    e.reverse.flow -= delta;
    u.excess -= delta;
    e.to.excess += delta;
    if (e.to.excess == delta && e.to != _source && e.to != _sink) {
      _activeNodes.add(e.to);
    }
  }

  /// 重标记操作 将 u 的高度提升到 min(邻居高度) + 1
  void _relabel(_Vertex u) {
    int minHeight = 2 * _n;
    for (final e in u.edges) {
      if (e.residualCapacity > 0) {
        minHeight = min(minHeight, e.to.height);
      }
    }
    u.height = minHeight + 1;
  }

  /// 排放操作 对一个溢出节点 u 不断进行 push 或 relabel，直到它不再溢出
  void _discharge(_Vertex u) {
    while (u.excess > 0) {
      if (u.currentEdgeIndex < u.edges.length) {
        final e = u.edges[u.currentEdgeIndex];
        if (e.residualCapacity > 0 && u.height == e.to.height + 1) {
          _push(u, e);
        } else {
          u.currentEdgeIndex++;
        }
      } else {
        _relabel(u);
        u.currentEdgeIndex = 0;

        //优化 可选
        if (++_relabelCounter >= _n) {
          _globalRelabel();
          _relabelCounter = 0;
        }
      }
    }
  }

  int _computeMaxFlow() {
    _source.height = _n;
    _sink.height = 0;

    for (final e in _source.edges) {
      e.flow = e.capacity;
      e.reverse.flow = -e.capacity;

      e.to.excess += e.capacity;
      _source.excess -= e.capacity;

      if (e.to != _source && e.to != _sink) {
        _activeNodes.add(e.to);
      }
    }

    //可选
    _globalRelabel();

    while (_activeNodes.isNotEmpty) {
      final u = _activeNodes.removeFirst();
      _discharge(u);
    }
    return _sink.excess;
  }
}

class _Vertex {
  final String id;
  final List<_Edge> edges = [];

  int height = 0;
  int excess = 0;
  int currentEdgeIndex = 0;

  _Vertex({required this.id});

  @override
  String toString() => 'V($id, h:$height, e:$excess)';
}

class _Edge {
  final _Vertex from;
  final _Vertex to;

  int capacity;
  int flow;

  late _Edge reverse;

  _Edge(this.from, this.to, this.capacity, this.flow);

  int get residualCapacity => capacity - flow;

  @override
  String toString() => '${from.id}->${to.id} ($flow/$capacity)';
}
