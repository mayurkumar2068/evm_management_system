import 'package:dio/dio.dart';
import 'package:evm_management_system/core/error/app_exception.dart';
import 'package:evm_management_system/core/error/failure.dart';

/// Centralized translation of low-level errors into domain [Failure]s.
///
/// This is the single place that knows how HTTP status codes and exception
/// types map to failures, satisfying the "handle 401/403/404/422/500 centrally"
/// requirement.
abstract final class ErrorMapper {
  /// Maps any caught [error] into a [Failure].
  static Failure map(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) return error;
    if (error is DioException) return _fromDio(error);
    if (error is AppException) return _fromAppException(error);
    return UnknownFailure(debugMessage: error.toString());
  }

  static Failure _fromAppException(AppException e) => switch (e) {
    NetworkException() => NetworkFailure(debugMessage: e.message),
    TimeoutException() => NetworkFailure(debugMessage: e.message),
    UnauthorizedException() => UnauthorizedFailure(debugMessage: e.message),
    ForbiddenException() => ForbiddenFailure(debugMessage: e.message),
    NotFoundException() => NotFoundFailure(debugMessage: e.message),
    ValidationException(:final fieldErrors) => ValidationFailure(
      fieldErrors: fieldErrors,
      debugMessage: e.message,
    ),
    ServerException(:final statusCode, :final errorCode) => ApiFailure(
      statusCode: statusCode,
      errorCode: errorCode,
      debugMessage: e.message,
    ),
    CacheException() => CacheFailure(debugMessage: e.message),
    SecureStorageException() => CacheFailure(debugMessage: e.message),
    SecurityException() => SecurityFailure(debugMessage: e.message),
    UnknownException() => UnknownFailure(debugMessage: e.message),
  };

  static Failure _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(debugMessage: 'Timeout: ${e.message}');
      case DioExceptionType.connectionError:
        return NetworkFailure(debugMessage: 'Connection error: ${e.message}');
      case DioExceptionType.cancel:
        return const UnknownFailure(debugMessage: 'Request cancelled');
      case DioExceptionType.badCertificate:
        return const SecurityFailure(debugMessage: 'Bad SSL certificate');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return _fromStatusCode(e);
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  static Failure _fromStatusCode(DioException e) {
    final int? code = e.response?.statusCode;
    final String? serverMessage = _extractMessage(e.response?.data);
    return switch (code) {
      401 => UnauthorizedFailure(debugMessage: serverMessage),
      403 => ForbiddenFailure(debugMessage: serverMessage),
      404 => NotFoundFailure(debugMessage: serverMessage),
      422 => ValidationFailure(
        fieldErrors: _extractFieldErrors(e.response?.data),
        debugMessage: serverMessage,
      ),
      _ => ApiFailure(statusCode: code, debugMessage: serverMessage),
    };
  }

  static String? _extractMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final Object? msg = data['message'] ?? data['error'] ?? data['detail'];
      return msg?.toString();
    }
    return data?.toString();
  }

  static Map<String, List<String>> _extractFieldErrors(Object? data) {
    if (data is Map<String, dynamic> && data['errors'] is Map) {
      final Map<dynamic, dynamic> errors =
          data['errors'] as Map<dynamic, dynamic>;
      return errors.map(
        (Object? key, Object? value) => MapEntry<String, List<String>>(
          key.toString(),
          value is List
              ? value.map((Object? e) => e.toString()).toList()
              : <String>[value.toString()],
        ),
      );
    }
    return const <String, List<String>>{};
  }
}
