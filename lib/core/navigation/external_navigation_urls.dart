/// Shared rules for URLs that must leave the embedded WebView.
abstract final class ExternalNavigationUrls {
  static const Set<String> externalSchemes = <String>{
    'mailto',
    'tel',
    'sms',
    'intent',
    'whatsapp',
    'geo',
    'maps',
    'comgooglemaps',
    'googlemaps',
    'google.navigation',
  };

  static bool isExternalScheme(String scheme) =>
      externalSchemes.contains(scheme.toLowerCase());

  static bool isExternalMapWebUrl(Uri uri) {
    final String host = uri.host.toLowerCase();
    if (host.contains('google.') &&
        (uri.path.contains('/maps') || uri.query.contains('maps'))) {
      return true;
    }
    if (host == 'maps.apple.com') {
      return true;
    }
    return false;
  }
}
