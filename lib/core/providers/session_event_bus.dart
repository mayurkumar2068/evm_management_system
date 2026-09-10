import 'dart:async';

enum SessionEvent { expired, forcedLogout }

class SessionEventBus {
  final StreamController<SessionEvent> _controller =
      StreamController<SessionEvent>.broadcast();

  Stream<SessionEvent> get events => _controller.stream;

  void emit(SessionEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  void dispose() => _controller.close();
}
