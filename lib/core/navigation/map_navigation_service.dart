import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/navigation/external_url_launcher.dart';
import 'package:evm_management_system/localization/locale_keys.dart';

class MapNavigationService {
  MapNavigationService({ExternalUrlLauncher? launcher})
    : _launcher = launcher ?? const ExternalUrlLauncher();

  static String get _defaultDestinationLabel =>
      LocaleKeys.presidingBoothPollingStation.tr();

  final ExternalUrlLauncher _launcher;

  Future<bool> openDirections({
    required double destinationLat,
    required double destinationLng,
    double? originLat,
    double? originLng,
    String? destinationLabel,
  }) async {
    // L2 VAPT F-15: never build a geo:/google.navigation: URI from
    // out-of-range or non-finite coordinates.
    if (!_isValidCoordinate(destinationLat, destinationLng) ||
        !_isValidOptionalPair(originLat, originLng)) {
      return false;
    }
    final String dest = '$destinationLat,$destinationLng';
    final String label = _encodeLabel(destinationLabel);
    final List<Uri> candidates = <Uri>[
      ..._nativeDirectionUris(
        dest: dest,
        label: label,
        originLat: originLat,
        originLng: originLng,
      ),
      _googleMapsDirectionsUri(
        dest: dest,
        originLat: originLat,
        originLng: originLng,
      ),
      Uri.parse('geo:$dest?q=$dest($label)'),
    ];
    return _launcher.launchFirst(candidates);
  }

  Future<bool> openPlaceSearch(String query) async {
    final String encoded = Uri.encodeComponent(_normalizeQuery(query));
    final List<Uri> candidates = <Uri>[
      if (Platform.isIOS)
        Uri.parse('comgooglemaps://?q=$encoded')
      else if (Platform.isAndroid)
        Uri.parse('geo:0,0?q=$encoded'),
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded'),
      Uri.parse('geo:0,0?q=$encoded'),
    ];
    return _launcher.launchFirst(candidates);
  }

  String staticMapImageUrl({
    required double lat,
    required double lng,
    int width = 520,
    int height = 220,
    int zoom = 15,
  }) {
    return 'https://staticmap.openstreetmap.de/staticmap.php'
        '?center=$lat,$lng'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&markers=$lat,$lng,red-pushpin';
  }

  static String _normalizeQuery(String query) {
    final String sanitized = _sanitizeFreeText(query);
    return sanitized.isNotEmpty ? sanitized : _defaultDestinationLabel;
  }

  static String _encodeLabel(String? destinationLabel) =>
      Uri.encodeComponent(_normalizeQuery(destinationLabel ?? ''));

  // L2 VAPT F-15: strip control characters and cap length before any
  // free-text value is embedded in a geo:/google.navigation: URI. This
  // runs ahead of Uri.encodeComponent, which escapes but does not itself
  // validate content.
  static String _sanitizeFreeText(String input, {int maxLength = 100}) {
    final String cleaned = input
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .trim();
    return cleaned.length > maxLength
        ? cleaned.substring(0, maxLength)
        : cleaned;
  }

  static bool _isValidCoordinate(double lat, double lng) =>
      lat.isFinite && lng.isFinite && lat.abs() <= 90 && lng.abs() <= 180;

  static bool _isValidOptionalPair(double? lat, double? lng) {
    if (lat == null && lng == null) return true;
    if (lat == null || lng == null) return false;
    return _isValidCoordinate(lat, lng);
  }

  static List<Uri> _nativeDirectionUris({
    required String dest,
    required String label,
    double? originLat,
    double? originLng,
  }) {
    if (Platform.isIOS) {
      if (originLat != null && originLng != null) {
        return <Uri>[
          Uri.parse(
            'comgooglemaps://?saddr=$originLat,$originLng'
            '&daddr=$dest&directionsmode=driving',
          ),
          Uri.parse('maps://?saddr=$originLat,$originLng&daddr=$dest&dirflg=d'),
        ];
      }
      return <Uri>[
        Uri.parse('comgooglemaps://?daddr=$dest&directionsmode=driving'),
        Uri.parse('maps://?daddr=$dest&dirflg=d'),
      ];
    }
    if (Platform.isAndroid) {
      return <Uri>[
        Uri.parse('google.navigation:q=$dest'),
        Uri.parse('geo:$dest?q=$dest($label)'),
      ];
    }
    return const <Uri>[];
  }

  static Uri _googleMapsDirectionsUri({
    required String dest,
    double? originLat,
    double? originLng,
  }) {
    if (originLat != null && originLng != null) {
      return Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$originLat,$originLng'
        '&destination=$dest'
        '&travelmode=driving',
      );
    }
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$dest'
      '&travelmode=driving',
    );
  }
}
