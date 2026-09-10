import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const List<AppRoute> _tabRoutes = <AppRoute>[
    AppRoute.dashboard,
    AppRoute.profile,
  ];

  int _activeIndex(String location) {
    for (int i = 0; i < _tabRoutes.length; i++) {
      if (location.startsWith(_tabRoutes[i].path)) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final String location = Get.currentRoute;
    final List<BottomNavItem> items = <BottomNavItem>[
      BottomNavItem(
        icon: AppIcons.dashboard,
        label: LocaleKeys.menuDashboard.tr(),
        onTap: () => Get.offNamed<dynamic>(AppRoute.dashboard.path),
      ),
      BottomNavItem(
        icon: AppIcons.profile,
        label: LocaleKeys.profileTitle.tr(),
        onTap: () => Get.offNamed<dynamic>(AppRoute.profile.path),
      ),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: child,
      bottomNavigationBar: AppBottomNav(
        items: items,
        activeIndex: _activeIndex(location),
      ),
    );
  }
}
