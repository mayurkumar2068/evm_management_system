import 'dart:math';

class RetryPolicy {
  RetryPolicy({
    required this.maxAttempts,
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 5),
    Random? random,
  }) : _random = random ?? Random.secure();

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final Random _random;

  bool shouldRetry(int attempt) => attempt < maxAttempts;

  Duration delayFor(int attempt) {
    final int exp = baseDelay.inMilliseconds * (1 << attempt);
    final int capped = min(exp, maxDelay.inMilliseconds);
    final int jittered = _random.nextInt(capped + 1);
    return Duration(milliseconds: jittered);
  }
}
