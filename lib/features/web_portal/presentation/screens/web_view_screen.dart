import 'package:evm_management_system/core/webview/config/webview_config.dart';
import 'package:evm_management_system/core/webview/widget/app_webview.dart';
import 'package:flutter/material.dart';

/// Navigation payload for [WebViewScreen]. Passed via GoRouter `extra`.
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
      ),
    );
  }
}
