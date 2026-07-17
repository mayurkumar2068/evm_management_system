import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';

/// Outcome of completing a presiding milestone or saving turnout.
class PresidingActionOutcome {
  const PresidingActionOutcome({
    required this.session,
    this.alreadyRegistered = false,
    this.message,
  });

  final PresidingSession session;
  final bool alreadyRegistered;
  final String? message;
}
