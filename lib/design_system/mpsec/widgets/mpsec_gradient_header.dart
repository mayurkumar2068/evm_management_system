import 'package:evm_management_system/design_system/mpsec/tokens/mpsec_tokens.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Branded presiding-officer header with gradient, avatar and menu affordance.
class MpSecGradientHeader extends StatelessWidget {
  const MpSecGradientHeader({
    required this.title,
    required this.subtitle,
    required this.instruction,
    this.leading,
    super.key,
  });

  final String title;
  final String subtitle;
  final String instruction;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: MpSecTokens.headerGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(MpSecTokens.cardRadius),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              instruction,
              style: AppTextStyles.caption.copyWith(
                color: scheme.onPrimary.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
