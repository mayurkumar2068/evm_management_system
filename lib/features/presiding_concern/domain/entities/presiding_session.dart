import 'package:evm_management_system/core/time/app_time_zone.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_ids.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_milestone.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/turnout_record.dart';

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
    this.loginUserName,
  });

  final int? electionId;
  final String? psId;
  final String? areaType;
  final String pollingStationCode;
  final String pollingStationName;
  final List<PresidingMilestone> milestones;
  final Map<String, TurnoutRecord> turnoutRecords;

  /// PO login username (`UserName`). Used for test-account bypasses.
  final String? loginUserName;

  /// Mock-poll next-day / 7 AM gates are skipped for every PO.
  bool get bypassesMockPollRules => true;

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

  /// Timestamp when "मतदान केंद्र पहुंचे" was marked, if known.
  DateTime? get reachedPollingStationAt {
    for (final PresidingMilestone milestone in milestones) {
      if (milestone.id == PresidingMilestoneIds.reachedPollingStation) {
        return milestone.isCompleted ? milestone.completedAt : null;
      }
    }
    return null;
  }

  /// IST wall-clock check: मॉक पोल / मतदान cannot run before 7:00 AM.
  static bool isPollStartTimeAllowed([DateTime? now]) {
    final DateTime ist = now ?? AppTimeZone.now();
    return ist.hour >= pollStartEarliestHour;
  }

  /// Mock poll is allowed only from the calendar day AFTER reaching the station.
  ///
  /// Same IST day as "मतदान केंद्र पहुंचे" stays blocked.
  bool isMockPollDayAllowed([DateTime? now]) {
    if (!hasReachedPollingStation) return false;
    final DateTime? reachedAt = reachedPollingStationAt;
    if (reachedAt == null) return true;
    final DateTime reachedDay = AppTimeZone.calendarDate(reachedAt);
    final DateTime today = AppTimeZone.calendarDate(now);
    return today.isAfter(reachedDay);
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

  /// After मतदान समाप्त, freeze 2–2 hourly + live and lock live counts.
  /// Dashboard chips then render as completed instead of enabled actions.
  PresidingSession completeDuringPollIfPollEnded() {
    if (!_isMilestoneCompleted(PresidingMilestoneIds.pollEnd)) return this;

    DateTime? latestHourly;
    for (final MapEntry<String, TurnoutRecord> entry in turnoutRecords.entries) {
      if (entry.key == TurnoutSlotIds.livePollInfo) continue;
      final DateTime? savedAt = entry.value.savedAt;
      if (savedAt == null) continue;
      if (latestHourly == null || savedAt.isAfter(latestHourly)) {
        latestHourly = savedAt;
      }
    }

    DateTime? pollEndedAt;
    for (final PresidingMilestone milestone in milestones) {
      if (milestone.id == PresidingMilestoneIds.pollEnd) {
        pollEndedAt = milestone.completedAt;
        break;
      }
    }

    final TurnoutRecord? live = turnoutRecords[TurnoutSlotIds.livePollInfo];
    final bool hasLiveCounts = (live?.male ?? 0) > 0 ||
        (live?.female ?? 0) > 0 ||
        (live?.thirdGender ?? 0) > 0;

    bool changed = false;
    final List<PresidingMilestone> nextMilestones = milestones.map((
      PresidingMilestone item,
    ) {
      if (item.id == PresidingMilestoneIds.twoHourlyInfo && !item.isCompleted) {
        changed = true;
        return item.copyWith(
          state: PresidingMilestoneState.completed,
          completedAt: latestHourly ?? pollEndedAt ?? DateTime.now(),
          pendingSync: false,
        );
      }
      if (item.id == PresidingMilestoneIds.livePollInfo && !item.isCompleted) {
        changed = true;
        final DateTime? liveAt = hasLiveCounts
            ? (live?.savedAt ?? pollEndedAt)
            : pollEndedAt;
        if (liveAt == null) {
          return item.copyWith(
            state: PresidingMilestoneState.completed,
            clearCompletedAt: true,
            pendingSync: false,
          );
        }
        return item.copyWith(
          state: PresidingMilestoneState.completed,
          completedAt: liveAt,
          pendingSync: false,
        );
      }
      return item;
    }).toList(growable: false);

    Map<String, TurnoutRecord> nextTurnout = turnoutRecords;
    if (live != null && !live.isLocked) {
      nextTurnout = Map<String, TurnoutRecord>.from(nextTurnout)
        ..[TurnoutSlotIds.livePollInfo] = live.copyWith(isLocked: true);
      changed = true;
    } else if (live == null) {
      nextTurnout = Map<String, TurnoutRecord>.from(nextTurnout)
        ..[TurnoutSlotIds.livePollInfo] = const TurnoutRecord(
          slotId: TurnoutSlotIds.livePollInfo,
          isLocked: true,
        );
      changed = true;
    }

    return changed
        ? copyWith(milestones: nextMilestones, turnoutRecords: nextTurnout)
        : this;
  }

  /// Locale key when [milestoneId] cannot be actioned, else `null`.
  String? milestoneActionBlockKey(String milestoneId) {
    if (milestoneId == PresidingMilestoneIds.twoHourlyInfo ||
        milestoneId == PresidingMilestoneIds.livePollInfo) {
      if (!_isMilestoneCompleted(PresidingMilestoneIds.pollStart)) {
        return 'presiding.reach_station_first';
      }
      // मतदान समाप्त के बाद ये बटन actionable नहीं रहने चाहिए।
      if (_isMilestoneCompleted(PresidingMilestoneIds.pollEnd)) {
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
    if (milestoneId == PresidingMilestoneIds.mockPoll &&
        !bypassesMockPollRules &&
        !isMockPollDayAllowed()) {
      return 'presiding.mock_poll_next_day';
    }
    if ((milestoneId == PresidingMilestoneIds.mockPoll ||
            milestoneId == PresidingMilestoneIds.pollStart) &&
        !isPollStartTimeAllowed()) {
      if (milestoneId == PresidingMilestoneIds.mockPoll &&
          bypassesMockPollRules) {
        return null;
      }
      return milestoneId == PresidingMilestoneIds.mockPoll
          ? 'presiding.mock_poll_before_7am'
          : 'presiding.poll_start_before_7am';
    }
    return null;
  }

  /// Gates later milestones until earlier ones are completed, in order.
  /// मॉक पोल is blocked on the arrival day, then before 7:00 AM IST next day.
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
    String? loginUserName,
  }) {
    return PresidingSession(
      electionId: electionId ?? this.electionId,
      psId: psId ?? this.psId,
      areaType: areaType ?? this.areaType,
      pollingStationCode: pollingStationCode ?? this.pollingStationCode,
      pollingStationName: pollingStationName ?? this.pollingStationName,
      milestones: milestones ?? this.milestones,
      turnoutRecords: turnoutRecords ?? this.turnoutRecords,
      loginUserName: loginUserName ?? this.loginUserName,
    );
  }
}
