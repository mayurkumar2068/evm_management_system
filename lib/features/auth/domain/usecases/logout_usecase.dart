import 'package:evm_management_system/core/error/result.dart';
import 'package:evm_management_system/core/usecase/usecase.dart';
import 'package:evm_management_system/features/auth/domain/repository/auth_repository.dart';

/// Ends the current session.
class LogoutUseCase implements UseCase<void, NoParams> {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(NoParams params) => _repository.logout();
}
