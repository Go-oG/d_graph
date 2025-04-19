
import 'package:d_util/d_util.dart';
import 'package:flutter/foundation.dart';

enum GraphType { directed, undirected }

class Graph<T> {
  final Map<dynamic, dynamic> extraMap = {};
  final List<Vertex<T>> _allVertices = [];
  final List<T> _nodes = [];
  final List<Edge<T>> _allEdges = [];

  late final GraphType type;

  Graph({this.type = GraphType.undirected, Iterable<Vertex<T>>? vertices, Iterable<Edge<T>>? edges}) {
    if (vertices != null) {
      _allVertices.addAll(vertices);
      _nodes.addAll(_allVertices.map((e) => e.data));
    }

    if (edges != null) {
      _allEdges.addAll(edges);
      for (Edge<T> e in edges) {
        final Vertex<T> from = e.from;
        final Vertex<T> to = e.to;
        if (!_allVertices.contains(from) || !_allVertices.contains(to)) {
          continue;
        }
        from.addEdge(e);
        if (type == GraphType.undirected) {
          Edge<T> reciprical = Edge<T>(e.cost, to, from);
          to.addEdge(reciprical);
          _allEdges.add(reciprical);
        }
      }
    }
  }

  Graph.of(Graph<T> g) {
    type = g.type;
    for (Vertex<T> v in g._allVertices) {
      _allVertices.add(Vertex<T>.of(v));
    }
    for (Vertex<T> v in vertices) {
      _allEdges.addAll(v.edges);
    }
  }

  List<Vertex<T>> get vertices {
    return _allVertices;
  }

  List<Edge<T>> get edges {
    return _allEdges;
  }

  List<T> get nodes => _nodes;

  void add(T data) {
    Vertex<T> vertex = Vertex(data);
    _allVertices.add(vertex);
    _nodes.add(data);
  }

  ///TODO 待完成
  void addEdge(T source, T target, int cost) {
    var edge = Edge<T>(cost, Vertex(source), Vertex(target));
  }

  @override
  int get hashCode {
    int code = type.hashCode + _allVertices.length + _allEdges.length;
    return Object.hash(code, Object.hashAll(_allVertices), Object.hashAll(_allEdges));
  }

  @override
  bool operator ==(Object g) {
    if (identical(g, this)) {
      return true;
    }
    if (g is! Graph<T>) {
      return false;
    }

    if (type != g.type) {
      return false;
    }

    if (_allVertices.length != g._allVertices.length) {
      return false;
    }

    if (_allEdges.length != g._allEdges.length) {
      return false;
    }

    var l1 = List.from(_allVertices);
    l1.sort((a, b) {
      return a.compareTo(b);
    });
    var l2 = List.from(g._allVertices);
    l2.sort((a, b) {
      return a.compareTo(b);
    });
    if (!listEquals(l1, l2)) {
      return false;
    }

    var l3 = List.from(_allEdges);
    l3.sort((a, b) {
      return a.compareTo(b);
    });
    var l4 = List.from(g._allEdges);
    l4.sort((a, b) {
      return a.compareTo(b);
    });
    return listEquals(l3, l4);
  }
}

class Vertex<T> implements Comparable<Vertex<T>> {
  final Map<dynamic, dynamic> extraMap = {};
  late T data;
  double weight = 0;
  List<Edge<T>> edges = [];

  Vertex(this.data, [this.weight = 0]);

  Vertex.of(Vertex<T> vertex) {
    data = vertex.data;
    weight = vertex.weight;
    edges.addAll(vertex.edges);
  }

  void addEdge(Edge<T> e) {
    edges.add(e);
  }

  Edge<T>? getEdge(Vertex<T> v) {
    for (Edge<T> e in edges) {
      if (e.to == v) {
        return e;
      }
    }
    return null;
  }

  bool pathTo(Vertex<T> v) {
    for (Edge<T> e in edges) {
      if (e.to == v) {
        return true;
      }
    }
    return false;
  }

  @override
  int get hashCode {
    return Object.hash(data, weight, edges.length);
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is! Vertex<T>) {
      return false;
    }
    if (weight != other.weight) {
      return false;
    }

    if (edges.length != other.edges.length) {
      return false;
    }

    if (data != (other.data)) {
      return false;
    }

    return listEquals(edges, other.edges);
  }

  @override
  int compareTo(Vertex<T> v) {
    final int valueComp = (data as dynamic).compareTo(v.data);
    if (valueComp != 0) return valueComp;

    if (this.weight < v.weight) {
      return -1;
    }
    if (this.weight > v.weight) {
      return 1;
    }

    if (this.edges.length < v.edges.length) {
      return -1;
    }
    if (this.edges.length > v.edges.length) {
      return 1;
    }

    final Iterator<Edge<T>> iter1 = edges.iterator;
    final Iterator<Edge<T>> iter2 = v.edges.iterator;
    while (iter1.moveNext() && iter2.moveNext()) {
      final Edge<T> e1 = iter1.current;
      final Edge<T> e2 = iter2.current;
      if (e1.cost < e2.cost) {
        return -1;
      }
      if (e1.cost > e2.cost) {
        return 1;
      }
    }
    return 0;
  }
}

class Edge<T> implements Comparable<Edge<T>> {
  final Map<dynamic, dynamic> extraMap = {};

  late final String id;
  late Vertex<T> from;
  late Vertex<T> to;
  late int cost;

  Edge(this.cost, this.from, this.to, {String? id}) {
    this.id = id ?? randomId();
    this.cost = cost;
    this.from = from;
    this.to = to;
  }

  Edge.of(Edge<T> e) {
    from = e.from;
    to = e.to;
    cost = e.cost;
  }

  @override
  int get hashCode {
    return Object.hash(cost, from, to);
  }

  @override
  int compareTo(Edge<T> e) {
    if (this.cost < e.cost) {
      return -1;
    }
    if (this.cost > e.cost) {
      return 1;
    }

    int from = this.from.compareTo(e.from);
    if (from != 0) {
      return from;
    }

    final int to = this.to.compareTo(e.to);
    if (to != 0) {
      return to;
    }
    return 0;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Edge<T>) {
      return false;
    }
    final Edge<T> e = other;

    if (this.cost != e.cost) {
      return false;
    }
    if (from != e.from) {
      return false;
    }
    return to == e.to;
  }

  T get source => from.data;

  set source(T v) => from.data = v;

  T get target => to.data;

  set target(T v) => to.data = v;
}

class CostPath<T> {
  final int cost;
  final List<Edge<T>> path;

  CostPath(this.cost, this.path);

  @override
  int get hashCode {
    return Object.hash(cost, Object.hashAll(path));
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    if ((other is! CostPath<T>)) {
      return false;
    }

    final CostPath<T> pair = other;
    if (this.cost != pair.cost) {
      return false;
    }

    var iter1 = path.iterator;
    var iter2 = pair.path.iterator;
    while (iter1.moveNext() && iter2.moveNext()) {
      if (iter1.current != iter2.current) {
        return false;
      }
    }
    return true;
  }
}

class CostVertex<T> implements Comparable<CostVertex<T>> {
  final Vertex<T> vertex;
  int cost;

  CostVertex(this.cost, this.vertex);

  @override
  int get hashCode {
    return Object.hash(cost, vertex);
  }

  @override
  int compareTo(CostVertex<T> p) {
    if (this.cost < p.cost) {
      return -1;
    }
    if (this.cost > p.cost) {
      return 1;
    }
    return 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is! CostVertex<T>) {
      return false;
    }

    if (cost != other.cost) {
      return false;
    }

    if (vertex != other.vertex) {
      return false;
    }
    return true;
  }
}
