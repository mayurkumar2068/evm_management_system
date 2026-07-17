import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:evm_management_system/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Premium Madhya Pradesh Election Management dashboard.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<DashboardController>().rebuildDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();

    return Obx(() {
      final DashboardState state = controller.state.value;

      return ColoredBox(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: <Widget>[
            DashboardHeader(name: state.userName, pending: state.pendingCount),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DashboardGap.page,
              ),
              child: DashboardWelcomeCard(
                name: state.userName,
                designation: state.designation,
                district: state.district,
              ),
            ),
            const SizedBox(height: DashboardGap.section),
            DashboardStatStrip(stats: state.stats),
            const SizedBox(height: DashboardGap.section),
            DashboardSectionHeader(
              title: LocaleKeys.dashboardMainServices.tr(),
            ),
            const SizedBox(height: DashboardGap.headerToContent),
            DashboardServicesGrid(services: state.services),
            const SizedBox(height: DashboardGap.section),
            DashboardSectionHeader(
              title: LocaleKeys.dashboardRecentActivity.tr(),
              onViewAll: () =>
                  Get.toNamed<dynamic>(AppRoute.activityHistory.path),
            ),
            const SizedBox(height: DashboardGap.headerToContent),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DashboardGap.page,
              ),
              child: DashboardActivityList(events: state.activity),
            ),
            const SizedBox(height: DashboardGap.section),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: DashboardGap.page),
              child: DashboardAlertBanner(),
            ),
          ],
        ),
      );
    });
  }
}
