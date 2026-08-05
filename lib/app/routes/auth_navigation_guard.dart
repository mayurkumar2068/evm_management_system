import 'package:evm_management_system/app/router/app_destinations.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/constants/feature_flags.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/auth/presentation/states/auth_state.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart' hide Trans;

/// Re-evaluates auth/onboarding guards whenever auth state changes.
abstract final class AuthNavigationGuard {
  static void apply() {
    final String? redirect = _computeRedirect(
      AppServices.auth.authState.value,
      Get.currentRoute,
      kSkipOnboarding || AppServices.onboarding.seen,
    );
    if (redirect == null) return;
    final String current = Get.currentRoute;
    if (current == redirect) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == redirect) return;
      // Prefer offNamed when stack is empty/splash; offAllNamed clears history.
      Get.offAllNamed<dynamic>(redirect);
    });
  }

  /// Auth + onboarding + role guard (mirrors former GoRouter redirect).
  static String? _computeRedirect(
    AuthState auth,
    String location,
    bool onboardingSeen,
  ) {
    // GetX may report '' before the first named route settles.
    final String normalized =
        location.isEmpty || location == '/' ? AppRoute.splash.path : location;
    final bool atSplash = normalized == AppRoute.splash.path;
    final bool atLogin = normalized == AppRoute.login.path;
    final bool atOnboarding = normalized == AppRoute.onboarding.path;

    if (kHideReports && normalized.startsWith(AppRoute.reports.path)) {
      return AppRoute.dashboard.path;
    }

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
        final AppDestination? dest = AppDestinations.byPath(normalized);
        final role = auth.user?.role;
        if (dest != null && role != null && !dest.isAllowedFor(role)) {
          return AppRoute.dashboard.path;
        }
        return null;
    }
  }
}
