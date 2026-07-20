/// Holds the active locale code for non-widget consumers (e.g. network
/// interceptors) that cannot access an easy_localization [BuildContext].
abstract final class AppLocaleHolder {
  static String code = 'hi';
}
