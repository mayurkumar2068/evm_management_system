import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/location/location_service.dart';
import 'package:evm_management_system/core/navigation/map_navigation_service.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Numbered section card with milestone rows for the presiding dashboard.
class PresidingMilestoneSectionCard extends StatelessWidget {
  const PresidingMilestoneSectionCard({
    required this.index,
    required this.title,
    required this.milestones,
    required this.onMilestoneTap,
    this.isMilestoneEnabled,
    this.boothMapStationName,
    super.key,
  });

  final int index;
  final String title;
  final List<PresidingMilestone> milestones;
  final Future<void> Function(PresidingMilestone milestone) onMilestoneTap;
  /// When false, the incomplete action chip is shown disabled (non-tappable).
  final bool Function(PresidingMilestone milestone)? isMilestoneEnabled;

  /// When set (and IPBMS is on), shows booth name + map chip above
  /// "मतदान केंद्र पहुँचे".
  final String? boothMapStationName;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];

    for (int i = 0; i < milestones.length; i++) {
      final PresidingMilestone milestone = milestones[i];
      final bool insertMapAbove =
          boothMapStationName != null &&
          milestone.id == PresidingMilestoneIds.reachedPollingStation;

      if (insertMapAbove) {
        if (rows.isNotEmpty) {
          rows.add(const Divider(height: 24, color: AppColors.slate100));
        }
        rows.add(_BoothNameMapRow(stationName: boothMapStationName!));
      }

      if (rows.isNotEmpty) {
        rows.add(const Divider(height: 24, color: AppColors.slate100));
      }
      rows.add(
        PresidingMilestoneRow(
          milestone: milestone,
          enabled: isMilestoneEnabled?.call(milestone) ?? true,
          onTap: () => onMilestoneTap(milestone),
        ),
      );
    }

    // Fallback if "reached" milestone missing — keep map at end.
    if (boothMapStationName != null &&
        milestones.every(
          (PresidingMilestone m) =>
              m.id != PresidingMilestoneIds.reachedPollingStation,
        )) {
      if (rows.isNotEmpty) {
        rows.add(const Divider(height: 24, color: AppColors.slate100));
      }
      rows.add(_BoothNameMapRow(stationName: boothMapStationName!));
    }

    return MpSecEnterpriseCard(
      title: '$index. $title',
      child: Column(children: rows),
    );
  }
}

/// Milestone-style row: booth name + action chip that opens Maps.
class _BoothNameMapRow extends StatefulWidget {
  const _BoothNameMapRow({required this.stationName});

  final String stationName;

  @override
  State<_BoothNameMapRow> createState() => _BoothNameMapRowState();
}

class _BoothNameMapRowState extends State<_BoothNameMapRow> {
  final MapNavigationService _maps = MapNavigationService();
  final LocationService _location = LocationService();

  double? _boothLat;
  double? _boothLong;
  GeoCoordinates? _current;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _loadCoords();
  }

  Future<void> _loadCoords() async {
    final PresidingElectionContextStore store = PresidingElectionContextStore(
      AppServices.secureStorage,
    );
    final PresidingElectionContext? ctx = await store.read();
    final ServiceSession? session = AppServices.serviceAuth.session.value;
    final GeoCoordinates? current = await _location.getCurrentCoordinates();
    if (!mounted) return;
    setState(() {
      _boothLat = ctx?.boothLat ?? session?.lat;
      _boothLong = ctx?.boothLong ?? session?.long;
      _current = current;
    });
  }

  bool get _hasCoords =>
      _boothLat != null &&
      _boothLong != null &&
      _boothLat!.abs() > 0 &&
      _boothLong!.abs() > 0;

  String get _stationLabel {
    final String name = widget.stationName.trim();
    return name.isNotEmpty
        ? name
        : LocaleKeys.presidingBoothPollingStation.tr();
  }

  Future<void> _openMap() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final bool opened = _hasCoords
          ? await _maps.openDirections(
              destinationLat: _boothLat!,
              destinationLng: _boothLong!,
              originLat: _current?.latitude,
              originLng: _current?.longitude,
              destinationLabel: _stationLabel,
            )
          : await _maps.openPlaceSearch(_stationLabel);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(LocaleKeys.presidingBoothMapError.tr()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                LocaleKeys.presidingBoothLocationTitle.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.slate700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _stationLabel,
                maxLines: 2,
                overflow: TextOverflow.clip,
                softWrap: true,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        MpSecStatusChip(
          label: _opening
              ? '...'
              : LocaleKeys.presidingBoothOpenMap.tr(),
          variant: _opening
              ? MpSecChipVariant.disabled
              : MpSecChipVariant.action,
          onTap: _opening ? null : _openMap,
        ),
      ],
    );
  }
}

/// Single milestone row with label and status chip.
class PresidingMilestoneRow extends StatelessWidget {
  const PresidingMilestoneRow({
    required this.milestone,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final PresidingMilestone milestone;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final String label = milestone.labelKey.tr();
    if (milestone.isCompleted) {
      if (milestone.completedAt != null) {
        final String timestamp = DateFormat(
          'dd-MMM-yyyy HH:mm:ss',
        ).format(milestone.completedAt!.toLocal());
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.slate700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            MpSecStatusChip(
              label: timestamp,
              variant: MpSecChipVariant.completed,
            ),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.slate700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          MpSecStatusChip(
            label: LocaleKeys.presidingMarkComplete.tr(),
            variant: MpSecChipVariant.completed,
          ),
        ],
      );
    }

    final MpSecChipVariant variant =
        !enabled ? MpSecChipVariant.disabled : MpSecChipVariant.action;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: enabled ? AppColors.slate700 : AppColors.slate400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        MpSecStatusChip(
          label: LocaleKeys.presidingMarkComplete.tr(),
          variant: variant,
          onTap: enabled ? onTap : null,
        ),
      ],
    );
  }
}
