import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/voter_search/presentation/controllers/voter_search_controller.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showVoterResultsFilterSheet({
  required BuildContext context,
  required VoterSearchController controller,
}) {
  final double sheetHeight = MediaQuery.sizeOf(context).height * 0.58;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext ctx) {
      final double keyboard = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: sheetHeight,
            width: double.infinity,
            child: Material(
              color: AppColors.surface,
              clipBehavior: Clip.antiAlias,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SafeArea(
                top: false,
                child: _VoterResultsFilterBody(controller: controller),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _VoterResultsFilterBody extends StatefulWidget {
  const _VoterResultsFilterBody({required this.controller});

  final VoterSearchController controller;

  @override
  State<_VoterResultsFilterBody> createState() =>
      _VoterResultsFilterBodyState();
}

class _VoterResultsFilterBodyState extends State<_VoterResultsFilterBody> {
  late String? _ward;
  late final TextEditingController _ageController;

  VoterSearchController get c => widget.controller;

  bool get _isUrban => c.areaType.value == VoterAreaType.urban;

  TextStyle get _titleStyle => AppTextStyles.variant(
    AppTextStyles.titleMedium,
    fontWeight: FontWeight.w600,
    color: AppColors.slate800,
  );

  TextStyle get _hintStyle => AppTextStyles.variant(
    AppTextStyles.caption,
    fontWeight: FontWeight.w400,
    color: AppColors.slate500,
  );

  TextStyle get _fieldTextStyle => AppTextStyles.variant(
    AppTextStyles.bodyMedium,
    fontWeight: FontWeight.w500,
    color: AppColors.slate800,
  );

  TextStyle get _buttonStyle => AppTextStyles.variant(
    AppTextStyles.bodyMedium,
    fontWeight: FontWeight.w600,
  );

  @override
  void initState() {
    super.initState();
    _ward = c.filterWardNo.value;
    _ageController = TextEditingController(text: c.filterAge.value ?? '');
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<VoterFilterWardOption> wards = c.availableFilterWards;
    final String wardSectionTitle = _isUrban
        ? LocaleKeys.voterSearchWardName.tr()
        : LocaleKeys.voterSearchRuralWardNo.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate200,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(LocaleKeys.voterSearchFilterTitle.tr(), style: _titleStyle),
              const SizedBox(height: 4),
              Text(
                _isUrban
                    ? LocaleKeys.voterSearchFilterUrbanHint.tr()
                    : LocaleKeys.voterSearchFilterRuralHint.tr(),
                style: _hintStyle,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _ageController,
                style: _fieldTextStyle,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: LocaleKeys.voterSearchAge.tr(),
                  hintText: LocaleKeys.voterSearchAgeHint.tr(),
                  prefixIcon: const Icon(
                    Icons.cake_outlined,
                    size: 20,
                    color: AppColors.slate500,
                  ),
                  filled: true,
                  fillColor: AppColors.slate50,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  labelStyle: AppTextStyles.variant(
                    AppTextStyles.caption,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate500,
                  ),
                  hintStyle: AppTextStyles.variant(
                    AppTextStyles.bodyMedium,
                    fontWeight: FontWeight.w400,
                    color: AppColors.slate400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.slate200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                wardSectionTitle,
                style: AppTextStyles.variant(
                  AppTextStyles.caption,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            itemCount: wards.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return _WardOptionTile(
                  selected: _ward == null,
                  label: LocaleKeys.voterSearchFilterWardAll.tr(),
                  onTap: () => setState(() => _ward = null),
                );
              }
              final VoterFilterWardOption w = wards[index - 1];
              return _WardOptionTile(
                selected: _ward == w.wardNo,
                label: w.rowLabel,
                onTap: () => setState(() => _ward = w.wardNo),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.slate200)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    c.clearResultFilters();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    LocaleKeys.voterSearchFilterClear.tr(),
                    style: _buttonStyle.copyWith(color: AppColors.primaryDark),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    c.applyResultFilters(
                      wardNo: _ward,
                      age: _ageController.text,
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    LocaleKeys.voterSearchFilterApply.tr(),
                    style: _buttonStyle.copyWith(color: AppColors.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WardOptionTile extends StatelessWidget {
  const _WardOptionTile({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primaryLight.withValues(alpha: 0.65)
          : AppColors.slate50,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.slate200,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.variant(
                    AppTextStyles.bodyMedium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 20,
                color: selected ? AppColors.primary : AppColors.slate300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
