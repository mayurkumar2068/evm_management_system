import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_spacing.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Centralized loading indicator with an optional message and a full-screen
/// blocking overlay variant.
class AppLoader extends StatelessWidget {
  const AppLoader({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          if (message != null) ...<Widget>[
            AppSpacing.vGapMd,
            Text(message!, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }

  /// Shows a modal blocking loader; returns a callback to dismiss it.
  static VoidCallback showOverlay(BuildContext context, {String? message}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          PopScope(canPop: false, child: AppLoader(message: message)),
    );
    return () => Navigator.of(context, rootNavigator: true).pop();
  }
}
