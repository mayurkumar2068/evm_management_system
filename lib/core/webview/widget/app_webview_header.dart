import 'dart:typed_data';

import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Soft blue→mint WebView chrome — matches Booth Survey / login hero.
class AppWebViewHeader extends StatelessWidget {
  const AppWebViewHeader({
    required this.title,
    required this.host,
    required this.onBack,
    required this.onReload,
    this.icon,
    super.key,
  });

  final String title;
  final String host;
  final Uint8List? icon;
  final VoidCallback onBack;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x383B82F6),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -36,
            top: -28,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(6, top + 6, 6, 14),
            child: Row(
              children: <Widget>[
                _ChromeIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: onBack,
                ),
                if (icon != null) ...<Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: MemoryImage(icon!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.lock_rounded,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              host,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _ChromeIconButton(
                  icon: Icons.refresh_rounded,
                  onPressed: onReload,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.brMd,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
