import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:flutter/services.dart';

/// Controls screenshot / screen-recording protection.
///
/// Abstracted behind an interface so the native secure-flag implementation
/// (Android `FLAG_SECURE`, iOS screenshot notifications) can be swapped without
/// touching UI code.
abstract interface class ScreenSecurityService {
  /// Blocks screenshots and hides app content in the recents switcher.
  Future<void> enableSecureMode();

  /// Re-allows screenshots (e.g. on non-sensitive screens).
  Future<void> disableSecureMode();
}

/// Default implementation using a platform [MethodChannel].
///
/// The corresponding native handler applies `FLAG_SECURE` on Android and posts
/// screenshot notifications on iOS. Missing handlers degrade gracefully.
class DefaultScreenSecurityService implements ScreenSecurityService {
  const DefaultScreenSecurityService();

  static const MethodChannel _channel = MethodChannel('evm/screen_security');

  @override
  Future<void> enableSecureMode() => _invoke('enableSecure');

  @override
  Future<void> disableSecureMode() => _invoke('disableSecure');

  Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      AppLogger.w('Screen security handler not registered for "$method"');
    } catch (e, s) {
      AppLogger.w('Screen security "$method" failed', error: e, stackTrace: s);
    }
  }
}
