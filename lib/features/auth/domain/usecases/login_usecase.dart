import 'package:evm_management_system/core/error/result.dart';
import 'package:evm_management_system/core/usecase/usecase.dart';
import 'package:evm_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:evm_management_system/features/auth/domain/entities/login_credentials.dart';
import 'package:evm_management_system/features/auth/domain/repository/auth_repository.dart';

class LoginUseCase implements UseCase<AuthUser, LoginCredentials> {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(LoginCredentials params) =>
      _repository.login(params);
}
