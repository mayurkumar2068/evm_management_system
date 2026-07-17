import 'package:evm_management_system/core/error/result.dart';

/// Marker for use cases that take no parameters.
class NoParams {
  const NoParams();
}

/// Base contract for an asynchronous use case.
///
/// Each use case encapsulates one piece of application business logic, returns
/// a [Result] (never throws, never returns null), and depends only on domain
/// repository abstractions.
abstract interface class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Base contract for a synchronous use case.
abstract interface class SyncUseCase<T, Params> {
  Result<T> call(Params params);
}

/// Base contract for a streaming use case.
abstract interface class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}
