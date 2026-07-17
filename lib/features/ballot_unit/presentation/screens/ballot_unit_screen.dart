import 'package:evm_management_system/shared/models/device_record.dart';
import 'package:evm_management_system/shared/widgets/device_registration_view.dart';
import 'package:flutter/material.dart';

/// Ballot Unit registration screen.
class BallotUnitScreen extends StatelessWidget {
  const BallotUnitScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const DeviceRegistrationView(kind: DeviceKind.ballotUnit);
}
