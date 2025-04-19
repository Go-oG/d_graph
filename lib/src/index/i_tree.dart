abstract class ITree<T> {
  bool add(T value);

  T? remove(T value);

  void clear();

  bool contains(T value);

  int get size;

  bool validate();

  Iterable<T> toCollection();

  bool get isEmpty => size <= 0;

  bool get isNotEmpty => !isEmpty;
}
