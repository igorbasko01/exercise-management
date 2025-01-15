class Result<T> {
  final T? data;
  final Exception? error;

  Result._({this.data, this.error});

  factory Result.success(T data) {
    return Result._(data: data);
  }

  factory Result.failure(Exception error) {
    return Result._(error: error);
  }

  bool get isSuccess => data != null;
  bool get isFailure => error != null;
}

extension UnpackResult<T> on Result<T> {
  void unpack({
    required Function(T data) onSuccess,
    required Function(Exception error) onFailure,
  }) {
    if (isSuccess) {
      onSuccess(data!);
    } else {
      onFailure(error!);
    }
  }
}