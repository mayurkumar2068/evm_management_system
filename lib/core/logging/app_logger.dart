import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:logger/logger.dart';

abstract final class AppLogger {
  static Logger _logger = _build(enabled: true, verbose: true);

  static void configure({required bool enabled, required bool verbose}) {
    _logger = _build(enabled: enabled, verbose: verbose);
  }

  static Logger _build({required bool enabled, required bool verbose}) {
    return Logger(
      filter: _EnvFilter(enabled: enabled, verbose: verbose),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 100,
        printEmojis: false,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
  }

  static void t(String message) => _logger.t(message);
  static void d(String message) => _logger.d(message);
  static void i(String message) => _logger.i(message);
  static void w(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);
  static void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}

class _EnvFilter extends LogFilter {
  _EnvFilter({required this.enabled, required this.verbose});

  final bool enabled;
  final bool verbose;

  @override
  bool shouldLog(LogEvent event) {
    // L2 VAPT F-17 backstop: a --release build must never emit verbose /
    // request-body logs, even if ENABLE_LOGGING=true leaks into a UAT
    // release build. Only warnings and errors ever print in release mode,
    // regardless of what the env config requested.
    if (kReleaseMode) return event.level.index >= Level.warning.index;
    if (!enabled) return event.level.index >= Level.warning.index;
    if (verbose) return true;
    return event.level.index >= Level.info.index;
  }
}
