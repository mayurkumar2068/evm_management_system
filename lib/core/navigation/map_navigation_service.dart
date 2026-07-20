import 'dart:io' show Platform;

import 'package:evm_management_system/core/navigation/external_url_launcher.dart';

/// Opens device maps for turn-by-turn navigation to a polling booth.
class MapNavigationService {
  MapNavigationService({ExternalUrlLauncher? launcher})
    : _launcher = launcher ?? const ExternalUrlLauncher();

  static const String _defaultDestinationLabel = 'मतदान केंद्र';

  final ExternalUrlLauncher _launcher;

  /// Google Maps directions from [origin] (optional) to booth [destination].
  Future<bool> openDirections({
    required double destinationLat,
    required double destinationLng,
    double? originLat,
    double? originLng,
    String? destinationLabel,
  }) async {
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

  /// Opens Google Maps search when booth coordinates are missing.
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

  /// OpenStreetMap static preview (no API key).
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

  static String _normalizeQuery(String query) =>
      query.trim().isNotEmpty ? query.trim() : _defaultDestinationLabel;

  static String _encodeLabel(String? destinationLabel) =>
      Uri.encodeComponent(_normalizeQuery(destinationLabel ?? ''));

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
          Uri.parse(
            'maps://?saddr=$originLat,$originLng&daddr=$dest&dirflg=d',
          ),
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
