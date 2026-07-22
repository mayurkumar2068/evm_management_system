import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:evm_management_system/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/activity_event.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Full-screen history view for Dashboard activities.
class DashboardViewAllScreen extends StatelessWidget {
  const DashboardViewAllScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();

    return Obx(() {
      final List<ActivityEvent> history = controller.state.value.activity;

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(LocaleKeys.dashboardRecentActivity.tr()),
          backgroundColor: AppColors.surface,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Get.back<void>(),
          ),
        ),
        body: history.isEmpty
            ? const _EmptyHistoryView()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final ActivityEvent event = history[index];
                  return _ActivityTile(event: event);
                },
              ),
      );
    });
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.event});

  final ActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final cfg = _getConfig(event.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cfg.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cfg.icon, color: cfg.color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (event.deviceId.isNotEmpty) event.deviceId,
                    if (event.officer.isNotEmpty) event.officer,
                  ].join(' • '),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('hh:mm a').format(event.timestamp),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.slate400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  ({IconData icon, Color color}) _getConfig(ActivityType t) {
    switch (t) {
      case ActivityType.registered:
        return (icon: Icons.add_circle_outline, color: AppColors.primary);
      case ActivityType.scanned:
        return (icon: Icons.qr_code_scanner, color: AppColors.teal);
      case ActivityType.updated:
        return (icon: Icons.edit_note_rounded, color: DashboardBrand.saffron);
      case ActivityType.login:
        return (icon: Icons.login_rounded, color: AppColors.purple);
      case ActivityType.sync:
        return (icon: Icons.sync_rounded, color: AppColors.info);
      case ActivityType.exported:
        return (icon: Icons.ios_share_rounded, color: AppColors.success);
    }
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: AppColors.slate200),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.dashboardActEmptyHint.tr(),
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.slate400),
          ),
        ],
      ),
    );
  }
}
