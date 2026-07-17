import 'package:evm_management_system/shared/models/device_record.dart';
import 'package:evm_management_system/shared/widgets/device_registration_view.dart';
import 'package:flutter/material.dart';

/// Control Unit registration screen.
class ControlUnitScreen extends StatelessWidget {
  const ControlUnitScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const DeviceRegistrationView(kind: DeviceKind.controlUnit);
}
