import 'dart:convert';

import 'package:evm_management_system/core/security/token_vault.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/features/auth/data/models/user_model.dart';

/// Contract for persisting auth state on-device.
abstract interface class AuthLocalDataSource {
  Future<void> saveSession({
    required UserModel user,
    required AuthTokens tokens,
  });
  Future<UserModel?> readUser();
  Future<bool> hasValidSession();
  Future<void> clearSession();
  Future<void> setBiometricEnabled({required bool enabled});
  Future<bool> isBiometricEnabled();
}

/// Secure-storage backed implementation.
///
/// Tokens and the user session live ONLY in the encrypted keystore via
/// [TokenVault] / [SecureStorageService] — never in SharedPreferences.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl({
    required TokenVault tokenVault,
    required SecureStorageService secureStorage,
  }) : _tokenVault = tokenVault,
       _secureStorage = secureStorage;

  final TokenVault _tokenVault;
  final SecureStorageService _secureStorage;

  @override
  Future<void> saveSession({
    required UserModel user,
    required AuthTokens tokens,
  }) async {
    await _tokenVault.save(tokens);
    await _secureStorage.write(
      SecureStorageKeys.userSession,
      jsonEncode(user.toJson()),
    );
  }

  @override
  Future<UserModel?> readUser() async {
    final String? raw = await _secureStorage.read(
      SecureStorageKeys.userSession,
    );
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<bool> hasValidSession() async {
    final AuthTokens? tokens = await _tokenVault.read();
    return tokens != null && !tokens.isExpired;
  }

  @override
  Future<void> clearSession() async {
    await _tokenVault.clear();
    await _secureStorage.delete(SecureStorageKeys.userSession);
  }

  @override
  Future<void> setBiometricEnabled({required bool enabled}) => _secureStorage
      .write(SecureStorageKeys.biometricEnabled, enabled.toString());

  @override
  Future<bool> isBiometricEnabled() async =>
      (await _secureStorage.read(SecureStorageKeys.biometricEnabled)) == 'true';
}
