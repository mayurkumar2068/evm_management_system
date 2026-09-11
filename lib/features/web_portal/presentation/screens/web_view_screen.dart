import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/webview/config/webview_config.dart';
import 'package:evm_management_system/core/webview/widget/app_webview.dart';
import 'package:flutter/material.dart';

class WebViewArgs {
  const WebViewArgs({
    required this.title,
    required this.url,
    this.headerPolicy = WebViewHeaderPolicy.sessionAndCustom,
    this.cachePolicy = WebViewCachePolicy.normal,
    this.syncCookies = true,
    this.injectSessionContext = true,
    this.enableJsBridge = true,
    this.bootstrapSession = true,
    this.showLogoutButton = false,
    this.extraHeaders = const <String, String>{},
  });

  final String title;
  final String url;
  final WebViewHeaderPolicy headerPolicy;
  final WebViewCachePolicy cachePolicy;
  final bool syncCookies;
  final bool injectSessionContext;
  final bool enableJsBridge;
  final bool bootstrapSession;

  final bool showLogoutButton;
  final Map<String, String> extraHeaders;
}

class WebViewScreen extends StatelessWidget {
  const WebViewScreen({required this.args, super.key});

  final WebViewArgs args;

  @override
  Widget build(BuildContext context) {
    return AppWebView(
      config: WebViewConfig(
        url: args.url,
        title: args.title,
        headerPolicy: args.headerPolicy,
        cachePolicy: args.cachePolicy,
        extraHeaders: args.extraHeaders,
        syncCookies: args.syncCookies,
        injectSessionContext: args.injectSessionContext,
        enableJsBridge: args.enableJsBridge,
        bootstrapSession: args.bootstrapSession,
        showLogoutButton: args.showLogoutButton,
        // Cleartext / LAN WebView only in non-prod (L1 VULN-001 / VULN-019).
        allowCleartextLocalhost: !AppServices.config.isProduction,
      ),
    );
  }
}
