import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Prewarms the platform WebView so the first real page launches instantly.
///
/// A hidden [HeadlessInAppWebView] boots the renderer process, JS engine and
/// network/cookie stack on app startup. Calling [warm] is idempotent and safe
/// to invoke from app bootstrap. The instance is kept alive for the app's life
/// (NOT disposed) so the engine stays warm; [shutdown] is available for tests.
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
          // Warm the same caches/storage the real views will reuse.
          cacheEnabled: true,
          clearCache: false,
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
        debugPrint('[WebViewWarmer] warm failed: $e');
      }
    } finally {
      _warming = false;
    }
  }

  Future<void> shutdown() async {
    try {
      await _headless?.dispose();
    } catch (_) {
      // ignore
    }
    _headless = null;
    _warmed = false;
  }
}
