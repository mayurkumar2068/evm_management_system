import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shows camera vs gallery options. Returns chosen [ImageSource] or `null`.
Future<ImageSource?> showImageSourcePickerSheet(BuildContext context) {
  return AppBottomSheet.show<ImageSource>(
    context,
    title: LocaleKeys.commonPickImageSource.tr(),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: Text(LocaleKeys.commonTakePhoto.tr()),
          onTap: () => Navigator.of(context).pop(ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(LocaleKeys.commonChooseFromGallery.tr()),
          onTap: () => Navigator.of(context).pop(ImageSource.gallery),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocaleKeys.commonCancel.tr()),
          ),
        ),
      ],
    ),
  );
}
