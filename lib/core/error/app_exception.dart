/// Base class for every exception thrown inside the application boundary.
///
/// Data sources throw [AppException] subtypes; repositories convert them into
/// [Failure]s so that the domain and presentation layers never deal with raw
/// exceptions. This keeps error handling centralized and predictable.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  /// Human-meaningful, non-localized technical message (for logs).
  final String message;

  /// The originating error, if any.
  final Object? cause;

  /// Stack trace captured at the throw site, if available.
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a network request fails for connectivity reasons.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause, super.stackTrace});
}

/// Thrown when the request timed out.
class TimeoutException extends AppException {
  const TimeoutException(super.message, {super.cause, super.stackTrace});
}

/// Thrown when the server responds with a non-success HTTP status code.
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

/// Thrown on HTTP 401 — authentication required / token invalid.
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.cause, super.stackTrace});
}

/// Thrown on HTTP 403 — authenticated but not permitted.
class ForbiddenException extends AppException {
  const ForbiddenException(super.message, {super.cause, super.stackTrace});
}

/// Thrown on HTTP 404 — resource not found.
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause, super.stackTrace});
}

/// Thrown on HTTP 422 — semantic validation errors from the server.
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    this.fieldErrors = const <String, List<String>>{},
    super.cause,
    super.stackTrace,
  });

  final Map<String, List<String>> fieldErrors;
}

/// Thrown when reading/writing the local database fails.
class CacheException extends AppException {
  const CacheException(super.message, {super.cause, super.stackTrace});
}

/// Thrown when secure storage operations fail.
class SecureStorageException extends AppException {
  const SecureStorageException(super.message, {super.cause, super.stackTrace});
}

/// Thrown when a device integrity / security policy check fails.
class SecurityException extends AppException {
  const SecurityException(super.message, {super.cause, super.stackTrace});
}

/// Fallback for unexpected, unclassified errors.
class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause, super.stackTrace});
}
