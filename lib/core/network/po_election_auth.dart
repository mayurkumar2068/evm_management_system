import 'package:evm_management_system/core/di/app_services.dart';
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
    return AppServices.tokenVault.accessToken;
  }
}
