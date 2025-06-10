import '../map_ext.dart';
import 'bellman_ford.dart';
import 'dijkstra.dart';
import 'graph.dart';

/// Johnson 算法是一种查找所有稀疏有向图中的顶点。
/// 它允许一些边权重为负数，但不存在负权重循环.
extension Johnson<T> on Graph<T> {
  Map<Vertex<T>, Map<Vertex<T>, List<Edge<T>>>> shortestPathsByJohnson(T maxData) {
    final Graph<T> graph = Graph.of(this);

    final Vertex<T> connector = Vertex<T>(maxData);

    for (Vertex<T> v in graph.vertices) {
      final int indexOfV = graph.vertices.indexOf(v);
      final Edge<T> edge = Edge<T>(0, connector, graph.vertices[indexOfV]);
      connector.addEdge(edge);
      graph.edges.add(edge);
    }

    graph.vertices.add(connector);

    final Map<Vertex<T>, CostPath<T>> costs = graph.shortestPathsByBellmanFord(connector);

    for (Edge<T> e in graph.edges) {
      final int weight = e.cost;
      final Vertex<T> u = e.from;
      final Vertex<T> v = e.to;

      if (u == connector || v == connector) {
        continue;
      }

      // Adjust the costs
      final int uCost = costs.get(u)!.cost;
      final int vCost = costs.get(v)!.cost;
      final int newWeight = weight + uCost - vCost;
      e.cost = newWeight;
    }

    final int indexOfConnector = graph.vertices.indexOf(connector);
    graph.vertices.removeAt(indexOfConnector);
    for (Edge<T> e in connector.edges) {
      final int indexOfConnectorEdge = graph.edges.indexOf(e);
      graph.edges.removeAt(indexOfConnectorEdge);
    }

    final Map<Vertex<T>, Map<Vertex<T>, List<Edge<T>>>> allShortestPaths = {};

    for (Vertex<T> v in graph.vertices) {
      final Map<Vertex<T>, CostPath<T>> costPaths = graph.shortestPathsByDijkstra(v);
      final Map<Vertex<T>, List<Edge<T>>> paths = {};
      for (Vertex<T> v2 in costPaths.keys) {
        final CostPath<T> pair = costPaths.get(v2)!;
        paths.put(v2, pair.path);
      }
      allShortestPaths.put(v, paths);
    }
    return allShortestPaths;
  }
}
