import 'package:evm_management_system/features/presiding_concern/domain/constants/presiding_area_type.dart';

final class PresidingElectionContext {
  const PresidingElectionContext({
    required this.electionId,
    required this.psId,
    required this.areaType,
    this.userId,
    this.loginUserName,
    this.pollingStationCode,
    this.pollingStationName,
    this.boothLat,
    this.boothLong,
    this.maleElectors,
    this.femaleElectors,
    this.otherElectors,
    this.totalElectors,
    this.isIpbms = false,
    this.isLivePoll = false,
  });

  final int electionId;
  final String psId;
  final String? userId;

  final String? loginUserName;

  final String areaType;
  final String? pollingStationCode;
  final String? pollingStationName;

  final double? boothLat;
  final double? boothLong;

  final int? maleElectors;
  final int? femaleElectors;
  final int? otherElectors;
  final int? totalElectors;

  final bool isIpbms;
  final bool isLivePoll;

  bool get hasBoothCoordinates =>
      boothLat != null &&
      boothLong != null &&
      boothLat!.abs() > 0 &&
      boothLong!.abs() > 0;

  PresidingAreaType get resolvedAreaType =>
      PresidingAreaType.parse(areaType, fallback: PresidingAreaType.rural);

  bool get hasElectors => (totalElectors ?? 0) > 0;

  bool get hasElectorCounts =>
      (maleElectors ?? 0) > 0 ||
      (femaleElectors ?? 0) > 0 ||
      (otherElectors ?? 0) > 0 ||
      (totalElectors ?? 0) > 0;

  bool get isComplete =>
      electionId > 0 && psId.isNotEmpty && _isValidAreaType(areaType);

  bool get isUrban => resolvedAreaType.isUrban;

  bool get isRural => resolvedAreaType.isRural;

  static bool _isValidAreaType(String value) {
    final String normalized = normalizeAreaType(value);
    return normalized == PresidingAreaType.urban.code ||
        normalized == PresidingAreaType.rural.code;
  }

  static String normalizeAreaType(String? raw) {
    return PresidingAreaType.tryParse(raw)?.code ?? '';
  }

  static String formatTurnoutPercent(int votes, int? electors) {
    final int base = electors ?? 0;
    if (base <= 0 || votes <= 0) return '0%';
    final double pct = (votes / base * 100).clamp(0, 100);
    return '${pct.toStringAsFixed(2)}%';
  }

  PresidingElectionContext copyWith({
    int? electionId,
    String? psId,
    String? areaType,
    String? userId,
    String? loginUserName,
    String? pollingStationCode,
    String? pollingStationName,
    double? boothLat,
    double? boothLong,
    int? maleElectors,
    int? femaleElectors,
    int? otherElectors,
    int? totalElectors,
    bool? isIpbms,
    bool? isLivePoll,
  }) {
    return PresidingElectionContext(
      electionId: electionId ?? this.electionId,
      psId: psId ?? this.psId,
      areaType: areaType ?? this.areaType,
      userId: userId ?? this.userId,
      loginUserName: loginUserName ?? this.loginUserName,
      pollingStationCode: pollingStationCode ?? this.pollingStationCode,
      pollingStationName: pollingStationName ?? this.pollingStationName,
      boothLat: boothLat ?? this.boothLat,
      boothLong: boothLong ?? this.boothLong,
      maleElectors: maleElectors ?? this.maleElectors,
      femaleElectors: femaleElectors ?? this.femaleElectors,
      otherElectors: otherElectors ?? this.otherElectors,
      totalElectors: totalElectors ?? this.totalElectors,
      isIpbms: isIpbms ?? this.isIpbms,
      isLivePoll: isLivePoll ?? this.isLivePoll,
    );
  }
}
