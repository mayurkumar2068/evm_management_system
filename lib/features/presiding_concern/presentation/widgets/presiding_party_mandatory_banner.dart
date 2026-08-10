import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Always-visible PO dashboard entry to fill polling-party details.
class PresidingPartyMandatoryBanner extends StatelessWidget {
  const PresidingPartyMandatoryBanner({required this.onTap, super.key});

  final VoidCallback onTap;

  String _text(BuildContext context, String key, String hi, String en) {
    final String translated = key.tr();
    if (translated != key && !translated.startsWith('presiding.')) {
      return translated;
    }
    final bool isHi = context.locale.languageCode.toLowerCase().startsWith('hi');
    return isHi ? hi : en;
  }

  @override
  Widget build(BuildContext context) {
    final String body = _text(
      context,
      LocaleKeys.presidingPartyMandatoryBanner,
      '(अनिवार्य) मतदान दल की जानकारी लिखें',
      '(Mandatory) Enter polling party details',
    );
    final String action = _text(
      context,
      LocaleKeys.presidingPartyFillButton,
      'दल विवरण',
      'Party details',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0B2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              body,
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF9A3412),
                fontWeight: FontWeight.w500,
                height: 1.35,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEA580C).withValues(alpha: 0.8),
              side: BorderSide(
                color: const Color(0xFFEA580C).withValues(alpha: 0.8),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              action,
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFFEA580C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
