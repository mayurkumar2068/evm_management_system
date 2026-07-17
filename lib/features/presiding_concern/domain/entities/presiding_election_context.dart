import 'package:evm_management_system/features/presiding_concern/domain/constants/presiding_area_type.dart';

/// Authenticated election context required by PO Election APIs.
final class PresidingElectionContext {
  const PresidingElectionContext({
    required this.electionId,
    required this.psId,
    required this.areaType,
    this.userId,
    this.pollingStationCode,
    this.pollingStationName,
  });

  final int electionId;
  final String psId;
  final String? userId;

  /// Urban (`U`) or rural (`R`) as returned by the auth API.
  final String areaType;
  final String? pollingStationCode;
  final String? pollingStationName;

  PresidingAreaType get resolvedAreaType => PresidingAreaType.parse(areaType);

  bool get isComplete =>
      electionId > 0 && psId.isNotEmpty && _isValidAreaType(areaType);

  bool get isUrban => resolvedAreaType.isUrban;

  bool get isRural => resolvedAreaType.isRural;

  static bool _isValidAreaType(String value) {
    final String normalized = normalizeAreaType(value);
    return normalized == PresidingAreaType.urban.code ||
        normalized == PresidingAreaType.rural.code;
  }

  /// Normalises backend area-type codes to `U` or `R`.
  static String normalizeAreaType(String? raw) {
    return PresidingAreaType.parse(raw, fallback: PresidingAreaType.urban).code;
  }

  PresidingElectionContext copyWith({
    int? electionId,
    String? psId,
    String? areaType,
    String? userId,
    String? pollingStationCode,
    String? pollingStationName,
  }) {
    return PresidingElectionContext(
      electionId: electionId ?? this.electionId,
      psId: psId ?? this.psId,
      areaType: areaType ?? this.areaType,
      userId: userId ?? this.userId,
      pollingStationCode: pollingStationCode ?? this.pollingStationCode,
      pollingStationName: pollingStationName ?? this.pollingStationName,
    );
  }
}
