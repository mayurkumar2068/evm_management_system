import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/utils/string_extensions.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/activity_event.dart';
import 'package:evm_management_system/shared/models/device_record.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Device detail — hero identity card, registering officer and a vertical
/// registration timeline. Fully derived from the live device-records and
/// activity-log stores for the [deviceId] passed in.
class DeviceDetailScreen extends StatelessWidget {
  const DeviceDetailScreen({this.deviceId, super.key});

  final String? deviceId;

  static String _dateTimeLabel(DateTime t) {
    return DateFormat('MMM dd, hh:mm a').format(t);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final DeviceRecord? record = deviceId == null
          ? null
          : AppServices.deviceRecords.byId(deviceId!);

      return Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: <Widget>[
            AppTopBar(
              title: LocaleKeys.detailTitle.tr(),
              onBack: () => Get.key.currentState?.canPop() == true
                  ? Get.back<dynamic>()
                  : Get.offAllNamed<dynamic>(AppRoute.dashboard.path),
              trailing: const Row(
                children: <Widget>[
                  _HeaderAction(icon: Icons.share_outlined),
                  SizedBox(width: 8),
                  _HeaderAction(icon: Icons.edit_outlined),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (record == null)
              _notFound(context)
            else ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HeroCard(record: record),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _registeredBy(record),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _timelineSection(record),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _notFound(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.devices_other_rounded,
            size: 48,
            color: AppColors.slate300,
          ),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.detailNotFound.tr(),
            style: const TextStyle(
              color: AppColors.slate500,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.detailNotFoundSub.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.slate400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _registeredBy(DeviceRecord record) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocaleKeys.profileRegisteredBy.tr(),
            style: const TextStyle(
              color: AppColors.slate400,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF60A5FA), Color(0xFF3B82F6)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  record.officer.initials,
                  style: AppTextStyles.titleSmall.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(record.officer, style: AppTextStyles.titleSmall),
                    Text(
                      '${LocaleKeys.regManufacturer.tr()} • ${record.manufacturer}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.slate400,
                      ),
                    ),
                    Text(
                      record.district,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timelineSection(DeviceRecord record) {
    final List<ActivityEvent> events =
        AppServices.activityLog.eventsForDevice(record.id)..sort(
          (ActivityEvent a, ActivityEvent b) =>
              b.timestamp.compareTo(a.timestamp),
        );

    final List<_TimelineEntry> entries = <_TimelineEntry>[
      for (final ActivityEvent e in events)
        _TimelineEntry(e.title, e.officer, _dateTimeLabel(e.timestamp)),
    ];
    // Always show the registration as the founding event.
    if (entries.every((_TimelineEntry e) => e.label != 'Device Registered')) {
      entries.add(
        _TimelineEntry(
          'Device Registered',
          record.officer,
          _dateTimeLabel(record.timestamp),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(LocaleKeys.profileTimeline.tr(), style: AppTextStyles.titleSmall),
        const SizedBox(height: 16),
        for (int i = 0; i < entries.length; i++)
          _TimelineTile(entry: entries[i], isLast: i == entries.length - 1),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.record});
  final DeviceRecord record;

  @override
  Widget build(BuildContext context) {
    final bool registered = record.status == DeviceStatus.registered;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
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
                      record.kind.label.toUpperCase(),
                      style: AppTextStyles.overline.copyWith(
                        color: const Color(0xFF9CB6F5),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.id,
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                      ),
                    ),
                    Text(
                      record.barcode,
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF9CB6F5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: AppRadius.brPill,
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      registered
                          ? LocaleKeys.statsRegistered.tr()
                          : _statusLabel(record.status),
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF86EFAC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: AppRadius.brMd,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      for (final int h in _bars(record.barcode))
                        Container(
                          width: 3,
                          height: 8.0 + h * 3.4,
                          margin: const EdgeInsets.symmetric(horizontal: 0.6),
                          color: Colors.white.withValues(alpha: 0.5 + h * 0.05),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  record.barcode.split('').join(' '),
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _HeroInfo(label: LocaleKeys.detailBoxNo.tr(), value: record.box),
              const SizedBox(width: 10),
              _HeroInfo(
                label: LocaleKeys.detailDistrict.tr(),
                value: record.district,
              ),
              const SizedBox(width: 10),
              _HeroInfo(
                label: LocaleKeys.detailMfrYear.tr(),
                value: '${record.manufacturer} / ${record.timestamp.year}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _statusLabel(DeviceStatus s) => switch (s) {
    DeviceStatus.registered => LocaleKeys.statsRegistered.tr(),
    DeviceStatus.pending => LocaleKeys.statsPending.tr(),
    DeviceStatus.inTransit => LocaleKeys.statsInTransit.tr(),
    DeviceStatus.defective => LocaleKeys.statsDefective.tr(),
  };

  /// Deterministic faux barcode bars derived from the real code so the visual
  /// reflects the device rather than a fixed pattern.
  static List<int> _bars(String code) {
    if (code.isEmpty) return const <int>[3, 1, 4, 1, 5, 9, 2, 6];
    return <int>[
      for (int i = 0; i < 30; i++) code.codeUnitAt(i % code.length) % 10,
    ];
  }
}

class _HeroInfo extends StatelessWidget {
  const _HeroInfo({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: AppRadius.brSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF9CB6F5),
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}

class _TimelineEntry {
  const _TimelineEntry(this.label, this.officer, this.at);
  final String label;
  final String officer;
  final String at;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry, required this.isLast});
  final _TimelineEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
                ),
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: AppColors.success,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.slate100)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.slate700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          entry.officer,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.slate400,
                          ),
                        ),
                        Text(
                          entry.at,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.slate400,
                          ),
                        ),
                      ],
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
