import 'package:evm_management_system/features/presiding_concern/domain/constants/presiding_area_type.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_ids.dart';

/// Lifecycle state of a presiding-officer milestone.
enum PresidingMilestoneState { pending, completed }

/// A single presiding-officer checkpoint with optional completion timestamp.
final class PresidingMilestone {
  const PresidingMilestone({
    required this.id,
    required this.sectionId,
    required this.labelKey,
    required this.state,
    this.completedAt,
    this.opensTurnout = false,
    this.pendingSync = false,
  });

  final String id;
  final String sectionId;
  final String labelKey;
  final PresidingMilestoneState state;
  final DateTime? completedAt;
  final bool opensTurnout;
  final bool pendingSync;

  bool get isCompleted => state == PresidingMilestoneState.completed;

  PresidingMilestone copyWith({
    PresidingMilestoneState? state,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? pendingSync,
  }) {
    return PresidingMilestone(
      id: id,
      sectionId: sectionId,
      labelKey: labelKey,
      state: state ?? this.state,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      opensTurnout: opensTurnout,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}

/// Turnout slot metadata for presiding-officer reporting UI.
final class TurnoutSlotDefinition {
  const TurnoutSlotDefinition({
    required this.slotId,
    required this.labelKey,
    this.queueOnly = false,
  });

  final String slotId;
  final String labelKey;
  final bool queueOnly;
}

/// Ordered turnout slots shown on the presiding turnout screen.
abstract final class TurnoutSlots {
  static const List<TurnoutSlotDefinition> _baseSlots = <TurnoutSlotDefinition>[
    TurnoutSlotDefinition(
      slotId: TurnoutSlotIds.slot9Am,
      labelKey: TurnoutSlotLabelKeys.slot9Am,
    ),
    TurnoutSlotDefinition(
      slotId: TurnoutSlotIds.slot11Am,
      labelKey: TurnoutSlotLabelKeys.slot11Am,
    ),
    TurnoutSlotDefinition(
      slotId: TurnoutSlotIds.slot1Pm,
      labelKey: TurnoutSlotLabelKeys.slot1Pm,
    ),
    TurnoutSlotDefinition(
      slotId: TurnoutSlotIds.slot3Pm,
      labelKey: TurnoutSlotLabelKeys.slot3Pm,
    ),
  ];

  static const TurnoutSlotDefinition _slot5Pm = TurnoutSlotDefinition(
    slotId: TurnoutSlotIds.slot5Pm,
    labelKey: TurnoutSlotLabelKeys.slot5Pm,
  );

  static const TurnoutSlotDefinition _queueCount = TurnoutSlotDefinition(
    slotId: TurnoutSlotIds.queueCount,
    labelKey: TurnoutSlotLabelKeys.queueCount,
    queueOnly: true,
  );

  static const TurnoutSlotDefinition _pollCompletion = TurnoutSlotDefinition(
    slotId: TurnoutSlotIds.pollCompletion,
    labelKey: TurnoutSlotLabelKeys.pollCompletion,
  );

  /// Rural: up to 3 PM. Urban: up to 5 PM. Both end with queue + final count.
  /// Missing/unknown area type is treated as rural (no 5PM).
  static List<TurnoutSlotDefinition> forAreaType(String? areaType) {
    final PresidingAreaType resolved = PresidingAreaType.parse(
      areaType,
      fallback: PresidingAreaType.rural,
    );
    return <TurnoutSlotDefinition>[
      ..._baseSlots,
      if (resolved.isUrban) _slot5Pm,
      _queueCount,
      _pollCompletion,
    ];
  }
}
