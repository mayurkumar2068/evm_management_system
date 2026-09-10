sealed class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  final String message;

  final Object? cause;

  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause, super.stackTrace});
}

class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.cause, super.stackTrace});
}

class ServerException extends AppException {
  const ServerException(
    super.message, {
    required this.statusCode,
    this.errorCode,
    super.cause,
    super.stackTrace,
  });

  final int statusCode;
  final String? errorCode;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.cause, super.stackTrace});
}

class ForbiddenException extends AppException {
  const ForbiddenException(super.message, {super.cause, super.stackTrace});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause, super.stackTrace});
}

class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    this.fieldErrors = const <String, List<String>>{},
    super.cause,
    super.stackTrace,
  });

  final Map<String, List<String>> fieldErrors;
}

class CacheException extends AppException {
  const CacheException(super.message, {super.cause, super.stackTrace});
}

class SecureStorageException extends AppException {
  const SecureStorageException(super.message, {super.cause, super.stackTrace});
}

class SecurityException extends AppException {
  const SecurityException(super.message, {super.cause, super.stackTrace});
}

class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause, super.stackTrace});
}
