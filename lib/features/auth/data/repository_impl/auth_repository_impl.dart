import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/error/error_mapper.dart';
import 'package:evm_management_system/core/error/failure.dart';
import 'package:evm_management_system/core/error/result.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/security/biometric_authenticator.dart';
import 'package:evm_management_system/core/security/token_vault.dart';
import 'package:evm_management_system/features/auth/data/datasource/auth_local_datasource.dart';
import 'package:evm_management_system/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:evm_management_system/features/auth/data/mapper/user_mapper.dart';
import 'package:evm_management_system/features/auth/data/models/auth_response_model.dart';
import 'package:evm_management_system/features/auth/data/models/user_model.dart';
import 'package:evm_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:evm_management_system/features/auth/domain/entities/login_credentials.dart';
import 'package:evm_management_system/features/auth/domain/repository/auth_repository.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/presiding_election_context_factory.dart';
import 'package:evm_management_system/localization/locale_keys.dart';

/// Concrete [AuthRepository] orchestrating remote, local and biometric sources.
/// Never throws: every path returns a [Result].
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    required BiometricAuthenticator biometric,
    required PresidingElectionContextStore presidingElectionContextStore,
    required EnvironmentConfig environmentConfig,
  }) : _remote = remote,
       _local = local,
       _biometric = biometric,
       _presidingElectionContextStore = presidingElectionContextStore,
       _environmentConfig = environmentConfig;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final BiometricAuthenticator _biometric;
  final PresidingElectionContextStore _presidingElectionContextStore;
  final EnvironmentConfig _environmentConfig;

  @override
  Future<Result<AuthUser>> login(LoginCredentials credentials) async {
    try {
      final AuthResponseModel response = await _remote.login(credentials);
      final AuthTokens tokens = AuthTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        expiresAt: DateTime.now().add(
          Duration(seconds: response.expiresInSeconds),
        ),
      );
      await _local.saveSession(user: response.user, tokens: tokens);
      await _persistPresidingElectionContext(
        response.user,
        fallbackElectionId: credentials.electionId,
      );
      return Result<AuthUser>.success(UserMapper.toEntity(response.user));
    } catch (e, s) {
      AppLogger.w('Login failed', error: e, stackTrace: s);
      return Result<AuthUser>.failure(ErrorMapper.map(e, s));
    }
  }

  @override
  Future<Result<void>> logout() async {
    // Local-only logout — remote revoke is unreliable on this network and must
    // never block or crash the UI after the user confirms sign-out.
    try {
      await _local.clearSession();
      await _presidingElectionContextStore.clear();
      return const Result<void>.success(null);
    } catch (e, s) {
      return Result<void>.failure(ErrorMapper.map(e, s));
    }
  }

  @override
  Future<Result<AuthUser>> currentUser() async {
    try {
      final UserModel? user = await _local.readUser();
      if (user == null) {
        return const Result<AuthUser>.failure(UnauthorizedFailure());
      }
      await _persistPresidingElectionContext(
        user,
        fallbackElectionId: _environmentConfig.electionId,
      );
      return Result<AuthUser>.success(UserMapper.toEntity(user));
    } catch (e, s) {
      return Result<AuthUser>.failure(ErrorMapper.map(e, s));
    }
  }

  @override
  Future<bool> hasValidSession() => _local.hasValidSession();

  @override
  Future<void> establishLocalSession(AuthUser user) async {
    final AuthTokens tokens = AuthTokens(
      accessToken: 'local-session',
      refreshToken: 'local-session',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
    final UserModel model = UserMapper.fromEntity(user);
    await _local.saveSession(user: model, tokens: tokens);
    await _persistPresidingElectionContext(
      model,
      fallbackElectionId: _environmentConfig.electionId,
    );
  }

  @override
  Future<Result<AuthUser>> loginWithBiometrics() async {
    try {
      if (!await _local.hasValidSession()) {
        return const Result<AuthUser>.failure(UnauthorizedFailure());
      }
      final bool ok = await _biometric.authenticate(
        localizedReason: LocaleKeys.authBiometricReason.tr(),
      );
      if (!ok) {
        return const Result<AuthUser>.failure(
          SecurityFailure(localizationKey: LocaleKeys.authInvalidCredentials),
        );
      }
      return currentUser();
    } catch (e, s) {
      return Result<AuthUser>.failure(ErrorMapper.map(e, s));
    }
  }

  @override
  Future<Result<void>> setBiometricEnabled({required bool enabled}) async {
    try {
      await _local.setBiometricEnabled(enabled: enabled);
      return const Result<void>.success(null);
    } catch (e, s) {
      return Result<void>.failure(ErrorMapper.map(e, s));
    }
  }

  @override
  Future<bool> isBiometricEnabled() => _local.isBiometricEnabled();

  Future<void> _persistPresidingElectionContext(
    UserModel user, {
    int? fallbackElectionId,
  }) async {
    final PresidingElectionContext? context =
        PresidingElectionContextFactory.fromUserModel(
          user,
          fallbackElectionId:
              fallbackElectionId ?? _environmentConfig.electionId,
        ) ??
        PresidingElectionContextFactory.fromDevEnv(_environmentConfig);
    if (context == null) return;
    await _presidingElectionContextStore.save(context);
  }
}
