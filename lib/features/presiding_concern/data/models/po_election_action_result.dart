class PoElectionActionResult {
  const PoElectionActionResult({
    required this.success,
    this.actionDateTime,
    this.alreadyRegistered = false,
    this.message,
  });

  final bool success;
  final DateTime? actionDateTime;
  final bool alreadyRegistered;
  final String? message;

  bool get accepted => success || alreadyRegistered;
}
