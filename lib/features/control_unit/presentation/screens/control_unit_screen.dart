import 'package:evm_management_system/shared/models/device_record.dart';
import 'package:evm_management_system/shared/widgets/device_registration_view.dart';
import 'package:flutter/material.dart';

/// Control Unit registration screen.
///
/// DORMANT (2026-08-14 cleanup): reachable only via `AppRoute.controlUnit`,
/// which currently has no live entry point anywhere in the app (no nav
/// tile, drawer item, or `Get.toNamed` call references it — verified by
/// repo-wide search). Kept in place rather than deleted so it can be wired
/// back in without rewriting it. See CLEANUP.md.
class ControlUnitScreen extends StatelessWidget {
  const ControlUnitScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const DeviceRegistrationView(kind: DeviceKind.controlUnit);
}
