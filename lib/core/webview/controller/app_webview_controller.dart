import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../javascript/app_bridge_js.dart';
import '../models/web_view_metrics.dart';

class AppWebViewController {
  AppWebViewController(this.raw);

  final InAppWebViewController raw;

  Future<void> reload() => raw.reload();

  Future<bool> canGoBack() => raw.canGoBack();

  Future<void> goBack() => raw.goBack();

  Future<void> loadUrl({required URLRequest request}) =>
      raw.loadUrl(urlRequest: request);

  Future<dynamic> runJs(String source) =>
      raw.evaluateJavascript(source: source);

  Future<void> setLanguage(String lang) =>
      raw.evaluateJavascript(source: applyLanguageJs(lang));

  Future<void> setTheme(String theme) =>
      raw.evaluateJavascript(source: applyThemeJs(theme));

  Future<WebViewMetrics?> collectMetrics() async {
    final dynamic result = await raw.evaluateJavascript(
      source: collectMetricsJs,
    );
    if (result is Map) return WebViewMetrics.fromJson(result);
    return null;
  }
}
