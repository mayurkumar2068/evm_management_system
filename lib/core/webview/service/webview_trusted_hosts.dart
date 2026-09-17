import 'webview_dev_host.dart';

/// L2 VAPT F-16: navigation-level allowlist for the WebView.
///
/// Government domains only. Dashboard "portal" cards are backend-driven
/// (see `DashboardCardMapper`), so this deliberately allowlists by domain
/// *suffix* rather than an exact host list — a new backend-added portal on
/// an existing government domain keeps working without an app release,
/// while anything off these suffixes (e.g. the personal GitHub Pages survey
/// host from F-11) is refused.
///
/// This is a same-origin gate on which pages the WebView will ever load —
/// it is not a per-request MIME/file-type filter. Closing F-09 (the native
/// file chooser itself) needs a `flutter_inappwebview` version that exposes
/// an `onShowFileChooser` Dart hook; the installed version doesn't. See
/// docs/L2_VAPT_IMPLEMENTATION.md (F-09) for details.
abstract final class WebViewTrustedHosts {
  static const Set<String> _trustedSuffixes = <String>{'mp.gov.in', 'eci.gov.in'};

  static bool isTrusted(Uri? uri, {required bool allowCleartextLocalhost}) {
    if (uri == null) return false;
    final String scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      // Non-web schemes are governed by WebViewNavigationPolicy /
      // ExternalNavigationUrls, not this host allowlist.
      return true;
    }
    final String host = uri.host.toLowerCase();
    if (host.isEmpty) return false;
    if (_matchesTrustedSuffix(host)) return true;
    return allowCleartextLocalhost && WebViewDevHost.matches(host);
  }

  static bool _matchesTrustedSuffix(String host) {
    for (final String suffix in _trustedSuffixes) {
      if (host == suffix || host.endsWith('.$suffix')) return true;
    }
    return false;
  }
}
