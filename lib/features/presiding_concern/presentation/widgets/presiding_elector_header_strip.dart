import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Login elector totals (total / male / female / other) for PO gradient headers.
class PresidingElectorHeaderStrip extends StatelessWidget {
  const PresidingElectorHeaderStrip({this.electionContext, super.key});

  /// When set, skips async load from secure storage.
  final PresidingElectionContext? electionContext;

  static bool hasCounts(PresidingElectionContext? ctx) {
    if (ctx == null) return false;
    return (ctx.totalElectors ?? 0) > 0 ||
        (ctx.maleElectors ?? 0) > 0 ||
        (ctx.femaleElectors ?? 0) > 0 ||
        (ctx.otherElectors ?? 0) > 0;
  }

  static int? resolvedTotal(PresidingElectionContext ctx) {
    if (ctx.totalElectors != null && ctx.totalElectors! > 0) {
      return ctx.totalElectors;
    }
    final int sum = (ctx.maleElectors ?? 0) +
        (ctx.femaleElectors ?? 0) +
        (ctx.otherElectors ?? 0);
    return sum > 0 ? sum : null;
  }

  @override
  Widget build(BuildContext context) {
    final PresidingElectionContext? inline = electionContext;
    if (inline != null) {
      if (!hasCounts(inline)) return const SizedBox.shrink();
      return _Strip(electionContext: inline);
    }

    return FutureBuilder<PresidingElectionContext?>(
      future: PresidingElectionContextStore(AppServices.secureStorage).read(),
      builder: (BuildContext context, AsyncSnapshot<PresidingElectionContext?> snap) {
        final PresidingElectionContext? ctx = snap.data;
        if (!hasCounts(ctx)) return const SizedBox.shrink();
        return _Strip(electionContext: ctx!);
      },
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.electionContext});

  final PresidingElectionContext electionContext;

  @override
  Widget build(BuildContext context) {
    final PresidingElectionContext ctx = electionContext;
    final int? total = PresidingElectorHeaderStrip.resolvedTotal(ctx);

    final List<Widget> chips = <Widget>[];

    void addChip({required String label, required int value}) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 6));
      chips.add(
        Expanded(
          child: _ElectorCountChip(label: label, value: value),
        ),
      );
    }

    if (total != null) {
      addChip(label: LocaleKeys.presidingReportColTotal.tr(), value: total);
    }
    if (ctx.maleElectors != null) {
      addChip(label: LocaleKeys.presidingMale.tr(), value: ctx.maleElectors!);
    }
    if (ctx.femaleElectors != null) {
      addChip(
        label: LocaleKeys.presidingFemale.tr(),
        value: ctx.femaleElectors!,
      );
    }
    if (ctx.otherElectors != null) {
      addChip(
        label: LocaleKeys.presidingThirdGender.tr(),
        value: ctx.otherElectors!,
      );
    }

    return Row(children: chips);
  }
}

/// White chip: `Label - count` in black (same style for total / male / female / other).
class _ElectorCountChip extends StatelessWidget {
  const _ElectorCountChip({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              text: '$label - ',
              style: AppTextStyles.caption.copyWith(
                color: Colors.black.withValues(alpha: 0.65),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            TextSpan(
              text: '$value',
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                height: 1.2,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
