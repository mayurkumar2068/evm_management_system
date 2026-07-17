/// Parsed outcome of a PO Election API write call.
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

  /// Whether the server accepted the action (including already-registered).
  bool get accepted => success || alreadyRegistered;
}
