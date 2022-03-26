class ApiResult<T> {
  final bool succeeded;
  final T? value;
  final Exception? error;

  ApiResult({
    required this.succeeded,
    this.value,
    this.error,
  });

  T get valueUnsafe => value!;

  factory ApiResult.success(T value) {
    return ApiResult(
      succeeded: true,
      value: value,
    );
  }

  factory ApiResult.failed(Exception error) {
    return ApiResult(
      succeeded: false,
      error: error,
    );
  }
}
