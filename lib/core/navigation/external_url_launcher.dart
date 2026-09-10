import 'package:url_launcher/url_launcher.dart';

class ExternalUrlLauncher {
  const ExternalUrlLauncher();

  Future<bool> launch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }

  Future<bool> launchFirst(Iterable<Uri> uris) async {
    for (final Uri uri in uris) {
      if (await launch(uri)) {
        return true;
      }
    }
    return false;
  }
}
