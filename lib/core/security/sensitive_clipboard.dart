import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Clipboard helper that marks copied text as sensitive on Android 13+.
///
/// Falls back to [Clipboard.setData] on other platforms / channel failures so
/// WebView bridge copy UX stays intact (L1 VULN-010).
abstract final class SensitiveClipboard {
  static const MethodChannel _channel = MethodChannel('mpsecnet/clipboard');

  static Future<void> setText(String text) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod<void>('setSensitiveText', <String, Object?>{
          'text': text,
        });
        return;
      } catch (_) {
        // Fall through to Flutter clipboard.
      }
    }
    await Clipboard.setData(ClipboardData(text: text));
  }
}
