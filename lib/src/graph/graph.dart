import 'package:dart_graph/dart_graph.dart';
import 'package:flutter/foundation.dart';
import 'package:quiver/collection.dart';

enum GraphType { directed, undirected }

class Graph<T> {
  late final GraphType type;
  final BiMap<T, Vertex<T>> _vertexMap = BiMap();
  final UniqueList<Vertex<T>> _allVertices = UniqueList();
  final List<Edge<T>> _allEdges = [];

  Graph(
      {this.type = GraphType.undirected, Iterable<Vertex<T>>? vertices, Iterable<Edge<T>>? edges}) {
    if (vertices != null) {
      for (final vertex in vertices) {
        addVertex(vertex);
      }
    }
    if (edges != null) {
      for (final edge in edges) {
        addEdgeNode(edge);
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

  UniqueList<Vertex<T>> get vertices => _allVertices;

  List<Edge<T>> get edges {
    return _allEdges;
  }

  void add(T data) {
    final old = _vertexMap[data];
    if (old != null) {
      debugPrint("当前已存在相同数据");
      return;
    }
    final vertex = Vertex(data);
    _vertexMap[data] = vertex;
    _allVertices.add(vertex);
  }

  void addVertex(Vertex<T> vertex) {
    final old = _vertexMap.inverse[vertex];
    if (old != null) {
      debugPrint("当前已存在相同数据");
      return;
    }
    _vertexMap[vertex.data] = vertex;
    _allVertices.add(vertex);
  }

  void addEdge(T source, T target, [int cost = 0]) {
    var edge = Edge<T>(cost, Vertex(source), Vertex(target));
    addEdgeNode(edge);
  }

  void addEdgeNode(Edge<T> e) {
    final Vertex<T> from = e.from;
    final Vertex<T> to = e.to;
    addVertex(from);
    addVertex(to);

    from.addEdge(e);
    _allEdges.add(e);

    if (type == GraphType.undirected) {
      final edge2 = Edge<T>(e.cost, to, from);
      to.addEdge(edge2);
      _allEdges.add(edge2);
    }
  }

  void remove(T data) {
    final old = _vertexMap[data];
    if (old == null) {
      return;
    }
    removeVertex(old);
  }

  void removeVertex(Vertex<T> v, [bool clearSelfEdge = true]) {
    if (_allVertices.remove(v)) {
      _vertexMap.remove(v.data);
      _allEdges.removeWhere((e) => e.from == v || e.to == v);
    }
    if (clearSelfEdge) {
      v.edges.clear();
    }
  }

  void clear() {
    _allEdges.clear();
    _allVertices.clear();
    _vertexMap.clear();
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

///顶点唯一性只和边关联
class Vertex<T> implements Comparable<Vertex<T>> {
  late final T data;
  final UniqueList<Edge<T>> _edges = UniqueList();

  double weight = 0;

  Vertex(this.data, [this.weight = 0]);

  Vertex.of(Vertex<T> vertex) {
    data = vertex.data;
    weight = vertex.weight;
    edges.addAll(vertex.edges);
  }

  UniqueList<Edge<T>> get edges => _edges;

  void addEdge(Edge<T> e) => _edges.add(e);

  Edge<T>? getEdge(Vertex<T> v) {
    for (Edge<T> e in _edges) {
      if (e.to == v) {
        return e;
      }
    }
    return null;
  }

  bool pathTo(Vertex<T> v) {
    for (Edge<T> e in _edges) {
      if (e.to == v) {
        return true;
      }
    }
    return false;
  }

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is! Vertex<T>) {
      return false;
    }
    return data == other.data;
  }

  @override
  int compareTo(Vertex<T> v) {
    if (T is Comparable) {
      return (data as Comparable).compareTo(v.data);
    }
    return -1;
  }
}

///边唯一性判断只和顶点关联
class Edge<T> implements Comparable<Edge<T>> {
  late final String id;
  late final Vertex<T> from;
  late final Vertex<T> to;

  int cost = 0;

  Edge(this.cost, this.from, this.to, {String? id}) {
    this.id = id ?? "";
    this.cost = cost;
    this.from = from;
    this.to = to;
  }

  Edge.of(Edge<T> e, {String? id}) {
    this.id = id ?? "";
    from = e.from;
    to = e.to;
    cost = e.cost;
  }

  @override
  int get hashCode {
    return Object.hash(id, from, to);
  }

  @override
  int compareTo(Edge<T> e) => this.cost.compareTo(e.cost);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is! Edge<T>) {
      return false;
    }
    final Edge<T> e = other;
    if (id != other.id) {
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

  const CostPath(this.cost, this.path);

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
