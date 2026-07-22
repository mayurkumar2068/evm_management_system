import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/media/app_image_picker_service.dart';
import 'package:evm_management_system/features/online_nomination/data/models/nomination_draft.dart';
import 'package:evm_management_system/features/online_nomination/data/repositories/nomination_draft_repository.dart';
import 'package:evm_management_system/features/online_nomination/data/repositories/urban_nomination_master_repository.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_form_state.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';

class NominationWorkflowController extends GetxController {
  NominationWorkflowController({
    required this.args,
    AppImagePickerService? imagePickerService,
    NominationDraftRepository? draftRepository,
    UrbanNominationMasterRepository? urbanMasterRepository,
  }) : _imagePickerService = imagePickerService ?? AppImagePickerService(),
       _draftRepository =
           draftRepository ?? Get.find<NominationDraftRepository>(),
       _urbanMasters =
           urbanMasterRepository ?? AppServices.urbanNominationMasters;

  final NominationFlowArgs args;
  final AppImagePickerService _imagePickerService;
  final NominationDraftRepository _draftRepository;
  final UrbanNominationMasterRepository _urbanMasters;

  Timer? _draftSaveTimer;
  Map<String, String>? _pendingDraftFields;
  int _urbanLoadToken = 0;

  final RxInt currentStep = 0.obs;
  final RxBool mastersLoading = false.obs;
  final RxnString mastersError = RxnString();

  final RxnString selectedDistrictId = RxnString();
  final RxnString selectedUrbanBodyTypeId = RxnString();
  final RxnString selectedMunicipalityId = RxnString();
  final RxnString selectedJanpadPanchayatId = RxnString();
  final RxnString selectedGramPanchayatId = RxnString();
  final RxnString selectedWardId = RxnString();
  final RxnString selectedGenderId = RxnString();
  final RxnString selectedCategoryId = RxnString();
  final RxnInt selectedUrbanBodyTypeIdMeta = RxnInt();

  final RxList<NominationOptionItem> districtOptions =
      <NominationOptionItem>[].obs;
  final RxList<NominationOptionItem> urbanBodyTypeOptions =
      <NominationOptionItem>[].obs;
  final RxList<NominationOptionItem> municipalityOptions =
      <NominationOptionItem>[].obs;
  final RxList<NominationOptionItem> janpadPanchayatOptions =
      <NominationOptionItem>[].obs;
  final RxList<NominationOptionItem> gramPanchayatOptions =
      <NominationOptionItem>[].obs;
  final RxList<NominationOptionItem> wardOptions = <NominationOptionItem>[].obs;

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

  static const List<NominationOptionItem> _districts = <NominationOptionItem>[
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
  ];

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

  static const List<NominationOptionItem> _urbanBodyTypes =
      <NominationOptionItem>[
        NominationOptionItem(
          id: 'nagarNigam',
          labelKey: LocaleKeys.nominationOptionBodyNagarNigam,
        ),
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

  static const Map<String, List<NominationOptionItem>> _wardByDistrict =
      <String, List<NominationOptionItem>>{
        'bhopal': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_12',
            labelKey: LocaleKeys.nominationOptionWard12,
          ),
          NominationOptionItem(
            id: 'ward_25',
            labelKey: LocaleKeys.nominationOptionWard25,
          ),
        ],
        'indore': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_25',
            labelKey: LocaleKeys.nominationOptionWard25,
          ),
          NominationOptionItem(
            id: 'ward_31',
            labelKey: LocaleKeys.nominationOptionWard31,
          ),
        ],
        'sagar': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_12',
            labelKey: LocaleKeys.nominationOptionWard12,
          ),
          NominationOptionItem(
            id: 'ward_31',
            labelKey: LocaleKeys.nominationOptionWard31,
          ),
        ],
      };

  static const Map<String, List<NominationOptionItem>> _janpadByDistrict =
      <String, List<NominationOptionItem>>{
        'bhopal': <NominationOptionItem>[
          NominationOptionItem(
            id: 'janpad_phanda',
            labelKey: LocaleKeys.nominationOptionJanpadPhanda,
          ),
          NominationOptionItem(
            id: 'janpad_berasia',
            labelKey: LocaleKeys.nominationOptionJanpadBerasia,
          ),
        ],
        'indore': <NominationOptionItem>[
          NominationOptionItem(
            id: 'janpad_depalpur',
            labelKey: LocaleKeys.nominationOptionJanpadDepalpur,
          ),
          NominationOptionItem(
            id: 'janpad_mhow',
            labelKey: LocaleKeys.nominationOptionJanpadMhow,
          ),
        ],
        'sagar': <NominationOptionItem>[
          NominationOptionItem(
            id: 'janpad_bina',
            labelKey: LocaleKeys.nominationOptionJanpadBina,
          ),
          NominationOptionItem(
            id: 'janpad_rahatgarh',
            labelKey: LocaleKeys.nominationOptionJanpadRahatgarh,
          ),
        ],
      };

  static const Map<String, List<NominationOptionItem>> _wardByJanpad =
      <String, List<NominationOptionItem>>{
        'janpad_phanda': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_7',
            labelKey: LocaleKeys.nominationOptionWard7,
          ),
          NominationOptionItem(
            id: 'ward_4',
            labelKey: LocaleKeys.nominationOptionWard4,
          ),
        ],
        'janpad_berasia': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_9',
            labelKey: LocaleKeys.nominationOptionWard9,
          ),
          NominationOptionItem(
            id: 'ward_12',
            labelKey: LocaleKeys.nominationOptionWard12,
          ),
        ],
        'janpad_depalpur': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_7',
            labelKey: LocaleKeys.nominationOptionWard7,
          ),
          NominationOptionItem(
            id: 'ward_9',
            labelKey: LocaleKeys.nominationOptionWard9,
          ),
        ],
        'janpad_mhow': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_4',
            labelKey: LocaleKeys.nominationOptionWard4,
          ),
          NominationOptionItem(
            id: 'ward_25',
            labelKey: LocaleKeys.nominationOptionWard25,
          ),
        ],
        'janpad_bina': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_31',
            labelKey: LocaleKeys.nominationOptionWard31,
          ),
          NominationOptionItem(
            id: 'ward_9',
            labelKey: LocaleKeys.nominationOptionWard9,
          ),
        ],
        'janpad_rahatgarh': <NominationOptionItem>[
          NominationOptionItem(
            id: 'ward_12',
            labelKey: LocaleKeys.nominationOptionWard12,
          ),
          NominationOptionItem(
            id: 'ward_7',
            labelKey: LocaleKeys.nominationOptionWard7,
          ),
        ],
      };

  static const Map<String, List<NominationOptionItem>> _gramByJanpad =
      <String, List<NominationOptionItem>>{
        'janpad_phanda': <NominationOptionItem>[
          NominationOptionItem(
            id: 'gram_ratua',
            labelKey: LocaleKeys.nominationOptionGramRatua,
          ),
          NominationOptionItem(
            id: 'gram_intkhedi',
            labelKey: LocaleKeys.nominationOptionGramIntkhedi,
          ),
        ],
        'janpad_berasia': <NominationOptionItem>[
          NominationOptionItem(
            id: 'gram_nazirabad',
            labelKey: LocaleKeys.nominationOptionGramNazirabad,
          ),
          NominationOptionItem(
            id: 'gram_dongargaon',
            labelKey: LocaleKeys.nominationOptionGramDongargaon,
          ),
        ],
        'janpad_depalpur': <NominationOptionItem>[
          NominationOptionItem(
            id: 'gram_gautampura',
            labelKey: LocaleKeys.nominationOptionGramGautampura,
          ),
          NominationOptionItem(
            id: 'gram_betma',
            labelKey: LocaleKeys.nominationOptionGramBetma,
          ),
        ],
        'janpad_mhow': <NominationOptionItem>[
          NominationOptionItem(
            id: 'gram_manpur',
            labelKey: LocaleKeys.nominationOptionGramManpur,
          ),
          NominationOptionItem(
            id: 'gram_choral',
            labelKey: LocaleKeys.nominationOptionGramChoral,
          ),
        ],
        'janpad_bina': <NominationOptionItem>[
          NominationOptionItem(
            id: 'gram_khurai',
            labelKey: LocaleKeys.nominationOptionGramKhurai,
          ),
          NominationOptionItem(
            id: 'gram_banagra',
            labelKey: LocaleKeys.nominationOptionGramBanagra,
          ),
        ],
        'janpad_rahatgarh': <NominationOptionItem>[
          NominationOptionItem(
            id: 'gram_rehli',
            labelKey: LocaleKeys.nominationOptionGramRehli,
          ),
          NominationOptionItem(
            id: 'gram_garhakota',
            labelKey: LocaleKeys.nominationOptionGramGarhakota,
          ),
        ],
      };

  bool get useUrbanApi => args.usesUrbanMasterApi;

  bool get showUrbanBodyType =>
      !useUrbanApi && args.postType.requiresUrbanBodyType;

  /// API urban flow always needs urban body after district.
  bool get showUrbanBodyName =>
      useUrbanApi || args.postType.requiresUrbanBodyName;

  bool get showJanpadPanchayat => args.postType.requiresJanpadPanchayat;
  bool get showGramPanchayat => args.postType.requiresGramPanchayat;

  bool get showWard =>
      useUrbanApi ? args.postType.requiresWard : args.postType.requiresWard;

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
      districtId: selectedDistrictId.value,
      urbanBodyTypeId: selectedUrbanBodyTypeId.value,
      municipalityId: showUrbanBodyName ? selectedMunicipalityId.value : null,
      janpadPanchayatId: showJanpadPanchayat
          ? selectedJanpadPanchayatId.value
          : null,
      gramPanchayatId: showGramPanchayat ? selectedGramPanchayatId.value : null,
      wardId: showWard ? selectedWardId.value : null,
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
      documents: Map<String, NominationDocumentUploadState>.from(
        documentStates,
      ),
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
      districtId: draft.districtId,
      urbanBodyTypeId: draft.urbanBodyTypeId,
      municipalityId: draft.municipalityId,
      janpadPanchayatId: draft.janpadPanchayatId,
      gramPanchayatId: draft.gramPanchayatId,
      wardId: draft.wardId,
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
    required String? districtId,
    required String? urbanBodyTypeId,
    required String? municipalityId,
    required String? janpadPanchayatId,
    required String? gramPanchayatId,
    required String? wardId,
  }) {
    if (useUrbanApi) {
      unawaited(
        _restoreUrbanApiSelections(
          districtId: districtId,
          municipalityId: municipalityId,
          wardId: wardId,
        ),
      );
      return;
    }

    districtOptions.assignAll(_districts);
    selectedDistrictId.value = districtId;

    if (showUrbanBodyType) {
      urbanBodyTypeOptions.assignAll(_urbanBodyTypes);
      selectedUrbanBodyTypeId.value = urbanBodyTypeId;
    } else {
      urbanBodyTypeOptions.clear();
      selectedUrbanBodyTypeId.value = null;
    }

    if (showUrbanBodyName) {
      municipalityOptions.assignAll(
        _municipalityOptionsFor(
          districtId: districtId,
          urbanBodyTypeId: urbanBodyTypeId,
        ),
      );
      selectedMunicipalityId.value = municipalityId;
    } else {
      municipalityOptions.clear();
      selectedMunicipalityId.value = null;
    }

    if (showJanpadPanchayat) {
      janpadPanchayatOptions.assignAll(
        _janpadByDistrict[districtId] ?? const <NominationOptionItem>[],
      );
      selectedJanpadPanchayatId.value = janpadPanchayatId;
    } else {
      janpadPanchayatOptions.clear();
      selectedJanpadPanchayatId.value = null;
    }

    if (showGramPanchayat) {
      gramPanchayatOptions.assignAll(
        _gramByJanpad[janpadPanchayatId] ?? const <NominationOptionItem>[],
      );
      selectedGramPanchayatId.value = gramPanchayatId;
    } else {
      gramPanchayatOptions.clear();
      selectedGramPanchayatId.value = null;
    }

    if (showWard) {
      wardOptions.assignAll(
        _wardOptionsFor(
          districtId: districtId,
          urbanBodyTypeId: urbanBodyTypeId,
          janpadPanchayatId: janpadPanchayatId,
        ),
      );
      selectedWardId.value = wardId;
    } else {
      wardOptions.clear();
      selectedWardId.value = null;
    }
  }

  Future<void> _restoreUrbanApiSelections({
    required String? districtId,
    required String? municipalityId,
    required String? wardId,
  }) async {
    await _loadUrbanDistricts();
    selectedDistrictId.value = districtId;
    if (districtId == null || districtId.isEmpty) return;
    await _loadUrbanBodies(districtId);
    selectedMunicipalityId.value = municipalityId;
    if (municipalityId != null) {
      for (final NominationOptionItem o in municipalityOptions) {
        if (o.id == municipalityId) {
          selectedUrbanBodyTypeIdMeta.value = int.tryParse(
            o.meta['typeId'] ?? '',
          );
          break;
        }
      }
    }
    if (showWard &&
        municipalityId != null &&
        municipalityId.isNotEmpty) {
      await _loadUrbanWards(dstId: districtId, ubId: municipalityId);
      selectedWardId.value = wardId;
    }
  }

  @override
  void onInit() {
    super.onInit();
    selectedGenderId.value = genderOptions.first.id;
    selectedCategoryId.value = categoryOptions.first.id;
    for (final NominationOptionItem doc in requiredDocuments) {
      documentStates[doc.id] = const NominationDocumentUploadState();
    }
    if (useUrbanApi) {
      unawaited(_loadUrbanDistricts());
    } else {
      districtOptions.assignAll(_districts);
    }
  }

  Future<void> _loadUrbanDistricts() async {
    final int electionId = args.urbanElectionId!;
    final int postId = args.urbanPostId!;
    final int token = ++_urbanLoadToken;
    mastersLoading.value = true;
    mastersError.value = null;
    try {
      final List<NominationOptionItem> rows = await _urbanMasters.fetchDistricts(
        electionId: electionId,
        postId: postId,
      );
      if (token != _urbanLoadToken || isClosed) return;
      districtOptions.assignAll(rows);
    } catch (e) {
      if (token != _urbanLoadToken || isClosed) return;
      mastersError.value = e.toString();
      districtOptions.clear();
    } finally {
      if (token == _urbanLoadToken && !isClosed) {
        mastersLoading.value = false;
      }
    }
  }

  Future<void> _loadUrbanBodies(String dstId) async {
    final int postId = args.urbanPostId!;
    final int token = ++_urbanLoadToken;
    mastersLoading.value = true;
    mastersError.value = null;
    municipalityOptions.clear();
    wardOptions.clear();
    selectedMunicipalityId.value = null;
    selectedWardId.value = null;
    selectedUrbanBodyTypeIdMeta.value = null;
    try {
      final List<NominationOptionItem> rows = await _urbanMasters
          .fetchUrbanBodyOptions(
            postId: postId,
            dstId: dstId,
            postType: args.postType,
          );
      if (token != _urbanLoadToken || isClosed) return;
      municipalityOptions.assignAll(rows);
    } catch (e) {
      if (token != _urbanLoadToken || isClosed) return;
      mastersError.value = e.toString();
      municipalityOptions.clear();
    } finally {
      if (token == _urbanLoadToken && !isClosed) {
        mastersLoading.value = false;
      }
    }
  }

  Future<void> _loadUrbanWards({
    required String dstId,
    required String ubId,
  }) async {
    final int postId = args.urbanPostId!;
    final int token = ++_urbanLoadToken;
    mastersLoading.value = true;
    mastersError.value = null;
    wardOptions.clear();
    selectedWardId.value = null;
    try {
      final List<NominationOptionItem> rows = await _urbanMasters.fetchWards(
        postId: postId,
        dstId: dstId,
        ubId: ubId,
      );
      if (token != _urbanLoadToken || isClosed) return;
      wardOptions.assignAll(rows);
    } catch (e) {
      if (token != _urbanLoadToken || isClosed) return;
      mastersError.value = e.toString();
      wardOptions.clear();
    } finally {
      if (token == _urbanLoadToken && !isClosed) {
        mastersLoading.value = false;
      }
    }
  }

  void onDistrictChanged(String? districtId) {
    selectedDistrictId.value = districtId;
    selectedUrbanBodyTypeId.value = null;
    selectedMunicipalityId.value = null;
    selectedJanpadPanchayatId.value = null;
    selectedGramPanchayatId.value = null;
    selectedWardId.value = null;
    selectedUrbanBodyTypeIdMeta.value = null;
    municipalityOptions.clear();
    janpadPanchayatOptions.clear();
    gramPanchayatOptions.clear();
    wardOptions.clear();

    if (useUrbanApi) {
      urbanBodyTypeOptions.clear();
      if (districtId != null && districtId.isNotEmpty) {
        unawaited(_loadUrbanBodies(districtId));
      }
      return;
    }

    if (showUrbanBodyType) {
      urbanBodyTypeOptions.assignAll(_urbanBodyTypes);
    } else {
      urbanBodyTypeOptions.clear();
    }

    if (showJanpadPanchayat) {
      janpadPanchayatOptions.assignAll(
        _janpadByDistrict[districtId] ?? const <NominationOptionItem>[],
      );
    }

    if (args.postType == NominationPostType.districtPanchayatMember) {
      wardOptions.assignAll(
        _wardByDistrict[districtId] ?? const <NominationOptionItem>[],
      );
    }
  }

  void onUrbanBodyTypeChanged(String? urbanBodyTypeId) {
    selectedUrbanBodyTypeId.value = urbanBodyTypeId;
    selectedMunicipalityId.value = null;
    selectedWardId.value = null;
    municipalityOptions.clear();
    wardOptions.clear();

    if (useUrbanApi) return;

    if (showUrbanBodyName) {
      municipalityOptions.assignAll(
        _municipalityOptionsFor(
          districtId: selectedDistrictId.value,
          urbanBodyTypeId: urbanBodyTypeId,
        ),
      );
      return;
    }

    if (args.postType == NominationPostType.parshad) {
      wardOptions.assignAll(
        _wardOptionsFor(
          districtId: selectedDistrictId.value,
          urbanBodyTypeId: urbanBodyTypeId,
          janpadPanchayatId: null,
        ),
      );
    }
  }

  void onMunicipalityChanged(String? municipalityId) {
    selectedMunicipalityId.value = municipalityId;
    selectedWardId.value = null;
    wardOptions.clear();
    selectedUrbanBodyTypeIdMeta.value = null;

    if (municipalityId != null) {
      for (final NominationOptionItem o in municipalityOptions) {
        if (o.id == municipalityId) {
          final String? typeRaw = o.meta['typeId'];
          selectedUrbanBodyTypeIdMeta.value = int.tryParse(typeRaw ?? '');
          break;
        }
      }
    }

    if (useUrbanApi &&
        showWard &&
        municipalityId != null &&
        selectedDistrictId.value != null) {
      unawaited(
        _loadUrbanWards(
          dstId: selectedDistrictId.value!,
          ubId: municipalityId,
        ),
      );
    }
  }

  void onJanpadPanchayatChanged(String? janpadPanchayatId) {
    selectedJanpadPanchayatId.value = janpadPanchayatId;
    selectedGramPanchayatId.value = null;
    selectedWardId.value = null;
    gramPanchayatOptions.clear();
    wardOptions.clear();

    if (showGramPanchayat) {
      gramPanchayatOptions.assignAll(
        _gramByJanpad[janpadPanchayatId] ?? const <NominationOptionItem>[],
      );
    }

    if (args.postType == NominationPostType.janpadPanchayatMember) {
      wardOptions.assignAll(
        _wardByJanpad[janpadPanchayatId] ?? const <NominationOptionItem>[],
      );
    }
  }

  void onGramPanchayatChanged(String? gramPanchayatId) {
    selectedGramPanchayatId.value = gramPanchayatId;
  }

  void onWardChanged(String? wardId) {
    selectedWardId.value = wardId;
  }

  void onGenderChanged(String? genderId) {
    selectedGenderId.value = genderId;
  }

  void onCategoryChanged(String? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  bool validateAreaStep() {
    if (selectedDistrictId.value == null) {
      return false;
    }
    if (showUrbanBodyType && selectedUrbanBodyTypeId.value == null) {
      return false;
    }
    if (showUrbanBodyName && selectedMunicipalityId.value == null) {
      return false;
    }
    if (showJanpadPanchayat && selectedJanpadPanchayatId.value == null) {
      return false;
    }
    if (showGramPanchayat && selectedGramPanchayatId.value == null) {
      return false;
    }
    if (showWard) {
      // API may return empty ward list for some posts — only require when options exist
      // or when post traditionally requires a ward.
      if (useUrbanApi) {
        if (wardOptions.isNotEmpty && selectedWardId.value == null) {
          return false;
        }
        if (args.postType.requiresWard && selectedWardId.value == null) {
          return false;
        }
      } else if (selectedWardId.value == null) {
        return false;
      }
    }
    return true;
  }

  List<NominationOptionItem> _municipalityOptionsFor({
    required String? districtId,
    required String? urbanBodyTypeId,
  }) {
    final List<_UrbanBodyOption> bodies =
        _bodiesByDistrict[districtId] ?? const <_UrbanBodyOption>[];
    final UrbanBodyType? type = _urbanBodyTypeFromId(urbanBodyTypeId);
    if (type == null) {
      return const <NominationOptionItem>[];
    }
    return bodies
        .where((_UrbanBodyOption b) => b.type == type)
        .map(
          (_UrbanBodyOption body) =>
              NominationOptionItem(id: body.id, labelKey: body.labelKey),
        )
        .toList(growable: false);
  }

  List<NominationOptionItem> _wardOptionsFor({
    required String? districtId,
    required String? urbanBodyTypeId,
    required String? janpadPanchayatId,
  }) {
    switch (args.postType) {
      case NominationPostType.parshad:
        final UrbanBodyType? type = _urbanBodyTypeFromId(urbanBodyTypeId);
        if (type == null) {
          return const <NominationOptionItem>[];
        }
        final List<_UrbanBodyOption> bodies =
            _bodiesByDistrict[districtId] ?? const <_UrbanBodyOption>[];
        final Map<String, NominationOptionItem> unique =
            <String, NominationOptionItem>{};
        for (final _UrbanBodyOption body in bodies.where(
          (_UrbanBodyOption b) => b.type == type,
        )) {
          for (final NominationOptionItem ward
              in _wardByMunicipality[body.id] ??
                  const <NominationOptionItem>[]) {
            unique[ward.id] = ward;
          }
        }
        return unique.values.toList(growable: false);
      case NominationPostType.districtPanchayatMember:
        return _wardByDistrict[districtId] ?? const <NominationOptionItem>[];
      case NominationPostType.janpadPanchayatMember:
        return _wardByJanpad[janpadPanchayatId] ??
            const <NominationOptionItem>[];
      case NominationPostType.mahapaur:
      case NominationPostType.adhyaksh:
      case NominationPostType.sarpanch:
        return const <NominationOptionItem>[];
    }
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
      final AppPickedImage? picked = await _imagePickerService
          .pickCompressedImage(source: source);
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
      urbanElectionId: args.urbanElectionId,
      urbanElectionName: args.urbanElectionName,
      urbanPostId: args.urbanPostId,
      urbanPostName: args.urbanPostName,
    );
  }

  String displayLabelFor(String? id, List<NominationOptionItem> options) {
    if (id == null) return '-';
    for (final NominationOptionItem option in options) {
      if (option.id != id) continue;
      if (option.isApiLabel) return option.label;
      if (option.labelKey.isEmpty) return option.id;
      return option.labelKey.tr();
    }
    return '-';
  }

  String get postDisplayLabel {
    final String? apiName = args.urbanPostName?.trim();
    if (apiName != null && apiName.isNotEmpty) return apiName;
    return args.postType.labelKey.tr();
  }

  String get electionDisplayLabel {
    final String? apiName = args.urbanElectionName?.trim();
    if (apiName != null && apiName.isNotEmpty) return apiName;
    return args.electionType.labelKey.tr();
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
