import 'package:evm_management_system/core/error/result.dart';

class NoParams {
  const NoParams();
}

abstract interface class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

abstract interface class SyncUseCase<T, Params> {
  Result<T> call(Params params);
}

abstract interface class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}
