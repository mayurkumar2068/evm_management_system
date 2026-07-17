import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/utils/date_time_extensions.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/activity_event.dart';
import 'package:evm_management_system/shared/models/device_record.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Notifications — alerts derived from inventory state and activity log.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<ActivityEvent> activity = AppServices.activityLog.events;
      final DeviceStats stats = AppServices.deviceRecords.statsFor(null);

      final List<_Notif> items = <_Notif>[];

      if (stats.pending > 0) {
        items.add(
          _Notif(
            _NotifType.alert,
            'Sync Required', // These titles could be localized too if they were dynamic, but sticking to existing ones for now
            '${stats.pending} record${stats.pending == 1 ? '' : 's'} pending — sync to the central server.',
            '',
            false,
          ),
        );
      }
      if (stats.defective > 0) {
        items.add(
          _Notif(
            _NotifType.warning,
            'Defective Devices',
            '${stats.defective} device${stats.defective == 1 ? '' : 's'} marked defective need review.',
            '',
            false,
          ),
        );
      }
      if (stats.inTransit > 0) {
        items.add(
          _Notif(
            _NotifType.info,
            'Devices In Transit',
            '${stats.inTransit} device${stats.inTransit == 1 ? '' : 's'} currently in transit.',
            '',
            false,
          ),
        );
      }

      // Most recent real actions become individual notifications.
      for (final ActivityEvent e in activity.take(8)) {
        items.add(
          _Notif(
            e.type == ActivityType.registered
                ? _NotifType.success
                : _NotifType.info,
            e.title,
            e.deviceId.isEmpty
                ? 'by ${e.officer}'
                : '${e.deviceId} • by ${e.officer}',
            e.timestamp.relativeTime,
            false,
            deviceId: e.deviceId,
          ),
        );
      }

      final int unread = items.length;
      return Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: <Widget>[
            AppTopBar(
              title: LocaleKeys.notificationsTitle.tr(),
              onBack: Get.key.currentState?.canPop() == true
                  ? () => Get.back<void>()
                  : null,
            ),
            if (items.isEmpty)
              _empty()
            else ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoSurface,
                    borderRadius: AppRadius.brMd,
                    border: Border.all(color: const Color(0xFFD7E3FF)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.notifications_active_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        LocaleKeys.notificationsCount.plural(unread),
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              for (final _Notif n in items)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _NotifCard(
                    notif: n,
                    onTap: n.deviceId.isEmpty
                        ? null
                        : () => Get.toNamed<dynamic>(
                            AppRoute.deviceDetail.path,
                            arguments: n.deviceId,
                          ),
                  ),
                ),
            ],
          ],
        ),
      );
    });
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: AppColors.slate300,
          ),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.notificationsEmpty.tr(),
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.notificationsEmptySub.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.slate400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

enum _NotifType { alert, success, warning, info }

class _Notif {
  const _Notif(
    this.type,
    this.title,
    this.body,
    this.time,
    this.read, {
    this.deviceId = '',
  });
  final _NotifType type;
  final String title;
  final String body;
  final String time;
  final bool read;
  final String deviceId;
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.notif, this.onTap});
  final _Notif notif;
  final VoidCallback? onTap;

  ({IconData icon, Color bg, Color fg}) get _cfg => switch (notif.type) {
    _NotifType.alert => (
      icon: Icons.warning_amber_rounded,
      bg: AppColors.errorSurface,
      fg: const Color(0xFFDC2626),
    ),
    _NotifType.success => (
      icon: Icons.check_circle_outline_rounded,
      bg: AppColors.successSurface,
      fg: const Color(0xFF16A34A),
    ),
    _NotifType.warning => (
      icon: Icons.error_outline_rounded,
      bg: AppColors.warningSurface,
      fg: const Color(0xFFD97706),
    ),
    _NotifType.info => (
      icon: Icons.info_outline_rounded,
      bg: AppColors.infoSurface,
      fg: const Color(0xFF1D4ED8),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color bg, Color fg}) c = _cfg;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      border: notif.read
          ? null
          : Border(left: BorderSide(color: c.fg, width: 3)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(c.icon, size: 18, color: c.fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          notif.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: notif.read
                                ? AppColors.slate500
                                : AppColors.slate800,
                          ),
                        ),
                      ),
                      if (!notif.read)
                        Container(
                          margin: const EdgeInsets.only(top: 5, left: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: c.fg,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notif.body,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.slate400,
                      height: 1.4,
                    ),
                  ),
                  if (notif.time.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      notif.time,
                      style: const TextStyle(
                        color: AppColors.slate300,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
