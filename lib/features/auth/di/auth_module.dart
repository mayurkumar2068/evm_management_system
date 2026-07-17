import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/security/biometric_authenticator.dart';
import 'package:evm_management_system/features/auth/data/datasource/auth_local_datasource.dart';
import 'package:evm_management_system/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:evm_management_system/features/auth/data/repository_impl/auth_repository_impl.dart';
import 'package:evm_management_system/features/auth/domain/repository/auth_repository.dart';
import 'package:evm_management_system/features/auth/domain/usecases/biometric_login_usecase.dart';
import 'package:evm_management_system/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:evm_management_system/features/auth/domain/usecases/login_usecase.dart';
import 'package:evm_management_system/features/auth/domain/usecases/logout_usecase.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:get/get.dart';

/// Lazily wires auth data sources, repository and use cases via GetX.
abstract final class AuthModule {
  static AuthRepository? _repository;
  static LoginUseCase? _login;
  static LogoutUseCase? _logout;
  static GetCurrentUserUseCase? _getCurrentUser;
  static BiometricLoginUseCase? _biometricLogin;
  static PresidingElectionContextStore? _presidingContextStore;

  static PresidingElectionContextStore get presidingContextStore =>
      _presidingContextStore ??= PresidingElectionContextStore(
        AppServices.secureStorage,
      );

  static AuthRepository get repository => _repository ??= AuthRepositoryImpl(
    remote: AuthRemoteDataSourceImpl(AppServices.apiClient),
    local: AuthLocalDataSourceImpl(
      tokenVault: AppServices.tokenVault,
      secureStorage: AppServices.secureStorage,
    ),
    biometric: Get.find<BiometricAuthenticator>(),
    presidingElectionContextStore: presidingContextStore,
    environmentConfig: AppServices.config,
  );

  static LoginUseCase get login => _login ??= LoginUseCase(repository);
  static LogoutUseCase get logout => _logout ??= LogoutUseCase(repository);
  static GetCurrentUserUseCase get getCurrentUser =>
      _getCurrentUser ??= GetCurrentUserUseCase(repository);
  static BiometricLoginUseCase get biometricLogin =>
      _biometricLogin ??= BiometricLoginUseCase(repository);

  static AuthLocalDataSource get localDataSource => AuthLocalDataSourceImpl(
    tokenVault: AppServices.tokenVault,
    secureStorage: AppServices.secureStorage,
  );
}
