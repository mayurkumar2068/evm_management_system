import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/features/presiding_concern/data/constants/po_election_api_fields.dart';
import 'package:evm_management_system/features/presiding_concern/domain/constants/presiding_area_type.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';

/// Maps turnout slot status fields from `po-status`.
final class TurnoutStatusFields {
  const TurnoutStatusFields({
    required this.male,
    required this.female,
    required this.other,
    required this.updatedAt,
  });

  final String male;
  final String female;
  final String other;
  final String updatedAt;
}

/// Single source of truth for turnout slot metadata, endpoints, and status keys.
final class TurnoutSlotConfig {
  const TurnoutSlotConfig({
    required this.slotId,
    required this.labelKey,
    required this.endpoint,
    this.statusFields,
    this.queueOnly = false,
    this.urbanOnly = false,
  });

  final String slotId;
  final String labelKey;
  final String endpoint;
  final TurnoutStatusFields? statusFields;
  final bool queueOnly;
  final bool urbanOnly;

  TurnoutSlotDefinition toDefinition() {
    return TurnoutSlotDefinition(
      slotId: slotId,
      labelKey: labelKey,
      queueOnly: queueOnly,
    );
  }
}

/// Registry consumed by UI, API mapper, and status sync.
abstract final class TurnoutSlotRegistry {
  static const TurnoutSlotConfig slot9Am = TurnoutSlotConfig(
    slotId: TurnoutSlotIds.slot9Am,
    labelKey: TurnoutSlotLabelKeys.slot9Am,
    endpoint: PoElectionEndpoints.insert09AmCount,
    statusFields: TurnoutStatusFields(
      male: PoElectionResponseFields.poll9AmMale,
      female: PoElectionResponseFields.poll9AmFemale,
      other: PoElectionResponseFields.poll9AmOther,
      updatedAt: PoElectionResponseFields.poll9AmUpdateTime,
    ),
  );

  static const TurnoutSlotConfig slot11Am = TurnoutSlotConfig(
    slotId: TurnoutSlotIds.slot11Am,
    labelKey: TurnoutSlotLabelKeys.slot11Am,
    endpoint: PoElectionEndpoints.insert11AmCount,
    statusFields: TurnoutStatusFields(
      male: PoElectionResponseFields.poll11AmMale,
      female: PoElectionResponseFields.poll11AmFemale,
      other: PoElectionResponseFields.poll11AmOther,
      updatedAt: PoElectionResponseFields.poll11AmUpdateTime,
    ),
  );

  static const TurnoutSlotConfig slot1Pm = TurnoutSlotConfig(
    slotId: TurnoutSlotIds.slot1Pm,
    labelKey: TurnoutSlotLabelKeys.slot1Pm,
    endpoint: PoElectionEndpoints.insert01PmCount,
    statusFields: TurnoutStatusFields(
      male: PoElectionResponseFields.poll1PmMale,
      female: PoElectionResponseFields.poll1PmFemale,
      other: PoElectionResponseFields.poll1PmOther,
      updatedAt: PoElectionResponseFields.poll1PmUpdateTime,
    ),
  );

  static const TurnoutSlotConfig slot3Pm = TurnoutSlotConfig(
    slotId: TurnoutSlotIds.slot3Pm,
    labelKey: TurnoutSlotLabelKeys.slot3Pm,
    endpoint: PoElectionEndpoints.insert03PmCount,
    statusFields: TurnoutStatusFields(
      male: PoElectionResponseFields.poll3PmMale,
      female: PoElectionResponseFields.poll3PmFemale,
      other: PoElectionResponseFields.poll3PmOther,
      updatedAt: PoElectionResponseFields.poll3PmUpdateTime,
    ),
  );

  static const TurnoutSlotConfig slot5Pm = TurnoutSlotConfig(
    slotId: TurnoutSlotIds.slot5Pm,
    labelKey: TurnoutSlotLabelKeys.slot5Pm,
    endpoint: PoElectionEndpoints.insert05PmCount,
    urbanOnly: true,
    statusFields: TurnoutStatusFields(
      male: PoElectionResponseFields.poll5PmMale,
      female: PoElectionResponseFields.poll5PmFemale,
      other: PoElectionResponseFields.poll5PmOther,
      updatedAt: PoElectionResponseFields.poll5PmUpdateTime,
    ),
  );

  static const TurnoutSlotConfig queueCount = TurnoutSlotConfig(
    slotId: TurnoutSlotIds.queueCount,
    labelKey: TurnoutSlotLabelKeys.queueCount,
    endpoint: PoElectionEndpoints.insertLineCount,
    queueOnly: true,
  );

  static const TurnoutSlotConfig pollCompletion = TurnoutSlotConfig(
    slotId: TurnoutSlotIds.pollCompletion,
    labelKey: TurnoutSlotLabelKeys.pollCompletion,
    endpoint: PoElectionEndpoints.insertFinalCount,
    statusFields: TurnoutStatusFields(
      male: PoElectionResponseFields.finalMale,
      female: PoElectionResponseFields.finalFemale,
      other: PoElectionResponseFields.finalOther,
      updatedAt: PoElectionResponseFields.finalUpdateTime,
    ),
  );

  static const TurnoutSlotConfig livePoll = TurnoutSlotConfig(
    slotId: TurnoutSlotIds.livePollInfo,
    labelKey: TurnoutSlotLabelKeys.livePollInfo,
    endpoint: PoElectionEndpoints.savePollLive,
    statusFields: TurnoutStatusFields(
      male: PoElectionResponseFields.pollLiveMale,
      female: PoElectionResponseFields.pollLiveFemale,
      other: PoElectionResponseFields.pollLiveOther,
      updatedAt: PoElectionResponseFields.pollLiveUpdateTime,
    ),
  );

  static const List<TurnoutSlotConfig> _turnoutScreenOrder =
      <TurnoutSlotConfig>[
        slot9Am,
        slot11Am,
        slot1Pm,
        slot3Pm,
        slot5Pm,
        queueCount,
        pollCompletion,
      ];

  static const List<TurnoutSlotConfig> _allConfigs = <TurnoutSlotConfig>[
    slot9Am,
    slot11Am,
    slot1Pm,
    slot3Pm,
    slot5Pm,
    queueCount,
    pollCompletion,
    livePoll,
  ];

  static List<TurnoutSlotDefinition> definitionsForAreaType(String? areaType) {
    return forAreaType(
      areaType,
    ).map((TurnoutSlotConfig c) => c.toDefinition()).toList();
  }

  static List<TurnoutSlotConfig> forAreaType(String? areaType) {
    final PresidingAreaType resolved = PresidingAreaType.parse(areaType);
    return _turnoutScreenOrder
        .where(
          (TurnoutSlotConfig config) => !config.urbanOnly || resolved.isUrban,
        )
        .toList(growable: false);
  }

  static TurnoutSlotConfig? findBySlotId(String slotId) {
    for (final TurnoutSlotConfig config in _allConfigs) {
      if (config.slotId == slotId) return config;
    }
    return null;
  }

  static String endpointFor(String slotId) {
    return findBySlotId(slotId)?.endpoint ?? PoElectionEndpoints.savePollLive;
  }

  static Iterable<TurnoutSlotConfig> genderStatusSlots() {
    return _allConfigs.where(
      (TurnoutSlotConfig config) =>
          config.statusFields != null && !config.queueOnly,
    );
  }
}
