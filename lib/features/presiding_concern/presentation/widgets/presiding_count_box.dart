import 'package:evm_management_system/features/presiding_concern/domain/turnout_count_validator.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PresidingCountBox extends StatelessWidget {
  const PresidingCountBox({
    required this.controller,
    required this.disabled,
    required this.accentColor,
    super.key,
  });

  final TextEditingController controller;
  final bool disabled;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        enabled: !disabled,
        readOnly: disabled,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
          const ReplaceInitialZeroFormatter(),
          LengthLimitingTextInputFormatter(
            TurnoutCountValidator.maxInputDigits,
          ),
        ],
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 10,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
        ),
      ),
    );
  }
}

/// When field shows only `0`, first typed digit replaces it (e.g. type `5` → `5`, not `05`).
class ReplaceInitialZeroFormatter extends TextInputFormatter {
  const ReplaceInitialZeroFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (oldValue.text == '0' &&
        newValue.text.length > 1 &&
        newValue.text.startsWith('0')) {
      final String replaced = newValue.text.substring(1);
      return TextEditingValue(
        text: replaced,
        selection: TextSelection.collapsed(offset: replaced.length),
      );
    }
    return newValue;
  }
}
