import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/features/auth/domain/entities/user_role.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A single navigable module surfaced in the navigation drawer.
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

  /// Empty means every authenticated role may access the route.
  final Set<UserRole> requiredRoles;

  bool isAllowedFor(UserRole role) =>
      requiredRoles.isEmpty || requiredRoles.contains(role);
}

/// The ordered list of modules shown in the drawer. Single source of truth for
/// navigation, used by both the drawer and the route role guards.
abstract final class AppDestinations {
  static const List<AppDestination> all = <AppDestination>[
    AppDestination(
      route: AppRoute.dashboard,
      labelKey: LocaleKeys.menuDashboard,
      icon: AppIcons.dashboard,
    ),
    AppDestination(
      route: AppRoute.masterStockRegister,
      labelKey: LocaleKeys.menuMasterStockRegister,
      icon: AppIcons.stockRegister,
    ),
    AppDestination(
      route: AppRoute.controlUnit,
      labelKey: LocaleKeys.menuControlUnit,
      icon: AppIcons.controlUnit,
    ),
    AppDestination(
      route: AppRoute.ballotUnit,
      labelKey: LocaleKeys.menuBallotUnit,
      icon: AppIcons.ballotUnit,
    ),
    AppDestination(
      route: AppRoute.scanner,
      labelKey: LocaleKeys.menuScanner,
      icon: AppIcons.scanner,
    ),
    AppDestination(
      route: AppRoute.reports,
      labelKey: LocaleKeys.menuReports,
      icon: AppIcons.reports,
    ),
    AppDestination(
      route: AppRoute.notifications,
      labelKey: LocaleKeys.menuNotifications,
      icon: AppIcons.notifications,
    ),
    AppDestination(
      route: AppRoute.auditTrail,
      labelKey: LocaleKeys.menuAuditTrail,
      icon: AppIcons.auditTrail,
      requiredRoles: <UserRole>{
        UserRole.superAdmin,
        UserRole.auditor,
        UserRole.stateOfficer,
      },
    ),
    AppDestination(
      route: AppRoute.syncManagement,
      labelKey: LocaleKeys.menuSyncManagement,
      icon: AppIcons.sync,
    ),
    AppDestination(
      route: AppRoute.search,
      labelKey: LocaleKeys.menuSearch,
      icon: AppIcons.search,
    ),
    AppDestination(
      route: AppRoute.profile,
      labelKey: LocaleKeys.menuProfile,
      icon: AppIcons.profile,
    ),
    AppDestination(
      route: AppRoute.settings,
      labelKey: LocaleKeys.menuSettings,
      icon: AppIcons.settings,
    ),
    AppDestination(
      route: AppRoute.help,
      labelKey: LocaleKeys.menuHelpSupport,
      icon: AppIcons.help,
    ),
    AppDestination(
      route: AppRoute.about,
      labelKey: LocaleKeys.menuAbout,
      icon: AppIcons.about,
    ),
  ];

  static AppDestination? byPath(String path) {
    for (final AppDestination d in all) {
      if (path.startsWith(d.path)) return d;
    }
    return null;
  }
}
