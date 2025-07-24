import 'package:exercise_management/core/base_exception.dart';
import 'package:exercise_management/core/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should create an ok result', () {
    final result = Result.ok(42);
    expect(result, isA<Ok>());
    expect((result as Ok).value, 42);
  });

  test('should create an error result', () {
    const error = TestException('error');
    const result = Result.error(error);
    expect(result, isA<Error>());
    expect((result as Error).error, error);
  });

  test('should go to ok case', () {
    final result = Result.ok(42);
    switch (result) {
      case Ok<int>():
        expect(result.value, 42);
        break;
      case Error():
        fail('should not go to error case');
      default:
        fail('should not go to default case');
    }
  });

  test('should go to error case', () {
    const error = TestException('error');
    const result = Result.error(error);
    switch (result) {
      case Ok<int>():
        fail('should not go to ok case');
      case Error():
        expect(result.error, error);
        break;
      default:
        fail('should not go to default case');
    }
  });
}

class TestException implements BaseException {
  const TestException(this.message);

  @override
  final String message;
}
