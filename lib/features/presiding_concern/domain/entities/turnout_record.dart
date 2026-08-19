import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_ids.dart';

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
