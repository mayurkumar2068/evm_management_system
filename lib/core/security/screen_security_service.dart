import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:flutter/services.dart';

abstract interface class ScreenSecurityService {
  Future<void> enableSecureMode();

  Future<void> disableSecureMode();
}

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
