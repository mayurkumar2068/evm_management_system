import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/presiding_concern/di/presiding_concern_module.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_session_scaffold.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/theme/presiding_ui_tokens.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_turnout_card.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Full-screen turnout entry for all presiding-officer reporting slots.
class PresidingTurnoutScreen extends StatelessWidget {
  const PresidingTurnoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PresidingSessionScaffold(
      builder: (BuildContext context, PresidingSession session) {
        return _TurnoutBody(session: session);
      },
    );
  }
}

class _TurnoutBody extends StatefulWidget {
  const _TurnoutBody({required this.session});

  final PresidingSession session;

  @override
  State<_TurnoutBody> createState() => _TurnoutBodyState();
}

class _TurnoutBodyState extends State<_TurnoutBody> {
  late String _selectedSlotId;
  bool _isTimeSlotExpanded = true;
  final Map<String, bool> _otherSlotExpanded = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _selectedSlotId = TurnoutSlotIds.slot9Am;
  }

  void _handleTimeTabTap(String slotId) {
    setState(() {
      if (_selectedSlotId == slotId) {
        _isTimeSlotExpanded = !_isTimeSlotExpanded;
      } else {
        _selectedSlotId = slotId;
        _isTimeSlotExpanded = true;
      }
    });
  }

  bool _isOtherSlotExpanded(String slotId) {
    return _otherSlotExpanded[slotId] ?? false;
  }

  void _setOtherSlotExpanded(String slotId, bool expanded) {
    setState(() => _otherSlotExpanded[slotId] = expanded);
  }

  @override
  void didUpdateWidget(covariant _TurnoutBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final List<TurnoutSlotDefinition> timeSlots = _timeSlotsFor(
      widget.session.areaType,
    );
    final bool stillValid = timeSlots.any(
      (TurnoutSlotDefinition slot) => slot.slotId == _selectedSlotId,
    );
    if (!stillValid && timeSlots.isNotEmpty) {
      _selectedSlotId = timeSlots.first.slotId;
    }
  }

  static List<TurnoutSlotDefinition> _timeSlotsFor(String? areaType) {
    return TurnoutSlots.forAreaType(areaType)
        .where(
          (TurnoutSlotDefinition slot) =>
              !slot.queueOnly && slot.slotId != TurnoutSlotIds.pollCompletion,
        )
        .toList(growable: false);
  }

  static List<TurnoutSlotDefinition> _otherSlotsFor(String? areaType) {
    return TurnoutSlots.forAreaType(areaType)
        .where(
          (TurnoutSlotDefinition slot) =>
              slot.queueOnly || slot.slotId == TurnoutSlotIds.pollCompletion,
        )
        .toList(growable: false);
  }

  TurnoutSlotDefinition? _selectedSlot(List<TurnoutSlotDefinition> timeSlots) {
    for (final TurnoutSlotDefinition slot in timeSlots) {
      if (slot.slotId == _selectedSlotId) return slot;
    }
    return timeSlots.isNotEmpty ? timeSlots.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final PresidingTurnoutController controller =
        Get.find<PresidingTurnoutController>();
    final List<TurnoutSlotDefinition> timeSlots = _timeSlotsFor(
      widget.session.areaType,
    );
    final List<TurnoutSlotDefinition> otherSlots = _otherSlotsFor(
      widget.session.areaType,
    );
    final List<TurnoutSlotDefinition> allSlots = TurnoutSlots.forAreaType(
      widget.session.areaType,
    );
    final TurnoutSlotDefinition? activeSlot = _selectedSlot(timeSlots);
    final bool allSlotsSaved = allSlots.every(
      (TurnoutSlotDefinition slot) =>
          widget.session.turnoutRecords[slot.slotId]?.savedAt != null,
    );
    final String stationLabel =
        widget.session.pollingStationName.startsWith('presiding.')
        ? widget.session.pollingStationName.tr()
        : widget.session.pollingStationName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppGradientHeader(
          leading: AppCircleBackButton(onTap: () => Get.back<void>()),
          title: LocaleKeys.presidingOfficerTitle.tr(),
          subtitle: LocaleKeys.presidingPollingStation.tr(
            args: <String>[widget.session.pollingStationCode, stationLabel],
          ),
          bottom: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              LocaleKeys.presidingEnterInfo.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: <Widget>[
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.event_note_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            LocaleKeys.presidingTurnoutIntroTitle.tr(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            LocaleKeys.presidingTurnoutIntroSubtitle.tr(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.slate500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            LocaleKeys.presidingAutoSaved.tr(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (activeSlot != null) ...<Widget>[
                AppCard(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              LocaleKeys.presidingVoterTurnout.tr(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: _isTimeSlotExpanded
                                ? 'Collapse'
                                : 'Expand',
                            onPressed: () {
                              setState(
                                () =>
                                    _isTimeSlotExpanded = !_isTimeSlotExpanded,
                              );
                            },
                            icon: Icon(
                              _isTimeSlotExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _TurnoutTimeTabBar(
                        slots: timeSlots,
                        selectedSlotId: _selectedSlotId,
                        isExpanded: _isTimeSlotExpanded,
                        records: widget.session.turnoutRecords,
                        onSelected: _handleTimeTabTap,
                      ),
                      AnimatedCrossFade(
                        firstCurve: Curves.easeInOut,
                        secondCurve: Curves.easeInOut,
                        sizeCurve: Curves.easeInOut,
                        crossFadeState: _isTimeSlotExpanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 220),
                        firstChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                            PresidingTurnoutCard(
                              key: ValueKey<String>(activeSlot.slotId),
                              title: activeSlot.labelKey.tr(),
                              slotId: activeSlot.slotId,
                              embedded: true,
                              initialRecord: widget
                                  .session
                                  .turnoutRecords[activeSlot.slotId],
                              mode: PresidingTurnoutCardMode.entry,
                              onSave:
                                  ({
                                    int? male,
                                    int? female,
                                    int? thirdGender,
                                    int? queueCount,
                                  }) {
                                    return controller.saveTurnout(
                                      slotId: activeSlot.slotId,
                                      male: male,
                                      female: female,
                                      thirdGender: thirdGender,
                                      queueCount: queueCount,
                                    );
                                  },
                            ),
                          ],
                        ),
                        secondChild: _CollapsedTimeSlotSummary(
                          slot: activeSlot,
                          record:
                              widget.session.turnoutRecords[activeSlot.slotId],
                          onExpand: () =>
                              setState(() => _isTimeSlotExpanded = true),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              for (final TurnoutSlotDefinition slot in otherSlots) ...<Widget>[
                PresidingTurnoutCard(
                  key: ValueKey<String>(slot.slotId),
                  title: slot.labelKey.tr(),
                  slotId: slot.slotId,
                  queueOnly: slot.queueOnly,
                  isExpanded: _isOtherSlotExpanded(slot.slotId),
                  onExpansionChanged: (bool expanded) {
                    _setOtherSlotExpanded(slot.slotId, expanded);
                  },
                  initialRecord: widget.session.turnoutRecords[slot.slotId],
                  mode: PresidingTurnoutCardMode.entry,
                  onSave:
                      ({
                        int? male,
                        int? female,
                        int? thirdGender,
                        int? queueCount,
                      }) {
                        return controller.saveTurnout(
                          slotId: slot.slotId,
                          male: male,
                          female: female,
                          thirdGender: thirdGender,
                          queueCount: queueCount,
                        );
                      },
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Get.back<void>(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(
                        LocaleKeys.presidingBack.tr(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.greenLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: allSlotsSaved ? () => Get.back<void>() : null,
                      icon: const Icon(Icons.check_box_outlined, size: 18),
                      label: Text(
                        LocaleKeys.presidingFinishAndBack.tr(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PresidingUiTokens.actionGreen,
                        side: BorderSide(color: PresidingUiTokens.actionGreen),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: PresidingUiTokens.finishButtonSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TurnoutTimeTabBar extends StatelessWidget {
  const _TurnoutTimeTabBar({
    required this.slots,
    required this.selectedSlotId,
    required this.isExpanded,
    required this.records,
    required this.onSelected,
  });

  final List<TurnoutSlotDefinition> slots;
  final String selectedSlotId;
  final bool isExpanded;
  final Map<String, TurnoutRecord> records;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: slots
            .map((TurnoutSlotDefinition slot) {
              final bool selected = slot.slotId == selectedSlotId;
              final TurnoutRecord? record = records[slot.slotId];
              final bool saved = record?.savedAt != null;
              final bool locked = record?.isLocked ?? false;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onSelected(slot.slotId),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? PresidingUiTokens.actionGreen
                          : AppColors.slate100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? PresidingUiTokens.actionGreen
                            : AppColors.slate200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (locked)
                          Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: selected ? Colors.white : AppColors.slate500,
                          )
                        else if (saved)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: selected ? Colors.white : AppColors.success,
                          ),
                        if (locked || saved) const SizedBox(width: 4),
                        Text(
                          slot.labelKey.tr(),
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : AppColors.slate700,
                          ),
                        ),
                        if (selected) ...<Widget>[
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _CollapsedTimeSlotSummary extends StatelessWidget {
  const _CollapsedTimeSlotSummary({
    required this.slot,
    required this.record,
    required this.onExpand,
  });

  final TurnoutSlotDefinition slot;
  final TurnoutRecord? record;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final int total =
        (record?.male ?? 0) +
        (record?.female ?? 0) +
        (record?.thirdGender ?? 0);
    final bool saved = record?.savedAt != null;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        onTap: onExpand,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                saved
                    ? Icons.check_circle_rounded
                    : Icons.pending_actions_rounded,
                color: saved ? AppColors.success : AppColors.slate400,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      slot.labelKey.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (saved)
                      Text(
                        LocaleKeys.presidingTotalVotesSummary.tr(
                          args: <String>['$total'],
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.slate500,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
