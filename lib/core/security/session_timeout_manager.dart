import 'dart:async';

class SessionTimeoutManager {
  SessionTimeoutManager({required this.timeout});

  final Duration timeout;
  Timer? _timer;
  void Function()? _onTimeout;

  void start(void Function() onTimeout) {
    _onTimeout = onTimeout;
    _restart();
  }

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
