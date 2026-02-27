import 'dart:math';

final class Vertex<T> {
  final String id;
  final T? data;
  double weight;

  Vertex({
    required this.id,
    this.data,
    this.weight = 0,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'data': data, "weight": weight};
  }

  static Vertex fromMap(Map<String, dynamic> map) {
    return Vertex(id: map['id'], data: map['data'], weight: map['weight']);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Vertex && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

final class Edge<T> {
  final String id;
  final String from;
  final String to;
  final bool directed;
  final T? data;

  double weight;

  Edge({
    required this.id,
    required this.from,
    required this.to,
    required this.directed,
    this.weight = 0,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'from': from, 'to': to, 'directed': directed, 'weight': weight, 'data': data};
  }

  static Edge fromMap<T>(Map<String, dynamic> map) {
    return Edge(
      id: map['id'],
      from: map['from'],
      to: map['to'],
      directed: map['directed'],
      data: map['data'],
      weight: map['weight'],
    );
  }
}

final class Graph<V, E> {
  final bool directed;
  final bool allowMultiEdge;
  final bool allowSelfLoop;
  final Map<String, dynamic> meta = {};

  final Map<String, Vertex<V>> _vertexMap = {};
  final Map<String, Edge<E>> _edgeMap = {};

  final Map<String, Map<String, Edge<E>>> _vertexOutEdges = {};
  final Map<String, Map<String, Edge<E>>> _vertexInEdges = {};

  late final GraphDegree _degree;

  Graph({
    this.directed = false,
    this.allowMultiEdge = true,
    this.allowSelfLoop = false,
    Iterable<Vertex<V>>? vertices,
    Iterable<Edge<E>>? edges,
    Map<String, dynamic>? meta,
  }) {
    _degree = GraphDegree(this);
    if (vertices != null) {
      for (var v in vertices) {
        _addVertex(v);
      }
    }
    if (edges != null) {
      for (var e in edges) {
        _addEdge(e);
      }
    }
    if (meta != null) {
      this.meta.addAll(meta);
    }
  }

  static Graph<V, E> of<V, E>(Graph<V, E> g) {
    return Graph<V, E>(
      directed: g.directed,
      allowMultiEdge: g.allowMultiEdge,
      allowSelfLoop: g.allowSelfLoop,
      meta: g.meta,
      vertices: g.vertexIterator,
      edges: g.edgeIterator,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'directed': directed,
      'allowMultiEdge': allowMultiEdge,
      'allowSelfLoop': allowSelfLoop,
      'meta': meta,
      'vertices': _vertexMap.values.map((v) => v.toMap()).toList(),
      'edges': _edgeMap.values.map((e) => e.toMap()).toList(),
    };
  }

  static Graph fromMap(Map<String, dynamic> graph) {
    return Graph(
      directed: graph['directed'],
      allowMultiEdge: graph['allowMultiEdge'] ?? false,
      allowSelfLoop: graph['allowSelfLoop'] ?? false,
      meta: graph['meta'] != null ? Map<String, dynamic>.from(graph['meta']) : null,
      vertices: (graph['vertices'] as List).map((v) => Vertex.fromMap(Map<String, dynamic>.from(v))).toList(),
      edges: (graph['edges'] as List).map((e) => Edge.fromMap(Map<String, dynamic>.from(e))).toList(),
    );
  }

  bool addVertex(String id, {V? value, double weight = 0}) {
    if (_vertexMap.containsKey(id)) {
      return false;
    }
    final vertex = Vertex(id: id, data: value, weight: weight);
    return _addVertex(vertex);
  }

  bool _addVertex(Vertex<V> vertex) {
    if (_vertexMap.containsKey(vertex.id)) {
      return false;
    }
    _vertexMap[vertex.id] = vertex;
    _degree._onVertexAdded(vertex);
    return true;
  }

  bool addEdge({
    required String id,
    required String fromVid,
    required String toVid,
    double weight = 0,
    bool? direct,
    E? value,
  }) {
    final edge = Edge(id: id, from: fromVid, to: toVid, data: value, directed: direct ?? directed, weight: weight);
    return _addEdge(edge);
  }

  bool _addEdge(Edge<E> edge) {
    final fromId = edge.from;
    final toVid = edge.from;
    if (!_vertexMap.containsKey(fromId) || !_vertexMap.containsKey(toVid)) {
      throw StateError('Edge endpoint does not exist');
    }
    if (!allowSelfLoop && fromId == toVid) {
      throw StateError('Self-loop is not allowed');
    }
    if (_edgeMap.containsKey(edge.id)) {
      return false;
    }
    if (!allowMultiEdge) {
      final outEdges = _vertexOutEdges[fromId];
      if (outEdges != null) {
        for (final existing in outEdges.values) {
          if (existing.to == toVid) {
            throw StateError('Multi-edge is not allowed between $fromId and $toVid');
          }
        }
      }
    }

    _edgeMap[edge.id] = edge;
    _vertexOutEdges.putIfAbsent(edge.from, () => {})[edge.id] = edge;
    _vertexInEdges.putIfAbsent(edge.to, () => {})[edge.id] = edge;

    if (!edge.directed) {
      _vertexOutEdges.putIfAbsent(edge.to, () => {})[edge.id] = edge;
      _vertexInEdges.putIfAbsent(edge.from, () => {})[edge.id] = edge;
    }

    _degree._onEdgeAdded(edge);
    return true;
  }

  Vertex<V>? removeVertex(String id) {
    final vertex = _vertexMap[id];
    if (vertex == null) {
      return null;
    }

    _degree._onVertexRemoved(vertex);
    final edgesToRemove = <Edge>{};
    _vertexOutEdges[id]?.values.forEach(edgesToRemove.add);
    _vertexInEdges[id]?.values.forEach(edgesToRemove.add);
    for (final e in edgesToRemove) {
      removeEdge(e.id);
    }
    _vertexOutEdges.remove(id);
    _vertexInEdges.remove(id);
    _vertexMap.remove(id);
    return vertex;
  }

  void removeVertices(Iterable<String> vertexs) {
    for (var v in vertexs) {
      removeVertex(v);
    }
  }

  void removeVertices2(Iterable<Vertex> vertexs) {
    for (var v in vertexs) {
      removeVertex(v.id);
    }
  }

  Edge<E>? removeEdge(String eid) {
    final edge = _edgeMap[eid];
    if (edge == null) {
      return null;
    }

    _degree._onEdgeRemoved(edge);

    _edgeMap.remove(edge.id);
    _vertexOutEdges[edge.from]?.remove(edge.id);
    _vertexInEdges[edge.to]?.remove(edge.id);

    if (!edge.directed) {
      _vertexOutEdges[edge.to]?.remove(edge.id);
      _vertexInEdges[edge.from]?.remove(edge.id);
    }

    return edge;
  }

  void removeEdges(Iterable<String> edges) {
    for (var v in edges) {
      removeEdge(v);
    }
  }

  void removeEdges2(Iterable<Edge> edges) {
    for (var v in edges) {
      removeEdge(v.id);
    }
  }

  Vertex<V> vertexOf(String vid) => vertexOfNull(vid)!;

  Vertex<V>? vertexOfNull(String vid) => _vertexMap[vid];

  List<Vertex<V>> neighbours(String vid) {
    Set<Vertex<V>> nodeSet = <Vertex<V>>{};
    for (var e in edges(vid)) {
      nodeSet.add(vertexOf(e.from));
      nodeSet.add(vertexOf(e.to));
    }
    nodeSet.remove(vertexOf(vid));
    return nodeSet.toList();
  }

  Edge<E> edgeOf(String id) => edgeOfNull(id)!;

  Edge<E>? edgeOfNull(String id) => _edgeMap[id];

  Edge<E>? edgeFrom(String from, String to) => _vertexOutEdges[from]?[to];

  void clear() {
    _vertexMap.clear();
    _edgeMap.clear();
    _vertexInEdges.clear();
    _vertexOutEdges.clear();
  }

  bool hasEdge(String eid) => _edgeMap.containsKey(eid);

  bool hasVertex(String vid) => _vertexMap.containsKey(vid);

  Degree degreeOf(String vid) => _degree.degreeOf(vid);

  WeightDegree weightDegreeOf(String vid) => _degree.weightDegreeOf(vid);

  Map<String, Edge<E>> inEdges(String vid) => _vertexInEdges.putIfAbsent(vid, () => {});

  Map<String, Edge<E>> outEdges(String vid) => _vertexOutEdges.putIfAbsent(vid, () => {});

  List<Edge<E>> edges(String vid) {
    final vertex = _vertexMap[vid];
    if (vertex == null) {
      return [];
    }
    Set<Edge<E>> edges = <Edge<E>>{};
    edges.addAll(inEdges(vid).values);
    edges.addAll(outEdges(vid).values);
    return edges.toList();
  }

  Iterable<Edge<E>> get edgeIterator => _edgeMap.values;

  Iterable<Vertex<V>> get vertexIterator => _vertexMap.values;

  Map<String, Vertex<V>> get vertexMap => _vertexMap;

  Map<String, Edge<E>> get edgeMap => _edgeMap;

  Map<String, Map<String, Edge<E>>> get vertexsOutEdges => _vertexOutEdges;

  Map<String, Map<String, Edge<E>>> get vertexsInEdges => _vertexInEdges;

  int get vertexCount => _vertexMap.length;

  int get edgeCount => _edgeMap.length;

  bool get hasEdges => _edgeMap.isNotEmpty;

  bool get hasVertices => _vertexMap.isNotEmpty;

  bool get isNotEdge => _edgeMap.isEmpty;

  bool get isNotVertex => _vertexMap.isEmpty;
}

final class GraphDegree {
  final Graph graph;

  final Map<String, Degree> _degreeMap = {};
  final Map<String, WeightDegree> _weightedDegreeMap = {};

  bool _frozen = false;
  bool _dirty = false;

  GraphDegree(this.graph) {
    _initialize();
  }

  void _initialize() {
    for (final v in graph.vertexIterator) {
      _degreeMap[v.id] = Degree();
      _weightedDegreeMap[v.id] = WeightDegree();
    }

    for (final e in graph.edgeIterator) {
      _applyEdge(e, 1);
    }
  }

  void freeze() => _frozen = true;

  void thaw() {
    if (!_frozen) return;
    _frozen = false;
    if (_dirty) {
      rebuild();
      _dirty = false;
    }
  }

  void rebuild() {
    for (final d in _degreeMap.values) {
      d.inDegree = 0;
      d.outDegree = 0;
    }
    for (final wd in _weightedDegreeMap.values) {
      wd.clear();
    }
    for (final e in graph.edgeIterator) {
      _applyEdge(e, 1);
    }
  }

  void _onVertexAdded(Vertex v) {
    _degreeMap[v.id] = Degree();
    _weightedDegreeMap[v.id] = WeightDegree();
  }

  void _onVertexRemoved(Vertex v) {
    _degreeMap.remove(v.id);
    _weightedDegreeMap.remove(v.id);
  }

  void _onEdgeAdded(Edge e) => _applyEdge(e, 1);

  void _onEdgeRemoved(Edge e) => _applyEdge(e, -1);

  void _applyEdge(Edge e, int delta) {
    if (_frozen) {
      _dirty = true;
      return;
    }

    final w = (e.weight) * delta;
    final isDirected = e.directed;
    final fromDegree = _degreeMap[e.from];
    final toDegree = _degreeMap[e.to];
    final fromWeighted = _weightedDegreeMap[e.from];
    final toWeighted = _weightedDegreeMap[e.to];

    if (fromDegree == null || toDegree == null) return;

    fromDegree.outDegree += delta;
    toDegree.inDegree += delta;

    if (!isDirected) {
      fromDegree.inDegree += delta;
      toDegree.outDegree += delta;
    }

    if (fromWeighted == null || toWeighted == null) return;

    fromWeighted.outWeight += w;
    toWeighted.inWeight += w;

    if (!isDirected) {
      fromWeighted.inWeight += w;
      toWeighted.outWeight += w;
    }
  }

  Degree degreeOf(String vid) => _degreeMap[vid] ?? Degree();

  WeightDegree weightDegreeOf(String vid) => _weightedDegreeMap[vid] ?? WeightDegree();
}

final class Degree {
  int inDegree = 0;
  int outDegree = 0;

  int get total => inDegree + outDegree;

  @override
  String toString() => 'Degree(in: $inDegree, out: $outDegree)';
}

final class WeightDegree {
  double inWeight = 0.0;
  double outWeight = 0.0;

  double get total => inWeight + outWeight;

  void clear() {
    inWeight = 0.0;
    outWeight = 0.0;
  }

  @override
  String toString() => 'WeightedDegree(in: $inWeight, out: $outWeight, total: $total)';
}

class CostPath {
  final double cost;
  final List<Edge> path;

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

    if ((other is! CostPath)) {
      return false;
    }

    final CostPath pair = other;
    if (cost != pair.cost) {
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

class CostVertex implements Comparable<CostVertex> {
  final Vertex vertex;
  double cost;

  CostVertex(this.cost, this.vertex);

  @override
  int get hashCode {
    return Object.hash(cost, vertex);
  }

  @override
  int compareTo(CostVertex p) {
    if (cost < p.cost) {
      return -1;
    }
    if (cost > p.cost) {
      return 1;
    }
    return 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is! CostVertex) {
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
