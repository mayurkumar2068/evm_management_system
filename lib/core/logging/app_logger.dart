import 'package:logger/logger.dart';

/// Application-wide logging facade.
///
/// Wraps the `logger` package behind a single entry point so call sites never
/// use `print`. Verbosity is environment-driven: in production only warnings
/// and errors are emitted. Replace [_logger] output to forward logs to Crashlytics
/// or a remote sink without touching call sites.
abstract final class AppLogger {
  static Logger _logger = _build(enabled: true, verbose: true);

  /// Configures the logger for the active environment. Call once on bootstrap.
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
    if (!enabled) return event.level.index >= Level.warning.index;
    if (verbose) return true;
    return event.level.index >= Level.info.index;
  }
}
