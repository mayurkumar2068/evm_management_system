import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/offline/web_form_submission.dart';
import 'package:evm_management_system/core/utils/date_time_extensions.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/activity_event.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Notifications — survey sync alerts and recent activity.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<WebFormSubmission> _submissions = const <WebFormSubmission>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<WebFormSubmission> all =
        await AppServices.webSubmissionRepository.all();
    if (!mounted) return;
    setState(() {
      _submissions = all;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ColoredBox(
        color: context.appBackground,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Obx(() {
      final List<ActivityEvent> activity = AppServices.activityLog.events;
      final List<_Notif> items = <_Notif>[];

      int pending = 0;
      int failed = 0;
      int syncedToday = 0;
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      for (final WebFormSubmission s in _submissions) {
        switch (s.status) {
          case WebSubmissionStatus.pending:
          case WebSubmissionStatus.syncing:
            pending++;
          case WebSubmissionStatus.failed:
            failed++;
          case WebSubmissionStatus.synced:
            final DateTime at = s.syncedAt ?? s.createdAt;
            final DateTime day = DateTime(at.year, at.month, at.day);
            if (day == today) syncedToday++;
        }
      }

      if (pending > 0) {
        items.add(
          _Notif(
            _NotifType.alert,
            LocaleKeys.dashboardStatSurveysPending.tr(),
            LocaleKeys.dashboardNotifPendingSync.tr(
              args: <String>['$pending'],
            ),
            '',
            false,
          ),
        );
      }
      if (failed > 0) {
        items.add(
          _Notif(
            _NotifType.warning,
            LocaleKeys.statsFailed.tr(),
            LocaleKeys.dashboardNotifFailed.tr(args: <String>['$failed']),
            '',
            false,
          ),
        );
      }
      if (syncedToday > 0) {
        items.add(
          _Notif(
            _NotifType.success,
            LocaleKeys.dashboardStatSurveysSynced.tr(),
            LocaleKeys.dashboardNotifSyncedToday.tr(
              args: <String>['$syncedToday'],
            ),
            '',
            false,
          ),
        );
      }

      for (final ActivityEvent e in activity.take(8)) {
        items.add(
          _Notif(
            e.type == ActivityType.sync
                ? _NotifType.success
                : _NotifType.info,
            e.title,
            e.deviceId.isEmpty
                ? e.officer
                : '${e.deviceId} • ${e.officer}',
            e.timestamp.relativeTime,
            false,
          ),
        );
      }

      if (items.isEmpty) {
        items.add(
          _Notif(
            _NotifType.info,
            LocaleKeys.notificationsTitle.tr(),
            LocaleKeys.dashboardNotifNone.tr(),
            '',
            true,
          ),
        );
      }

      final int unread = items.where((_Notif n) => !n.read).length;
      return ColoredBox(
        color: context.appBackground,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: <Widget>[
              AppTopBar(
                title: LocaleKeys.notificationsTitle.tr(),
                onBack: Get.key.currentState?.canPop() == true
                    ? () => Get.back<void>()
                    : null,
              ),
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
                  child: _NotifCard(notif: n),
                ),
            ],
          ),
        ),
      );
    });
  }
}

enum _NotifType { alert, success, warning, info }

class _Notif {
  const _Notif(
    this.type,
    this.title,
    this.body,
    this.time,
    this.read,
  );
  final _NotifType type;
  final String title;
  final String body;
  final String time;
  final bool read;
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.notif});
  final _Notif notif;

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
