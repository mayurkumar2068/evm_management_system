import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/controllers/device_records_controller.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/device_record.dart';
import 'package:evm_management_system/shared/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Persistent scaffold shared by authenticated routes. Hosts the floating
/// bottom navigation while each child screen renders its own gradient header
/// and body content.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const List<AppRoute> _tabRoutes = <AppRoute>[
    AppRoute.dashboard,
    AppRoute.masterStockRegister,
    AppRoute.scanner,
    AppRoute.reports,
    AppRoute.profile,
  ];

  int _activeIndex(String location) {
    for (int i = 0; i < _tabRoutes.length; i++) {
      if (location.startsWith(_tabRoutes[i].path)) return i;
    }
    return -1;
  }

  Future<void> _scanAndRegister(BuildContext context) async {
    final Object? result = await Get.toNamed<Object?>(AppRoute.scanner.path);
    if (result is! String || result.isEmpty) return;
    final DeviceRecordsController records = AppServices.deviceRecords;
    final DeviceRecord record = records.register(
      kind: DeviceKind.controlUnit,
      barcode: result,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        content: Text('${record.id} added from scan (${record.status.key})'),
      ),
    );
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
        icon: AppIcons.stockRegister,
        label: LocaleKeys.regInventory.tr(),
        onTap: () => Get.offNamed<dynamic>(AppRoute.masterStockRegister.path),
      ),
      BottomNavItem(
        icon: AppIcons.scanner,
        label: LocaleKeys.commonSearch.tr(),
        isCenter: true,
        onTap: () => _scanAndRegister(context),
      ),
      BottomNavItem(
        icon: AppIcons.reports,
        label: LocaleKeys.regReports.tr(),
        onTap: () => Get.offNamed<dynamic>(AppRoute.reports.path),
      ),
      BottomNavItem(
        icon: AppIcons.profile,
        label: LocaleKeys.profileTitle.tr(),
        onTap: () => Get.offNamed<dynamic>(AppRoute.profile.path),
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: AppBottomNav(
        items: items,
        activeIndex: _activeIndex(location),
      ),
    );
  }
}
