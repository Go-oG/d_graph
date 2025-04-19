import 'dart:collection';
import 'dart:math';


import 'package:d_util/d_util.dart';

import 'graph.dart' as g;

/// push-relabel 算法（或者 preflow-push algorithm） 是一种计算最大流量的算法。
/// 名称 “push-relabel” 来自算法中使用的两个基本操作。
/// 在整个执行过程中，算法保持 “preflow” 并通过移动逐渐将其转换为最大流量
class PushRelabel {
  final Queue<_Vertex> _queue = Queue();
  final List<_Vertex> _vertices = [];

  late int relabelCounter;
  late int n;
  late final _Vertex _source;
  late final _Vertex _sink;

  static int getMaximumFlow<T>(Map<g.Edge<T>, int> edgesToCapacities, g.Vertex<T> source, g.Vertex<T> sink) {
    final Map<g.Vertex<T>, _Vertex> vertexMap = SplayTreeMap<g.Vertex<T>, _Vertex>();
    for (g.Edge<T> edge in edgesToCapacities.keys) {
      vertexMap.put(edge.from, _Vertex());
      vertexMap.put(edge.to, _Vertex());
    }

    final _Vertex s = _Vertex();
    vertexMap.put(source, s);

    final _Vertex t = _Vertex();
    vertexMap.put(sink, t);

    final PushRelabel pushRelabel = PushRelabel._(vertexMap.values, s, t);
    for (MapEntry<g.Edge<T>, int> edgeWithCapacity in edgesToCapacities.entries) {
      final g.Edge<T> e = edgeWithCapacity.key;
      _addEdge(vertexMap.get(e.from)!, vertexMap.get(e.to)!, edgeWithCapacity.value);
    }

    return pushRelabel._maxFlow();
  }

  PushRelabel._(Iterable<_Vertex> vertices, this._source, this._sink) {
    _vertices.addAll(vertices);
    n = vertices.length;
  }

  static void _addEdge(_Vertex from, _Vertex to, int cost) {
    final int placeOfEdge = from.edges.indexOf(_Edge.of(from, to));
    if (placeOfEdge == -1) {
      final _Edge edge = _Edge(from, to, cost);
      final _Edge revertedEdge = _Edge(to, from, 0);
      edge.revertedEdge = revertedEdge;
      revertedEdge.revertedEdge = edge;
      from.edges.add(edge);
      to.edges.add(revertedEdge);
    } else {
      from.edges.get(placeOfEdge).cost += cost;
    }
  }

  void _recomputeHeight() {
    final Queue<_Vertex> que = Queue();
    for (_Vertex vertex in _vertices) {
      vertex.visited = false;
      vertex.height = 2 * n;
    }

    _sink.height = 0;
    _source.height = n;
    _source.visited = true;
    _sink.visited = true;
    que.add(_sink);
    while (que.isNotEmpty) {
      final _Vertex act = que.removeFirst();
      for (_Edge e in act.edges) {
        if (!e.to.visited && e.revertedEdge.cost > e.revertedEdge.flow) {
          e.to.height = act.height + 1;
          que.add(e.to);
          e.to.visited = true;
        }
      }
    }
    que.add(_source);
    while (que.isNotEmpty) {
      final _Vertex act = que.removeFirst();
      for (_Edge e in act.edges) {
        if (!e.to.visited && e.revertedEdge.cost > e.revertedEdge.flow) {
          e.to.height = act.height + 1;
          que.add(e.to);
          e.to.visited = true;
        }
      }
    }
  }

  void _init() {
    for (_Edge e in _source.edges) {
      e.flow = e.cost;
      e.revertedEdge.flow = -e.flow;
      e.to.excess += e.flow;
      if (e.to != _source && e.to != _sink) {
        _queue.add(e.to);
      }
    }
    _recomputeHeight();
    relabelCounter = 0;
  }

  static void _relabel(_Vertex v) {
    int minimum = 0;
    for (_Edge e in v.edges) {
      if (e.flow < e.cost) {
        minimum = min(minimum, e.to.height);
      }
    }
    v.height = minimum + 1;
  }

  void _push(_Vertex u, _Edge e) {
    final delta = (u.excess < e.cost - e.flow) ? u.excess : e.cost - e.flow;
    e.flow += delta;
    e.revertedEdge.flow -= delta;
    u.excess -= delta;

    if (e.to.excess == 0 && e.to != _source && e.to != _sink) {
      _queue.add(e.to);
    }

    e.to.excess += delta;
  }

  void _discharge(_Vertex u) {
    while (u.excess > 0) {
      if (u.currentEdge == u.edges.size) {
        _relabel(u);
        if ((++relabelCounter) == n) {
          _recomputeHeight();
          for (_Vertex vertex in _vertices) {
            vertex.currentEdge = 0;
          }
          relabelCounter = 0;
        }
        u.currentEdge = 0;
      } else {
        _Edge e = u.edges.get(u.currentEdge);
        if (e.flow < e.cost && u.height == e.to.height + 1) {
          _push(u, e);
        } else {
          u.currentEdge++;
        }
      }
    }
  }

  int _maxFlow() {
    _init();
    while (_queue.isNotEmpty) {
      _discharge(_queue.removeFirst());
    }
    return _sink.excess;
  }
}

final class _Vertex {
  final List<_Edge> edges = [];

  bool visited = false;
  late int height;
  late int currentEdge;
  late int excess;
}

final class _Edge {
  final _Vertex from;
  final _Vertex to;
  int cost = 0;
  int flow = 0;

  late _Edge revertedEdge;

  _Edge(this.from, this.to, this.cost);

  _Edge.of(this.from, this.to);

  @override
  bool operator ==(Object other) {
    return identical(other, this) || (other is _Edge && other.to == to && other.from == from);
  }

  @override
  int get hashCode {
    return Object.hash(from, to);
  }
}
