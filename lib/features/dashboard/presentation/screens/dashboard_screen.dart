import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/constants/feature_flags.dart';
import 'package:evm_management_system/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:evm_management_system/features/dashboard/presentation/models/dashboard_models.dart';
import 'package:evm_management_system/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Premium MP State Election Management dashboard.
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
      final DashboardCategory category = controller.activeCategory.value;
      final List<DashboardService> services = controller.filteredServices;

      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DashboardBackdrop(),
          RefreshIndicator(
            onRefresh: () async {
              controller.rebuildDashboard();
              await Future<void>.delayed(const Duration(milliseconds: 300));
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: <Widget>[
                DashboardHeader(
                  name: state.userName,
                  pending: state.pendingCount,
                ),
                if (!kHideDashboardStats) ...<Widget>[
                  const SizedBox(height: DashboardGap.section),
                  DashboardStatStrip(stats: state.stats),
                ],
                const SizedBox(height: 16),
                DashboardSectionHeader(
                  title: LocaleKeys.dashboardMainServices.tr(),
                ),
                const SizedBox(height: 8),
                DashboardCategoryToggle(
                  active: category,
                  onChanged: controller.setCategory,
                ),
                const SizedBox(height: 10),
                DashboardServicesGrid(services: services),
              ],
            ),
          ),
        ],
      );
    });
  }
}
