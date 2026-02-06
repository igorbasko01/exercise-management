/// A wrapper class to handle nullable values in `copyWith` methods.
///
/// This allows distinguishing between:
/// 1. Not passing a value (don't update)
/// 2. Passing `null` (update to null) - represented as `Value(null)`
/// 3. Passing a non-null value (update to value) - represented as `Value(value)`
class Value<T> {
  final T value;
  const Value(this.value);
}
