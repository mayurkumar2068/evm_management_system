import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewWarmer {
  HeadlessInAppWebView? _headless;
  bool _warming = false;
  bool _warmed = false;

  bool get isWarm => _warmed;

  Future<void> warm() async {
    if (_warmed || _warming) return;
    _warming = true;
    try {
      _headless = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('about:blank')),
        initialSettings: InAppWebViewSettings(
          transparentBackground: true,
          cacheEnabled: false,
          cacheMode: CacheMode.LOAD_NO_CACHE,
          clearCache: true,
        ),
        onWebViewCreated: (InAppWebViewController _) {},
        onLoadStop: (InAppWebViewController _, WebUri? __) {
          _warmed = true;
        },
      );
      await _headless!.run();
      _warmed = true;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.d('[WebViewWarmer] warm failed: $e');
      }
    } finally {
      _warming = false;
    }
  }

  Future<void> shutdown() async {
    try {
      await _headless?.dispose();
    } catch (_) {}
    _headless = null;
    _warmed = false;
  }
}
