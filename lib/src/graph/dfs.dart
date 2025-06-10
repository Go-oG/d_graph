import 'package:dart_graph/dart_graph.dart';

extension DFSG<T> on Graph<T> {
  List<Vertex<T>> dfs(Vertex<T> source) {
    final List<Vertex<T>> vertices = [];
    vertices.addAll(this.vertices);

    final int n = vertices.size;
    final Map<Vertex<T>, int> vertexToIndex = {};
    for (var i = 0; i < n; i++) {
      final Vertex<T> v = vertices.get(i);
      vertexToIndex.put(v, i);
    }

    final Array<Array<int>> adj = Array(n);
    for (var i = 0; i < n; i++) {
      final Vertex<T> v = vertices.get(i);
      final int idx = vertexToIndex.get(v)!;
      final Array<int> array = Array(n);
      adj[idx] = array;
      for (Edge<T> e in v.edges) {
        array[vertexToIndex.get(e.to)!] = 1;
      }
    }

    final Array<int> visited = Array(n);
    for (var i = 0; i < visited.length; i++) {
      visited[i] = -1;
    }

    final Array<Vertex<T>> arr = Array(n);

    Vertex<T> element = source;
    int c = 0;
    int i = vertexToIndex.get(element)!;
    int k = 0;

    visited[i] = 1;
    arr[k] = element;
    k++;

    final List<Vertex<T>> stack = [];
    stack.add(source);
    while (stack.isNotEmpty) {
      element = stack.last;
      c = vertexToIndex.get(element)!;
      i = 0;
      while (i < n) {
        if (adj[c][i] == 1 && visited[i] == -1) {
          final Vertex<T> v = vertices.get(i);
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
