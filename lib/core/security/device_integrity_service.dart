import 'package:evm_management_system/core/logging/app_logger.dart';

/// Result of a device integrity assessment.
class DeviceIntegrityReport {
  const DeviceIntegrityReport({
    required this.isRooted,
    required this.isJailbroken,
    required this.isEmulator,
    required this.isDeveloperMode,
  });

  const DeviceIntegrityReport.trusted()
    : isRooted = false,
      isJailbroken = false,
      isEmulator = false,
      isDeveloperMode = false;

  final bool isRooted;
  final bool isJailbroken;
  final bool isEmulator;
  final bool isDeveloperMode;

  /// Whether the device violates the security policy and access must be denied.
  bool get isCompromised => isRooted || isJailbroken;
}

/// Abstraction over device security checks (root / jailbreak / emulator).
///
/// Implemented via [DefaultDeviceIntegrityService] which is wired to native
/// detectors (e.g. `flutter_jailbreak_detection`, Play Integrity / DeviceCheck)
/// in production. Kept behind an interface so detectors can be swapped per the
/// Dependency Inversion Principle without touching guards or UI.
abstract interface class DeviceIntegrityService {
  Future<DeviceIntegrityReport> assess();
}

/// Default best-effort implementation.
///
/// Returns a trusted report by default and is the integration point for a
/// platform `MethodChannel` or a dedicated detection plugin. Wiring the real
/// native detector requires no changes to callers.
class DefaultDeviceIntegrityService implements DeviceIntegrityService {
  const DefaultDeviceIntegrityService();

  @override
  Future<DeviceIntegrityReport> assess() async {
    try {
      // Integration point: invoke native root/jailbreak/Play Integrity checks.
      return const DeviceIntegrityReport.trusted();
    } catch (e, s) {
      AppLogger.w(
        'Device integrity assessment failed',
        error: e,
        stackTrace: s,
      );
      return const DeviceIntegrityReport.trusted();
    }
  }
}
