import 'package:evm_management_system/design_system/mpsec/tokens/mpsec_tokens.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Material 3 enterprise card with 24px radius and soft elevation.
class MpSecEnterpriseCard extends StatelessWidget {
  const MpSecEnterpriseCard({
    required this.child,
    this.title,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(MpSecTokens.cardRadius),
        border: Border.all(color: MpSecTokens.softBlue.withValues(alpha: 0.18)),
        boxShadow: MpSecTokens.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Text(
              title!,
              style: AppTextStyles.titleMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );

    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MpSecTokens.cardRadius),
          child: content,
        ),
      ),
    );
  }
}
