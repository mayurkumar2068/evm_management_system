import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_gradients.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppGradientHeader extends StatelessWidget {
  const AppGradientHeader({
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.bottom,
    this.centerTitle = false,
    this.gradient = AppGradients.header,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 20),
    super.key,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottom;

  final bool centerTitle;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;

  static const double _sideSlot = 38;

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
                  centerTitle
                      ? SizedBox(
                          width: double.infinity,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              if (leading != null)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: leading!,
                                ),
                              if (trailing != null)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: trailing!,
                                ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      leading != null || trailing != null
                                      ? _sideSlot + 8
                                      : 0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    if (title != null)
                                      Text(
                                        title!,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.titleLarge
                                            .copyWith(color: Colors.white),
                                      ),
                                    if (subtitle != null)
                                      Text(
                                        subtitle!,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.caption.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
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
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (trailing != null) trailing!,
                          ],
                        ),
                if (bottom != null) ...<Widget>[
                  if (title != null) const SizedBox(height: 14),
                  bottom!,
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

class AppCircleBackButton extends StatelessWidget {
  const AppCircleBackButton({
    required this.onTap,
    this.light = false,
    super.key,
  });

  final VoidCallback onTap;

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
