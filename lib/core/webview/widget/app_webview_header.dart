import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Soft blue→mint WebView chrome — follows app light / dark theme.
class AppWebViewHeader extends StatelessWidget {
  const AppWebViewHeader({
    required this.title,
    required this.onBack,
    required this.onReload,
    this.icon,
    super.key,
  });

  final String title;
  final Uint8List? icon;
  final VoidCallback onBack;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    final bool isDark = context.isAppDark;
    final Color titleColor = isDark ? context.appOnSurface : Colors.white;
    final Color iconWell = isDark
        ? context.appChip
        : Colors.white.withValues(alpha: 0.18);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.light,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: isDark ? null : AppGradients.header,
          color: isDark ? context.appSurface : null,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
          border: isDark
              ? Border(bottom: BorderSide(color: context.appOutline))
              : null,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : const Color(0x383B82F6),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            if (!isDark)
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
                    color: titleColor,
                    background: iconWell,
                    onPressed: onBack,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  if (icon != null) ...<Widget>[
                    Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: iconWell,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.appOutline),
                        image: DecorationImage(
                          image: MemoryImage(icon!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _ChromeIconButton(
                    icon: Icons.refresh_rounded,
                    color: titleColor,
                    background: iconWell,
                    onPressed: onReload,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.brMd,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
