import 'package:evm_management_system/features/presiding_concern/domain/constants/presiding_area_type.dart';

/// Identifiers for presiding-officer workflow milestones.
abstract final class PresidingMilestoneIds {
  static const String leftMaterialCenter = 'left_material_center';
  static const String reachedPollingStation = 'reached_polling_station';
  static const String materialReceived = 'material_received';
  static const String mockPoll = 'mock_poll';
  static const String pollStart = 'poll_start';
  static const String twoHourlyInfo = 'two_hourly_info';
  static const String livePollInfo = 'live_poll_info';
  static const String pollEnd = 'poll_end';
  static const String machineSealed = 'machine_sealed';
  static const String materialHandedOver = 'material_handed_over';
}

/// Section groupings for the presiding-officer dashboard.
abstract final class PresidingSectionIds {
  static const String arrival = 'arrival';
  static const String prePoll = 'pre_poll';
  static const String duringPoll = 'during_poll';
  static const String postPoll = 'post_poll';
}

/// Turnout slot identifiers for interval reporting.
abstract final class TurnoutSlotIds {
  static const String slot9Am = 'slot_9am';
  static const String slot11Am = 'slot_11am';
  static const String slot1Pm = 'slot_1pm';
  static const String slot3Pm = 'slot_3pm';
  static const String slot5Pm = 'slot_5pm';
  static const String queueCount = 'queue_count';
  static const String pollCompletion = 'poll_completion';
  static const String livePollInfo = 'live_poll_info';
}

/// Localization keys for turnout slot labels (resolved via `.tr()` in UI).
abstract final class TurnoutSlotLabelKeys {
  static const String slot9Am = 'presiding.slot_9am';
  static const String slot11Am = 'presiding.slot_11am';
  static const String slot1Pm = 'presiding.slot_1pm';
  static const String slot3Pm = 'presiding.slot_3pm';
  static const String slot5Pm = 'presiding.slot_5pm';
  static const String queueCount = 'presiding.queue_count';
  static const String pollCompletion = 'presiding.poll_completion';
  static const String livePollInfo = 'presiding.milestones.live_poll_info';
}

/// Default presiding session seed values stored as localization keys.
abstract final class PresidingDefaults {
  static const String stationNameKey = 'presiding.default_station';
}

/// i18n keys for milestone labels persisted in session JSON.
abstract final class PresidingMilestoneLabelKeys {
  static const String leftMaterialCenter =
      'presiding.milestones.left_material_center';
  static const String reachedPollingStation =
      'presiding.milestones.reached_polling_station';
  static const String materialReceived =
      'presiding.milestones.material_received';
  static const String mockPoll = 'presiding.milestones.mock_poll';
  static const String pollStart = 'presiding.milestones.poll_start';
  static const String twoHourlyInfo = 'presiding.milestones.two_hourly_info';
  static const String livePollInfo = 'presiding.milestones.live_poll_info';
  static const String pollEnd = 'presiding.milestones.poll_end';
  static const String machineSealed = 'presiding.milestones.machine_sealed';
  static const String materialHandedOver =
      'presiding.milestones.material_handed_over';
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
  static List<TurnoutSlotDefinition> forAreaType(String? areaType) {
    final PresidingAreaType resolved = PresidingAreaType.parse(areaType);
    return <TurnoutSlotDefinition>[
      ..._baseSlots,
      if (resolved.isUrban) _slot5Pm,
      _queueCount,
      _pollCompletion,
    ];
  }
}

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
    bool? pendingSync,
  }) {
    return PresidingMilestone(
      id: id,
      sectionId: sectionId,
      labelKey: labelKey,
      state: state ?? this.state,
      completedAt: completedAt ?? this.completedAt,
      opensTurnout: opensTurnout,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}

/// Voter turnout figures captured at a time interval.
final class TurnoutRecord {
  const TurnoutRecord({
    required this.slotId,
    this.male,
    this.female,
    this.thirdGender,
    this.queueCount,
    this.savedAt,
    this.pendingSync = true,
    this.isLocked = false,
  });

  final String slotId;
  final int? male;
  final int? female;
  final int? thirdGender;
  final int? queueCount;
  final DateTime? savedAt;
  final bool pendingSync;
  final bool isLocked;

  bool get isQueueOnly => slotId == TurnoutSlotIds.queueCount;

  TurnoutRecord copyWith({
    int? male,
    int? female,
    int? thirdGender,
    int? queueCount,
    DateTime? savedAt,
    bool? pendingSync,
    bool? isLocked,
  }) {
    return TurnoutRecord(
      slotId: slotId,
      male: male ?? this.male,
      female: female ?? this.female,
      thirdGender: thirdGender ?? this.thirdGender,
      queueCount: queueCount ?? this.queueCount,
      savedAt: savedAt ?? this.savedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

/// Active presiding-officer session context for a polling station.
final class PresidingSession {
  const PresidingSession({
    required this.electionId,
    required this.psId,
    required this.areaType,
    required this.pollingStationCode,
    required this.pollingStationName,
    required this.milestones,
    required this.turnoutRecords,
  });

  final int? electionId;
  final String? psId;
  final String? areaType;
  final String pollingStationCode;
  final String pollingStationName;
  final List<PresidingMilestone> milestones;
  final Map<String, TurnoutRecord> turnoutRecords;

  bool get hasElectionContext =>
      (electionId ?? 0) > 0 &&
      (psId?.isNotEmpty ?? false) &&
      (areaType?.isNotEmpty ?? false);

  PresidingSession copyWith({
    int? electionId,
    String? psId,
    String? areaType,
    String? pollingStationCode,
    String? pollingStationName,
    List<PresidingMilestone>? milestones,
    Map<String, TurnoutRecord>? turnoutRecords,
  }) {
    return PresidingSession(
      electionId: electionId ?? this.electionId,
      psId: psId ?? this.psId,
      areaType: areaType ?? this.areaType,
      pollingStationCode: pollingStationCode ?? this.pollingStationCode,
      pollingStationName: pollingStationName ?? this.pollingStationName,
      milestones: milestones ?? this.milestones,
      turnoutRecords: turnoutRecords ?? this.turnoutRecords,
    );
  }
}
