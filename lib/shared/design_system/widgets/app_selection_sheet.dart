import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_gradients.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_radius.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_text_styles.dart';
import 'package:evm_management_system/shared/design_system/widgets/app_gradient_button.dart';
import 'package:evm_management_system/shared/design_system/widgets/tricolor_wave.dart';
import 'package:flutter/material.dart';

/// A single selectable row rendered by [AppSelectionSheet].
@immutable
class AppSelectionOption<T> {
  const AppSelectionOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.leadingText,
    this.leading,
    this.enabled = true,
    this.badge,
  });

  /// The value returned when this option is confirmed.
  final T value;

  /// Primary label (e.g. native language name).
  final String title;

  /// Secondary label (e.g. English language name).
  final String? subtitle;

  /// Short text rendered inside the leading avatar (e.g. "अ", "A"). Ignored
  /// when [leading] is supplied.
  final String? leadingText;

  /// Custom leading widget; overrides [leadingText] when set.
  final Widget? leading;

  /// Disabled rows are dimmed and not tappable (e.g. "coming soon").
  final bool enabled;

  /// Optional trailing badge text (e.g. "Coming soon"). Replaces the
  /// selection indicator when present.
  final String? badge;
}

/// A clean, theme-matched single-select modal bottom sheet.
///
/// Reusable for any "pick one" data collection (language, role, region, …):
/// pass a [title], the [options] and an optional [initialValue]; the future
/// completes with the chosen value, or `null` if dismissed.
///
/// ```dart
/// final lang = await AppSelectionSheet.show<String>(
///   context,
///   title: 'भाषा चुनें',
///   subtitle: 'कृपया अपनी पसंदीदा भाषा चुनें',
///   headerIcon: Icons.language_rounded,
///   confirmLabel: 'जारी रखें',
///   initialValue: 'hi',
///   options: const <AppSelectionOption<String>>[ ... ],
/// );
/// ```
abstract final class AppSelectionSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<AppSelectionOption<T>> options,
    String? subtitle,
    IconData headerIcon = Icons.tune_rounded,
    T? initialValue,
    String confirmLabel = 'Continue',
    bool isDismissible = true,
    bool showWave = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (BuildContext ctx) => _SelectionSheetBody<T>(
        title: title,
        subtitle: subtitle,
        headerIcon: headerIcon,
        options: options,
        initialValue: initialValue,
        confirmLabel: confirmLabel,
        showWave: showWave,
      ),
    );
  }
}

class _SelectionSheetBody<T> extends StatefulWidget {
  const _SelectionSheetBody({
    required this.title,
    required this.options,
    required this.headerIcon,
    required this.confirmLabel,
    required this.showWave,
    this.subtitle,
    this.initialValue,
  });

  final String title;
  final String? subtitle;
  final IconData headerIcon;
  final List<AppSelectionOption<T>> options;
  final T? initialValue;
  final String confirmLabel;
  final bool showWave;

  @override
  State<_SelectionSheetBody<T>> createState() => _SelectionSheetBodyState<T>();
}

class _SelectionSheetBodyState<T> extends State<_SelectionSheetBody<T>> {
  static const Color _brandGreen = Color(0xFF1B7A3C);

  late T? _selected = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final double maxListHeight = MediaQuery.of(context).size.height * 0.46;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.slate200,
              borderRadius: AppRadius.brPill,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.greenLight,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.headerIcon, color: _brandGreen, size: 30),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(color: _brandGreen),
            ),
          ),
          if (widget.subtitle != null) ...<Widget>[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.slate500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.options.length,
              itemBuilder: (_, int i) => _OptionTile<T>(
                option: widget.options[i],
                selected: widget.options[i].value == _selected,
                onTap: () =>
                    setState(() => _selected = widget.options[i].value),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _ConfirmBar(
            label: widget.confirmLabel,
            enabled: _selected != null,
            showWave: widget.showWave,
            onConfirm: () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
    );
  }
}

class _OptionTile<T> extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppSelectionOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: option.enabled ? 1 : 0.5,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.brLg,
            onTap: option.enabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.greenLight : Colors.white,
                borderRadius: AppRadius.brLg,
                border: Border.all(
                  color: selected ? AppColors.green : AppColors.slate200,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: <Widget>[
                  _leading(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          option.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (option.subtitle != null)
                          Text(
                            option.subtitle!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.slate500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _trailing(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _leading() {
    if (option.leading != null) return option.leading!;
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.green.withValues(alpha: 0.14)
            : AppColors.slate100,
        shape: BoxShape.circle,
      ),
      child: Text(
        option.leadingText ?? '',
        style: AppTextStyles.titleMedium.copyWith(
          color: selected ? AppColors.greenDark : AppColors.slate600,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _trailing() {
    if (option.badge != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: const BoxDecoration(
          color: AppColors.slate100,
          borderRadius: AppRadius.brPill,
        ),
        child: Text(
          option.badge!,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.slate500,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? AppColors.green : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.green : AppColors.slate300,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.label,
    required this.enabled,
    required this.onConfirm,
    required this.showWave,
  });

  final String label;
  final bool enabled;
  final VoidCallback onConfirm;
  final bool showWave;

  @override
  Widget build(BuildContext context) {
    final Widget button = Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: AppGradientButton(
        label: label,
        icon: Icons.arrow_forward_rounded,
        gradient: AppGradients.green,
        onPressed: enabled ? onConfirm : null,
      ),
    );

    if (!showWave) return button;

    return SizedBox(
      height: 104,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 64,
            child: TricolorWave(),
          ),
          Align(alignment: Alignment.bottomCenter, child: button),
        ],
      ),
    );
  }
}
