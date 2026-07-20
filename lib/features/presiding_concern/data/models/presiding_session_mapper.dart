import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';

/// Serialises presiding-officer entities to JSON for local storage.
abstract final class PresidingSessionMapper {
  static const String _milestonesKey = 'milestones';
  static const String _turnoutKey = 'turnout';
  static const String _stationCodeKey = 'polling_station_code';
  static const String _stationNameKey = 'polling_station_name';
  static const String _electionIdKey = 'election_id';
  static const String _psIdKey = 'ps_id';
  static const String _areaTypeKey = 'area_type';

  /// Seeds the default milestone catalogue matching the legacy workflow.
  static List<PresidingMilestone> defaultMilestones() {
    return <PresidingMilestone>[
      const PresidingMilestone(
        id: PresidingMilestoneIds.leftMaterialCenter,
        sectionId: PresidingSectionIds.arrival,
        labelKey: PresidingMilestoneLabelKeys.leftMaterialCenter,
        state: PresidingMilestoneState.pending,
      ),
      const PresidingMilestone(
        id: PresidingMilestoneIds.reachedPollingStation,
        sectionId: PresidingSectionIds.arrival,
        labelKey: PresidingMilestoneLabelKeys.reachedPollingStation,
        state: PresidingMilestoneState.pending,
      ),
      const PresidingMilestone(
        id: PresidingMilestoneIds.materialReceived,
        sectionId: PresidingSectionIds.prePoll,
        labelKey: PresidingMilestoneLabelKeys.materialReceived,
        state: PresidingMilestoneState.pending,
      ),
      const PresidingMilestone(
        id: PresidingMilestoneIds.mockPoll,
        sectionId: PresidingSectionIds.prePoll,
        labelKey: PresidingMilestoneLabelKeys.mockPoll,
        state: PresidingMilestoneState.pending,
      ),
      const PresidingMilestone(
        id: PresidingMilestoneIds.pollStart,
        sectionId: PresidingSectionIds.prePoll,
        labelKey: PresidingMilestoneLabelKeys.pollStart,
        state: PresidingMilestoneState.pending,
      ),
      const PresidingMilestone(
        id: PresidingMilestoneIds.twoHourlyInfo,
        sectionId: PresidingSectionIds.duringPoll,
        labelKey: PresidingMilestoneLabelKeys.twoHourlyInfo,
        state: PresidingMilestoneState.pending,
        opensTurnout: true,
      ),
      const PresidingMilestone(
        id: PresidingMilestoneIds.livePollInfo,
        sectionId: PresidingSectionIds.duringPoll,
        labelKey: PresidingMilestoneLabelKeys.livePollInfo,
        state: PresidingMilestoneState.pending,
        opensTurnout: true,
      ),
      const PresidingMilestone(
        id: PresidingMilestoneIds.pollEnd,
        sectionId: PresidingSectionIds.postPoll,
        labelKey: PresidingMilestoneLabelKeys.pollEnd,
        state: PresidingMilestoneState.pending,
      ),
      const PresidingMilestone(
        id: PresidingMilestoneIds.machineSealed,
        sectionId: PresidingSectionIds.postPoll,
        labelKey: PresidingMilestoneLabelKeys.machineSealed,
        state: PresidingMilestoneState.pending,
      ),
      const PresidingMilestone(
        id: PresidingMilestoneIds.materialHandedOver,
        sectionId: PresidingSectionIds.postPoll,
        labelKey: PresidingMilestoneLabelKeys.materialHandedOver,
        state: PresidingMilestoneState.pending,
      ),
    ];
  }

  /// Converts a [PresidingSession] to a JSON map.
  static Map<String, dynamic> toJson(PresidingSession session) {
    return <String, dynamic>{
      if (session.electionId != null) _electionIdKey: session.electionId,
      if (session.psId != null) _psIdKey: session.psId,
      if (session.areaType != null) _areaTypeKey: session.areaType,
      _stationCodeKey: session.pollingStationCode,
      _stationNameKey: session.pollingStationName,
      _milestonesKey: session.milestones.map(_milestoneToJson).toList(),
      _turnoutKey: session.turnoutRecords.map(
        (String key, TurnoutRecord value) =>
            MapEntry<String, dynamic>(key, _turnoutToJson(value)),
      ),
    };
  }

  /// Parses a JSON map into a [PresidingSession].
  static PresidingSession fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawMilestones =
        json[_milestonesKey] as List<dynamic>? ?? <dynamic>[];
    final Map<String, dynamic> rawTurnout =
        (json[_turnoutKey] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return PresidingSession(
      electionId:
          json[_electionIdKey] as int? ??
          int.tryParse('${json[_electionIdKey] ?? ''}'),
      psId: json[_psIdKey] as String?,
      areaType: json[_areaTypeKey] as String?,
      pollingStationCode: json[_stationCodeKey] as String? ?? '',
      pollingStationName:
          json[_stationNameKey] as String? ?? PresidingDefaults.stationNameKey,
      milestones: rawMilestones.isEmpty
          ? defaultMilestones()
          : rawMilestones
                .map(
                  (dynamic e) => _milestoneFromJson(e as Map<String, dynamic>),
                )
                .toList(),
      turnoutRecords: rawTurnout.map(
        (String key, dynamic value) => MapEntry<String, TurnoutRecord>(
          key,
          _turnoutFromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  static Map<String, dynamic> _milestoneToJson(PresidingMilestone milestone) {
    return <String, dynamic>{
      'id': milestone.id,
      'section_id': milestone.sectionId,
      'label_key': milestone.labelKey,
      'state': milestone.state.name,
      'completed_at': milestone.completedAt?.toIso8601String(),
      'opens_turnout': milestone.opensTurnout,
      'pending_sync': milestone.pendingSync,
    };
  }

  static PresidingMilestone _milestoneFromJson(Map<String, dynamic> json) {
    return PresidingMilestone(
      id: json['id'] as String,
      sectionId: json['section_id'] as String,
      labelKey: json['label_key'] as String,
      state: PresidingMilestoneState.values.byName(
        json['state'] as String? ?? PresidingMilestoneState.pending.name,
      ),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.tryParse(json['completed_at'] as String),
      opensTurnout: json['opens_turnout'] as bool? ?? false,
      pendingSync: json['pending_sync'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _turnoutToJson(TurnoutRecord record) {
    return <String, dynamic>{
      'slot_id': record.slotId,
      'male': record.male,
      'female': record.female,
      'third_gender': record.thirdGender,
      'queue_count': record.queueCount,
      'saved_at': record.savedAt?.toIso8601String(),
      'pending_sync': record.pendingSync,
      'is_locked': record.isLocked,
    };
  }

  static TurnoutRecord _turnoutFromJson(Map<String, dynamic> json) {
    return TurnoutRecord(
      slotId: json['slot_id'] as String,
      male: json['male'] as int?,
      female: json['female'] as int?,
      thirdGender: json['third_gender'] as int?,
      queueCount: json['queue_count'] as int?,
      savedAt: json['saved_at'] == null
          ? null
          : DateTime.tryParse(json['saved_at'] as String),
      pendingSync: json['pending_sync'] as bool? ?? true,
      isLocked:
          json['is_locked'] as bool? ??
          (json['saved_at'] != null && (json['saved_at'] as String).isNotEmpty),
    );
  }
}
