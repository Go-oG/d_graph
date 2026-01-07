import 'package:dart_graph/dart_graph.dart';

extension DFSG on Graph {
  List<Vertex> dfs(Vertex source) {
    final List<Vertex> vertices = vertexIterator.toList();

    final int n = vertices.size;
    final Map<Vertex, int> vertexToIndex = {};
    for (var i = 0; i < n; i++) {
      final Vertex v = vertices.get(i);
      vertexToIndex.put(v, i);
    }

    final Array<Array<int>> adj = Array(n);
    for (var i = 0; i < n; i++) {
      final Vertex v = vertices.get(i);
      final int idx = vertexToIndex.get(v)!;
      final Array<int> array = Array(n);
      adj[idx] = array;
      for (Edge e in edges2(v)) {
        array[vertexToIndex[getVertex(e.to)]!] = 1;
      }
    }

    final Array<int> visited = Array(n);
    for (var i = 0; i < visited.length; i++) {
      visited[i] = -1;
    }

    final Array<Vertex> arr = Array(n);

    Vertex element = source;
    int c = 0;
    int i = vertexToIndex.get(element)!;
    int k = 0;

    visited[i] = 1;
    arr[k] = element;
    k++;

    final List<Vertex> stack = [];
    stack.add(source);
    while (stack.isNotEmpty) {
      element = stack.last;
      c = vertexToIndex.get(element)!;
      i = 0;
      while (i < n) {
        if (adj[c][i] == 1 && visited[i] == -1) {
          final Vertex v = vertices.get(i);
          stack.add(v);
          visited[i] = 1;

          element = v;
          c = vertexToIndex.get(element)!;
          i = 0;

          arr[k] = v;
          k++;
          continue;
        }
        i++;
      }
      stack.removeLast();
    }
    return arr.toList();
  }

  List<int> dfs2(int n, Array<Array<int>> adjacencyMatrix, int source) {
    final Array<int> visited = Array(n);
    for (int i = 0; i < visited.length; i++) {
      visited[i] = -1;
    }

    int element = source;
    int i = source;
    Array<int> arr = Array(n);
    int k = 0;

    visited[source] = 1;
    arr[k] = element;
    k++;

    final List<int> stack = [];
    stack.add(source);
    while (stack.isNotEmpty) {
      element = stack.last;
      i = 0;
      while (i < n) {
        if (adjacencyMatrix[element][i] == 1 && visited[i] == -1) {
          stack.add(i);
          visited[i] = 1;
          element = i;
          i = 0;
          arr[k] = element;
          k++;
          continue;
        }
        i++;
      }
      stack.removeLast();
    }
    return arr.toList();
  }
}
