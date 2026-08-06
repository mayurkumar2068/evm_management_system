import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Clears disposable runtime caches on every cold start.
///
/// Does **not** touch auth tokens, onboarding, settings, or PO offline DB.
abstract final class AppStartupCache {
  static Future<void> clearOnLaunch() async {
    try {
      imageCache.clear();
      imageCache.clearLiveImages();
    } catch (e) {
      AppLogger.w('Startup image cache clear failed: $e');
    }

    try {
      await InAppWebViewController.clearAllCache();
    } catch (e) {
      AppLogger.w('Startup WebView cache clear failed: $e');
    }

    AppLogger.i('Startup caches cleared');
  }
}
