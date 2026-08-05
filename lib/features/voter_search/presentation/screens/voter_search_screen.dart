import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/voter_search/data/models/voter_search_models.dart';
import 'package:evm_management_system/features/voter_search/di/voter_search_module.dart';
import 'package:evm_management_system/features/voter_search/presentation/controllers/voter_search_controller.dart';
import 'package:evm_management_system/features/voter_search/presentation/widgets/voter_elector_result_card.dart';
import 'package:evm_management_system/features/voter_search/presentation/widgets/voter_search_widgets.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;

/// Native voter search screen (SECSearchAPI) — replaces WebView portal.
class VoterSearchScreen extends StatefulWidget {
  const VoterSearchScreen({super.key});

  @override
  State<VoterSearchScreen> createState() => _VoterSearchScreenState();
}

class _VoterSearchScreenState extends State<VoterSearchScreen>
    with SingleTickerProviderStateMixin {
  late final VoterSearchController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = VoterSearchModule.ensureController();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _controller.setTab(
        _tabController.index == 0
            ? VoterSearchTab.details
            : VoterSearchTab.epic,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppGradientHeader(
            leading: AppCircleBackButton(onTap: () => Get.back<void>()),
            title: LocaleKeys.voterSearchTitle.tr(),
            trailing: HeaderIconButton(
              icon: Icons.refresh_rounded,
              onTap: _controller.refreshAll,
            ),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          ),
          Expanded(
            child: Obx(() {
              if (_controller.showingResults.value) {
                return _ResultsView(controller: _controller);
              }
              return _SearchFormView(
                controller: _controller,
                tabController: _tabController,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SearchFormView extends StatelessWidget {
  const _SearchFormView({
    required this.controller,
    required this.tabController,
  });

  final VoterSearchController controller;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: VoterSearchInstructionCard(),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: AppRadius.brLg,
              border: Border.all(color: AppColors.slate200),
            ),
            clipBehavior: Clip.antiAlias,
            child: TabBar(
              controller: tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: const BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.brLg,
              ),
              labelColor: AppColors.primaryDeep,
              unselectedLabelColor: AppColors.slate500,
              labelStyle: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
              unselectedLabelStyle: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overlayColor: WidgetStateProperty.all(
                AppColors.primary.withValues(alpha: 0.06),
              ),
              tabs: <Widget>[
                Tab(text: LocaleKeys.voterSearchTabDetails.tr()),
                Tab(text: LocaleKeys.voterSearchTabEpic.tr()),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: <Widget>[
              _DetailsTab(controller: controller),
              _EpicTab(controller: controller),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.controller});

  final VoterSearchController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.detailsFormKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: <Widget>[
          AppCard(
            borderRadius: AppRadius.brXl,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Obx(
                  () => AppDropdown<VoterDistrict>(
                    label: LocaleKeys.voterSearchDistrict.tr(),
                    hint: LocaleKeys.voterSearchDistrictHint.tr(),
                    items: controller.districts.toList(growable: false),
                    value: controller.selectedDistrict.value,
                    isRequired: true,
                    isLoading: controller.loadingDistricts.value,
                    prefixIcon: Icons.map_outlined,
                    labelBuilder: (VoterDistrict d) =>
                        d.displayName(controller.preferHindi),
                    onChanged: controller.onDistrictChanged,
                  ),
                ),
                AppSpacing.vGapMd,
                Obx(
                  () => VoterAreaTypeRadioRow(
                    isUrban: controller.areaType.value == VoterAreaType.urban,
                    onChanged: (bool urban) {
                      controller.setAreaType(
                        urban ? VoterAreaType.urban : VoterAreaType.rural,
                      );
                    },
                  ),
                ),
                AppSpacing.vGapMd,
                Obx(() {
                  if (controller.areaType.value == VoterAreaType.rural) {
                    return AppDropdown<VoterBlock>(
                      label: LocaleKeys.voterSearchBlock.tr(),
                      hint: LocaleKeys.voterSearchBlockHint.tr(),
                      items: controller.blocks.toList(growable: false),
                      value: controller.selectedBlock.value,
                      isRequired: true,
                      isLoading: controller.loadingBlocks.value,
                      enabled: controller.selectedDistrict.value != null,
                      prefixIcon: Icons.account_tree_outlined,
                      labelBuilder: (VoterBlock b) =>
                          b.displayName(controller.preferHindi),
                      onChanged: controller.onBlockChanged,
                    );
                  }
                  return AppDropdown<VoterUrbanBody>(
                    label: LocaleKeys.voterSearchUrbanBody.tr(),
                    hint: LocaleKeys.voterSearchUrbanBodyHint.tr(),
                    items: controller.urbanBodies.toList(growable: false),
                    value: controller.selectedUrbanBody.value,
                    isRequired: true,
                    isLoading: controller.loadingUrbanBodies.value,
                    enabled: controller.selectedDistrict.value != null,
                    prefixIcon: Icons.apartment_rounded,
                    labelBuilder: (VoterUrbanBody u) =>
                        u.displayName(controller.preferHindi),
                    onChanged: controller.onUrbanBodyChanged,
                  );
                }),
                AppSpacing.vGapMd,
                AppTextField(
                  label: LocaleKeys.voterSearchElectorName.tr(),
                  hint: LocaleKeys.voterSearchElectorNameHint.tr(),
                  controller: controller.electorNameController,
                  isRequired: true,
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => controller.flushNameTransliteration(),
                ),
                AppSpacing.vGapMd,
                AppTextField(
                  label: LocaleKeys.voterSearchRelativeName.tr(),
                  hint: LocaleKeys.voterSearchRelativeNameHint.tr(),
                  controller: controller.relativeNameController,
                  prefixIcon: Icons.family_restroom_rounded,
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => controller.flushNameTransliteration(),
                ),
                AppSpacing.vGapMd,
                Obx(
                  () => AppDropdown<String?>(
                    label: LocaleKeys.voterSearchGender.tr(),
                    hint: LocaleKeys.voterSearchGenderHint.tr(),
                    items: controller.genderOptions,
                    value: controller.selectedGender.value,
                    prefixIcon: Icons.wc_rounded,
                    labelBuilder: controller.genderLabel,
                    onChanged: controller.onGenderChanged,
                  ),
                ),
                AppSpacing.vGapMd,
                AppTextField(
                  label: LocaleKeys.voterSearchAge.tr(),
                  hint: LocaleKeys.voterSearchAgeHint.tr(),
                  controller: controller.ageController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.cake_outlined,
                  maxLength: 3,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ],
            ),
          ),
          Obx(() {
            final String? err = controller.formError.value;
            if (err == null || err.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                err,
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            );
          }),
          const SizedBox(height: 18),
          Obx(
            () => AppButton(
              label: LocaleKeys.voterSearchSearch.tr(),
              icon: Icons.search_rounded,
              isLoading: controller.searching.value,
              onPressed: controller.searching.value ? null : controller.search,
            ),
          ),
        ],
      ),
    );
  }
}

class _EpicTab extends StatelessWidget {
  const _EpicTab({required this.controller});

  final VoterSearchController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.epicFormKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: <Widget>[
          AppCard(
            borderRadius: AppRadius.brXl,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Obx(
                  () => AppDropdown<VoterDistrict>(
                    label: LocaleKeys.voterSearchDistrict.tr(),
                    hint: LocaleKeys.voterSearchDistrictHint.tr(),
                    items: controller.districts.toList(growable: false),
                    value: controller.selectedDistrict.value,
                    isRequired: true,
                    isLoading: controller.loadingDistricts.value,
                    prefixIcon: Icons.map_outlined,
                    labelBuilder: (VoterDistrict d) =>
                        d.displayName(controller.preferHindi),
                    onChanged: controller.onDistrictChanged,
                  ),
                ),
                AppSpacing.vGapMd,
                Obx(
                  () => VoterAreaTypeRadioRow(
                    isUrban: controller.areaType.value == VoterAreaType.urban,
                    onChanged: (bool urban) {
                      controller.setAreaType(
                        urban ? VoterAreaType.urban : VoterAreaType.rural,
                      );
                    },
                  ),
                ),
                AppSpacing.vGapMd,
                AppTextField(
                  label: LocaleKeys.voterSearchEpicNo.tr(),
                  hint: LocaleKeys.voterSearchEpicHint.tr(),
                  controller: controller.epicController,
                  isRequired: true,
                  prefixIcon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  ],
                ),
              ],
            ),
          ),
          Obx(() {
            final String? err = controller.formError.value;
            if (err == null || err.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                err,
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            );
          }),
          const SizedBox(height: 18),
          Obx(
            () => AppButton(
              label: LocaleKeys.voterSearchSearch.tr(),
              icon: Icons.search_rounded,
              isLoading: controller.searching.value,
              onPressed: controller.searching.value ? null : controller.search,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.controller});

  final VoterSearchController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<VoterElector> list = controller.results.toList(growable: false);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        LocaleKeys.voterSearchResultsTitle.tr(),
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LocaleKeys.voterSearchResultsCount.tr(
                          args: <String>['${list.length}'],
                        ),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: controller.backToSearch,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(LocaleKeys.voterSearchBackToSearch.tr()),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        LocaleKeys.voterSearchNoResults.tr(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.slate500,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      return VoterElectorResultCard(elector: list[index]);
                    },
                  ),
          ),
        ],
      );
    });
  }
}
