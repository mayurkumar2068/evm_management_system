import 'package:connectivity_plus/connectivity_plus.dart';

/// Reports and streams the device's network reachability.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Emits `true` when at least one transport (wifi/mobile/ethernet) is online.
  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged.map(
    (List<ConnectivityResult> results) => _isOnline(results),
  );

  Future<bool> get isOnline async =>
      _isOnline(await _connectivity.checkConnectivity());

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((ConnectivityResult r) => r != ConnectivityResult.none);
}
