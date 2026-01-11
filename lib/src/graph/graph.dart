import 'package:dart_graph/dart_graph.dart';

final class Vertex<T> with ValueExtraMixin {
  final String id;
  final T? data;
  final String? label;
  final Map<String, dynamic> meta = {};
  double weight = 0;

  Vertex({
    required this.id,
    Map<String, dynamic>? meta,
    this.label,
    this.data,
  }) {
    if (meta != null) {
      this.meta.addAll(meta);
    }
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'label': label, 'data': data, 'meta': meta};
  }

  static Vertex fromMap(Map<String, dynamic> map) {
    return Vertex(id: map['id'], label: map['label'], data: map['data'], meta: map['meta']);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Vertex && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

final class Edge with ValueExtraMixin {
  final String id;
  final String from;
  final String to;
  final bool? directed;
  final Map<String, dynamic> meta = {};
  final Object? data;

  double weight;

  Edge({
    required this.id,
    required this.from,
    required this.to,
    Map<String, dynamic>? meta,
    this.directed,
    this.weight = 0,
    this.data,
  }) {
    if (meta != null) {
      this.meta.addAll(meta);
    }
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'from': from, 'to': to, 'directed': directed, 'weight': weight, 'data': data, 'meta': meta};
  }

  static Edge fromMap<T>(Map<String, dynamic> map) {
    return Edge(
      id: map['id'],
      from: map['from'],
      to: map['to'],
      directed: map['directed'],
      meta: map['meta'],
      data: map['data'],
      weight: map['weight'],
    );
  }

  bool isDirected(bool graphDirected) => directed ?? graphDirected;
}

final class Graph<T> {
  final bool directed;
  final bool allowMultiEdge;
  final bool allowSelfLoop;
  final Map<String, dynamic> meta = {};

  final Map<String, Vertex<T>> _vertexMap = {};
  final Map<String, Edge> _edgeMap = {};

  final Map<String, Map<String, Edge>> _vertexOutEdges = {};
  final Map<String, Map<String, Edge>> _vertexInEdges = {};

  late final GraphDegree _degree;

  Graph({
    this.directed = false,
    this.allowMultiEdge = true,
    this.allowSelfLoop = false,
    Iterable<Vertex<T>>? vertices,
    Iterable<Edge>? edges,
    Map<String, dynamic>? meta,
  }) {
    _degree = GraphDegree(this);
    if (vertices != null) {
      addVertices(vertices);
    }
    if (edges != null) {
      addEdges(edges);
    }
    if (meta != null) {
      this.meta.addAll(meta);
    }
  }

  static Graph<D> of<D>(Graph<D> g, {String? id}) {
    return Graph(
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

  void addVertex(Vertex<T> vertex) {
    if (_vertexMap.containsKey(vertex.id)) {
      return;
    }
    _vertexMap[vertex.id] = vertex;
    _degree._onVertexAdded(vertex);
  }

  void addVertices(Iterable<Vertex<T>> vertexs) {
    for (var v in vertexs) {
      addVertex(v);
    }
  }

  Vertex<T> getVertex(String id) => getVertexOrNull(id)!;

  Vertex<T>? getVertexOrNull(String id) => _vertexMap[id];

  Edge getEdge(String id) => getEdgeOrNull(id)!;

  Edge? getEdgeOrNull(String id) => _edgeMap[id];

  Edge? getEdge2(String from, String to) {
    for (var e in edges(from)) {
      if (e.to == to) {
        return e;
      }
    }
    return null;
  }

  void removeVertex(Vertex<T> vertex) {
    final id = vertex.id;
    if (!_vertexMap.containsKey(id)) return;
    _degree._onVertexRemoved(vertex);

    final edgesToRemove = <Edge>{};
    _vertexOutEdges[id]?.values.forEach(edgesToRemove.add);
    _vertexInEdges[id]?.values.forEach(edgesToRemove.add);

    for (final e in edgesToRemove) {
      removeEdge(e);
    }

    _vertexOutEdges.remove(id);
    _vertexInEdges.remove(id);
    _vertexMap.remove(id);
  }

  void removeVertices(Iterable<Vertex<T>> vertexs) {
    for (var v in vertexs) {
      removeVertex(v);
    }
  }

  void addEdges(Iterable<Edge> edges) {
    for (var e in edges) {
      addEdge(e);
    }
  }

  void addEdge(Edge edge) {
    if (!_vertexMap.containsKey(edge.from) || !_vertexMap.containsKey(edge.to)) {
      throw StateError('Edge endpoint does not exist');
    }

    if (_edgeMap.containsKey(edge.id)) {
      return;
    }
    if (!allowSelfLoop && edge.from == edge.to) {
      throw StateError('Self-loop is not allowed');
    }

    if (!allowMultiEdge) {
      final outEdges = _vertexOutEdges[edge.from];
      if (outEdges != null) {
        for (final existing in outEdges.values) {
          if (existing.to == edge.to) {
            throw StateError('Multi-edge is not allowed between ${edge.from} and ${edge.to}');
          }
        }
      }
    }

    _edgeMap[edge.id] = edge;
    _vertexOutEdges.putIfAbsent(edge.from, () => {})[edge.id] = edge;
    _vertexInEdges.putIfAbsent(edge.to, () => {})[edge.id] = edge;

    if (!edge.isDirected(directed)) {
      _vertexOutEdges.putIfAbsent(edge.to, () => {})[edge.id] = edge;
      _vertexInEdges.putIfAbsent(edge.from, () => {})[edge.id] = edge;
    }

    _degree._onEdgeAdded(edge);
  }

  void removeEdge(Edge edge) {
    if (!_edgeMap.containsKey(edge.id)) return;

    _degree._onEdgeRemoved(edge);

    _edgeMap.remove(edge.id);
    _vertexOutEdges[edge.from]?.remove(edge.id);
    _vertexInEdges[edge.to]?.remove(edge.id);

    if (!edge.isDirected(directed)) {
      _vertexOutEdges[edge.to]?.remove(edge.id);
      _vertexInEdges[edge.from]?.remove(edge.id);
    }
  }

  void removeEdges(Iterable<Edge> edges) {
    for (var v in edges) {
      removeEdge(v);
    }
  }

  void clear() {
    _vertexMap.clear();
    _edgeMap.clear();
    _vertexInEdges.clear();
    _vertexOutEdges.clear();
  }

  bool hasEdge(Edge edge) => _edgeMap.containsKey(edge.id);

  bool hasVertex(Vertex<T> vertex) => _vertexMap.containsKey(vertex.id);

  Degree degreeOf(String vertexId) => _degree.degreeOf(vertexId);

  WeightDegree weightDegreeOf(String vertexId) => _degree.weightDegreeOf(vertexId);

  Map<String, Edge> inEdges(Vertex<T> vertex) => _vertexInEdges[vertex.id] ?? const {};

  Map<String, Edge> outEdges(Vertex<T> vertex) => _vertexOutEdges[vertex.id] ?? const {};

  List<Edge> edges(String vertexId) {
    final vertex = _vertexMap[vertexId];
    if (vertex == null) {
      return [];
    }
    return edges2(vertex);
  }

  List<Edge> edges2(Vertex<T> vertex) {
    Set<Edge> edges = <Edge>{};
    edges.addAll(inEdges(vertex).values);
    edges.addAll(outEdges(vertex).values);
    return edges.toList();
  }

  Iterable<Edge> get edgeIterator => _edgeMap.values;

  Iterable<Vertex<T>> get vertexIterator => _vertexMap.values;

  Map<String, Vertex<T>> get vertexMap => _vertexMap;

  Map<String, Edge> get edgeMap => _edgeMap;

  Map<String, Map<String, Edge>> get vertexsOutEdges => _vertexOutEdges;

  Map<String, Map<String, Edge>> get vertexsInEdges => _vertexInEdges;

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
    final isDirected = e.isDirected(graph.directed);

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
