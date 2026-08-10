import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_party_details_form.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Full-screen fallback route for polling-party details (dashboard uses bottom sheet).
class PresidingPartyDetailsScreen extends StatelessWidget {
  const PresidingPartyDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: Column(
        children: <Widget>[
          AppGradientHeader(
            centerTitle: true,
            title: LocaleKeys.presidingPartyTitle.tr(),
            subtitle: LocaleKeys.presidingPartySubtitle.tr(),
            leading: AppCircleBackButton(onTap: () => Get.back<void>()),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.slate100),
                ),
                child: PresidingPartyDetailsForm(
                  onCompleted: () => Get.back<void>(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
