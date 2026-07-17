import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Latitude and longitude captured from the device GPS.
class GeoCoordinates {
  const GeoCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Reads the current device location for PO Election API submissions.
class LocationService {
  /// Returns current coordinates when permission and GPS are available.
  Future<GeoCoordinates?> getCurrentCoordinates() async {
    try {
      final PermissionStatus status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) {
        final PermissionStatus requested = await Permission.locationWhenInUse
            .request();
        if (!requested.isGranted) return null;
      }

      if (!await Geolocator.isLocationServiceEnabled()) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return GeoCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on Exception {
      return null;
    }
  }
}
