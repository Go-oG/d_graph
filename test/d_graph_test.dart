import 'dart:math';
import 'dart:ui';

import 'package:dart_graph/dart_graph.dart';

void main() {

  var tree = RTree<Rect>((e)=>e,6);
  Random random = Random(1);
  List<Rect> list = [];
  for (int i = 0; i < 10000000; i++) {
    final rect = Rect.fromLTRB(
      random.nextDouble() * 100 + 50,
      random.nextDouble() * 100 + 50,
      random.nextDouble() * 1000 + 500,
      random.nextDouble() * 1000 + 500,
    );
    list.add(rect);
  }
  int st = DateTime.now().millisecondsSinceEpoch;
  tree = tree.addAll(list);
  print("构建耗时:${DateTime.now().millisecondsSinceEpoch - st}");
  st = DateTime.now().millisecondsSinceEpoch;
  final res = tree.search(Rect.fromLTRB(20, 20, 2000, 2000));
  print("搜索耗时:${DateTime.now().millisecondsSinceEpoch - st} size:${res.length}");

}
