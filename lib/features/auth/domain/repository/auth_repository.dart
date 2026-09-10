import 'package:evm_management_system/core/error/result.dart';
import 'package:evm_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:evm_management_system/features/auth/domain/entities/login_credentials.dart';

abstract interface class AuthRepository {
  Future<Result<AuthUser>> login(LoginCredentials credentials);

  Future<Result<void>> logout();

  Future<Result<AuthUser>> currentUser();

  Future<bool> hasValidSession();

  Future<void> establishLocalSession(AuthUser user);

  Future<Result<AuthUser>> loginWithBiometrics();

  Future<Result<void>> setBiometricEnabled({required bool enabled});

  Future<bool> isBiometricEnabled();
}
