import 'dart:collection';

import 'package:d_util/d_util.dart';

import 'graph.dart';

/// 广度优先搜索 （BFS） 是一种用于遍历或搜索树或图形数据结构的算法。它从树根（或图形的某个任意节点，有时称为
/// 'search key'） 并首先探索邻居节点，然后再移动到下一级别的邻居.
/// <p>
/// @see <a href="https://en.wikipedia.org/wiki/Breadth-first_search">Breadth-First Search (Wikipedia)</a>
/// <br>
/// @author Justin Wetherell <phishman3579@gmail.com>
extension BFSGE<T> on Graph<T> {
  List<Vertex<T>> bfs(Vertex<T> source) {
    final List<Vertex<T>> vertices = [];
    vertices.addAll(this.vertices);

    final n = vertices.size;
    final Map<Vertex<T>, int> vertexToIndex = {};
    for (var i = 0; i < n; i++) {
      final Vertex<T> v = vertices.get(i);
      vertexToIndex.put(v, i);
    }

    final Array<Array<int>> adj = Array(n);

    for (var i = 0; i < n; i++) {
      final Vertex<T> v = vertices.get(i);
      final idx = vertexToIndex.get(v)!;
      final Array<int> array = Array(n);
      adj[idx] = array;
      final List<Edge<T>> edges = v.edges;
      for (Edge<T> e in edges) {
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

    arr[k] = element;
    visited[i] = 1;
    k++;

    final Queue<Vertex<T>> queue = Queue();
    queue.add(source);
    while (queue.isNotEmpty) {
      element = queue.first;
      c = vertexToIndex.get(element)!;
      i = 0;
      while (i < n) {
        if (adj[c][i] == 1 && visited[i] == -1) {
          final Vertex<T> v = vertices.get(i);
          queue.add(v);
          visited[i] = 1;

          arr[k] = v;
          k++;
        }
        i++;
      }
      queue.removeFirst();
    }
    return arr.toList();
  }

  List<int> bfs2(int n, Array<Array<int>> adjacencyMatrix, int source) {
    final Array<int> visited = Array(n);
    for (var i = 0; i < visited.length; i++) {
      visited[i] = -1;
    }

    int element = source;
    int i = source;
    Array<int> arr = Array(n);
    int k = 0;

    arr[k] = element;
    visited[i] = 1;
    k++;

    final Queue<int> queue = Queue();
    queue.add(source);
    while (queue.isNotEmpty) {
      element = queue.first;
      i = 0;
      while (i < n) {
        if (adjacencyMatrix[element][i] == 1 && visited[i] == -1) {
          queue.add(i);
          visited[i] = 1;

          arr[k] = i;
          k++;
        }
        i++;
      }
      queue.removeFirst();
    }
    return arr.toList();
  }
}
