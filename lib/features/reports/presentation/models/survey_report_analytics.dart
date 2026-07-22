import 'package:evm_management_system/core/offline/web_form_submission.dart';

/// Location fields extracted from a survey / web-form payload.
class SurveyLocationFacts {
  const SurveyLocationFacts({
    required this.districtId,
    required this.districtName,
    required this.boothId,
    required this.boothName,
    required this.areaType,
  });

  final String districtId;
  final String districtName;
  final String boothId;
  final String boothName;

  /// `urban` | `rural` | `unknown`
  final String areaType;

  String get districtLabel =>
      districtName.isNotEmpty ? districtName : (districtId.isNotEmpty ? districtId : '—');

  String get boothLabel =>
      boothName.isNotEmpty ? boothName : (boothId.isNotEmpty ? boothId : '—');

  bool get isUrban => areaType == 'urban';
  bool get isRural => areaType == 'rural';
}

/// Aggregated report row for one district.
class DistrictSurveyAgg {
  DistrictSurveyAgg({required this.key, required this.label});

  final String key;
  final String label;
  int urban = 0;
  int rural = 0;
  int unknown = 0;
  final Map<String, PollingStationAgg> stations = <String, PollingStationAgg>{};

  int get total => urban + rural + unknown;
  int get stationCount => stations.length;
}

/// Aggregated report row for one polling station within a district.
class PollingStationAgg {
  PollingStationAgg({
    required this.key,
    required this.label,
    required this.areaType,
  });

  final String key;
  final String label;
  final String areaType;
  int count = 0;
}

/// Helpers to parse location metadata from locally queued survey payloads.
class SurveyReportAnalytics {
  const SurveyReportAnalytics._();

  static SurveyLocationFacts fromPayload(Map<String, dynamic> payload) {
    final Map<String, dynamic> location = _asMap(payload['location']);
    final String districtId = _firstNonEmpty(<String?>[
      payload['districtId']?.toString(),
      payload['DistID']?.toString(),
      payload['distId']?.toString(),
      location['districtId']?.toString(),
      location['DistID']?.toString(),
    ]);
    final String districtName = _firstNonEmpty(<String?>[
      payload['districtName']?.toString(),
      payload['DistName']?.toString(),
      payload['distName']?.toString(),
      location['districtName']?.toString(),
      location['DistName']?.toString(),
    ]);
    final String boothId = _firstNonEmpty(<String?>[
      payload['psId']?.toString(),
      payload['boothId']?.toString(),
      payload['PSId']?.toString(),
      location['boothId']?.toString(),
      location['psId']?.toString(),
    ]);
    final String boothName = _firstNonEmpty(<String?>[
      payload['psName']?.toString(),
      payload['boothName']?.toString(),
      payload['PSName']?.toString(),
      location['boothName']?.toString(),
      location['psName']?.toString(),
    ]);
    final String areaType = _normalizeArea(
      payload['psType']?.toString() ??
          payload['areaType']?.toString() ??
          payload['AreaType']?.toString() ??
          location['areaType']?.toString(),
    );
    return SurveyLocationFacts(
      districtId: districtId,
      districtName: districtName,
      boothId: boothId,
      boothName: boothName,
      areaType: areaType,
    );
  }

  static List<DistrictSurveyAgg> byDistrict(List<WebFormSubmission> records) {
    final Map<String, DistrictSurveyAgg> map = <String, DistrictSurveyAgg>{};
    for (final WebFormSubmission s in records) {
      final SurveyLocationFacts loc = fromPayload(s.payload);
      final String key = loc.districtId.isNotEmpty
          ? loc.districtId
          : (loc.districtName.isNotEmpty ? loc.districtName : '_unknown');
      final DistrictSurveyAgg row = map.putIfAbsent(
        key,
        () => DistrictSurveyAgg(key: key, label: loc.districtLabel),
      );
      if (loc.isUrban) {
        row.urban++;
      } else if (loc.isRural) {
        row.rural++;
      } else {
        row.unknown++;
      }

      final String stationKey = loc.boothId.isNotEmpty
          ? loc.boothId
          : (loc.boothName.isNotEmpty ? loc.boothName : '_unknown');
      final PollingStationAgg station = row.stations.putIfAbsent(
        stationKey,
        () => PollingStationAgg(
          key: stationKey,
          label: loc.boothLabel,
          areaType: loc.areaType,
        ),
      );
      station.count++;
    }

    final List<DistrictSurveyAgg> list = map.values.toList()
      ..sort((DistrictSurveyAgg a, DistrictSurveyAgg b) => b.total.compareTo(a.total));
    return list;
  }

  static ({int urban, int rural, int unknown}) areaTotals(
    List<WebFormSubmission> records,
  ) {
    int urban = 0, rural = 0, unknown = 0;
    for (final WebFormSubmission s in records) {
      final SurveyLocationFacts loc = fromPayload(s.payload);
      if (loc.isUrban) {
        urban++;
      } else if (loc.isRural) {
        rural++;
      } else {
        unknown++;
      }
    }
    return (urban: urban, rural: rural, unknown: unknown);
  }

  static String _normalizeArea(String? raw) {
    final String v = (raw ?? '').trim().toUpperCase();
    if (v == 'U' || v == 'URBAN') return 'urban';
    if (v == 'R' || v == 'RURAL') return 'rural';
    return 'unknown';
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final String? v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (Object? k, Object? v) => MapEntry(k.toString(), v),
      );
    }
    return const <String, dynamic>{};
  }
}
