import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Login elector totals shown under the PO gradient header.
class PresidingElectorHeaderStrip extends StatelessWidget {
  const PresidingElectorHeaderStrip({this.electionContext, super.key});

  final PresidingElectionContext? electionContext;

  static PresidingElectionContext? _fromSession(ServiceSession session) {
    return PresidingElectionContext(
      electionId: 0,
      psId: session.userId,
      areaType: PresidingElectionContext.normalizeAreaType(session.section),
      maleElectors: session.maleElectors,
      femaleElectors: session.femaleElectors,
      otherElectors: session.otherElectors,
      totalElectors: session.totalElectors,
    );
  }

  static PresidingElectionContext? resolveContext(
    PresidingElectionContext? passed,
  ) {
    final ServiceSession? session = AppServices.serviceAuth.session.value;
    if (session != null && session.kind == ServiceLoginKind.presiding) {
      PresidingElectionContextStore.warmFromServiceSession(session);
    }

    final PresidingElectionContext? fromSession =
        session != null &&
            session.kind == ServiceLoginKind.presiding &&
            session.hasElectorCounts
        ? _fromSession(session)
        : null;

    return PresidingElectionContextStore.preferWithElectors(
      PresidingElectionContextStore.preferWithElectors(
        passed,
        PresidingElectionContextStore.memoryCache,
      ),
      fromSession,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Re-resolves when PO service session restores on Android cold-start.
      AppServices.serviceAuth.session.value;
      final PresidingElectionContext? ctx = resolveContext(electionContext);

      if (ctx == null || !ctx.hasElectorCounts) {
        return const SizedBox.shrink();
      }

      final int male = ctx.maleElectors ?? 0;
      final int female = ctx.femaleElectors ?? 0;
      final int other = ctx.otherElectors ?? 0;
      final int total = (ctx.totalElectors ?? 0) > 0
          ? ctx.totalElectors!
          : male + female + other;

      final List<_ElectorCardData> items = <_ElectorCardData>[
        _ElectorCardData(
          label: LocaleKeys.presidingReportColTotal.tr(),
          value: total,
          accent: AppColors.primary,
        ),
        _ElectorCardData(
          label: LocaleKeys.presidingMale.tr(),
          value: male,
          accent: const Color(0xFF10B981),
        ),
        _ElectorCardData(
          label: LocaleKeys.presidingFemale.tr(),
          value: female,
          accent: const Color(0xFFF43F8F),
        ),
        _ElectorCardData(
          label: LocaleKeys.presidingThirdGender.tr(),
          value: other,
          accent: const Color(0xFF8B5CF6),
        ),
      ];

      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: _ElectorCountChip(item: items[0])),
                const SizedBox(width: 8),
                Expanded(child: _ElectorCountChip(item: items[1])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(child: _ElectorCountChip(item: items[2])),
                const SizedBox(width: 8),
                Expanded(child: _ElectorCountChip(item: items[3])),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ElectorCardData {
  const _ElectorCardData({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final int value;
  final Color accent;
}

class _ElectorCountChip extends StatelessWidget {
  const _ElectorCountChip({required this.item});

  final _ElectorCardData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '${item.label} ',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.slate700,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            TextSpan(
              text: '${item.value}',
              style: AppTextStyles.titleMedium.copyWith(
                color: item.accent,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
