import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/activity_event.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Audit Trail — chronological activity log grouped by day.
class AuditTrailScreen extends StatelessWidget {
  const AuditTrailScreen({super.key});

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<ActivityEvent> events = AppServices.activityLog.events;

      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      // Group events by calendar day, newest day first.
      final Map<DateTime, List<ActivityEvent>> grouped =
          <DateTime, List<ActivityEvent>>{};
      for (final ActivityEvent e in events) {
        final DateTime day = DateTime(
          e.timestamp.year,
          e.timestamp.month,
          e.timestamp.day,
        );
        grouped.putIfAbsent(day, () => <ActivityEvent>[]).add(e);
      }
      final List<DateTime> days = grouped.keys.toList()
        ..sort((DateTime a, DateTime b) => b.compareTo(a));

      String dayLabel(DateTime day) {
        final int diff = today.difference(day).inDays;
        final String date = DateFormat('MMM dd').format(day);
        if (diff == 0) return '${LocaleKeys.auditToday.tr()} — $date';
        if (diff == 1) return '${LocaleKeys.auditYesterday.tr()} — $date';
        return date;
      }

      return Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: <Widget>[
            AppTopBar(
              title: LocaleKeys.auditTitle.tr(),
              onBack: Get.key.currentState?.canPop() == true
                  ? () => Get.back<void>()
                  : null,
              trailing: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppSquareIconButton(icon: Icons.filter_list_rounded),
                  SizedBox(width: 8),
                  AppSquareIconButton(icon: Icons.download_rounded),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: AppColors.slate400,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM dd, yyyy').format(now),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.slate600,
                        ),
                      ),
                    ),
                    Text(
                      events.length == 1
                          ? '1 event'
                          : '${events.length} events', // Simplified plural for now, or use tr plural
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.slate400,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.expand_more_rounded,
                      size: 16,
                      color: AppColors.slate400,
                    ),
                  ],
                ),
              ),
            ),
            if (events.isEmpty)
              const _EmptyAudit()
            else
              for (final DateTime day in days)
                _group(dayLabel(day), grouped[day]!),
          ],
        ),
      );
    });
  }

  Widget _group(String label, List<ActivityEvent> events) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.slate400,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          for (int i = 0; i < events.length; i++)
            _TimelineRow(
              event: events[i],
              time: _time(events[i].timestamp),
              isLast: i == events.length - 1,
            ),
        ],
      ),
    );
  }
}

class _EmptyAudit extends StatelessWidget {
  const _EmptyAudit();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.fact_check_outlined,
            size: 48,
            color: AppColors.slate300,
          ),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.auditEmpty.tr(),
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.auditEmptySub.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.slate400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.time,
    required this.isLast,
  });
  final ActivityEvent event;
  final String time;
  final bool isLast;

  ({IconData icon, Color bg, Color fg}) get _cfg => switch (event.type) {
    ActivityType.registered => (
      icon: Icons.add_rounded,
      bg: AppColors.primaryLight,
      fg: AppColors.primary,
    ),
    ActivityType.scanned => (
      icon: Icons.qr_code_rounded,
      bg: AppColors.greenLight,
      fg: AppColors.green,
    ),
    ActivityType.updated => (
      icon: Icons.edit_outlined,
      bg: AppColors.warningSurface,
      fg: const Color(0xFFD97706),
    ),
    ActivityType.login => (
      icon: Icons.lock_outline_rounded,
      bg: AppColors.purpleLight,
      fg: AppColors.purple,
    ),
    ActivityType.sync => (
      icon: Icons.sync_rounded,
      bg: const Color(0xFFE0FFF8),
      fg: AppColors.teal,
    ),
    ActivityType.exported => (
      icon: Icons.download_rounded,
      bg: AppColors.slate50,
      fg: AppColors.slate600,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color bg, Color fg}) c = _cfg;
    final bool hasDevice = event.deviceId.isNotEmpty;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.bg,
                  borderRadius: AppRadius.brMd,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(c.icon, size: 15, color: c.fg),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.slate100)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                onTap: hasDevice
                    ? () => Get.toNamed<dynamic>(
                        AppRoute.deviceDetail.path,
                        arguments: event.deviceId,
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                event.title,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate700,
                                ),
                              ),
                              if (hasDevice)
                                Text(
                                  event.deviceId,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.slate400,
                                    fontSize: 10,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          time,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.slate400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LocaleKeys.auditBy.tr(args: [event.officer]),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.slate400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
