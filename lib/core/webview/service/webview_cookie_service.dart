import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../models/web_session_context.dart';
import 'webview_logger.dart';

/// Central cookie manager: mirrors the session into first-party cookies for the
/// page's origin so server-rendered pages and same-site XHR are authenticated
/// without the token ever appearing in the URL.
///
/// - `app_token`  → Secure + HttpOnly (only over https)
/// - `app_lang`   → readable by JS (language sync)
/// - `app_theme`  → readable by JS (theme sync)
/// - `app_device` → readable by JS
class WebViewCookieService {
  /// Creates the cookie synchronization service.
  WebViewCookieService({CookieManager? manager, WebViewLogger? logger})
    : _cookies = manager ?? CookieManager.instance(),
      _logger = logger ?? const WebViewLogger();

  final CookieManager _cookies;
  final WebViewLogger _logger;

  /// Mirrors the current app session into the WebView cookie jar.
  Future<void> sync(WebUri url, WebSessionContext ctx) async {
    final bool secure = url.scheme == 'https';
    final Uri uri = Uri.tryParse(url.toString()) ?? Uri();
    final int persistentExpiryMs = DateTime.now()
        .add(const Duration(days: 30))
        .millisecondsSinceEpoch;

    final List<String> written = <String>[];

    Future<void> set(
      String name,
      String value, {
      bool httpOnly = false,
      bool sessionOnly = false,
    }) async {
      if (value.isEmpty) return;

      const HTTPCookieSameSitePolicy sameSite = HTTPCookieSameSitePolicy.LAX;
      await _cookies.setCookie(
        url: url,
        name: name,
        value: value,
        path: '/',
        isSecure: secure,
        isHttpOnly: httpOnly && secure,
        sameSite: sameSite,
        expiresDate: sessionOnly ? null : persistentExpiryMs,
      );
      written.add(name);
    }

    if (ctx.accessToken != null) {
      await set(
        'app_token',
        ctx.accessToken!,
        httpOnly: true,
        sessionOnly: true,
      );
    }
    await set('app_lang', ctx.language);
    await set('app_theme', ctx.themeName);
    await set('app_device', ctx.deviceId);
    final String? districtId = ctx.districtId;
    if (districtId != null) {
      await set('app_district_id', districtId);
    }
    final String? distName = ctx.distName;
    if (distName != null) {
      await set('app_dist_name', distName);
    }
    final String? bodyId = ctx.bodyId;
    if (bodyId != null) {
      await set('app_body_id', bodyId);
    }
    final String? bodyName = ctx.bodyName;
    if (bodyName != null) {
      await set('app_body_name', bodyName);
    }
    final String? urbanRural = ctx.urbanRural;
    if (urbanRural != null) {
      await set('app_urban_rural', urbanRural);
    }

    if (written.isNotEmpty) {
      _logger.logCookieBatchWrite(uri: uri, names: written, secure: secure);
    }

    await logCookiesFor(url, source: 'post_sync');
  }

  /// Remove the session cookies for an origin (e.g. on logout).
  Future<void> clearFor(WebUri url) async {
    for (final String name in const <String>[
      'app_token',
      'app_lang',
      'app_theme',
      'app_device',
    ]) {
      await _cookies.deleteCookie(url: url, name: name, path: '/');
    }
  }

  /// Reads and logs cookies for the supplied origin.
  Future<void> logCookiesFor(WebUri url, {required String source}) async {
    final List<Cookie> cookies = await _cookies.getCookies(url: url);
    final Uri uri = Uri.tryParse(url.toString()) ?? Uri();
    _logger.logCookies(uri: uri, cookies: cookies, source: source);
  }
}
