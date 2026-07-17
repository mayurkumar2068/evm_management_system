import 'package:url_launcher/url_launcher.dart';

/// Opens device maps for turn-by-turn navigation to a polling booth.
class MapNavigationService {
  /// Google Maps directions from [origin] (optional) to booth [destination].
  Future<bool> openDirections({
    required double destinationLat,
    required double destinationLng,
    double? originLat,
    double? originLng,
    String? destinationLabel,
  }) async {
    final String dest = '$destinationLat,$destinationLng';
    final Uri uri;
    if (originLat != null && originLng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$originLat,$originLng'
        '&destination=$dest'
        '&travelmode=driving',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$dest'
        '&travelmode=driving',
      );
    }
    if (!await canLaunchUrl(uri)) {
      final String label = Uri.encodeComponent(
        destinationLabel?.trim().isNotEmpty == true
            ? destinationLabel!.trim()
            : 'मतदान केंद्र',
      );
      final Uri fallback = Uri.parse('geo:$dest?q=$dest($label)');
      return launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
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
}
