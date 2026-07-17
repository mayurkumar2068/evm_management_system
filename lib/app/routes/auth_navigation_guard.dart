import 'package:evm_management_system/app/router/app_destinations.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/auth/presentation/states/auth_state.dart';
import 'package:get/get.dart' hide Trans;

/// Re-evaluates auth/onboarding guards whenever auth state changes.
abstract final class AuthNavigationGuard {
  static void apply() {
    final String? redirect = _computeRedirect(
      AppServices.auth.authState.value,
      Get.currentRoute,
      AppServices.onboarding.seen,
    );
    if (redirect == null) return;
    final String current = Get.currentRoute;
    if (current == redirect) return;
    Get.offAllNamed<dynamic>(redirect);
  }

  /// Auth + onboarding + role guard (mirrors former GoRouter redirect).
  static String? _computeRedirect(
    AuthState auth,
    String location,
    bool onboardingSeen,
  ) {
    final bool atSplash = location == AppRoute.splash.path;
    final bool atLogin = location == AppRoute.login.path;
    final bool atOnboarding = location == AppRoute.onboarding.path;

    switch (auth.status) {
      case AuthStatus.unknown:
        return atSplash ? null : AppRoute.splash.path;
      case AuthStatus.authenticating:
      case AuthStatus.unauthenticated:
        if (!onboardingSeen) {
          return atOnboarding ? null : AppRoute.onboarding.path;
        }
        return atLogin ? null : AppRoute.login.path;
      case AuthStatus.authenticated:
        if (atSplash || atLogin || atOnboarding) {
          return AppRoute.dashboard.path;
        }
        final AppDestination? dest = AppDestinations.byPath(location);
        final role = auth.user?.role;
        if (dest != null && role != null && !dest.isAllowedFor(role)) {
          return AppRoute.dashboard.path;
        }
        return null;
    }
  }
}
