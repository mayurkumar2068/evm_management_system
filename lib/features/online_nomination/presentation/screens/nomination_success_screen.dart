import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/online_nomination_widgets.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

class NominationSuccessScreen extends StatelessWidget {
  const NominationSuccessScreen({required this.args, super.key});

  final NominationFlowArgs args;

  String get _applicationNumber =>
      args.applicationNumber ?? 'NOM/2026/IND/000123';

  void _goToLogin() {
    Get.offAllNamed<void>(
      AppRoute.nominationTrackStatus.path,
      arguments: args,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NominationScreenShell(
      body: Column(
        children: <Widget>[
          AppTopBar(
            title: LocaleKeys.nominationSuccess.tr(),
            onBack: () => Get.back<void>(),
          ),
          Expanded(
            child: ListView(
              padding: AppSpacing.page,
              children: <Widget>[
                NominationSuccessCard(
                  applicationNumber: _applicationNumber,
                  submittedAt: args.submittedAt,
                  userId: args.regUserId,
                  password: args.regPassword,
                  onCopy: () {
                    final String copyText = <String>[
                      _applicationNumber,
                      if (args.regUserId != null &&
                          args.regUserId!.trim().isNotEmpty)
                        'User ID: ${args.regUserId}',
                      if (args.regPassword != null &&
                          args.regPassword!.trim().isNotEmpty)
                        'Password: ${args.regPassword}',
                    ].join('\n');
                    Clipboard.setData(ClipboardData(text: copyText));
                    AppSnackbar.success(
                      context,
                      LocaleKeys.nominationCopiedId.tr(),
                    );
                  },
                ),
                AppSpacing.vGapLg,
                NominationGovButton(
                  label: LocaleKeys.nominationEntryLoginTitle.tr(),
                  icon: Icons.login_rounded,
                  onPressed: _goToLogin,
                ),
                AppSpacing.vGapSm,
                NominationGovButton(
                  label: LocaleKeys.nominationBackHome.tr(),
                  outlined: true,
                  onPressed: () =>
                      Get.offAllNamed<void>(AppRoute.dashboard.path),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
