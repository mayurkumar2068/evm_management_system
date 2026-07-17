import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_icons.dart';
import 'package:evm_management_system/shared/widgets/module_placeholder.dart';
import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) => ModulePlaceholder(
    title: LocaleKeys.menuHelpSupport.tr(),
    icon: AppIcons.help,
  );
}
