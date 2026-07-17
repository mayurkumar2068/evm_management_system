import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/features/presiding_concern/data/config/turnout_slot_registry.dart';
import 'package:evm_management_system/features/presiding_concern/data/constants/po_election_api_fields.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';

/// Maps presiding-officer domain actions to PO Election API request bodies.
abstract final class PoElectionApiMapper {
  /// Builds the request body for a milestone completion action.
  static Map<String, dynamic>? milestoneBody({
    required PresidingElectionContext context,
    required String milestoneId,
    double? lat,
    double? long,
  }) {
    final Map<String, dynamic> base = _base(context, lat: lat, long: long);
    return switch (milestoneId) {
      PresidingMilestoneIds.leftMaterialCenter => <String, dynamic>{
        ...base,
        PoElectionRequestFields.isDepartedFromHome: true,
      },
      PresidingMilestoneIds.reachedPollingStation => <String, dynamic>{
        ...base,
        PoElectionRequestFields.isReachedToPs: true,
      },
      PresidingMilestoneIds.materialReceived => <String, dynamic>{
        ...base,
        PoElectionRequestFields.isMaterialReceived: true,
      },
      PresidingMilestoneIds.mockPoll => <String, dynamic>{
        ...base,
        PoElectionRequestFields.isMockPollConducted: true,
      },
      PresidingMilestoneIds.pollStart => <String, dynamic>{
        ...base,
        PoElectionRequestFields.isPollStarted: true,
      },
      PresidingMilestoneIds.pollEnd => <String, dynamic>{
        ...base,
        PoElectionRequestFields.isPollEnded: true,
      },
      PresidingMilestoneIds.machineSealed => <String, dynamic>{
        ...base,
        PoElectionRequestFields.isMachineSealed: true,
      },
      PresidingMilestoneIds.materialHandedOver => <String, dynamic>{
        ...base,
        PoElectionRequestFields.isMaterialSubmitted: true,
      },
      _ => null,
    };
  }

  /// Resolves the PO Election endpoint for a milestone.
  static String? milestoneEndpoint(String milestoneId) {
    return switch (milestoneId) {
      PresidingMilestoneIds.leftMaterialCenter =>
        PoElectionEndpoints.insertDepartFromHome,
      PresidingMilestoneIds.reachedPollingStation =>
        PoElectionEndpoints.insertReachedToPs,
      PresidingMilestoneIds.materialReceived =>
        PoElectionEndpoints.insertMaterialReceived,
      PresidingMilestoneIds.mockPoll =>
        PoElectionEndpoints.insertMockPollConducted,
      PresidingMilestoneIds.pollStart => PoElectionEndpoints.insertPollStarted,
      PresidingMilestoneIds.pollEnd => PoElectionEndpoints.insertPollEnded,
      PresidingMilestoneIds.machineSealed =>
        PoElectionEndpoints.insertMachineSealed,
      PresidingMilestoneIds.materialHandedOver =>
        PoElectionEndpoints.insertMaterialSubmitted,
      _ => null,
    };
  }

  /// Builds the request body for a turnout slot save action.
  static Map<String, dynamic>? turnoutBody({
    required PresidingElectionContext context,
    required TurnoutRecord record,
    double? lat,
    double? long,
  }) {
    final Map<String, dynamic> base = _base(context, lat: lat, long: long);
    if (record.slotId == TurnoutSlotIds.queueCount) {
      return <String, dynamic>{
        ...base,
        PoElectionRequestFields.male: 0,
        PoElectionRequestFields.female: 0,
        PoElectionRequestFields.other: 0,
        PoElectionRequestFields.total: record.queueCount ?? 0,
      };
    }

    if (TurnoutSlotRegistry.findBySlotId(record.slotId) != null) {
      return <String, dynamic>{...base, ..._genderCounts(record)};
    }

    return null;
  }

  /// Resolves the PO Election endpoint for a turnout slot.
  static String turnoutEndpoint(String slotId) {
    return TurnoutSlotRegistry.endpointFor(slotId);
  }

  /// Live poll snapshot body used after poll start.
  static Map<String, dynamic> livePollBody({
    required PresidingElectionContext context,
    required TurnoutRecord record,
    double? lat,
    double? long,
  }) {
    return <String, dynamic>{
      ..._base(context, lat: lat, long: long),
      PoElectionRequestFields.male: record.male,
      PoElectionRequestFields.female: record.female,
      PoElectionRequestFields.other: record.thirdGender,
    };
  }

  static Map<String, dynamic> _base(
    PresidingElectionContext context, {
    double? lat,
    double? long,
  }) {
    return <String, dynamic>{
      PoElectionRequestFields.electionId: context.electionId,
      PoElectionRequestFields.psId: context.psId,
      if (lat != null) PoElectionRequestFields.lat: lat,
      if (long != null) PoElectionRequestFields.long: long,
    };
  }

  static Map<String, int> _genderCounts(TurnoutRecord record) {
    return <String, int>{
      PoElectionRequestFields.male: record.male ?? 0,
      PoElectionRequestFields.female: record.female ?? 0,
      PoElectionRequestFields.other: record.thirdGender ?? 0,
    };
  }
}
