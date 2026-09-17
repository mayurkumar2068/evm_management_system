import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class AppPickedImage {
  const AppPickedImage({
    required this.path,
    required this.fileName,
    required this.bytes,
    required this.mimeType,
  });

  final String path;
  final String fileName;
  final Uint8List bytes;
  final String mimeType;

  String get dataUrl => 'data:$mimeType;base64,${base64Encode(bytes)}';
}

class AppImagePickerService {
  AppImagePickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  // L2 VAPT F-04/F-05: defense-in-depth allowlist. image_picker already
  // scopes the source to the OS camera/gallery UI (images only), but we
  // still reject anything outside this extension set before it leaves this
  // service — server-side validation remains the primary control.
  static const Set<String> _allowedExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };

  Future<AppPickedImage?> pickCompressedImage({
    required ImageSource source,
    double maxSide = 1280,
    int quality = 60,
  }) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: quality.clamp(1, 100),
      preferredCameraDevice: CameraDevice.rear,

      requestFullMetadata: false,
    );
    if (file == null) {
      return null;
    }
    if (!_hasAllowedExtension(file.path)) {
      return null;
    }

    final Uint8List bytes = await file.readAsBytes();
    final String fileName = _fileNameFromPath(file.path);
    return AppPickedImage(
      path: file.path,
      fileName: fileName,
      bytes: bytes,
      mimeType: _mimeForPath(file.path),
    );
  }

  static bool _hasAllowedExtension(String path) {
    final String p = path.toLowerCase();
    final int dot = p.lastIndexOf('.');
    if (dot == -1 || dot == p.length - 1) return false;
    return _allowedExtensions.contains(p.substring(dot + 1));
  }

  Future<String> persistToTemp({
    required Uint8List bytes,
    required String prefix,
  }) async {
    final Directory dir = await getTemporaryDirectory();
    final String fileName =
        '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _fileNameFromPath(String path) {
    final int index = path.lastIndexOf(Platform.pathSeparator);
    if (index < 0) {
      return path;
    }
    return path.substring(index + 1);
  }

  static String _mimeForPath(String path) {
    final String p = path.toLowerCase();
    if (p.endsWith('.png')) {
      return 'image/png';
    }
    if (p.endsWith('.webp')) {
      return 'image/webp';
    }
    if (p.endsWith('.heic') || p.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }
}
