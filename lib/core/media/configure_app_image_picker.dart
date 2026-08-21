import 'package:flutter/foundation.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Configures [image_picker] for store-safe photo selection.
///
/// Android: force the system [Photo Picker](https://developer.android.com/training/data-storage/shared/photopicker)
/// on API 32 and below as well (API 33+ already uses it). Gallery picks then
/// need **no** `READ_MEDIA_*` / `READ_EXTERNAL_STORAGE` permission.
///
/// Call once at process start, before any `pickImage` / `pickMultiImage`.
void configureAppImagePicker() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }
  final ImagePickerPlatform impl = ImagePickerPlatform.instance;
  if (impl is ImagePickerAndroid) {
    impl.useAndroidPhotoPicker = true;
  }
}
