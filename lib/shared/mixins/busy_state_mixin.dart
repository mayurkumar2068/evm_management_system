import 'package:flutter/widgets.dart';

/// Reduces busy/error boilerplate in [StatefulWidget] states.
///
/// Provides [busy] and [error] fields plus [runBusy] which wraps an async
/// action in `setState(() => busy = true)` / `setState(() => busy = false)`
/// with automatic error capture and `mounted` guards.
mixin BusyStateMixin<T extends StatefulWidget> on State<T> {
  bool busy = false;
  String? error;

  /// Executes [action] while setting [busy] = true and clearing [error].
  /// On exception, sets [error] to the exception message (or [fallback]).
  Future<void> runBusy(
    Future<void> Function() action, {
    String? fallback,
  }) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      error = fallback ?? e.toString();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
