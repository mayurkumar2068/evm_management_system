import 'package:evm_management_system/core/error/failure.dart';

/// A type-safe alternative to throwing exceptions or returning null.
///
/// Every repository / use case returns a [Result], forcing callers to handle
/// both the success and failure branches explicitly.
sealed class Result<T> {
  const Result();

  /// Creates a successful result.
  const factory Result.success(T value) = Success<T>;

  /// Creates a failed result.
  const factory Result.failure(Failure failure) = Err<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Err<T>;

  /// Returns the value when successful, otherwise `null`.
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    Err<T>() => null,
  };

  /// Returns the failure when failed, otherwise `null`.
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Err<T>(:final failure) => failure,
  };

  /// Exhaustively folds both branches into a single value of type [R].
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) => switch (this) {
    Success<T>(:final value) => onSuccess(value),
    Err<T>(:final failure) => onFailure(failure),
  };

  /// Transforms the success value while preserving a failure.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success<T>(:final value) => Result<R>.success(transform(value)),
    Err<T>(:final failure) => Result<R>.failure(failure),
  };

  /// Chains another [Result]-returning operation.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Success<T>(:final value) => transform(value),
    Err<T>(:final failure) => Result<R>.failure(failure),
  };
}

/// The success branch.
final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

/// The failure branch.
final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
