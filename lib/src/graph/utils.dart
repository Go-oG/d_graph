import 'package:dart_graph/dart_graph.dart';

final class MatchingResult<V> {
  final Map<Vertex<V>, Vertex<V>> mate;
  late final int size;

  MatchingResult(this.mate) {
    // 因为 mate 存储了双向关系 (u->v 和 v->u)，所以大小除以 2
    size = mate.length ~/ 2;
  }

  @override
  String toString() {
    return 'Matching Size: $size';
  }
}

final class MSTResult<E> {
  final double totalCost;
  final List<Edge<E>> edges;
  MSTResult(this.totalCost, this.edges);
}
