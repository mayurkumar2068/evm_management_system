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
