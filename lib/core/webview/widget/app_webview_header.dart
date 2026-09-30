import 'package:MPSECNET/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppWebViewHeader extends StatelessWidget {
  const AppWebViewHeader({
    required this.title,
    required this.onBack,
    required this.onReload,
    this.icon,
    this.onLogout,
    super.key,
  });

  final String title;
  final Uint8List? icon;
  final VoidCallback onBack;
  final VoidCallback onReload;

  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return AppGradientHeader(
      leading: AppCircleBackButton(
        onTap: onBack,
        light: true,
      ),
      title: title,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppCircleActionButton(
            icon: Icons.refresh_rounded,
            onTap: onReload,
          ),
          if (onLogout != null) ...<Widget>[
            const SizedBox(width: 8),
            AppCircleActionButton(
              icon: Icons.logout_rounded,
              onTap: onLogout!,
            ),
          ],
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
    );
  }
}
