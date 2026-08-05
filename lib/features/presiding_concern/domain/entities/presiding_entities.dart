import 'package:evm_management_system/core/time/app_time_zone.dart';
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

  bool get isLivePoll => slotId == TurnoutSlotIds.livePollInfo;

  /// Hourly/queue slots lock after save. Live poll stays editable until locked
  /// (when 2–2 hourly turnout is submitted / live milestone completed).
  bool get isReadOnly {
    if (isLivePoll) return isLocked;
    return isLocked || savedAt != null;
  }

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

  /// Earliest allowed clock hour (IST) for मॉक पोल and मतदान प्रारम्भ.
  static const int pollStartEarliestHour = 7;

  /// True once "मतदान केंद्र पहुंचे" has been marked complete.
  bool get hasReachedPollingStation => milestones.any(
        (PresidingMilestone m) =>
            m.id == PresidingMilestoneIds.reachedPollingStation &&
            m.isCompleted,
      );

  /// IST wall-clock check: मॉक पोल / मतदान cannot run before 7:00 AM.
  static bool isPollStartTimeAllowed([DateTime? now]) {
    final DateTime ist = now ?? AppTimeZone.now();
    return ist.hour >= pollStartEarliestHour;
  }

  /// Milestones that must be completed in order (one-by-one).
  /// After 2–2 hourly submit, machine seal unlocks (poll-end is not a UI step).
  static const List<String> sequentialMilestoneIds = <String>[
    PresidingMilestoneIds.leftMaterialCenter,
    PresidingMilestoneIds.materialReceived,
    PresidingMilestoneIds.reachedPollingStation,
    PresidingMilestoneIds.mockPoll,
    PresidingMilestoneIds.pollStart,
    PresidingMilestoneIds.twoHourlyInfo,
    PresidingMilestoneIds.machineSealed,
    PresidingMilestoneIds.materialHandedOver,
  ];

  /// Locale key when [milestoneId] cannot be actioned, else `null`.
  String? milestoneActionBlockKey(String milestoneId) {
    if (milestoneId == PresidingMilestoneIds.twoHourlyInfo ||
        milestoneId == PresidingMilestoneIds.livePollInfo) {
      if (!_isMilestoneCompleted(PresidingMilestoneIds.pollStart)) {
        return 'presiding.reach_station_first';
      }
      return null;
    }
    // Machine seal unlocks only after 2–2 hourly + live are submitted.
    if (milestoneId == PresidingMilestoneIds.machineSealed) {
      if (!_isMilestoneCompleted(PresidingMilestoneIds.twoHourlyInfo) ||
          !_isMilestoneCompleted(PresidingMilestoneIds.livePollInfo)) {
        return 'presiding.reach_station_first';
      }
    }
    // Hidden poll-end step: auto-completed from 2–2 finish, not shown in UI.
    if (milestoneId == PresidingMilestoneIds.pollEnd) {
      if (!_isMilestoneCompleted(PresidingMilestoneIds.twoHourlyInfo) ||
          !_isMilestoneCompleted(PresidingMilestoneIds.livePollInfo)) {
        return 'presiding.reach_station_first';
      }
      return null;
    }

    final int index = sequentialMilestoneIds.indexOf(milestoneId);
    if (index < 0) {
      return 'presiding.reach_station_first';
    }
    for (int i = 0; i < index; i++) {
      if (!_isMilestoneCompleted(sequentialMilestoneIds[i])) {
        return 'presiding.reach_station_first';
      }
    }
    if ((milestoneId == PresidingMilestoneIds.mockPoll ||
            milestoneId == PresidingMilestoneIds.pollStart) &&
        !isPollStartTimeAllowed()) {
      return milestoneId == PresidingMilestoneIds.mockPoll
          ? 'presiding.mock_poll_before_7am'
          : 'presiding.poll_start_before_7am';
    }
    return null;
  }

  /// Gates later milestones until earlier ones are completed, in order.
  /// मॉक पोल and मतदान प्रारम्भ are also blocked before 7:00 AM IST.
  bool isMilestoneActionEnabled(String milestoneId) =>
      milestoneActionBlockKey(milestoneId) == null;

  bool _isMilestoneCompleted(String milestoneId) {
    for (final PresidingMilestone milestone in milestones) {
      if (milestone.id == milestoneId) {
        return milestone.isCompleted;
      }
    }
    return false;
  }

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
