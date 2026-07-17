import 'dart:async';

/// Session-level events broadcast from `core` (e.g. by the [AuthInterceptor])
/// so the presentation layer can react — without `core` depending on a feature.
enum SessionEvent { expired, forcedLogout }

/// Lightweight broadcast bus for [SessionEvent]s.
class SessionEventBus {
  final StreamController<SessionEvent> _controller =
      StreamController<SessionEvent>.broadcast();

  Stream<SessionEvent> get events => _controller.stream;

  void emit(SessionEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  void dispose() => _controller.close();
}
