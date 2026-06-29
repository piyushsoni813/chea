import 'package:dio/dio.dart';
import '../errors/failures.dart';

/// Wraps every API call so callers get a typed result without try/catch noise.
class ApiResult<T> {
  final T? data;
  final Failure? failure;
  const ApiResult._({this.data, this.failure});

  factory ApiResult.success(T data) => ApiResult._(data: data);
  factory ApiResult.failed(Failure f) => ApiResult._(failure: f);

  bool get isSuccess => failure == null;
  T get requireData => data!;
}

/// Utility: run [fn] and translate Dio exceptions → Failures.
Future<ApiResult<T>> safeApiCall<T>(Future<T> Function() fn) async {
  try {
    final result = await fn();
    return ApiResult.success(result);
  } on DioException catch (e) {
    return ApiResult.failed(_fromDio(e));
  } catch (e) {
    return ApiResult.failed(UnknownFailure(e.toString()));
  }
}

Failure _fromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure('No internet connection. Please check your network.');
    default:
  }
  final status = e.response?.statusCode;
  final msg = e.response?.data?['detail']?.toString() ?? e.message ?? 'Unknown error';
  return switch (status) {
    401 => const UnauthorizedFailure(),
    404 => NotFoundFailure(msg),
    422 => ValidationFailure(msg),
    _ when status != null && status >= 500 =>
        ServerFailure('Server error. Please try again later.', statusCode: status),
    _ => ServerFailure(msg, statusCode: status),
  };
}
