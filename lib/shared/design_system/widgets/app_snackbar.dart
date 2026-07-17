import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_icons.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

enum AppSnackbarType { success, error, info, warning }

/// Consistent, themed snackbars. Screens call these helpers instead of building
/// raw [SnackBar]s, so every toast looks and behaves the same.
abstract final class AppSnackbar {
  static void success(BuildContext context, String message) =>
      _show(context, message, AppSnackbarType.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppSnackbarType.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, AppSnackbarType.info);

  static void warning(BuildContext context, String message) =>
      _show(context, message, AppSnackbarType.warning);

  static void _show(
    BuildContext context,
    String message,
    AppSnackbarType type,
  ) {
    final ({Color color, IconData icon}) style = switch (type) {
      AppSnackbarType.success => (
        color: AppColors.success,
        icon: AppIcons.success,
      ),
      AppSnackbarType.error => (color: AppColors.error, icon: AppIcons.error),
      AppSnackbarType.warning => (
        color: AppColors.warning,
        icon: AppIcons.error,
      ),
      AppSnackbarType.info => (color: AppColors.info, icon: AppIcons.about),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: style.color,
          content: Row(
            children: <Widget>[
              Icon(style.icon, color: AppColors.onPrimary, size: 20),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.onPrimary),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
