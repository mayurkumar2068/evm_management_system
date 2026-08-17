import 'package:evm_management_system/features/presiding_concern/domain/constants/presiding_area_type.dart';

/// Authenticated election context required by PO Election APIs.
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
  });

  final int electionId;
  final String psId;
  final String? userId;

  /// PO login username (`UserName`), used for test-account rule bypasses.
  final String? loginUserName;

  /// Urban (`U`) or rural (`R`) as returned by the auth API.
  final String areaType;
  final String? pollingStationCode;
  final String? pollingStationName;

  /// Polling booth coordinates from login API (`Lat` / `Long`).
  final double? boothLat;
  final double? boothLong;

  /// Elector counts from PO login (`MaleElectors` / `FemaleElectors` / …).
  final int? maleElectors;
  final int? femaleElectors;
  final int? otherElectors;
  final int? totalElectors;

  bool get hasBoothCoordinates =>
      boothLat != null &&
      boothLong != null &&
      boothLat!.abs() > 0 &&
      boothLong!.abs() > 0;

  PresidingAreaType get resolvedAreaType => PresidingAreaType.parse(
    areaType,
    fallback: PresidingAreaType.rural,
  );

  bool get hasElectors => (totalElectors ?? 0) > 0;

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
  ///
  /// Returns empty string when [raw] is missing/unknown (does not invent urban).
  static String normalizeAreaType(String? raw) {
    return PresidingAreaType.tryParse(raw)?.code ?? '';
  }

  /// Turnout % for [votes] against [electors] (clamped, 2 decimals).
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
    );
  }
}
