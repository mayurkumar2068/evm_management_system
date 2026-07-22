import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Provides [Scaffold] + [Material] so text inherits theme and Hindi glyphs
/// render without debug underlines.
class NominationScreenShell extends StatelessWidget {
  const NominationScreenShell({required this.body, super.key});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: Material(
        type: MaterialType.transparency,
        color: context.appBackground,
        child: body,
      ),
    );
  }
}
