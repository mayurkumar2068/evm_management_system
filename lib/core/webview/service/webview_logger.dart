import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Structured logger for WebView lifecycle, navigation, cookie, and SSL events.
class WebViewLogger {
  /// Creates a WebView logger.
  const WebViewLogger();

  /// Logs the initial request that bootstraps the WebView.
  void logInitialRequest({
    required URLRequest request,
    required Map<String, String> headers,
  }) {
    AppLogger.i(
      '[WebView] initial request '
      'url=${request.url} method=${request.method ?? 'GET'} '
      'headers=${_sanitizeHeaders(headers)}',
    );
  }

  /// Logs a navigation policy decision.
  void logNavigationDecision({
    required Uri uri,
    required String reason,
    required String action,
    bool? isMainFrame,
    bool? isRedirect,
    String? method,
  }) {
    AppLogger.i(
      '[WebView] navigation decision url=$uri action=$action reason=$reason '
      'mainFrame=${isMainFrame ?? true} redirect=${isRedirect ?? false} '
      'method=${method ?? 'GET'}',
    );
  }

  /// Logs that a new page started loading.
  void logLoadStart(Uri? uri) {
    AppLogger.i('[WebView] load start url=${uri ?? 'unknown'}');
  }

  /// Logs that a page finished loading.
  void logLoadStop(Uri? uri) {
    AppLogger.i('[WebView] load stop url=${uri ?? 'unknown'}');
  }

  /// Logs incremental loading progress.
  void logProgress({required int progress, Uri? uri}) {
    AppLogger.d('[WebView] progress=$progress url=${uri ?? 'unknown'}');
  }

  /// Logs a redirect observation.
  void logRedirect({
    required Uri? from,
    required Uri? to,
    required String source,
  }) {
    AppLogger.i(
      '[WebView] redirect source=$source from=${from ?? 'unknown'} '
      'to=${to ?? 'unknown'}',
    );
  }

  /// Logs cookies for a given origin without exposing secret values.
  void logCookies({
    required Uri uri,
    required List<Cookie> cookies,
    required String source,
  }) {
    final List<String> serialized = cookies.map(_sanitizeCookie).toList();
    AppLogger.d(
      '[WebView] cookies source=$source url=$uri cookies=$serialized',
    );
  }

  /// Logs that cookie writes completed for an origin.
  void logCookieBatchWrite({
    required Uri uri,
    required List<String> names,
    required bool secure,
  }) {
    AppLogger.d(
      '[WebView] cookie sync url=$uri names=${names.join(', ')} secure=$secure',
    );
  }

  /// Logs that a cookie write completed.
  void logCookieWrite({
    required Uri uri,
    required String name,
    required bool secure,
    required bool httpOnly,
    required HTTPCookieSameSitePolicy sameSite,
  }) {
    AppLogger.d(
      '[WebView] cookie sync url=$uri name=$name secure=$secure '
      'httpOnly=$httpOnly sameSite=$sameSite',
    );
  }

  /// Logs an SSL trust decision.
  void logSslDecision({
    required String host,
    required String action,
    required String reason,
    Object? sslError,
  }) {
    AppLogger.i(
      '[WebView] ssl decision host=$host action=$action reason=$reason '
      'sslError=${sslError ?? 'none'}',
    );
  }

  /// Logs an HTTP response for the main document.
  void logHttpResponse({
    required Uri? uri,
    required int? statusCode,
    required String? mimeType,
    required Map<String, String>? headers,
  }) {
    AppLogger.i(
      '[WebView] response url=${uri ?? 'unknown'} status=${statusCode ?? 'n/a'} '
      'mime=${mimeType ?? 'unknown'} headers=${_sanitizeHeaders(headers)}',
    );
  }

  /// Logs a WebView error event.
  void logError({
    required Uri? uri,
    required String category,
    required String description,
    bool ignored = false,
  }) {
    final String prefix = ignored
        ? '[WebView] ignored error'
        : '[WebView] error';
    AppLogger.w(
      '$prefix category=$category url=${uri ?? 'unknown'} '
      'description=$description',
    );
  }

  /// Logs arbitrary console-style diagnostics from the page.
  void logConsole({required String level, required String message}) {
    AppLogger.d('[WebView] console level=$level message=$message');
  }

  /// Returns a copy of headers with secret values redacted.
  Map<String, String> _sanitizeHeaders(Map<String, String>? headers) {
    if (headers == null) {
      return <String, String>{};
    }

    final Map<String, String> sanitized = <String, String>{};
    headers.forEach((String key, String value) {
      final String lowerKey = key.toLowerCase();
      if (lowerKey == 'authorization' ||
          lowerKey == 'cookie' ||
          lowerKey == 'set-cookie') {
        sanitized[key] = '<redacted>';
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  /// Serializes a cookie without exposing the raw value.
  String _sanitizeCookie(Cookie cookie) {
    return '{name: ${cookie.name}, domain: ${cookie.domain}, '
        'path: ${cookie.path}, secure: ${cookie.isSecure}, '
        'httpOnly: ${cookie.isHttpOnly}, sameSite: ${cookie.sameSite}}';
  }
}
