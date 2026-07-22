import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_radius.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Standardized confirmation / message dialogs.
abstract final class AppDialog {
  /// Shows a confirmation dialog. Resolves to `true` when confirmed.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        final ColorScheme scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: scheme.surface,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
          title: Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(color: scheme.onSurface),
          ),
          content: Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(cancelLabel ?? LocaleKeys.commonCancel.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: destructive ? Colors.red : scheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmLabel ?? LocaleKeys.commonOk.tr()),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
