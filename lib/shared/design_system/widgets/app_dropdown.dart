import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_radius.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:flutter/material.dart';

abstract final class AppFieldDecoration {
  static InputDecoration dropdown({
    required String labelText,
    String? errorText,
    String? helperText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: labelText,
      errorText: errorText,
      helperText: helperText,
      filled: true,
      fillColor: enabled ? AppColors.surface : AppColors.slate100,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      alignLabelWithHint: true,
      isDense: true,
      contentPadding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      labelStyle: AppTextStyles.caption.copyWith(
        color: AppColors.slate500,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: AppTextStyles.label.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      helperStyle: AppTextStyles.caption.copyWith(color: AppColors.slate500),
      errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
      errorMaxLines: 2,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(
              prefixIcon,
              size: 20,
              color: enabled ? AppColors.slate500 : AppColors.slate300,
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      suffixIcon: suffixIcon,
      border: _border(AppColors.slate200),
      enabledBorder: _border(AppColors.slate200),
      disabledBorder: _border(AppColors.slate100),
      focusedBorder: _border(AppColors.primary, width: 1.5),
      errorBorder: _border(AppColors.error),
      focusedErrorBorder: _border(AppColors.error, width: 1.5),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.value,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.enabled = true,
    this.isLoading = false,
    this.isRequired = false,
    this.validator,
  });

  final String label;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  final T? value;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;

  final bool enabled;
  final bool isLoading;
  final bool isRequired;

  final FormFieldValidator<T>? validator;

  bool get _hasItems => items.isNotEmpty;

  bool get _hasSelection => value != null && items.contains(value);

  String get _label => isRequired ? '$label *' : label;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Text(
      hint ?? _label,
      style: AppTextStyles.bodyMedium.copyWith(
        color: enabled ? AppColors.slate400 : AppColors.slate300,
      ),
      overflow: TextOverflow.ellipsis,
    );

    return DropdownButtonFormField<T>(
      key: ValueKey('$label-$value-${items.length}-$enabled'),
      initialValue: _hasSelection ? value : null,
      isExpanded: true,
      isDense: true,
      borderRadius: AppRadius.brMd,
      menuMaxHeight: 280,
      dropdownColor: AppColors.surface,
      elevation: 3,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 22,
        color: enabled ? AppColors.slate500 : AppColors.slate300,
      ),
      hint: placeholder,
      disabledHint: placeholder,
      decoration: AppFieldDecoration.dropdown(
        labelText: _label,
        errorText: errorText,
        helperText: helperText,
        prefixIcon: prefixIcon,
        enabled: enabled,
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      items: !_hasItems
          ? const []
          : items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      labelBuilder(item),
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.slate800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
      onChanged: enabled && !isLoading ? onChanged : null,
      validator: validator,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.slate800,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
