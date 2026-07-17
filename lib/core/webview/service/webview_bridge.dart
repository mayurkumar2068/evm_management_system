import 'package:evm_management_system/core/media/app_image_picker_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../config/webview_config.dart';

/// Native side of the reusable JS bridge. Registered once per controller; every
/// page calls `window.AppBridge.*` and the same Flutter handlers respond.
class WebViewBridge {
  WebViewBridge({
    this.onClose,
    this.onLogout,
    this.onNavigate,
    this.onScanner,
    this.onMessage,
    this.onSubmitForm,
  });

  static const String handlerName = 'app_bridge';

  /// Native image picker. Routing camera/gallery capture through this (instead
  /// of the WebView's built-in `<input capture>` chooser) writes the photo to
  /// the app cache via image_picker's own FileProvider and never inserts into
  /// MediaStore — sidestepping OEM camera crashes (e.g. Vivo VCameraMode NPE).
  final AppImagePickerService _imagePickerService = AppImagePickerService();

  final VoidCallback? onClose;
  final VoidCallback? onLogout;
  final ValueChanged<String>? onNavigate;
  final VoidCallback? onScanner;
  final ValueChanged<WebBridgeMessage>? onMessage;

  /// Offline-first form submit from any Angular page.
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> payload)?
  onSubmitForm;

  void register(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: handlerName,
      callback: _handle,
    );
  }

  Future<dynamic> _handle(List<dynamic> args) async {
    final String action = args.isNotEmpty ? (args[0]?.toString() ?? '') : '';
    final Map<String, dynamic> payload = (args.length > 1 && args[1] is Map)
        ? Map<String, dynamic>.from(args[1] as Map)
        : <String, dynamic>{};

    switch (action) {
      case 'close':
        onClose?.call();
        return <String, dynamic>{'ok': true};
      case 'logout':
        onLogout?.call();
        return <String, dynamic>{'ok': true};
      case 'navigate':
        onNavigate?.call(payload['route']?.toString() ?? '');
        return <String, dynamic>{'ok': true};
      case 'openScanner':
        onScanner?.call();
        return <String, dynamic>{'ok': true};
      case 'pickImage':
        return _pickImage(payload);
      case 'submitForm':
        if (onSubmitForm == null) {
          return <String, dynamic>{
            'ok': false,
            'success': false,
            'error': 'submit_unavailable',
          };
        }
        return onSubmitForm!(payload);
      case 'share':
        final String text = <String?>[
          payload['text']?.toString(),
          payload['url']?.toString(),
        ].where((String? e) => e != null && e.isNotEmpty).join(' ');
        if (text.isNotEmpty) {
          await SharePlus.instance.share(ShareParams(text: text));
        }
        return <String, dynamic>{'ok': true};
      case 'clipboardCopy':
        await Clipboard.setData(
          ClipboardData(text: payload['text']?.toString() ?? ''),
        );
        return <String, dynamic>{'ok': true};
      case 'log':
        debugPrint('[webview] ${payload['message']}');
        return <String, dynamic>{'ok': true};
      case 'message':
        onMessage?.call(
          WebBridgeMessage(
            payload['action']?.toString() ?? 'message',
            (payload['payload'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{},
          ),
        );
        return <String, dynamic>{'ok': true};
      default:
        return <String, dynamic>{'ok': false, 'error': 'unknown_action'};
    }
  }

  /// Captures (camera) or picks (gallery) a single image natively and returns
  /// it to the web as a base64 JPEG data URL:
  ///   { ok: true, dataUrl: 'data:image/jpeg;base64,...' }
  /// On cancel: { ok: false, cancelled: true }. On error: { ok: false, error }.
  Future<Map<String, dynamic>> _pickImage(Map<String, dynamic> payload) async {
    try {
      final bool fromCamera =
          (payload['source']?.toString() ?? 'camera') == 'camera';
      final double maxSide = _toDouble(payload['maxWidth']) ?? 1280;
      final int quality = (_toDouble(payload['quality']) ?? 60).round().clamp(
        1,
        100,
      );

      final AppPickedImage? picked = await _imagePickerService
          .pickCompressedImage(
            source: fromCamera ? ImageSource.camera : ImageSource.gallery,
            maxSide: maxSide,
            quality: quality,
          );

      if (picked == null) {
        return <String, dynamic>{'ok': false, 'cancelled': true};
      }

      return <String, dynamic>{'ok': true, 'dataUrl': picked.dataUrl};
    } catch (e) {
      debugPrint('[webview] pickImage failed: $e');
      return <String, dynamic>{'ok': false, 'error': e.toString()};
    }
  }

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
