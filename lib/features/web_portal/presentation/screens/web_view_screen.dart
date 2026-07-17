import 'package:evm_management_system/core/webview/config/webview_config.dart';
import 'package:evm_management_system/core/webview/widget/app_webview.dart';
import 'package:flutter/material.dart';

/// Navigation payload for [WebViewScreen]. Passed via GoRouter `extra`.
class WebViewArgs {
  const WebViewArgs({required this.title, required this.url});
  final String title;
  final String url;
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
        headerPolicy: WebViewHeaderPolicy.sessionAndCustom,
      ),
    );
  }
}
