import 'package:evm_management_system/app/router/app_destinations.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/auth/presentation/states/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Blocks navigation until auth/onboarding state allows the target route.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final AuthState auth = AppServices.auth.authState.value;
    final bool onboardingSeen = AppServices.onboarding.seen;
    final String location = route ?? AppRoute.splash.path;

    final bool atSplash = location == AppRoute.splash.path;
    final bool atLogin = location == AppRoute.login.path;
    final bool atOnboarding = location == AppRoute.onboarding.path;

    switch (auth.status) {
      case AuthStatus.unknown:
        return atSplash ? null : RouteSettings(name: AppRoute.splash.path);
      case AuthStatus.authenticating:
      case AuthStatus.unauthenticated:
        if (!onboardingSeen) {
          return atOnboarding
              ? null
              : RouteSettings(name: AppRoute.onboarding.path);
        }
        return atLogin ? null : RouteSettings(name: AppRoute.login.path);
      case AuthStatus.authenticated:
        if (atSplash || atLogin || atOnboarding) {
          return RouteSettings(name: AppRoute.dashboard.path);
        }
        final AppDestination? dest = AppDestinations.byPath(location);
        final role = auth.user?.role;
        if (dest != null && role != null && !dest.isAllowedFor(role)) {
          return RouteSettings(name: AppRoute.dashboard.path);
        }
        return null;
    }
  }
}
