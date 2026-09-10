import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Soft decorative orbs behind PO / PS auth screens.
class ServiceAuthBackdrop extends StatelessWidget {
  const ServiceAuthBackdrop({
    super.key,
    this.leftOrbTop = 120,
  });

  final double leftOrbTop;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            top: leftOrbTop,
            left: -90,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft survey-style hero: logo + title row, decorative orbs.
class ServiceAuthHero extends StatelessWidget {
  const ServiceAuthHero({
    required this.title,
    this.subtitle,
    this.showBottomOrb = true,
    this.compactTitle = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool showBottomOrb;
  final bool compactTitle;

  @override
  Widget build(BuildContext context) {
    final String? subtitleText = subtitle?.trim();
    final bool hasSubtitle =
        subtitleText != null && subtitleText.isNotEmpty;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: AppRadius.brXl,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          if (showBottomOrb)
            Positioned(
              right: 28,
              bottom: -36,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const ClipOval(
                        child: BrandLogo(width: 40),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: (compactTitle
                                ? AppTextStyles.titleMedium
                                : AppTextStyles.titleLarge)
                            .copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: compactTitle ? 1.25 : 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasSubtitle) ...<Widget>[
                  const SizedBox(height: 20),
                  Text(
                    subtitleText,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceAuthHintStrip extends StatelessWidget {
  const ServiceAuthHintStrip({required this.text, super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: AppColors.primaryDark.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.slate600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceAuthSubmitButton extends StatelessWidget {
  const ServiceAuthSubmitButton({
    required this.busy,
    required this.onPressed,
    required this.text,
    super.key,
  });
  final bool busy;
  final VoidCallback onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.primaryButton,
          borderRadius: AppRadius.brPill,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: busy ? null : onPressed,
            borderRadius: AppRadius.brPill,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          text,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Label-above soft field — same chrome for focused / unfocused.
class ServiceAuthSoftField extends StatelessWidget {
  const ServiceAuthSoftField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    super.key,
    this.enabled = true,
    this.obscure = false,
    this.suffix,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final bool focused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: focused ? AppColors.primaryBright : context.appMutedStrong,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: focused ? context.appSurface : context.appChip,
            borderRadius: AppRadius.brLg,
            border: Border.all(
              color: focused ? AppColors.primary : context.appOutline,
              width: focused ? 1.6 : 1,
            ),
            boxShadow: focused
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            obscureText: obscure,
            textInputAction: textInputAction,
            keyboardType: keyboardType,
            onSubmitted: onSubmitted,
            inputFormatters: inputFormatters ??
                (obscure
                    ? null
                    : <TextInputFormatter>[
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ]),
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.appOnSurface,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: context.appMuted,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: Icon(
                icon,
                color: focused ? AppColors.primary : context.appMuted,
                size: 20,
              ),
              suffixIcon: suffix,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// White elevated card wrapping auth form content.
class ServiceAuthFormCard extends StatelessWidget {
  const ServiceAuthFormCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: context.appOutline),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: context.isAppDark ? 0.18 : 0.08,
            ),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
