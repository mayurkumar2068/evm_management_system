import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/legal/privacy_urls.dart';
import 'package:evm_management_system/core/navigation/external_url_launcher.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

abstract final class PrivacyPolicy {
  static const String defaultUrl = PrivacyUrls.statement;

  static Uri resolveUri() {
    String url = defaultUrl;
    if (Get.isRegistered<EnvironmentConfig>()) {
      final String fromEnv = AppServices.config.privacyPolicyUrl.trim();
      if (fromEnv.isNotEmpty) {
        url = fromEnv;
      }
    }
    return Uri.parse(url);
  }

  static Future<void> open(
    BuildContext context, {
    ExternalUrlLauncher launcher = const ExternalUrlLauncher(),
  }) async {
    final bool ok = await launcher.launch(resolveUri());
    if (!ok && context.mounted) {
      AppSnackbar.error(context, LocaleKeys.legalPrivacyPolicyOpenFailed.tr());
    }
  }
}
