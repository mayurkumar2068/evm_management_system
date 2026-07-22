import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:evm_management_system/shared/design_system/widgets/app_gradient_header.dart';
import 'package:flutter/material.dart';

/// Lightweight top bar for light-background screens: an optional back button,
/// a title and optional trailing actions. Honours the status-bar inset.
class AppTopBar extends StatelessWidget {
  const AppTopBar({required this.title, this.onBack, this.trailing, super.key});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 12),
      child: Row(
        children: <Widget>[
          if (onBack != null) ...<Widget>[
            AppCircleBackButton(onTap: onBack!),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
