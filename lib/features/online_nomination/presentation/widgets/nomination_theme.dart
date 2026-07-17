import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Nomination-specific gradient styling built on [AppGradients.nomination].
abstract final class NominationTheme {
  static const Gradient primary = AppGradients.nomination;
  static const Gradient button = AppGradients.nominationButton;

  static BoxDecoration gradientCircle({double? radius}) => BoxDecoration(
    gradient: button,
    borderRadius: radius == null ? null : BorderRadius.circular(radius),
    shape: radius == null ? BoxShape.circle : BoxShape.rectangle,
  );

  static BoxDecoration gradientPill() =>
      const BoxDecoration(gradient: button, borderRadius: AppRadius.brPill);
}

/// Renders [text] with the nomination brand gradient.
class NominationGradientText extends StatelessWidget {
  const NominationGradientText(
    this.text, {
    required this.style,
    this.textAlign,
    this.maxLines,
    super.key,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) =>
          NominationTheme.primary.createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        style: AppTextStyles.withDevanagariFallback(
          style.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

/// Circular icon container with theme gradient background.
class NominationGradientIcon extends StatelessWidget {
  const NominationGradientIcon({
    required this.icon,
    this.size = 48,
    this.iconSize = 24,
    super.key,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: NominationTheme.gradientCircle(),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
