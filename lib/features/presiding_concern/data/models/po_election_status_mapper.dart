import 'package:evm_management_system/features/presiding_concern/data/config/turnout_slot_registry.dart';
import 'package:evm_management_system/features/presiding_concern/data/constants/po_election_api_fields.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';

/// Maps `po-status` API payload into presiding session entities.
abstract final class PoElectionStatusMapper {
  static Map<String, TurnoutRecord> turnoutRecordsFromStatus(
    Map<String, dynamic> data,
  ) {
    final Map<String, TurnoutRecord> records = <String, TurnoutRecord>{};

    for (final TurnoutSlotConfig config
        in TurnoutSlotRegistry.genderStatusSlots()) {
      final TurnoutStatusFields? fields = config.statusFields;
      if (fields == null) continue;

      final TurnoutRecord? record = _genderRecord(
        slotId: config.slotId,
        male: _int(data[fields.male]),
        female: _int(data[fields.female]),
        other: _int(data[fields.other]),
        savedAt: _date(data[fields.updatedAt]),
      );
      if (record != null) records[config.slotId] = record;
    }

    final int? queueMale = _int(data[PoElectionResponseFields.qMale]);
    final int? queueFemale = _int(data[PoElectionResponseFields.qFemale]);
    final int? queueOther = _int(data[PoElectionResponseFields.qOther]);
    final DateTime? queueSavedAt = _date(
      data[PoElectionResponseFields.qUpdateTime],
    );
    if (queueMale != null ||
        queueFemale != null ||
        queueOther != null ||
        queueSavedAt != null) {
      records[TurnoutSlotIds.queueCount] = TurnoutRecord(
        slotId: TurnoutSlotIds.queueCount,
        queueCount: (queueMale ?? 0) + (queueFemale ?? 0) + (queueOther ?? 0),
        savedAt: queueSavedAt,
        pendingSync: false,
        isLocked: queueSavedAt != null,
      );
    }

    return records;
  }

  static List<PresidingMilestone> milestonesFromStatus({
    required List<PresidingMilestone> current,
    required Map<String, dynamic> data,
  }) {
    return current
        .map((PresidingMilestone milestone) {
          final _MilestoneStatus? status = _milestoneStatus(milestone.id, data);
          if (status == null) return milestone;
          if (!status.isCompleted) return milestone;
          return milestone.copyWith(
            state: PresidingMilestoneState.completed,
            completedAt:
                status.completedAt ?? milestone.completedAt ?? DateTime.now(),
            pendingSync: false,
          );
        })
        .toList(growable: false);
  }

  static TurnoutRecord? _genderRecord({
    required String slotId,
    required int? male,
    required int? female,
    required int? other,
    required DateTime? savedAt,
  }) {
    if (male == null && female == null && other == null && savedAt == null) {
      return null;
    }
    return TurnoutRecord(
      slotId: slotId,
      male: male ?? 0,
      female: female ?? 0,
      thirdGender: other ?? 0,
      savedAt: savedAt,
      pendingSync: false,
      isLocked: savedAt != null,
    );
  }

  static _MilestoneStatus? _milestoneStatus(
    String milestoneId,
    Map<String, dynamic> data,
  ) {
    return switch (milestoneId) {
      PresidingMilestoneIds.leftMaterialCenter => _MilestoneStatus(
        isCompleted: _bool(data[PoElectionResponseFields.isDepartedFromHome]),
        completedAt: _date(data[PoElectionResponseFields.departedFromHomeTime]),
      ),
      PresidingMilestoneIds.reachedPollingStation => _MilestoneStatus(
        isCompleted: _bool(
          data[PoElectionResponseFields.isReachedToPollingStation],
        ),
        completedAt: _date(
          data[PoElectionResponseFields.reachedToPollingStationTime],
        ),
      ),
      PresidingMilestoneIds.materialReceived => _MilestoneStatus(
        isCompleted: _bool(data[PoElectionResponseFields.isMaterialReceived]),
        completedAt: _date(data[PoElectionResponseFields.materialReceivedTime]),
      ),
      PresidingMilestoneIds.mockPoll => _MilestoneStatus(
        isCompleted: _bool(data[PoElectionResponseFields.isMockPollConducted]),
        completedAt: _date(
          data[PoElectionResponseFields.mockPollConductedTime],
        ),
      ),
      PresidingMilestoneIds.pollStart => _MilestoneStatus(
        isCompleted: _bool(data[PoElectionResponseFields.isPollStarted]),
        completedAt: _date(data[PoElectionResponseFields.pollStartedTime]),
      ),
      PresidingMilestoneIds.pollEnd => _MilestoneStatus(
        isCompleted: _bool(data[PoElectionResponseFields.isPollEnded]),
        completedAt: _date(data[PoElectionResponseFields.pollEndedTime]),
      ),
      PresidingMilestoneIds.machineSealed => _MilestoneStatus(
        isCompleted: _bool(data[PoElectionResponseFields.isMachineSealed]),
        completedAt: _date(data[PoElectionResponseFields.machineSealedTime]),
      ),
      PresidingMilestoneIds.materialHandedOver => _MilestoneStatus(
        isCompleted: _bool(data[PoElectionResponseFields.isMaterialSubmitted]),
        completedAt: _date(
          data[PoElectionResponseFields.materialSubmittedTime],
        ),
      ),
      _ => null,
    };
  }

  static int? _int(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value == null) return false;
    final String normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
}

final class _MilestoneStatus {
  const _MilestoneStatus({required this.isCompleted, this.completedAt});

  final bool isCompleted;
  final DateTime? completedAt;
}
