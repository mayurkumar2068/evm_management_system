import 'dart:async';

/// Enforces idle session timeout.
///
/// Any user interaction calls [heartbeat]; if no heartbeat is received within
/// the configured [timeout], [onTimeout] fires so the app can force a logout.
class SessionTimeoutManager {
  SessionTimeoutManager({required this.timeout});

  final Duration timeout;
  Timer? _timer;
  void Function()? _onTimeout;

  /// Starts monitoring. [onTimeout] is invoked once when the session expires.
  void start(void Function() onTimeout) {
    _onTimeout = onTimeout;
    _restart();
  }

  /// Records user activity and resets the idle countdown.
  void heartbeat() {
    if (_onTimeout == null) return;
    _restart();
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer(timeout, () => _onTimeout?.call());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _onTimeout = null;
  }
}
