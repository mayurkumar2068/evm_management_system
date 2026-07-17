/// Canonical URL paths for every route (deep-link ready). No path string is
/// ever hardcoded at call sites — navigation uses [RouteNames] instead.
abstract final class RoutePaths {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  // Shell (authenticated) routes.
  static const String dashboard = '/dashboard';
  static const String viewAll = '/viewAll';
  static const String masterStockRegister = '/stock-register';
  static const String controlUnit = '/control-units';
  static const String ballotUnit = '/ballot-units';
  static const String deviceDetail = '/device-detail';
  static const String scanner = '/scanner';
  static const String reports = '/reports';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String auditTrail = '/audit-trail';
  static const String syncManagement = '/sync';
  static const String search = '/search';
  static const String help = '/help';
  static const String about = '/about';
}
