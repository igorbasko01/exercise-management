import 'package:exercise_management/core/base_exception.dart';

class Result<T> {
  final T? data;
  final BaseException? error;

  Result._({this.data, this.error});

  factory Result.success(T data) {
    return Result._(data: data);
  }

  factory Result.failure(BaseException error) {
    return Result._(error: error);
  }

  bool get isSuccess => data != null;
  bool get isFailure => error != null;
}

extension UnpackResult<T> on Result<T> {
  void unpack({
    required Function(T data) onSuccess,
    required Function(BaseException error) onFailure,
  }) {
    if (isSuccess) {
      onSuccess(data as T);
    } else {
      onFailure(error!);
    }
  }
}