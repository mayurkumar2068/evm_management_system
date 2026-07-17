import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Consistent placeholder body for feature modules that are scaffolded but not
/// yet implemented. Keeps every module visually and structurally uniform so new
/// teams can drop their UI in without re-deciding layout.
class ModulePlaceholder extends StatelessWidget {
  const ModulePlaceholder({
    required this.title,
    required this.icon,
    this.description,
    super.key,
  });

  final String title;
  final IconData icon;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      message: description ?? 'This module is ready for implementation.',
      icon: icon,
    );
  }
}
