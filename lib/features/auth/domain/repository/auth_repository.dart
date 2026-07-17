import 'package:evm_management_system/core/error/result.dart';
import 'package:evm_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:evm_management_system/features/auth/domain/entities/login_credentials.dart';

/// Domain contract for authentication. The data layer implements it; use cases
/// and controllers depend only on this abstraction (Dependency Inversion).
abstract interface class AuthRepository {
  /// Authenticates with [credentials] and persists the session securely.
  Future<Result<AuthUser>> login(LoginCredentials credentials);

  /// Clears the session locally and best-effort notifies the server.
  Future<Result<void>> logout();

  /// Returns the cached authenticated user, or a failure if none/expired.
  Future<Result<AuthUser>> currentUser();

  /// Whether a valid, non-expired session exists on device.
  Future<bool> hasValidSession();

  /// Persists a locally-minted session for [user] so it survives app restarts.
  ///
  /// Used by the DEV preview bypass (no backend) to behave like a real login;
  /// not used by UAT/PROD which receive tokens from the server.
  Future<void> establishLocalSession(AuthUser user);

  /// Re-authenticates via device biometrics against the stored session.
  Future<Result<AuthUser>> loginWithBiometrics();

  /// Persists the user's biometric-login preference.
  Future<Result<void>> setBiometricEnabled({required bool enabled});

  /// Whether biometric login is enabled by the user.
  Future<bool> isBiometricEnabled();
}
