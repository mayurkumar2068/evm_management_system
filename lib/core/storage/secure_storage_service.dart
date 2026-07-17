import 'package:evm_management_system/core/error/app_exception.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Hardware-backed secure key/value storage.
///
/// The ONLY place tokens and sensitive material may live on-device. Backed by
/// the iOS Keychain and Android EncryptedSharedPreferences/Keystore. Plain
/// `SharedPreferences` is never used for secrets.
class SecureStorageService {
  SecureStorageService([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e, s) {
      throw SecureStorageException(
        'write($key) failed',
        cause: e,
        stackTrace: s,
      );
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e, s) {
      throw SecureStorageException(
        'read($key) failed',
        cause: e,
        stackTrace: s,
      );
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e, s) {
      throw SecureStorageException(
        'delete($key) failed',
        cause: e,
        stackTrace: s,
      );
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e, s) {
      throw SecureStorageException('deleteAll failed', cause: e, stackTrace: s);
    }
  }
}

/// Stable key namespace for [SecureStorageService] entries.
abstract final class SecureStorageKeys {
  static const String accessToken = 'evm.access_token';
  static const String refreshToken = 'evm.refresh_token';
  static const String tokenExpiry = 'evm.token_expiry';
  static const String userSession = 'evm.user_session';
  static const String biometricEnabled = 'evm.biometric_enabled';
  static const String encryptionKey = 'evm.db_encryption_key';
  static const String onboardingSeen = 'evm.onboarding_seen';
  static const String presidingElectionContext =
      'evm.presiding_election_context';
}
