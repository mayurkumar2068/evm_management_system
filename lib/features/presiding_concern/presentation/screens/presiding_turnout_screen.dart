import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/presiding_concern/di/presiding_concern_module.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_action_outcome.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/presiding_concern/domain/turnout_count_validator.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_po_screen_header.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_session_scaffold.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_turnout_card.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_theme_button.dart';
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
  bool _submittingFinish = false;

  bool get _isTurnoutSubmitted {
    return widget.session.milestones.any(
      (PresidingMilestone m) =>
          m.id == PresidingMilestoneIds.twoHourlyInfo && m.isCompleted,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedSlotId = TurnoutSlotIds.slot9Am;
  }

  void _handleTimeTabTap(String slotId) {
    if (_isTurnoutSubmitted) return;
    if (!_canSelectHourly(slotId)) return;
    setState(() {
      if (_selectedSlotId == slotId) {
        _isTimeSlotExpanded = !_isTimeSlotExpanded;
      } else {
        _selectedSlotId = slotId;
        _isTimeSlotExpanded = true;
      }
    });
  }

  bool _isHourlyClosed(String slotId) {
    if (_isTurnoutSubmitted) return true;
    return TurnoutCountValidator.isHourlySlotClosed(
      session: widget.session,
      slotId: slotId,
    );
  }

  bool _canSelectHourly(String slotId) {
    if (_isTurnoutSubmitted) return false;
    final bool lockedByLater =
        TurnoutCountValidator.isEarlierHourlyLockedByLaterSave(
      session: widget.session,
      slotId: slotId,
    );
    final bool saved =
        widget.session.turnoutRecords[slotId]?.savedAt != null;
    // Skipped earlier hour (never saved) cannot be opened after a later save.
    if (lockedByLater && !saved) return false;
    return true;
  }

  void _nudgeSelectionIfNeeded() {
    final List<TurnoutSlotDefinition> timeSlots = _timeSlotsFor(
      widget.session.areaType,
    );
    if (timeSlots.isEmpty) return;
    if (_canSelectHourly(_selectedSlotId) &&
        timeSlots.any(
          (TurnoutSlotDefinition s) => s.slotId == _selectedSlotId,
        )) {
      return;
    }
    for (int i = timeSlots.length - 1; i >= 0; i--) {
      final String id = timeSlots[i].slotId;
      if (widget.session.turnoutRecords[id]?.savedAt != null) {
        _selectedSlotId = id;
        return;
      }
    }
    _selectedSlotId = timeSlots.first.slotId;
  }

  bool _isOtherSlotExpanded(String slotId) {
    return _otherSlotExpanded[slotId] ?? false;
  }

  void _setOtherSlotExpanded(String slotId, bool expanded) {
    if (_isTurnoutSubmitted) return;
    if (expanded &&
        !TurnoutCountValidator.isLastTimeSlotSaved(widget.session)) {
      final String? lastId =
          TurnoutCountValidator.lastTimeSlotId(widget.session.areaType);
      final String messageKey = lastId == TurnoutSlotIds.slot5Pm
          ? LocaleKeys.presidingFill5PmBeforeNext
          : LocaleKeys.presidingFill3PmBeforeNext;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageKey.tr())),
      );
      return;
    }
    setState(() => _otherSlotExpanded[slotId] = expanded);
  }

  Future<void> _finishAndBack() async {
    if (_submittingFinish || _isTurnoutSubmitted) return;
    setState(() => _submittingFinish = true);
    try {
      final PresidingDashboardController dashboard =
          Get.find<PresidingDashboardController>();
      final PresidingActionOutcome outcome = await dashboard.completeMilestone(
        PresidingMilestoneIds.twoHourlyInfo,
      );
      if (!mounted) return;
      final bool twoHourlyDone = outcome.session.milestones.any(
        (PresidingMilestone m) =>
            m.id == PresidingMilestoneIds.twoHourlyInfo && m.isCompleted,
      );
      if (!twoHourlyDone) {
        if (outcome.message != null && outcome.message!.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(outcome.message!.tr())));
        }
        return;
      }
      // Lock live जानकारी too — same submit boundary as 2–2 hourly.
      await dashboard.completeMilestone(PresidingMilestoneIds.livePollInfo);
      if (!mounted) return;
      // Auto-complete मतदान समाप्त (API) so machine seal can unlock next.
      await dashboard.completeMilestone(PresidingMilestoneIds.pollEnd);
      if (!mounted) return;
      Get.back<void>();
    } finally {
      if (mounted) setState(() => _submittingFinish = false);
    }
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
    _nudgeSelectionIfNeeded();
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
    final bool turnoutSubmitted = _isTurnoutSubmitted;
    final bool lastHourlySaved =
        TurnoutCountValidator.isLastTimeSlotSaved(widget.session);
    final bool allSlotsSaved = allSlots.every((TurnoutSlotDefinition slot) {
      if (slot.queueOnly || slot.slotId == TurnoutSlotIds.pollCompletion) {
        return widget.session.turnoutRecords[slot.slotId]?.savedAt != null;
      }
      return TurnoutCountValidator.isHourlySlotSatisfied(
        session: widget.session,
        slotId: slot.slotId,
      );
    });
    final String stationLabel =
        widget.session.pollingStationName.startsWith('presiding.')
        ? widget.session.pollingStationName.tr()
        : widget.session.pollingStationName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PresidingPoScreenHeader(
          leading: AppCircleBackButton(onTap: () => Get.back<void>()),
          title: LocaleKeys.presidingOfficerTitle.tr(),
          subtitle: LocaleKeys.presidingPollingStation.tr(
            args: <String>[
              widget.session.pollingStationCode,
              stationLabel,
            ],
          ),
        ),
        // Last label kept outside the gradient header.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            LocaleKeys.presidingEnterInfo.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.slate700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: <Widget>[
              if (activeSlot != null) ...<Widget>[
                AppCard(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
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
                            visualDensity: VisualDensity.compact,
                            tooltip: _isTimeSlotExpanded
                                ? LocaleKeys.presidingCollapse.tr()
                                : LocaleKeys.presidingExpand.tr(),
                            onPressed: () {
                              if (turnoutSubmitted) return;
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
                      _TurnoutTimeTabBar(
                        slots: timeSlots,
                        selectedSlotId: _selectedSlotId,
                        isExpanded: _isTimeSlotExpanded,
                        records: widget.session.turnoutRecords,
                        canSelect: _canSelectHourly,
                        isLocked: _isHourlyClosed,
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
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            PresidingTurnoutCard(
                              key: ValueKey<String>(activeSlot.slotId),
                              title: activeSlot.labelKey.tr(),
                              slotId: activeSlot.slotId,
                              embedded: true,
                              initialRecord: widget
                                  .session
                                  .turnoutRecords[activeSlot.slotId],
                              forceReadOnly: turnoutSubmitted ||
                                  _isHourlyClosed(activeSlot.slotId),
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
                          onExpand: () {
                            if (turnoutSubmitted) return;
                            if (!_canSelectHourly(activeSlot.slotId) &&
                                !_isHourlyClosed(activeSlot.slotId)) {
                              return;
                            }
                            setState(() => _isTimeSlotExpanded = true);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              for (final TurnoutSlotDefinition slot in otherSlots) ...<Widget>[
                PresidingTurnoutCard(
                  key: ValueKey<String>(slot.slotId),
                  title: slot.labelKey.tr(),
                  slotId: slot.slotId,
                  queueOnly: slot.queueOnly,
                  isExpanded:
                      lastHourlySaved && _isOtherSlotExpanded(slot.slotId),
                  interactionEnabled: lastHourlySaved && !turnoutSubmitted,
                  onExpansionChanged: (bool expanded) {
                    _setOtherSlotExpanded(slot.slotId, expanded);
                  },
                  initialRecord: widget.session.turnoutRecords[slot.slotId],
                  forceReadOnly: turnoutSubmitted || !lastHourlySaved,
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
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Expanded(
                    child: PresidingThemeButton(
                      onPressed: () => Get.back<void>(),
                      icon: Icons.arrow_back_rounded,
                      label: LocaleKeys.presidingBack.tr(),
                      height: 50,
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PresidingThemeButton(
                      onPressed: allSlotsSaved && !turnoutSubmitted
                          ? _finishAndBack
                          : null,
                      icon: Icons.check_circle_outline_rounded,
                      label: LocaleKeys.presidingFinishAndBack.tr(),
                      height: 50,
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
    required this.canSelect,
    required this.isLocked,
    required this.onSelected,
  });

  final List<TurnoutSlotDefinition> slots;
  final String selectedSlotId;
  final bool isExpanded;
  final Map<String, TurnoutRecord> records;
  final bool Function(String slotId) canSelect;
  final bool Function(String slotId) isLocked;
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
              final bool locked = isLocked(slot.slotId);
              final bool selectable = canSelect(slot.slotId);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Opacity(
                  opacity: selectable || selected ? 1 : 0.45,
                  child: InkWell(
                    onTap: selectable ? () => onSelected(slot.slotId) : null,
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: selected ? AppGradients.primaryButton : null,
                        color: selected ? null : AppColors.slate100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.35)
                              : AppColors.slate200,
                        ),
                        boxShadow: selected
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.22,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (locked)
                            Icon(
                              Icons.lock_rounded,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : AppColors.slate500,
                            )
                          else if (saved)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          if (locked || saved) const SizedBox(width: 4),
                          Text(
                            slot.labelKey.tr(),
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : selectable
                                  ? AppColors.slate700
                                  : AppColors.slate400,
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
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: onExpand,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
