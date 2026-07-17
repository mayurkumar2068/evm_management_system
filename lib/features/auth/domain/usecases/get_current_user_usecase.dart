import 'package:evm_management_system/core/error/result.dart';
import 'package:evm_management_system/core/usecase/usecase.dart';
import 'package:evm_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:evm_management_system/features/auth/domain/repository/auth_repository.dart';

/// Retrieves the currently authenticated user from the secure session.
class GetCurrentUserUseCase implements UseCase<AuthUser, NoParams> {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(NoParams params) => _repository.currentUser();
}
