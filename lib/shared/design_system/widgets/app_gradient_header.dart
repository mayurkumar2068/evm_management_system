import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_gradients.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Signature gradient header band used at the top of primary screens. Renders
/// the brand gradient with a soft saffron glow, a title/subtitle and optional
/// leading (back) and trailing widgets, plus arbitrary [bottom] content.
class AppGradientHeader extends StatelessWidget {
  const AppGradientHeader({
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.bottom,
    this.gradient = AppGradients.header,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 20),
    super.key,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottom;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.secondary.withValues(alpha: 0.18),
                    AppColors.secondary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: padding.add(EdgeInsets.only(top: topInset)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (title != null || leading != null || trailing != null)
                  Row(
                    children: <Widget>[
                      if (leading != null) ...<Widget>[
                        leading!,
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (title != null)
                              Text(
                                title!,
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                if (bottom != null) ...<Widget>[
                  if (title != null) const SizedBox(height: 18),
                  bottom!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular translucent icon button used inside gradient headers.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          if (badgeCount != null && badgeCount! > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small white circular back button used on light-background screens.
class AppCircleBackButton extends StatelessWidget {
  const AppCircleBackButton({
    required this.onTap,
    this.light = false,
    super.key,
  });

  final VoidCallback onTap;

  /// When true, renders a translucent style for gradient backgrounds.
  final bool light;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: light ? Colors.white.withValues(alpha: 0.15) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: light
              ? null
              : const <BoxShadow>[
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(
          Icons.chevron_left_rounded,
          color: light ? Colors.white : AppColors.slate700,
          size: 22,
        ),
      ),
    );
  }
}
