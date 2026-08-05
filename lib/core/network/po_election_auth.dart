import 'dart:convert';

import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/features/service_auth/presentation/controllers/service_auth_controller.dart';
import 'package:get/get.dart';

/// Resolves the PO Election API bearer token after presiding-officer login.
abstract final class PoElectionAuth {
  /// Returns the active access token from session memory or secure vault.
  static Future<String?> accessToken() async {
    if (Get.isRegistered<ServiceAuthController>()) {
      final String? sessionToken = AppServices.serviceAuth.session.value?.token;
      if (sessionToken != null && sessionToken.isNotEmpty) {
        return sessionToken;
      }
    }

    final String? persisted = await _tokenFromPersistedServiceSession();
    if (persisted != null && persisted.isNotEmpty) {
      return persisted;
    }

    return AppServices.tokenVault.accessToken;
  }

  static Future<String?> _tokenFromPersistedServiceSession() async {
    try {
      final String? raw = await AppServices.secureStorage.read(
            SecureStorageKeys.serviceSession,
          ) ??
          await AppServices.secureStorage.read(SecureStorageKeys.userSession);
      if (raw == null || raw.isEmpty) return null;
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      if (json['token'] is! String) return null;
      final ServiceSession session = ServiceSession.fromJson(json);
      return session.token;
    } catch (_) {
      return null;
    }
  }
}
