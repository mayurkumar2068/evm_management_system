import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/utils/date_time_extensions.dart';
import 'package:evm_management_system/features/dashboard/presentation/widgets/dashboard_stat_strip.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/activity_event.dart';
import 'package:flutter/material.dart';

class DashboardActivityList extends StatelessWidget {
  const DashboardActivityList({required this.events, super.key});
  final List<ActivityEvent> events;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tiles = events.isEmpty
        ? _fallbackTiles()
        : <Widget>[
            for (final ActivityEvent e in events.take(5))
              _ActivityTile(
                icon: _cfg(e.type).icon,
                color: _cfg(e.type).color,
                title: e.title,
                subtitle: e.officer,
                time: e.timestamp.relativeTime,
              ),
          ];
    return Column(children: tiles);
  }

  List<Widget> _fallbackTiles() => <Widget>[
    _ActivityTile(
      icon: Icons.assignment_turned_in_outlined,
      color: AppColors.primary,
      title: LocaleKeys.dashboardActEmptyHint.tr(),
      subtitle: '',
      time: '',
    ),
  ];

  static ({IconData icon, Color color}) _cfg(ActivityType t) => switch (t) {
    ActivityType.registered => (
      icon: Icons.add_circle_outline,
      color: AppColors.primary,
    ),
    ActivityType.scanned => (
      icon: Icons.qr_code_rounded,
      color: AppColors.green,
    ),
    ActivityType.updated => (
      icon: Icons.edit_outlined,
      color: AppColors.primaryBright,
    ),
    ActivityType.login => (
      icon: Icons.lock_outline_rounded,
      color: AppColors.primaryDark,
    ),
    ActivityType.sync => (icon: Icons.sync_rounded, color: AppColors.teal),
    ActivityType.exported => (
      icon: Icons.download_rounded,
      color: AppColors.slate600,
    ),
  };
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.time,
    this.subtitle = '',
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: DashboardStatStrip.cardDecoration(context),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (subtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: context.appMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (time.isNotEmpty) ...<Widget>[
            const SizedBox(width: 10),
            Text(
              time,
              style: AppTextStyles.caption.copyWith(
                color: context.appMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
