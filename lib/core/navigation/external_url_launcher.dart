import 'package:url_launcher/url_launcher.dart';

/// Launches URLs in an external app (Maps, browser, mail, etc.).
class ExternalUrlLauncher {
  const ExternalUrlLauncher();

  /// Tries to open [uri] outside the WebView / Flutter shell.
  Future<bool> launch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      // iOS may return false without LSApplicationQueriesSchemes — try anyway.
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }

  /// Returns true when any candidate URL opens successfully.
  Future<bool> launchFirst(Iterable<Uri> uris) async {
    for (final Uri uri in uris) {
      if (await launch(uri)) {
        return true;
      }
    }
    return false;
  }
}
