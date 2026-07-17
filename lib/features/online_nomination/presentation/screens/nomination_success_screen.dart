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
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: _applicationNumber));
                    AppSnackbar.success(
                      context,
                      LocaleKeys.nominationCopiedId.tr(),
                    );
                  },
                ),
                AppSpacing.vGapLg,
                Row(
                  children: <Widget>[
                    Expanded(
                      child: NominationGovButton(
                        label: LocaleKeys.nominationActionDownloadPdf.tr(),
                        outlined: true,
                        expanded: false,
                        icon: Icons.picture_as_pdf_outlined,
                        onPressed: () => Get.toNamed<void>(
                          AppRoute.nominationReceipt.path,
                          arguments: args,
                        ),
                      ),
                    ),
                    AppSpacing.gapSm,
                    Expanded(
                      child: NominationGovButton(
                        label: LocaleKeys.nominationBackHome.tr(),
                        expanded: false,
                        onPressed: () =>
                            Get.offAllNamed<void>(AppRoute.dashboard.path),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapSm,
                NominationGovButton(
                  label: LocaleKeys.nominationTrackStatusCta.tr(),
                  outlined: true,
                  onPressed: () => Get.toNamed<void>(
                    AppRoute.nominationTrackStatus.path,
                    arguments: args,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
