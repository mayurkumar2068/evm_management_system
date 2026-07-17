import 'package:evm_management_system/core/error/result.dart';
import 'package:evm_management_system/core/usecase/usecase.dart';
import 'package:evm_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:evm_management_system/features/auth/domain/repository/auth_repository.dart';

/// Authenticates the officer using device biometrics against a stored session.
class BiometricLoginUseCase implements UseCase<AuthUser, NoParams> {
  const BiometricLoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(NoParams params) =>
      _repository.loginWithBiometrics();
}
