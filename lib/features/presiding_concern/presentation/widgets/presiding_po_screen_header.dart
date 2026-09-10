import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_elector_header_strip.dart';
import 'package:evm_management_system/shared/design_system/widgets/app_gradient_header.dart';
import 'package:flutter/material.dart';

class PresidingPoScreenHeader extends StatelessWidget {
  const PresidingPoScreenHeader({
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.electionContext,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final PresidingElectionContext? electionContext;

  @override
  Widget build(BuildContext context) {
    return AppGradientHeader(
      centerTitle: true,
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      bottom: PresidingElectorHeaderStrip(electionContext: electionContext),
    );
  }
}
