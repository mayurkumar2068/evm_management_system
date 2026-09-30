import 'dart:async';
import 'dart:io';

import 'package:MPSECNET/core/network/connectivity_service.dart';
import 'package:get/get.dart' hide Trans;

enum NetworkQuality { offline, poor, good }

/// Probes real internet reachability and latency on top of the raw
/// transport state from [ConnectivityService], so a device connected to a
/// Wi-Fi/mobile network with no actual internet access is still reported
/// correctly instead of showing as online.
class NetworkQualityService {
  NetworkQualityService(this._connectivity);

  final ConnectivityService _connectivity;

  final Rx<NetworkQuality> quality = NetworkQuality.offline.obs;

  static const Duration _pollInterval = Duration(seconds: 15);
  static const Duration _probeTimeout = Duration(seconds: 5);
  static const Duration _poorLatencyThreshold = Duration(milliseconds: 800);
  static final Uri _probeUri = Uri.parse(
    'https://www.gstatic.com/generate_204',
  );

  Timer? _timer;
  StreamSubscription<bool>? _connectivitySub;
  bool _checking = false;

  void start() {
    unawaited(_check());
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => unawaited(_check()));
    _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onStatusChange.listen(
      (_) => unawaited(_check()),
    );
  }

  void dispose() {
    _timer?.cancel();
    _connectivitySub?.cancel();
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      final bool hasTransport = await _connectivity.isOnline;
      if (!hasTransport) {
        quality.value = NetworkQuality.offline;
        return;
      }
      final Duration? latency = await _probeLatency();
      if (latency == null) {
        quality.value = NetworkQuality.offline;
      } else if (latency > _poorLatencyThreshold) {
        quality.value = NetworkQuality.poor;
      } else {
        quality.value = NetworkQuality.good;
      }
    } finally {
      _checking = false;
    }
  }

  Future<Duration?> _probeLatency() async {
    final HttpClient client = HttpClient()..connectionTimeout = _probeTimeout;
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      final HttpClientRequest request = await client
          .getUrl(_probeUri)
          .timeout(_probeTimeout);
      final HttpClientResponse response = await request.close().timeout(
        _probeTimeout,
      );
      await response.drain<void>();
      stopwatch.stop();
      final bool ok = response.statusCode >= 200 && response.statusCode < 400;
      return ok ? stopwatch.elapsed : null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
