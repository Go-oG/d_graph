# dart_graph

`dart_graph` 是一个面向 Flutter 绘制、几何计算、图算法和空间索引的工具库。它以 Flutter 的 `Offset`、`Rect`、`Path` 为基础，提供常用几何对象、贝塞尔曲线工具、图结构与算法，以及 R-Tree、QuadTree、KdTree、堆、搜索树等数据结构。

## 特性

- 几何模型：`Circle`、`SegmentLine`、`RayLine`、`Line`、`Polygon`、`Triangle`、`Arc`、`AnnularSector`
- 几何计算：面积、长度、中心点、包围盒、包含判断、相交判断、交点计算、距离计算
- Flutter 绘制辅助：几何对象可生成 `Path`，并提供 `Path`、`Offset`、`Rect`、`RRect` 扩展
- 曲线工具：三次贝塞尔曲线、圆弧/圆/圆角矩形转曲线、曲线分段、等距采样、折线与平滑曲线风格
- 图算法：BFS、DFS、Dijkstra、A*、Bellman-Ford、Floyd-Warshall、Johnson、Prim、Kruskal、拓扑排序、连通分量、环检测、匹配、最大流
- 空间索引：`RTree`、`QuadTree`、`KdTree`，适合碰撞检测、范围查询、最近点查询等场景
- 常用数据结构：`Tree`、`BinarySearchTree`、`AVLTree`、`BTree`、`BinaryHeap`

## 环境要求

```yaml
environment:
  sdk: ">=3.11.0 <4.0.0"
  flutter: ">=3.41.0"
```

库中大量 API 依赖 `dart:ui` 的 `Offset`、`Rect`、`Path`，推荐在 Flutter 项目中使用。

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  dart_graph: ^1.2.2
```

如果从当前仓库源码引入，也可以使用本地路径依赖：

```yaml
dependencies:
  dart_graph:
    path: ../d_graph
```

然后执行：

```bash
flutter pub get
```

## 快速开始

```dart
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';
```

### 几何计算

```dart
final circle = Circle(center: Offset.zero, radius: 10);
final line = SegmentLine(const Offset(-20, 0), const Offset(20, 0));

final intersects = circle.isOverlap(line);
final points = circle.crossPoint(line);
final distance = circle.distanceWithPoint(const Offset(30, 0));

print(intersects); // true
print(points); // 圆与线段的交点
print(distance); // 点到圆的距离
```

所有继承自 `BasicGeometry` 的几何对象都提供统一能力：

```dart
geometry.area;
geometry.length;
geometry.center;
geometry.bbox;
geometry.path;
geometry.containsPoint(point);
geometry.isOverlap(otherGeometry);
geometry.crossPoint(otherGeometry);
geometry.distance(otherGeometry);
```

### 扇形与圆环扇形

```dart
import 'dart:math';
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';

final arc = Arc(
  center: const Offset(100, 100),
  innerRadius: 40,
  outRadius: 80,
  startAngle: 0.asRadians,
  sweepAngle: (pi / 2).asRadians,
  cornerRadius: 6,
);

final contains = arc.containsPoint(const Offset(150, 120));
final path = arc.path;
```

### 曲线与 Path

```dart
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';

final points = [
  const Offset(0, 80),
  const Offset(40, 20),
  const Offset(80, 60),
  const Offset(120, 10),
];

final curves = CatmullRomCurve(smooth: 0.5).apply(points);
final path = curves.toCurvePath(false);

final middlePoint = path.percentOffset(0.5);
final dashedPath = path.dashPath([8, 4]);
```

可用线型包括普通折线、阶梯线、圆角阶梯线、Basis、Cardinal、Catmull-Rom、Monotone、Natural 等。

### 空间索引

```dart
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';

final tree = RTree<Rect>((rect) => rect);

tree.addAll([
  const Rect.fromLTWH(0, 0, 20, 20),
  const Rect.fromLTWH(50, 50, 10, 10),
  const Rect.fromLTWH(90, 20, 30, 30),
]);

final visibleItems = tree.search(const Rect.fromLTWH(0, 0, 60, 60));
final hasCollision = tree.hasCollides(const Rect.fromLTWH(10, 10, 20, 20));
```

`RTree` 适合矩形范围检索；`QuadTree` 适合二维点数据的范围查询和邻近查询；`KdTree` 适合点集的矩形查询和最近点查询。

### 树和堆

```dart
import 'package:dart_graph/dart_graph.dart';

final heap = BinaryHeapArray<int>((a, b) => a.compareTo(b), HeapType.min);
heap.add(3);
heap.add(1);
heap.add(2);

print(heap.removeHead()); // 1

final tree = Tree<String>();
tree.add(null, 'root');
tree.add('root', 'child-a');
tree.add('root', 'child-b');

final path = tree.findPath('child-a', 'child-b');
```

## 模块说明

| 模块 | 主要 API | 说明 |
| --- | --- | --- |
| 几何对象 | `Circle`、`SegmentLine`、`Polygon`、`Triangle`、`Arc` | 构建可计算、可绘制的几何对象 |
| 几何工具 | `IntersectUtil`、`ContainsUtil`、`BoundaryUtil`、`CoordUtil` | 相交、包含、边界、坐标换算等静态工具 |
| 曲线 | `Curve`、`CurveUtil`、`LineStyle`、`EvenSpacer2` | 构建贝塞尔曲线和 Flutter `Path` |
| 图 | `Graph`、`Vertex`、`Edge` | 图结构、遍历、最短路径、生成树、最大流、匹配 |
| 空间索引 | `RTree`、`QuadTree`、`KdTree` | 面向二维空间数据的索引和查询 |
| 基础结构 | `Tree`、`BinaryHeap`、`BinarySearchTree`、`AVLTree`、`BTree` | 常见树结构和堆结构 |
| 扩展方法 | `OffsetExt`、`RectExt`、`PathExt`、`DTS*Ext` | 简化 Flutter 和 DTS 几何类型之间的操作 |

## 图算法概览

`Graph<V, E>` 使用字符串 `id` 标识顶点和边，顶点与边都可携带业务数据和权重。

- 遍历：`bfs`、`dfs`
- 最短路径：`shortestPaths`、`shortestPathTo`、`aStar`、`shortestPathsByBellmanFord`、`getVertexAllShortestPaths`、`shortestPathsByJohnson`
- 最小生成树：`minSpanningTreeByPrim`、`minSpanningTreeByKruskal`
- 有向无环图：`topologicalSort`、`topologicalLevelSort`
- 图分析：`connectedComponents`、`hasCycle`
- 匹配与流：`maxMatching`、`maxMatchingGeneral`、`EdmondsKarp`、`PushRelabel`

## 开发

```bash
flutter pub get
flutter analyze
flutter test
```

## 许可证

详见 [LICENSE](LICENSE)。
