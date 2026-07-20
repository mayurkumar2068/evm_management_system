import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/utils/validators.dart';
import 'package:evm_management_system/features/online_nomination/data/models/nomination_draft.dart';
import 'package:evm_management_system/features/online_nomination/presentation/controllers/nomination_workflow_controller.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_form_state.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/online_nomination_widgets.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/widgets/image_source_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';

class NominationWorkflowScreen extends StatefulWidget {
  const NominationWorkflowScreen({required this.args, super.key});

  final NominationFlowArgs args;

  @override
  State<NominationWorkflowScreen> createState() =>
      _NominationWorkflowScreenState();
}

class _NominationWorkflowScreenState extends State<NominationWorkflowScreen> {
  late final String _tag;
  late final NominationWorkflowController _controller;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _parentNameCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _aadhaarCtrl = TextEditingController();
  final TextEditingController _voterIdCtrl = TextEditingController();
  final TextEditingController _addressLineCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();

  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _parentNameFocus = FocusNode();
  final FocusNode _dobFocus = FocusNode();
  final FocusNode _mobileFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _aadhaarFocus = FocusNode();
  final FocusNode _voterIdFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _pincodeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tag = 'nomination_${DateTime.now().microsecondsSinceEpoch}';
    _controller = Get.put(
      NominationWorkflowController(args: widget.args),
      tag: _tag,
    );
    for (final TextEditingController controller in _draftTextControllers) {
      controller.addListener(_persistDraft);
    }
    if (widget.args.resumeDraft) {
      unawaited(_restoreDraft());
    }
  }

  List<TextEditingController> get _draftTextControllers =>
      <TextEditingController>[
        _fullNameCtrl,
        _parentNameCtrl,
        _dobCtrl,
        _mobileCtrl,
        _emailCtrl,
        _aadhaarCtrl,
        _voterIdCtrl,
        _addressLineCtrl,
        _pincodeCtrl,
      ];

  Map<String, String> _draftTextFields() {
    return <String, String>{
      'fullName': _fullNameCtrl.text,
      'parentName': _parentNameCtrl.text,
      'dob': _dobCtrl.text,
      'mobile': _mobileCtrl.text,
      'email': _emailCtrl.text,
      'aadhaar': _aadhaarCtrl.text,
      'voterId': _voterIdCtrl.text,
      'addressLine': _addressLineCtrl.text,
      'pincode': _pincodeCtrl.text,
    };
  }

  void _persistDraft() {
    _controller.scheduleDraftSave(_draftTextFields());
  }

  ValueChanged<T?> _dropdownSaver<T>(ValueChanged<T?> handler) {
    return (T? value) {
      handler(value);
      _persistDraft();
    };
  }

  Future<void> _restoreDraft() async {
    final NominationDraft? draft = await AppServices.nominationDrafts
        .loadActive();
    if (draft == null || !mounted) {
      return;
    }
    if (draft.electionType != widget.args.electionType ||
        draft.postType != widget.args.postType) {
      return;
    }
    _controller.applyDraft(draft);
    _fullNameCtrl.text = draft.fullName;
    _parentNameCtrl.text = draft.parentName;
    _dobCtrl.text = draft.dob;
    _mobileCtrl.text = draft.mobile;
    _emailCtrl.text = draft.email;
    _aadhaarCtrl.text = draft.aadhaar;
    _voterIdCtrl.text = draft.voterId;
    _addressLineCtrl.text = draft.addressLine;
    _pincodeCtrl.text = draft.pincode;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _parentNameCtrl.dispose();
    _dobCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _aadhaarCtrl.dispose();
    _voterIdCtrl.dispose();
    _addressLineCtrl.dispose();
    _pincodeCtrl.dispose();
    _fullNameFocus.dispose();
    _parentNameFocus.dispose();
    _dobFocus.dispose();
    _mobileFocus.dispose();
    _emailFocus.dispose();
    _aadhaarFocus.dispose();
    _voterIdFocus.dispose();
    _addressFocus.dispose();
    _pincodeFocus.dispose();
    unawaited(_controller.persistDraft(_draftTextFields()));
    Get.delete<NominationWorkflowController>(tag: _tag, force: true);
    super.dispose();
  }

  Future<void> _pickDob() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30),
      firstDate: DateTime(1950),
      lastDate: now,
    );
    if (picked != null) {
      _dobCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      _persistDraft();
    }
  }

  bool _validateCurrentStep() {
    final int step = _controller.currentStep.value;
    switch (step) {
      case 0:
        if (!_controller.validateAreaStep()) {
          AppSnackbar.warning(
            context,
            LocaleKeys.nominationValidationDropdown.tr(),
          );
          return false;
        }
        return true;
      case 1:
      case 2:
        if (!(_formKey.currentState?.validate() ?? false)) {
          return false;
        }
        return true;
      case 4:
        if (!_controller.validateDocumentsStep()) {
          AppSnackbar.warning(
            context,
            LocaleKeys.nominationValidationDocuments.tr(),
          );
          return false;
        }
        return true;
      case 6:
        if (!_controller.validateDeclaration()) {
          AppSnackbar.warning(
            context,
            LocaleKeys.nominationValidationDeclaration.tr(),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _onPrimaryAction() {
    if (!_validateCurrentStep()) return;

    final int step = _controller.currentStep.value;
    final bool isLast =
        step == NominationWorkflowController.workflowSteps.length - 1;
    if (isLast) {
      _controller.applicationNumber.value = _controller
          .generateApplicationNumber();
      _controller.submittedAt.value = DateTime.now();
      unawaited(_controller.clearSavedDraft());
      Get.toNamed<void>(
        AppRoute.nominationSuccess.path,
        arguments: _controller.buildSubmissionArgs(),
      );
      return;
    }
    _controller.nextStep();
    _persistDraft();
  }

  Widget _buildAreaSelection() {
    return Obx(
      () => Column(
        children: <Widget>[
          AppDropdown<String>(
            label: LocaleKeys.nominationFieldDistrict.tr(),
            items: _controller.districtOptions.map((e) => e.id).toList(),
            value: _controller.selectedDistrictId.value,
            isRequired: true,
            prefixIcon: Icons.location_city_outlined,
            labelBuilder: (String value) => _controller
                .labelKeyFor(value, _controller.districtOptions)
                .tr(),
            onChanged: _dropdownSaver<String?>(_controller.onDistrictChanged),
            enabled: _controller.districtOptions.isNotEmpty,
          ),
          if (_controller.showUrbanBodyType) ...<Widget>[
            AppSpacing.vGapMd,
            AppDropdown<String>(
              label: LocaleKeys.nominationFieldBodyType.tr(),
              items: _controller.urbanBodyTypeOptions.map((e) => e.id).toList(),
              value: _controller.selectedUrbanBodyTypeId.value,
              isRequired: true,
              prefixIcon: Icons.account_balance_outlined,
              labelBuilder: (String value) => _controller
                  .labelKeyFor(value, _controller.urbanBodyTypeOptions)
                  .tr(),
              onChanged: _dropdownSaver<String?>(
                _controller.onUrbanBodyTypeChanged,
              ),
              enabled: _controller.urbanBodyTypeOptions.isNotEmpty,
            ),
          ],
          if (_controller.showUrbanBodyName) ...<Widget>[
            AppSpacing.vGapMd,
            AppDropdown<String>(
              label: _controller.municipalityFieldLabelKey.tr(),
              items: _controller.municipalityOptions.map((e) => e.id).toList(),
              value: _controller.selectedMunicipalityId.value,
              isRequired: true,
              prefixIcon: Icons.apartment_outlined,
              labelBuilder: (String value) => _controller
                  .labelKeyFor(value, _controller.municipalityOptions)
                  .tr(),
              onChanged: _dropdownSaver<String?>(
                _controller.onMunicipalityChanged,
              ),
              enabled: _controller.municipalityOptions.isNotEmpty,
            ),
          ],
          if (_controller.showJanpadPanchayat) ...<Widget>[
            AppSpacing.vGapMd,
            AppDropdown<String>(
              label: LocaleKeys.nominationFieldJanpadPanchayat.tr(),
              items: _controller.janpadPanchayatOptions
                  .map((e) => e.id)
                  .toList(),
              value: _controller.selectedJanpadPanchayatId.value,
              isRequired: true,
              prefixIcon: Icons.account_tree_outlined,
              labelBuilder: (String value) => _controller
                  .labelKeyFor(value, _controller.janpadPanchayatOptions)
                  .tr(),
              onChanged: _dropdownSaver<String?>(
                _controller.onJanpadPanchayatChanged,
              ),
              enabled: _controller.janpadPanchayatOptions.isNotEmpty,
            ),
          ],
          if (_controller.showGramPanchayat) ...<Widget>[
            AppSpacing.vGapMd,
            AppDropdown<String>(
              label: LocaleKeys.nominationFieldGramPanchayat.tr(),
              items: _controller.gramPanchayatOptions.map((e) => e.id).toList(),
              value: _controller.selectedGramPanchayatId.value,
              isRequired: true,
              prefixIcon: Icons.holiday_village_outlined,
              labelBuilder: (String value) => _controller
                  .labelKeyFor(value, _controller.gramPanchayatOptions)
                  .tr(),
              onChanged: _dropdownSaver<String?>(
                _controller.onGramPanchayatChanged,
              ),
              enabled: _controller.gramPanchayatOptions.isNotEmpty,
            ),
          ],
          if (_controller.showWard) ...<Widget>[
            AppSpacing.vGapMd,
            AppDropdown<String>(
              label: LocaleKeys.nominationFieldWard.tr(),
              items: _controller.wardOptions.map((e) => e.id).toList(),
              value: _controller.selectedWardId.value,
              isRequired: true,
              prefixIcon: Icons.pin_drop_outlined,
              labelBuilder: (String value) =>
                  _controller.labelKeyFor(value, _controller.wardOptions).tr(),
              onChanged: _dropdownSaver<String?>(_controller.onWardChanged),
              enabled: _controller.wardOptions.isNotEmpty,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCandidateDetails() {
    return Column(
      children: <Widget>[
        AppTextField(
          controller: _fullNameCtrl,
          focusNode: _fullNameFocus,
          label: LocaleKeys.nominationFieldFullName.tr(),
          isRequired: true,
          prefixIcon: Icons.person_outline,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          validator: Validators.required,
          onSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_parentNameFocus),
        ),
        AppSpacing.vGapMd,
        AppTextField(
          controller: _parentNameCtrl,
          focusNode: _parentNameFocus,
          label: LocaleKeys.nominationFieldParentName.tr(),
          isRequired: true,
          prefixIcon: Icons.family_restroom_outlined,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          validator: Validators.required,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_dobFocus),
        ),
        AppSpacing.vGapMd,
        AppTextField(
          controller: _dobCtrl,
          focusNode: _dobFocus,
          label: LocaleKeys.nominationFieldDob.tr(),
          isRequired: true,
          readOnly: true,
          prefixIcon: Icons.calendar_today_outlined,
          suffixIcon: Icons.arrow_drop_down,
          validator: Validators.ageMin25,
          onTap: _pickDob,
        ),
        AppSpacing.vGapMd,
        Obx(
          () => AppDropdown<String>(
            label: LocaleKeys.nominationFieldGender.tr(),
            items: NominationWorkflowController.genderOptions
                .map((e) => e.id)
                .toList(),
            value: _controller.selectedGenderId.value,
            isRequired: true,
            prefixIcon: Icons.wc_outlined,
            labelBuilder: (String value) => _controller
                .labelKeyFor(value, NominationWorkflowController.genderOptions)
                .tr(),
            onChanged: _dropdownSaver<String?>(_controller.onGenderChanged),
          ),
        ),
        AppSpacing.vGapMd,
        Obx(
          () => AppDropdown<String>(
            label: LocaleKeys.nominationFieldCategory.tr(),
            items: NominationWorkflowController.categoryOptions
                .map((e) => e.id)
                .toList(),
            value: _controller.selectedCategoryId.value,
            isRequired: true,
            prefixIcon: Icons.badge_outlined,
            labelBuilder: (String value) => _controller
                .labelKeyFor(
                  value,
                  NominationWorkflowController.categoryOptions,
                )
                .tr(),
            onChanged: _dropdownSaver<String?>(_controller.onCategoryChanged),
          ),
        ),
        AppSpacing.vGapMd,
        AppTextField(
          controller: _mobileCtrl,
          focusNode: _mobileFocus,
          label: LocaleKeys.nominationFieldMobile.tr(),
          isRequired: true,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: Validators.mobile,
          onSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
        ),
        AppSpacing.vGapMd,
        AppTextField(
          controller: _emailCtrl,
          focusNode: _emailFocus,
          label: LocaleKeys.nominationFieldEmail.tr(),
          isRequired: true,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.email,
          onSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_aadhaarFocus),
        ),
        AppSpacing.vGapMd,
        AppTextField(
          controller: _aadhaarCtrl,
          focusNode: _aadhaarFocus,
          label: LocaleKeys.nominationFieldAadhaar.tr(),
          isRequired: true,
          prefixIcon: Icons.fingerprint_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: <TextInputFormatter>[AadhaarInputFormatter()],
          validator: Validators.aadhaar,
          onSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_voterIdFocus),
        ),
        AppSpacing.vGapMd,
        AppTextField(
          controller: _voterIdCtrl,
          focusNode: _voterIdFocus,
          label: LocaleKeys.nominationFieldVoterId.tr(),
          isRequired: true,
          prefixIcon: Icons.how_to_vote_outlined,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.characters,
          validator: Validators.voterId,
        ),
      ],
    );
  }

  Widget _buildAddress() {
    return Column(
      children: <Widget>[
        AppTextField(
          controller: _addressLineCtrl,
          focusNode: _addressFocus,
          label: LocaleKeys.nominationFieldAddressLine.tr(),
          isRequired: true,
          prefixIcon: Icons.home_outlined,
          maxLines: 2,
          textInputAction: TextInputAction.next,
          validator: Validators.required,
          onSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_pincodeFocus),
        ),
        AppSpacing.vGapMd,
        AppTextField(
          controller: _pincodeCtrl,
          focusNode: _pincodeFocus,
          label: LocaleKeys.nominationFieldPincode.tr(),
          isRequired: true,
          prefixIcon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: Validators.pincode,
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Obx(
      () => Column(
        children: <Widget>[
          NominationSummaryRow(
            label: LocaleKeys.nominationElectionType.tr(),
            value: widget.args.electionType.labelKey.tr(),
          ),
          NominationSummaryRow(
            label: LocaleKeys.nominationPost.tr(),
            value: widget.args.postType.labelKey.tr(),
          ),
          NominationSummaryRow(
            label: LocaleKeys.nominationFieldDistrict.tr(),
            value: _controller
                .labelKeyFor(
                  _controller.selectedDistrictId.value,
                  _controller.districtOptions,
                )
                .tr(),
          ),
          if (_controller.showUrbanBodyType)
            NominationSummaryRow(
              label: LocaleKeys.nominationFieldBodyType.tr(),
              value: _controller
                  .labelKeyFor(
                    _controller.selectedUrbanBodyTypeId.value,
                    _controller.urbanBodyTypeOptions,
                  )
                  .tr(),
            ),
          if (_controller.showUrbanBodyName)
            NominationSummaryRow(
              label: _controller.municipalityFieldLabelKey.tr(),
              value: _controller
                  .labelKeyFor(
                    _controller.selectedMunicipalityId.value,
                    _controller.municipalityOptions,
                  )
                  .tr(),
            ),
          if (_controller.showJanpadPanchayat)
            NominationSummaryRow(
              label: LocaleKeys.nominationFieldJanpadPanchayat.tr(),
              value: _controller
                  .labelKeyFor(
                    _controller.selectedJanpadPanchayatId.value,
                    _controller.janpadPanchayatOptions,
                  )
                  .tr(),
            ),
          if (_controller.showGramPanchayat)
            NominationSummaryRow(
              label: LocaleKeys.nominationFieldGramPanchayat.tr(),
              value: _controller
                  .labelKeyFor(
                    _controller.selectedGramPanchayatId.value,
                    _controller.gramPanchayatOptions,
                  )
                  .tr(),
            ),
          if (_controller.showWard)
            NominationSummaryRow(
              label: LocaleKeys.nominationFieldWard.tr(),
              value: _controller
                  .labelKeyFor(
                    _controller.selectedWardId.value,
                    _controller.wardOptions,
                  )
                  .tr(),
            ),
        ],
      ),
    );
  }

  Widget _buildDocuments() {
    return Obx(
      () => Column(
        children: <Widget>[
          for (final NominationOptionItem item
              in NominationWorkflowController.requiredDocuments) ...<Widget>[
            NominationUploadCard(
              title: item.labelKey.tr(),
              state:
                  _controller.documentStates[item.id] ??
                  const NominationDocumentUploadState(),
              onUpload: () => _pickDocument(item.id),
              onReplace: () => _pickDocument(item.id),
              onDelete: () {
                _controller.removeDocument(item.id);
                _persistDraft();
              },
              onRetry: () => _pickDocument(item.id),
            ),
            AppSpacing.vGapSm,
          ],
        ],
      ),
    );
  }

  Future<void> _pickDocument(String documentId) async {
    final ImageSource? source = await showImageSourcePickerSheet(context);
    if (source == null || !mounted) {
      return;
    }

    final bool uploaded = await _controller.pickAndUploadDocument(
      documentId,
      source: source,
    );
    if (!mounted) {
      return;
    }

    final NominationDocumentUploadState? state =
        _controller.documentStates[documentId];
    if (uploaded) {
      _persistDraft();
      AppSnackbar.success(context, LocaleKeys.commonSaved.tr());
      return;
    }
    if (state?.status == NominationDocumentUploadStatus.error) {
      AppSnackbar.error(context, LocaleKeys.commonSomethingWentWrong.tr());
    }
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        NominationInfoCard(
          title: LocaleKeys.nominationPreviewPersonalInfo.tr(),
          onEdit: () => _controller.goToStep(1),
          children: <Widget>[
            NominationSummaryRow(
              label: LocaleKeys.nominationFieldFullName.tr(),
              value: _fullNameCtrl.text.isEmpty ? '-' : _fullNameCtrl.text,
            ),
            NominationSummaryRow(
              label: LocaleKeys.nominationFieldParentName.tr(),
              value: _parentNameCtrl.text.isEmpty ? '-' : _parentNameCtrl.text,
            ),
            NominationSummaryRow(
              label: LocaleKeys.nominationFieldMobile.tr(),
              value: _mobileCtrl.text.isEmpty ? '-' : _mobileCtrl.text,
            ),
            NominationSummaryRow(
              label: LocaleKeys.nominationFieldEmail.tr(),
              value: _emailCtrl.text.isEmpty ? '-' : _emailCtrl.text,
            ),
          ],
        ),
        NominationInfoCard(
          title: LocaleKeys.nominationPreviewElectionInfo.tr(),
          onEdit: () => _controller.goToStep(0),
          children: <Widget>[
            NominationSummaryRow(
              label: LocaleKeys.nominationElectionType.tr(),
              value: widget.args.electionType.labelKey.tr(),
            ),
            NominationSummaryRow(
              label: LocaleKeys.nominationPost.tr(),
              value: widget.args.postType.labelKey.tr(),
            ),
            NominationSummaryRow(
              label: LocaleKeys.nominationFieldDistrict.tr(),
              value: _controller
                  .labelKeyFor(
                    _controller.selectedDistrictId.value,
                    _controller.districtOptions,
                  )
                  .tr(),
            ),
          ],
        ),
        NominationInfoCard(
          title: LocaleKeys.nominationPreviewDocumentsInfo.tr(),
          onEdit: () => _controller.goToStep(4),
          children: <Widget>[
            NominationSummaryRow(
              label: LocaleKeys.nominationDocumentsTitle.tr(),
              value: _controller.validateDocumentsStep()
                  ? LocaleKeys.nominationAllDocumentsUploaded.tr()
                  : LocaleKeys.nominationValidationDocuments.tr(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeclaration() {
    return Obx(
      () => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.greenDark,
        value: _controller.declarationAccepted.value,
        onChanged: (bool? value) {
          _controller.setDeclaration(value ?? false);
          _persistDraft();
        },
        title: Text(
          LocaleKeys.nominationDeclarationText.tr(),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.slate700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildAreaSelection();
      case 1:
        return _buildCandidateDetails();
      case 2:
        return _buildAddress();
      case 3:
        return _buildSummary();
      case 4:
        return _buildDocuments();
      case 5:
        return _buildPreview();
      case 6:
        return _buildDeclaration();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NominationScreenShell(
      body: Column(
        children: <Widget>[
          AppTopBar(
            title: LocaleKeys.nominationWorkflowTitle.tr(),
            onBack: () => Get.back<void>(),
          ),
          Expanded(
            child: Obx(() {
              final int step = _controller.currentStep.value;
              final bool isLast =
                  step == NominationWorkflowController.workflowSteps.length - 1;
              final bool showSave = step == 1;

              return Form(
                key: _formKey,
                child: ListView(
                  padding: AppSpacing.page,
                  children: <Widget>[
                    NominationHorizontalStepper(
                      steps: NominationWorkflowController.workflowSteps,
                      currentStep: step,
                    ),
                    AppSpacing.vGapLg,
                    AppCard(
                      borderRadius: AppRadius.brXl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            NominationWorkflowController
                                .workflowSteps[step]
                                .labelKey
                                .tr(),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.slate900,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          AppSpacing.vGapMd,
                          _buildStepContent(step),
                        ],
                      ),
                    ),
                    AppSpacing.vGapLg,
                    LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final bool stackButtons =
                                constraints.maxWidth < 360;
                            final List<Widget> buttons = <Widget>[
                              NominationGovButton(
                                label: LocaleKeys.nominationPrevious.tr(),
                                outlined: true,
                                expanded: !stackButtons,
                                onPressed: step == 0
                                    ? null
                                    : () {
                                        _controller.previousStep();
                                        _persistDraft();
                                      },
                              ),
                              if (showSave)
                                NominationGovButton(
                                  label: LocaleKeys.nominationActionSave.tr(),
                                  outlined: true,
                                  expanded: !stackButtons,
                                  onPressed: () async {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      await _controller.persistDraft(
                                        _draftTextFields(),
                                      );
                                      if (!context.mounted) {
                                        return;
                                      }
                                      AppSnackbar.success(
                                        context,
                                        LocaleKeys.commonSaved.tr(),
                                      );
                                    }
                                  },
                                ),
                              NominationGovButton(
                                label: isLast
                                    ? LocaleKeys.nominationSubmitAction.tr()
                                    : LocaleKeys.nominationNext.tr(),
                                expanded: !stackButtons,
                                onPressed: _onPrimaryAction,
                              ),
                            ];

                            if (stackButtons) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  for (
                                    int i = 0;
                                    i < buttons.length;
                                    i++
                                  ) ...<Widget>[
                                    if (i > 0) AppSpacing.vGapSm,
                                    buttons[i],
                                  ],
                                ],
                              );
                            }

                            return Row(
                              children: <Widget>[
                                for (
                                  int i = 0;
                                  i < buttons.length;
                                  i++
                                ) ...<Widget>[
                                  if (i > 0) AppSpacing.gapSm,
                                  Expanded(child: buttons[i]),
                                ],
                              ],
                            );
                          },
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
