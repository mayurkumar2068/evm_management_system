import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Standard labelled text input with validation and optional obscuring.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.enabled = true,
    this.readOnly = false,
    this.isRequired = false,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final IconData? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool readOnly;
  final bool isRequired;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final List<String>? autofillHints;
  final TextCapitalization textCapitalization;

  String get _labelText => isRequired ? '$label *' : label;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        enabled: enabled,
        readOnly: readOnly,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        maxLines: maxLines,
        minLines: minLines,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        onTap: onTap,
        validator: validator,
        autofillHints: autofillHints,
        textCapitalization: textCapitalization,
        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.slate800),
        decoration: InputDecoration(
          labelText: _labelText,
          hintText: hint,
          errorText: errorText,
          helperText: helperText,
          counterText: maxLength == null ? null : '',
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 22),
          suffixIcon:
              suffix ??
              (suffixIcon == null ? null : Icon(suffixIcon, size: 22)),
        ),
      ),
    );
  }
}
