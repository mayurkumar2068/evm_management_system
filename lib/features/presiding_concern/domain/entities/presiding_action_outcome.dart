import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';

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
