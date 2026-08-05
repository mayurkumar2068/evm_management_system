import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';

/// Result of male/female/other turnout validation.
final class TurnoutCountValidationResult {
  const TurnoutCountValidationResult.ok()
      : messageKey = null,
        categoryKey = null,
        limit = null;

  const TurnoutCountValidationResult.fail(
    this.messageKey, {
    this.categoryKey,
    this.limit,
  });

  final String? messageKey;
  final String? categoryKey;
  final int? limit;

  bool get isOk => messageKey == null;
}

/// Thrown when turnout counts violate elector or progressive-slot rules.
final class TurnoutCountValidationException implements Exception {
  const TurnoutCountValidationException(this.result);

  final TurnoutCountValidationResult result;

  @override
  String toString() =>
      result.messageKey ?? 'TurnoutCountValidationException';
}

/// Caps from login electors + floor from earlier time slots.
final class TurnoutCountBounds {
  const TurnoutCountBounds({
    this.maxMale,
    this.maxFemale,
    this.maxOther,
    this.minMale = 0,
    this.minFemale = 0,
    this.minOther = 0,
  });

  final int? maxMale;
  final int? maxFemale;
  final int? maxOther;
  final int minMale;
  final int minFemale;
  final int minOther;
}

/// Shared rules for 2–2 hourly, final, and live poll counts.
abstract final class TurnoutCountValidator {
  /// Max digits allowed when entering turnout / queue counts.
  static const int maxInputDigits = 4;

  /// Max integer value for a single count field (4 digits).
  static const int maxEnterableCount = 9999;

  /// Ordered cumulative slots (time + final status). Live uses these as floor.
  static List<String> cumulativeSlotOrder(String? areaType) {
    return TurnoutSlots.forAreaType(areaType)
        .where(
          (TurnoutSlotDefinition s) =>
              !s.queueOnly && s.slotId != TurnoutSlotIds.livePollInfo,
        )
        .map((TurnoutSlotDefinition s) => s.slotId)
        .toList(growable: false);
  }

  /// Urban last = 5PM, rural last = 3PM (last non-queue time slot).
  static String? lastTimeSlotId(String? areaType) {
    final List<String> timeSlots = TurnoutSlots.forAreaType(areaType)
        .where(
          (TurnoutSlotDefinition s) =>
              !s.queueOnly &&
              s.slotId != TurnoutSlotIds.pollCompletion &&
              s.slotId != TurnoutSlotIds.livePollInfo,
        )
        .map((TurnoutSlotDefinition s) => s.slotId)
        .toList(growable: false);
    if (timeSlots.isEmpty) return null;
    return timeSlots.last;
  }

  static int recordTotal(TurnoutRecord? record) {
    if (record == null) return 0;
    return (record.male ?? 0) +
        (record.female ?? 0) +
        (record.thirdGender ?? 0);
  }

  static TurnoutCountBounds boundsFor({
    required PresidingSession session,
    required String slotId,
    PresidingElectionContext? electors,
    int? maxMale,
    int? maxFemale,
    int? maxOther,
  }) {
    final List<String> order = cumulativeSlotOrder(session.areaType);
    final int index = order.indexOf(slotId);

    int minMale = 0;
    int minFemale = 0;
    int minOther = 0;

    if (slotId == TurnoutSlotIds.livePollInfo) {
      for (final String id in order) {
        final TurnoutRecord? r = session.turnoutRecords[id];
        if (r == null) continue;
        minMale = _max(minMale, r.male ?? 0);
        minFemale = _max(minFemale, r.female ?? 0);
        minOther = _max(minOther, r.thirdGender ?? 0);
      }
    } else if (index > 0) {
      for (int i = 0; i < index; i++) {
        final TurnoutRecord? r = session.turnoutRecords[order[i]];
        if (r == null) continue;
        minMale = _max(minMale, r.male ?? 0);
        minFemale = _max(minFemale, r.female ?? 0);
        minOther = _max(minOther, r.thirdGender ?? 0);
      }
    }

    return TurnoutCountBounds(
      maxMale: maxMale ?? electors?.maleElectors,
      maxFemale: maxFemale ?? electors?.femaleElectors,
      maxOther: maxOther ?? electors?.otherElectors,
      minMale: minMale,
      minFemale: minFemale,
      minOther: minOther,
    );
  }

  static TurnoutCountValidationResult validate({
    required int male,
    required int female,
    required int other,
    required TurnoutCountBounds bounds,
  }) {
    if (male < 0 || female < 0 || other < 0) {
      return const TurnoutCountValidationResult.fail(
        'presiding.count_cannot_be_negative',
      );
    }

    if (male > maxEnterableCount ||
        female > maxEnterableCount ||
        other > maxEnterableCount) {
      return const TurnoutCountValidationResult.fail(
        'presiding.count_max_four_digits',
        limit: maxEnterableCount,
      );
    }

    if (male < bounds.minMale) {
      return TurnoutCountValidationResult.fail(
        'presiding.count_not_less_than_previous',
        categoryKey: 'presiding.male',
        limit: bounds.minMale,
      );
    }
    if (female < bounds.minFemale) {
      return TurnoutCountValidationResult.fail(
        'presiding.count_not_less_than_previous',
        categoryKey: 'presiding.female',
        limit: bounds.minFemale,
      );
    }
    if (other < bounds.minOther) {
      return TurnoutCountValidationResult.fail(
        'presiding.count_not_less_than_previous',
        categoryKey: 'presiding.third_gender',
        limit: bounds.minOther,
      );
    }

    if (bounds.maxMale != null && male > bounds.maxMale!) {
      return TurnoutCountValidationResult.fail(
        'presiding.count_exceeds_electors',
        categoryKey: 'presiding.male',
        limit: bounds.maxMale,
      );
    }
    if (bounds.maxFemale != null && female > bounds.maxFemale!) {
      return TurnoutCountValidationResult.fail(
        'presiding.count_exceeds_electors',
        categoryKey: 'presiding.female',
        limit: bounds.maxFemale,
      );
    }
    if (bounds.maxOther != null && other > bounds.maxOther!) {
      return TurnoutCountValidationResult.fail(
        'presiding.count_exceeds_electors',
        categoryKey: 'presiding.third_gender',
        limit: bounds.maxOther,
      );
    }

    return const TurnoutCountValidationResult.ok();
  }

  /// Last hourly total + queue must be ≤ मतदान समाप्ति total (== allowed).
  ///
  /// Urban last slot = 5PM, rural = 3PM.
  static TurnoutCountValidationResult validateLastPlusQueueVsCompletion({
    required PresidingSession session,
    required String slotId,
    int? male,
    int? female,
    int? other,
    int? queueCount,
  }) {
    final String? lastId = lastTimeSlotId(session.areaType);
    if (lastId == null) {
      return const TurnoutCountValidationResult.ok();
    }

    final bool touchesRule = slotId == lastId ||
        slotId == TurnoutSlotIds.queueCount ||
        slotId == TurnoutSlotIds.pollCompletion;
    if (!touchesRule) {
      return const TurnoutCountValidationResult.ok();
    }

    final TurnoutRecord? lastRecord = session.turnoutRecords[lastId];
    final TurnoutRecord? queueRecord =
        session.turnoutRecords[TurnoutSlotIds.queueCount];
    final TurnoutRecord? completionRecord =
        session.turnoutRecords[TurnoutSlotIds.pollCompletion];

    int lastTotal = recordTotal(lastRecord);
    int queueVal = queueRecord?.queueCount ?? 0;
    int completionTotal = recordTotal(completionRecord);

    if (slotId == lastId) {
      lastTotal = (male ?? 0) + (female ?? 0) + (other ?? 0);
    } else if (slotId == TurnoutSlotIds.queueCount) {
      queueVal = queueCount ?? 0;
    } else if (slotId == TurnoutSlotIds.pollCompletion) {
      completionTotal = (male ?? 0) + (female ?? 0) + (other ?? 0);
    }

    final int lastPlusQueue = lastTotal + queueVal;

    if (slotId == TurnoutSlotIds.pollCompletion) {
      if (completionTotal < lastPlusQueue) {
        return TurnoutCountValidationResult.fail(
          'presiding.count_completion_below_last_plus_queue',
          limit: lastPlusQueue,
        );
      }
      return const TurnoutCountValidationResult.ok();
    }

    // Editing last slot / queue after completion is already saved.
    final bool completionSaved = completionRecord?.savedAt != null;
    if (!completionSaved) {
      return const TurnoutCountValidationResult.ok();
    }

    if (lastPlusQueue > completionTotal) {
      return TurnoutCountValidationResult.fail(
        'presiding.count_last_plus_queue_exceeds_completion',
        limit: completionTotal,
      );
    }

    return const TurnoutCountValidationResult.ok();
  }

  static int _max(int a, int b) => a >= b ? a : b;
}
