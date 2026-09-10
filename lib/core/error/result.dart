import 'package:evm_management_system/core/error/failure.dart';

sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;

  const factory Result.failure(Failure failure) = Err<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Err<T>;

  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    Err<T>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Err<T>(:final failure) => failure,
  };

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) => switch (this) {
    Success<T>(:final value) => onSuccess(value),
    Err<T>(:final failure) => onFailure(failure),
  };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success<T>(:final value) => Result<R>.success(transform(value)),
    Err<T>(:final failure) => Result<R>.failure(failure),
  };

  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
    Success<T>(:final value) => transform(value),
    Err<T>(:final failure) => Result<R>.failure(failure),
  };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
