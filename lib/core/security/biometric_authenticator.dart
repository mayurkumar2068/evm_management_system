import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:local_auth/local_auth.dart';

/// Wraps platform biometric (fingerprint / Face ID) authentication.
class BiometricAuthenticator {
  BiometricAuthenticator([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Whether the device has biometric hardware that is enrolled and usable.
  Future<bool> isAvailable() async {
    try {
      final bool supported = await _auth.isDeviceSupported();
      final bool canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (e, s) {
      AppLogger.w(
        'Biometric availability check failed',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  /// Prompts the user for biometric authentication. Returns `true` on success.
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e, s) {
      AppLogger.w('Biometric authentication failed', error: e, stackTrace: s);
      return false;
    }
  }
}
