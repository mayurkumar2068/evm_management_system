import 'package:evm_management_system/core/navigation/external_navigation_urls.dart';

/// What the engine should do with a navigation target.
enum WebNavDecision {
  /// Load inside the WebView (normal in-app navigation).
  allow,

  /// Hand off to the OS (mailto:, tel:, maps:, upi:, intent:, external http
  /// that should leave the app, downloadable docs, etc.).
  external,

  /// Silently block.
  block,
}

/// Structured decision payload for a navigation target.
class WebNavigationDecision {
  /// Creates a structured navigation decision.
  const WebNavigationDecision({required this.action, required this.reason});

  final WebNavDecision action;
  final String reason;
}

/// Centralized URL interception. Every screen routes through the same rules so
/// behavior is consistent app-wide.
class WebViewNavigationPolicy {
  /// Creates a centralized navigation policy.
  const WebViewNavigationPolicy();

  static const Set<String> _dangerousSchemes = <String>{
    'javascript',
    'file',
    'content',
    'chrome',
    'about-srcdoc',
  };

  /// File extensions that should be handed to the OS / download pipeline.
  static const Set<String> _downloadExt = <String>{
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'csv',
    'zip',
    'apk',
    'ppt',
    'pptx',
  };

  /// Returns the decision for a target URL.
  WebNavigationDecision decide(Uri uri) {
    final String scheme = uri.scheme.toLowerCase();

    if (scheme == 'about' || scheme == 'data' || scheme == 'blob') {
      return const WebNavigationDecision(
        action: WebNavDecision.allow,
        reason: 'embedded_scheme',
      );
    }
    if (ExternalNavigationUrls.isExternalScheme(scheme)) {
      return const WebNavigationDecision(
        action: WebNavDecision.external,
        reason: 'supported_external_scheme',
      );
    }
    if (_dangerousSchemes.contains(scheme) || scheme.isEmpty) {
      return const WebNavigationDecision(
        action: WebNavDecision.block,
        reason: 'dangerous_or_invalid_scheme',
      );
    }
    if (scheme == 'http' || scheme == 'https') {
      if (ExternalNavigationUrls.isExternalMapWebUrl(uri)) {
        return const WebNavigationDecision(
          action: WebNavDecision.external,
          reason: 'external_map_url',
        );
      }
      final String path = uri.path.toLowerCase();
      final int dot = path.lastIndexOf('.');
      if (dot != -1) {
        final String ext = path.substring(dot + 1);
        if (_downloadExt.contains(ext)) {
          return const WebNavigationDecision(
            action: WebNavDecision.external,
            reason: 'download_extension',
          );
        }
      }
      return const WebNavigationDecision(
        action: WebNavDecision.allow,
        reason: 'web_navigation',
      );
    }

    return const WebNavigationDecision(
      action: WebNavDecision.block,
      reason: 'unsupported_custom_scheme',
    );
  }
}
