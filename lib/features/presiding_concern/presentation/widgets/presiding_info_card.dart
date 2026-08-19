import 'package:evm_management_system/features/presiding_concern/presentation/theme/presiding_ui_tokens.dart';
import 'package:flutter/material.dart';

class PresidingInfoCard extends StatelessWidget {
  const PresidingInfoCard({
    required this.child,
    this.padding,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PresidingUiTokens.cardGreenSurface,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: Border.all(color: PresidingUiTokens.cardGreenBorder),
      ),
      child: child,
    );
  }
}
