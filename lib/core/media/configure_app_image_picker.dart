import 'package:flutter/foundation.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void configureAppImagePicker() {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }
  final ImagePickerPlatform impl = ImagePickerPlatform.instance;
  if (impl is ImagePickerAndroid) {
    impl.useAndroidPhotoPicker = true;
  }
}
