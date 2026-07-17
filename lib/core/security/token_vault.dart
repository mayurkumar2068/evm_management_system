import 'dart:convert';

import 'package:evm_management_system/core/storage/secure_storage_service.dart';

/// Immutable bundle of authentication tokens.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// True when the token expires within [window] and should be refreshed early.
  bool willExpireWithin(Duration window) =>
      DateTime.now().add(window).isAfter(expiresAt);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.toIso8601String(),
  };
}

/// Single owner of authentication tokens, persisted only in secure storage.
///
/// Tokens are encrypted at rest by the platform keystore via
/// [SecureStorageService]; they are never written to SharedPreferences or the
/// app database.
class TokenVault {
  TokenVault(this._storage);

  final SecureStorageService _storage;
  AuthTokens? _cached;

  Future<void> save(AuthTokens tokens) async {
    _cached = tokens;
    await _storage.write(
      SecureStorageKeys.accessToken,
      jsonEncode(tokens.toJson()),
    );
  }

  Future<AuthTokens?> read() async {
    if (_cached != null) return _cached;
    final String? raw = await _storage.read(SecureStorageKeys.accessToken);
    if (raw == null) return null;
    _cached = AuthTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return _cached;
  }

  Future<String?> get accessToken async => (await read())?.accessToken;

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(SecureStorageKeys.accessToken);
    await _storage.delete(SecureStorageKeys.refreshToken);
    await _storage.delete(SecureStorageKeys.userSession);
  }
}
