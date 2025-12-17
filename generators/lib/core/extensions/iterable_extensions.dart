/// Extensions for [Iterable] types.
extension IterableExtensions<T> on Iterable<T> {
  /// Returns the first element that satisfies the given [test] function,
  /// or `null` if no such element is found.
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
