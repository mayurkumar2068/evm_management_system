import 'dart:math';

/// Computes backoff delays for failed sync attempts.
///
/// Exponential growth with full jitter, capped at [maxDelay], and bounded by
/// [maxAttempts] (sourced from the environment config).
class RetryPolicy {
  RetryPolicy({
    required this.maxAttempts,
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 5),
    Random? random,
  }) : _random = random ?? Random();

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final Random _random;

  bool shouldRetry(int attempt) => attempt < maxAttempts;

  /// Backoff before the next attempt (0-indexed [attempt]).
  Duration delayFor(int attempt) {
    final int exp = baseDelay.inMilliseconds * (1 << attempt);
    final int capped = min(exp, maxDelay.inMilliseconds);
    final int jittered = _random.nextInt(capped + 1);
    return Duration(milliseconds: jittered);
  }
}
