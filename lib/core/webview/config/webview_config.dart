import 'package:flutter/widgets.dart';

import '../models/web_view_metrics.dart';

enum WebViewHttpMethod { get, post }

enum WebViewCachePolicy { normal, noCache, cacheFirst }

enum WebViewHeaderPolicy { none, customOnly, sessionAndCustom }

enum WebViewServerTrustPolicy { compatibility, strict }

class WebBridgeMessage {
  const WebBridgeMessage(this.action, this.payload);
  final String action;
  final Map<String, dynamic> payload;
}

class WebViewConfig {
  const WebViewConfig({
    required this.url,
    this.title = '',
    this.method = WebViewHttpMethod.get,
    this.postBody,
    this.extraHeaders = const <String, String>{},
    this.headerPolicy = WebViewHeaderPolicy.customOnly,
    this.showHeader = true,
    this.enableJsBridge = true,
    this.enablePullToRefresh = true,
    this.injectSessionContext = true,
    this.syncCookies = true,
    this.cachePolicy = WebViewCachePolicy.normal,
    this.allowCleartextLocalhost = true,
    this.serverTrustPolicy = WebViewServerTrustPolicy.compatibility,
    this.pinnedCertificateSha256 = const <String>{},
    this.onPageStarted,
    this.onPageFinished,
    this.onError,
    this.onMetrics,
    this.onBridgeMessage,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String url;
  final String title;
  final WebViewHttpMethod method;
  final String? postBody;

  /// Per-call headers merged on top of the auto-injected session headers.
  final Map<String, String> extraHeaders;
  final WebViewHeaderPolicy headerPolicy;

  final bool showHeader;
  final bool enableJsBridge;
  final bool enablePullToRefresh;
  final bool injectSessionContext;
  final bool syncCookies;
  final WebViewCachePolicy cachePolicy;

  /// Allow http://localhost / 10.0.2.2 (dev micro-apps) over cleartext.
  final bool allowCleartextLocalhost;
  final WebViewServerTrustPolicy serverTrustPolicy;
  final Set<String> pinnedCertificateSha256;

  final VoidCallback? onPageStarted;
  final ValueChanged<String>? onPageFinished; // final URL
  final ValueChanged<String>? onError; // message
  final ValueChanged<WebViewMetrics>? onMetrics;
  final ValueChanged<WebBridgeMessage>? onBridgeMessage;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(BuildContext context, VoidCallback retry)? errorBuilder;

  /// Returns a copy with selected fields overridden.
  WebViewConfig copyWith({
    String? url,
    String? title,
    Map<String, String>? extraHeaders,
    WebViewHeaderPolicy? headerPolicy,
    WebViewServerTrustPolicy? serverTrustPolicy,
    Set<String>? pinnedCertificateSha256,
  }) {
    return WebViewConfig(
      url: url ?? this.url,
      title: title ?? this.title,
      method: method,
      postBody: postBody,
      extraHeaders: extraHeaders ?? this.extraHeaders,
      headerPolicy: headerPolicy ?? this.headerPolicy,
      showHeader: showHeader,
      enableJsBridge: enableJsBridge,
      enablePullToRefresh: enablePullToRefresh,
      injectSessionContext: injectSessionContext,
      syncCookies: syncCookies,
      cachePolicy: cachePolicy,
      allowCleartextLocalhost: allowCleartextLocalhost,
      serverTrustPolicy: serverTrustPolicy ?? this.serverTrustPolicy,
      pinnedCertificateSha256:
          pinnedCertificateSha256 ?? this.pinnedCertificateSha256,
      onPageStarted: onPageStarted,
      onPageFinished: onPageFinished,
      onError: onError,
      onMetrics: onMetrics,
      onBridgeMessage: onBridgeMessage,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
    );
  }
}
