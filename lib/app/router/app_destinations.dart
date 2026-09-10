import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/features/auth/domain/entities/user_role.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_icons.dart';
import 'package:flutter/widgets.dart';

class AppDestination {
  const AppDestination({
    required this.route,
    required this.labelKey,
    required this.icon,
    this.requiredRoles = const <UserRole>{},
  });

  final AppRoute route;
  final String labelKey;
  final IconData icon;

  String get routeName => route.name;
  String get path => route.path;

  final Set<UserRole> requiredRoles;

  bool isAllowedFor(UserRole role) =>
      requiredRoles.isEmpty || requiredRoles.contains(role);
}

abstract final class AppDestinations {
  static const List<AppDestination> all = <AppDestination>[
    AppDestination(
      route: AppRoute.dashboard,
      labelKey: LocaleKeys.menuDashboard,
      icon: AppIcons.dashboard,
    ),
    AppDestination(
      route: AppRoute.notifications,
      labelKey: LocaleKeys.menuNotifications,
      icon: AppIcons.notifications,
    ),
    AppDestination(
      route: AppRoute.profile,
      labelKey: LocaleKeys.menuProfile,
      icon: AppIcons.profile,
    ),
  ];

  static AppDestination? byPath(String path) {
    for (final AppDestination d in all) {
      if (path.startsWith(d.path)) return d;
    }
    return null;
  }
}
