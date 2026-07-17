import 'dart:async';

import 'package:evm_management_system/core/media/app_image_picker_service.dart';
import 'package:evm_management_system/features/online_nomination/data/models/nomination_draft.dart';
import 'package:evm_management_system/features/online_nomination/data/repositories/nomination_draft_repository.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_form_state.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class NominationWorkflowController extends GetxController {
  NominationWorkflowController({
    required this.args,
    AppImagePickerService? imagePickerService,
    NominationDraftRepository? draftRepository,
  })  : _imagePickerService = imagePickerService ?? AppImagePickerService(),
        _draftRepository = draftRepository ?? Get.find<NominationDraftRepository>();

  final NominationFlowArgs args;
  final AppImagePickerService _imagePickerService;
  final NominationDraftRepository _draftRepository;

  Timer? _draftSaveTimer;
  Map<String, String>? _pendingDraftFields;

  final RxInt currentStep = 0.obs;

  final RxnString selectedStateId = RxnString();
  final RxnString selectedDistrictId = RxnString();
  final RxnString selectedUrbanBodyTypeId = RxnString();
  final RxnString selectedMunicipalityId = RxnString();
  final RxnString selectedWardId = RxnString();
  final RxnString selectedReservationId = RxnString();
  final RxnString selectedGenderId = RxnString();
  final RxnString selectedCategoryId = RxnString();

  final RxList<NominationOptionItem> stateOptions =
      <NominationOptionItem>[].obs;
  final RxList<NominationOptionItem> districtOptions =
      <NominationOptionItem>[].obs;
  final RxList<NominationOptionItem> urbanBodyTypeOptions =
      <NominationOptionItem>[].obs;
  final RxList<NominationOptionItem> municipalityOptions =
      <NominationOptionItem>[].obs;
  final RxList<NominationOptionItem> wardOptions = <NominationOptionItem>[].obs;
  final RxList<NominationOptionItem> reservationOptions =
      <NominationOptionItem>[].obs;

  final RxMap<String, NominationDocumentUploadState> documentStates =
      <String, NominationDocumentUploadState>{}.obs;

  final RxBool declarationAccepted = false.obs;
  final RxnString applicationNumber = RxnString();
  final Rxn<DateTime> submittedAt = Rxn<DateTime>();

  static const List<NominationOptionItem> genderOptions =
      <NominationOptionItem>[
        NominationOptionItem(
          id: 'male',
          labelKey: LocaleKeys.nominationOptionMale,
        ),
        NominationOptionItem(
          id: 'female',
          labelKey: LocaleKeys.nominationOptionFemale,
        ),
        NominationOptionItem(
          id: 'other',
          labelKey: LocaleKeys.nominationOptionOther,
        ),
      ];

  static const List<NominationOptionItem> categoryOptions =
      <NominationOptionItem>[
        NominationOptionItem(
          id: 'general',
          labelKey: LocaleKeys.nominationOptionGeneral,
        ),
        NominationOptionItem(id: 'sc', labelKey: LocaleKeys.nominationOptionSc),
        NominationOptionItem(id: 'st', labelKey: LocaleKeys.nominationOptionSt),
        NominationOptionItem(
          id: 'obc',
          labelKey: LocaleKeys.nominationOptionObc,
        ),
      ];

  static const List<NominationOptionItem> _reservations =
      <NominationOptionItem>[
        NominationOptionItem(
          id: 'general',
          labelKey: LocaleKeys.nominationOptionGeneral,
        ),
        NominationOptionItem(id: 'sc', labelKey: LocaleKeys.nominationOptionSc),
        NominationOptionItem(id: 'st', labelKey: LocaleKeys.nominationOptionSt),
        NominationOptionItem(
          id: 'obc',
          labelKey: LocaleKeys.nominationOptionObc,
        ),
        NominationOptionItem(
          id: 'women',
          labelKey: LocaleKeys.nominationOptionWomen,
        ),
      ];

  static const List<NominationOptionItem> _states = <NominationOptionItem>[
    NominationOptionItem(
      id: 'mp',
      labelKey: LocaleKeys.nominationOptionStateMp,
    ),
  ];

  static const Map<String, List<NominationOptionItem>> _districtByState =
      <String, List<NominationOptionItem>>{
        'mp': <NominationOptionItem>[
          NominationOptionItem(
            id: 'bhopal',
            labelKey: LocaleKeys.nominationOptionDistrictBhopal,
          ),
          NominationOptionItem(
            id: 'indore',
            labelKey: LocaleKeys.nominationOptionDistrictIndore,
          ),
          NominationOptionItem(
            id: 'sagar',
            labelKey: LocaleKeys.nominationOptionDistrictSagar,
          ),
        ],
      };

  static const Map<String, List<_UrbanBodyOption>> _bodiesByDistrict =
      <String, List<_UrbanBodyOption>>{
        'bhopal': <_UrbanBodyOption>[
          _UrbanBodyOption(
            id: 'bhopal_nagar_nigam',
            labelKey: LocaleKeys.nominationOptionMunicipalityBhopalNagarNigam,
            type: UrbanBodyType.nagarNigam,
          ),
          _UrbanBodyOption(
            id: 'berasia_palika',
            labelKey: LocaleKeys.nominationOptionMunicipalityBerasiaPalika,
            type: UrbanBodyType.nagarPalikaParishad,
          ),
          _UrbanBodyOption(
            id: 'kolar_parishad',
            labelKey: LocaleKeys.nominationOptionMunicipalityKolarParishad,
            type: UrbanBodyType.nagarParishad,
          ),
        ],
        'indore': <_UrbanBodyOption>[
          _UrbanBodyOption(
            id: 'indore_nagar_nigam',
            labelKey: LocaleKeys.nominationOptionMunicipalityIndoreNagarNigam,
            type: UrbanBodyType.nagarNigam,
          ),
          _UrbanBodyOption(
            id: 'depalpur_palika',
            labelKey: LocaleKeys.nominationOptionMunicipalityDepalpurPalika,
            type: UrbanBodyType.nagarPalikaParishad,
          ),
          _UrbanBodyOption(
            id: 'mhow_parishad',
            labelKey: LocaleKeys.nominationOptionMunicipalityMhowParishad,
            type: UrbanBodyType.nagarParishad,
          ),
        ],
        'sagar': <_UrbanBodyOption>[
          _UrbanBodyOption(
            id: 'sagar_nagar_nigam',
            labelKey: LocaleKeys.nominationOptionMunicipalitySagarNagarNigam,
            type: UrbanBodyType.nagarNigam,
          ),
          _UrbanBodyOption(
            id: 'bina_palika',
            labelKey: LocaleKeys.nominationOptionMunicipalityBinaPalika,
            type: UrbanBodyType.nagarPalikaParishad,
          ),
          _UrbanBodyOption(
            id: 'rahatgarh_parishad',
            labelKey: LocaleKeys.nominationOptionMunicipalityRahatgarhParishad,
            type: UrbanBodyType.nagarParishad,
          ),
        ],
      };

  static const List<NominationOptionItem> _adhyakshBodyTypes =
      <NominationOptionItem>[
        NominationOptionItem(
          id: 'nagarPalikaParishad',
          labelKey: LocaleKeys.nominationOptionBodyNagarPalikaParishad,
        ),
        NominationOptionItem(
          id: 'nagarParishad',
          labelKey: LocaleKeys.nominationOptionBodyNagarParishad,
        ),
      ];

  static const Map<String, List<NominationOptionItem>> _wardByMunicipality =
      <String, List<NominationOptionItem>>{
        'bhopal_nagar_nigam': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_12',
            labelKey: LocaleKeys.nominationOptionWard12,
          ),
          NominationOptionItem(
            id: 'ward_25',
            labelKey: LocaleKeys.nominationOptionWard25,
          ),
        ],
        'berasia_palika': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_7',
            labelKey: LocaleKeys.nominationOptionWard7,
          ),
          NominationOptionItem(
            id: 'ward_4',
            labelKey: LocaleKeys.nominationOptionWard4,
          ),
        ],
        'kolar_parishad': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_7',
            labelKey: LocaleKeys.nominationOptionWard7,
          ),
          NominationOptionItem(
            id: 'ward_4',
            labelKey: LocaleKeys.nominationOptionWard4,
          ),
        ],
        'indore_nagar_nigam': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_25',
            labelKey: LocaleKeys.nominationOptionWard25,
          ),
          NominationOptionItem(
            id: 'ward_31',
            labelKey: LocaleKeys.nominationOptionWard31,
          ),
        ],
        'depalpur_palika': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_9',
            labelKey: LocaleKeys.nominationOptionWard9,
          ),
          NominationOptionItem(
            id: 'ward_7',
            labelKey: LocaleKeys.nominationOptionWard7,
          ),
        ],
        'mhow_parishad': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_9',
            labelKey: LocaleKeys.nominationOptionWard9,
          ),
          NominationOptionItem(
            id: 'ward_7',
            labelKey: LocaleKeys.nominationOptionWard7,
          ),
        ],
        'sagar_nagar_nigam': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_12',
            labelKey: LocaleKeys.nominationOptionWard12,
          ),
          NominationOptionItem(
            id: 'ward_31',
            labelKey: LocaleKeys.nominationOptionWard31,
          ),
        ],
        'bina_palika': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_4',
            labelKey: LocaleKeys.nominationOptionWard4,
          ),
          NominationOptionItem(
            id: 'ward_9',
            labelKey: LocaleKeys.nominationOptionWard9,
          ),
        ],
        'rahatgarh_parishad': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_4',
            labelKey: LocaleKeys.nominationOptionWard4,
          ),
          NominationOptionItem(
            id: 'ward_9',
            labelKey: LocaleKeys.nominationOptionWard9,
          ),
        ],
      };

  bool get showUrbanBodyType => args.postType.requiresUrbanBodyType;
  bool get showWard => args.postType.requiresWard;
  String get municipalityFieldLabelKey =>
      args.postType.municipalityFieldLabelKey;

  @override
  void onClose() {
    _draftSaveTimer?.cancel();
    super.onClose();
  }

  void scheduleDraftSave(Map<String, String> textFields) {
    _pendingDraftFields = textFields;
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 500), () {
      final Map<String, String>? fields = _pendingDraftFields;
      if (fields != null) {
        unawaited(persistDraft(fields));
      }
    });
  }

  NominationDraft buildDraft(Map<String, String> textFields) {
    return NominationDraft(
      electionType: args.electionType,
      postType: args.postType,
      currentStep: currentStep.value,
      savedAt: DateTime.now(),
      stateId: selectedStateId.value,
      districtId: selectedDistrictId.value,
      urbanBodyTypeId: selectedUrbanBodyTypeId.value,
      municipalityId: selectedMunicipalityId.value,
      wardId: selectedWardId.value,
      reservationId: selectedReservationId.value,
      genderId: selectedGenderId.value,
      categoryId: selectedCategoryId.value,
      fullName: textFields['fullName'] ?? '',
      parentName: textFields['parentName'] ?? '',
      dob: textFields['dob'] ?? '',
      mobile: textFields['mobile'] ?? '',
      email: textFields['email'] ?? '',
      aadhaar: textFields['aadhaar'] ?? '',
      voterId: textFields['voterId'] ?? '',
      addressLine: textFields['addressLine'] ?? '',
      pincode: textFields['pincode'] ?? '',
      declarationAccepted: declarationAccepted.value,
      documents: Map<String, NominationDocumentUploadState>.from(documentStates),
    );
  }

  Future<void> persistDraft(Map<String, String> textFields) async {
    await _draftRepository.save(buildDraft(textFields));
  }

  Future<void> clearSavedDraft() async {
    await _draftRepository.clear();
  }

  void applyDraft(NominationDraft draft) {
    restoreAreaSelections(
      stateId: draft.stateId,
      districtId: draft.districtId,
      urbanBodyTypeId: draft.urbanBodyTypeId,
      municipalityId: draft.municipalityId,
      wardId: draft.wardId,
      reservationId: draft.reservationId,
    );
    selectedGenderId.value = draft.genderId ?? genderOptions.first.id;
    selectedCategoryId.value = draft.categoryId ?? categoryOptions.first.id;
    currentStep.value = draft.currentStep.clamp(0, workflowSteps.length - 1);
    declarationAccepted.value = draft.declarationAccepted;
    for (final NominationOptionItem doc in requiredDocuments) {
      documentStates[doc.id] =
          draft.documents[doc.id] ?? const NominationDocumentUploadState();
    }
  }

  void restoreAreaSelections({
    required String? stateId,
    required String? districtId,
    required String? urbanBodyTypeId,
    required String? municipalityId,
    required String? wardId,
    required String? reservationId,
  }) {
    selectedStateId.value = stateId;
    districtOptions.assignAll(
      _districtByState[stateId] ?? const <NominationOptionItem>[],
    );
    selectedDistrictId.value = districtId;
    urbanBodyTypeOptions.assignAll(
      showUrbanBodyType ? _adhyakshBodyTypes : const <NominationOptionItem>[],
    );
    selectedUrbanBodyTypeId.value = urbanBodyTypeId;
    municipalityOptions.assignAll(
      _municipalityOptionsFor(
        districtId: districtId,
        urbanBodyTypeId: urbanBodyTypeId,
      ),
    );
    selectedMunicipalityId.value = municipalityId;
    if (showWard) {
      wardOptions.assignAll(
        _wardByMunicipality[municipalityId] ?? const <NominationOptionItem>[],
      );
      selectedWardId.value = wardId;
      reservationOptions.assignAll(
        wardId == null ? const <NominationOptionItem>[] : _reservations,
      );
    } else {
      wardOptions.clear();
      selectedWardId.value = null;
      reservationOptions.assignAll(
        municipalityId == null
            ? const <NominationOptionItem>[]
            : _reservations,
      );
    }
    selectedReservationId.value = reservationId;
  }

  @override
  void onInit() {
    super.onInit();
    stateOptions.assignAll(_states);
    selectedStateId.value = _states.first.id;
    onStateChanged(selectedStateId.value);
    selectedGenderId.value = genderOptions.first.id;
    selectedCategoryId.value = categoryOptions.first.id;
    for (final NominationOptionItem doc in requiredDocuments) {
      documentStates[doc.id] = const NominationDocumentUploadState();
    }
  }

  void onStateChanged(String? stateId) {
    selectedStateId.value = stateId;
    selectedDistrictId.value = null;
    selectedUrbanBodyTypeId.value = null;
    selectedMunicipalityId.value = null;
    selectedWardId.value = null;
    selectedReservationId.value = null;
    districtOptions.assignAll(
      _districtByState[stateId] ?? const <NominationOptionItem>[],
    );
    urbanBodyTypeOptions.clear();
    municipalityOptions.clear();
    wardOptions.clear();
    reservationOptions.clear();
  }

  void onDistrictChanged(String? districtId) {
    selectedDistrictId.value = districtId;
    selectedUrbanBodyTypeId.value = null;
    selectedMunicipalityId.value = null;
    selectedWardId.value = null;
    selectedReservationId.value = null;
    wardOptions.clear();
    reservationOptions.clear();

    if (showUrbanBodyType) {
      urbanBodyTypeOptions.assignAll(_adhyakshBodyTypes);
      municipalityOptions.clear();
      return;
    }

    urbanBodyTypeOptions.clear();
    municipalityOptions.assignAll(
      _municipalityOptionsFor(districtId: districtId, urbanBodyTypeId: null),
    );
  }

  void onUrbanBodyTypeChanged(String? urbanBodyTypeId) {
    selectedUrbanBodyTypeId.value = urbanBodyTypeId;
    selectedMunicipalityId.value = null;
    selectedWardId.value = null;
    selectedReservationId.value = null;
    wardOptions.clear();
    reservationOptions.clear();
    municipalityOptions.assignAll(
      _municipalityOptionsFor(
        districtId: selectedDistrictId.value,
        urbanBodyTypeId: urbanBodyTypeId,
      ),
    );
  }

  void onMunicipalityChanged(String? municipalityId) {
    selectedMunicipalityId.value = municipalityId;
    selectedWardId.value = null;
    selectedReservationId.value = null;

    if (showWard) {
      wardOptions.assignAll(
        _wardByMunicipality[municipalityId] ?? const <NominationOptionItem>[],
      );
      reservationOptions.clear();
      return;
    }

    wardOptions.clear();
    reservationOptions.assignAll(
      municipalityId == null ? const <NominationOptionItem>[] : _reservations,
    );
  }

  void onWardChanged(String? wardId) {
    selectedWardId.value = wardId;
    selectedReservationId.value = null;
    reservationOptions.assignAll(
      wardId == null ? const <NominationOptionItem>[] : _reservations,
    );
  }

  void onReservationChanged(String? reservationId) {
    selectedReservationId.value = reservationId;
  }

  void onGenderChanged(String? genderId) {
    selectedGenderId.value = genderId;
  }

  void onCategoryChanged(String? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  bool validateAreaStep() {
    final bool baseValid =
        selectedStateId.value != null &&
        selectedDistrictId.value != null &&
        selectedMunicipalityId.value != null &&
        selectedReservationId.value != null;
    if (!baseValid) {
      return false;
    }
    if (showUrbanBodyType && selectedUrbanBodyTypeId.value == null) {
      return false;
    }
    if (showWard && selectedWardId.value == null) {
      return false;
    }
    return true;
  }

  List<NominationOptionItem> _municipalityOptionsFor({
    required String? districtId,
    required String? urbanBodyTypeId,
  }) {
    final List<_UrbanBodyOption> bodies =
        _bodiesByDistrict[districtId] ?? const <_UrbanBodyOption>[];
    final Iterable<_UrbanBodyOption> filtered = switch (args.postType) {
      NominationPostType.mahapaur =>
        bodies.where((_UrbanBodyOption b) => b.type == UrbanBodyType.nagarNigam),
      NominationPostType.adhyaksh => bodies.where((_UrbanBodyOption b) {
        final UrbanBodyType? type = _urbanBodyTypeFromId(urbanBodyTypeId);
        return type != null && b.type == type;
      }),
      NominationPostType.parshad => bodies,
      _ => bodies,
    };
    return filtered
        .map(
          (_UrbanBodyOption body) =>
              NominationOptionItem(id: body.id, labelKey: body.labelKey),
        )
        .toList(growable: false);
  }

  UrbanBodyType? _urbanBodyTypeFromId(String? id) {
    return switch (id) {
      'nagarNigam' => UrbanBodyType.nagarNigam,
      'nagarPalikaParishad' => UrbanBodyType.nagarPalikaParishad,
      'nagarParishad' => UrbanBodyType.nagarParishad,
      _ => null,
    };
  }

  bool validateDocumentsStep() {
    for (final NominationOptionItem doc in requiredDocuments) {
      final NominationDocumentUploadState? state = documentStates[doc.id];
      if (state == null ||
          state.status != NominationDocumentUploadStatus.uploaded) {
        return false;
      }
    }
    return true;
  }

  bool validateDeclaration() => declarationAccepted.value;

  void goToStep(int step) {
    if (step >= 0 && step < workflowSteps.length) {
      currentStep.value = step;
    }
  }

  void nextStep() {
    if (currentStep.value < workflowSteps.length - 1) {
      currentStep.value += 1;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value -= 1;
    }
  }

  void setDeclaration(bool value) {
    declarationAccepted.value = value;
  }

  Future<bool> pickAndUploadDocument(
    String documentId, {
    required ImageSource source,
  }) async {
    final NominationDocumentUploadState previous =
        documentStates[documentId] ?? const NominationDocumentUploadState();

    documentStates[documentId] = previous.copyWith(
      status: NominationDocumentUploadStatus.uploading,
      clearErrorMessage: true,
    );

    try {
      final AppPickedImage? picked = await _imagePickerService.pickCompressedImage(
        source: source,
      );
      if (picked == null) {
        documentStates[documentId] = previous;
        return false;
      }

      final String savedPath = await _imagePickerService.persistToTemp(
        bytes: picked.bytes,
        prefix: 'nomination_$documentId',
      );

      documentStates[documentId] = NominationDocumentUploadState(
        status: NominationDocumentUploadStatus.uploaded,
        fileName: picked.fileName,
        filePath: savedPath,
      );
      return true;
    } catch (_) {
      documentStates[documentId] = previous.copyWith(
        status: NominationDocumentUploadStatus.error,
        errorMessage: LocaleKeys.commonSomethingWentWrong,
      );
      return false;
    }
  }

  void removeDocument(String documentId) {
    documentStates[documentId] = const NominationDocumentUploadState();
  }

  String generateApplicationNumber() {
    final int year = DateTime.now().year;
    final String seq = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(7);
    return 'NOM/$year/IND/$seq';
  }

  NominationFlowArgs buildSubmissionArgs() {
    return NominationFlowArgs(
      electionType: args.electionType,
      postType: args.postType,
      applicationNumber: applicationNumber.value,
      submittedAt: submittedAt.value,
    );
  }

  String labelKeyFor(String? id, List<NominationOptionItem> options) {
    if (id == null) return '-';
    final Iterable<NominationOptionItem> matched = options.where(
      (NominationOptionItem option) => option.id == id,
    );
    if (matched.isEmpty) return '-';
    return matched.first.labelKey;
  }

  static const List<NominationStepItem> workflowSteps = <NominationStepItem>[
    NominationStepItem(
      id: 'area_selection',
      labelKey: LocaleKeys.nominationAreaSelection,
    ),
    NominationStepItem(
      id: 'candidate_details',
      labelKey: LocaleKeys.nominationCandidateDetails,
    ),
    NominationStepItem(id: 'address', labelKey: LocaleKeys.nominationAddress),
    NominationStepItem(
      id: 'summary',
      labelKey: LocaleKeys.nominationElectionSummary,
    ),
    NominationStepItem(
      id: 'documents',
      labelKey: LocaleKeys.nominationDocumentUpload,
    ),
    NominationStepItem(id: 'preview', labelKey: LocaleKeys.nominationPreview),
    NominationStepItem(
      id: 'declaration',
      labelKey: LocaleKeys.nominationDeclaration,
    ),
  ];

  static const List<NominationOptionItem> requiredDocuments =
      <NominationOptionItem>[
        NominationOptionItem(
          id: 'photo',
          labelKey: LocaleKeys.nominationDocumentPhoto,
        ),
        NominationOptionItem(
          id: 'id_proof',
          labelKey: LocaleKeys.nominationDocumentIdProof,
        ),
        NominationOptionItem(
          id: 'address_proof',
          labelKey: LocaleKeys.nominationDocumentAddressProof,
        ),
        NominationOptionItem(
          id: 'affidavit',
          labelKey: LocaleKeys.nominationDocumentAffidavit,
        ),
        NominationOptionItem(
          id: 'caste',
          labelKey: LocaleKeys.nominationDocumentCaste,
        ),
        NominationOptionItem(
          id: 'noc',
          labelKey: LocaleKeys.nominationDocumentNoc,
        ),
      ];
}

class _UrbanBodyOption {
  const _UrbanBodyOption({
    required this.id,
    required this.labelKey,
    required this.type,
  });

  final String id;
  final String labelKey;
  final UrbanBodyType type;
}
