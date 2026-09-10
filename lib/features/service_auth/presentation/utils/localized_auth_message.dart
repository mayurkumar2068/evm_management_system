import 'package:easy_localization/easy_localization.dart';

String localizedAuthMessage(String message) {
  if (message.startsWith('auth.') ||
      message.startsWith('error.') ||
      message.startsWith('service_auth.') ||
      message.startsWith('common.')) {
    return message.tr();
  }
  return message;
}
