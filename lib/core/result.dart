import 'package:exercise_management/core/base_exception.dart';

/// A class that represents the result of an operation that can either succeed or fail.
///
/// Evaluate the result using a switch statement:
/// ```dart
/// switch (result) {
///  case Ok<Type>():
///  // handle success using: result.value
///  break;
///  case Error<Type>():
///  // handle error using: result.error
///  break;
///  default:
///  // handle other cases
///  break;
/// }
/// ```
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok._;

  const factory Result.error(BaseException error) = Error._;
}

final class Ok<T> extends Result<T> {
  const Ok._(this.value);

  final T value;

  @override
  String toString() => 'Result<$T>.ok($value)';
}

final class Error<T> extends Result<T> {
  const Error._(this.error);

  final BaseException error;

  @override
  String toString() => 'Result<$T>.error($error)';
}