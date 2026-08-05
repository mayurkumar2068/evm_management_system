import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/features/voter_search/data/datasources/voter_search_remote_datasource.dart';
import 'package:evm_management_system/features/voter_search/data/hindi_transliteration_service.dart';
import 'package:evm_management_system/features/voter_search/data/models/voter_search_models.dart';
import 'package:evm_management_system/features/voter_search/data/repositories/voter_search_repository.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

enum VoterSearchTab { details, epic }

enum VoterAreaType { rural, urban }

/// GetX controller for native voter search (SECSearchAPI).
class VoterSearchController extends GetxController {
  VoterSearchController(
    this._repository, {
    HindiTransliterationService? transliteration,
  }) : _transliteration = transliteration ?? HindiTransliterationService();

  final VoterSearchRepository _repository;
  final HindiTransliterationService _transliteration;

  final GlobalKey<FormState> detailsFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> epicFormKey = GlobalKey<FormState>();

  late final TextEditingController electorNameController;
  late final TextEditingController relativeNameController;
  late final TextEditingController ageController;
  late final TextEditingController epicController;

  final Rx<VoterSearchTab> activeTab = VoterSearchTab.details.obs;
  final Rx<VoterAreaType> areaType = VoterAreaType.rural.obs;

  final RxBool loadingDistricts = false.obs;
  final RxBool loadingBlocks = false.obs;
  final RxBool loadingUrbanBodies = false.obs;
  final RxBool searching = false.obs;
  final RxBool showingResults = false.obs;
  final RxBool transliteratingName = false.obs;

  final RxList<VoterDistrict> districts = <VoterDistrict>[].obs;
  final RxList<VoterBlock> blocks = <VoterBlock>[].obs;
  final RxList<VoterUrbanBody> urbanBodies = <VoterUrbanBody>[].obs;
  final RxList<VoterElector> results = <VoterElector>[].obs;

  final Rxn<VoterDistrict> selectedDistrict = Rxn<VoterDistrict>();
  final Rxn<VoterBlock> selectedBlock = Rxn<VoterBlock>();
  final Rxn<VoterUrbanBody> selectedUrbanBody = Rxn<VoterUrbanBody>();
  final RxnString selectedGender = RxnString('M');

  final RxnString formError = RxnString();
  final Map<String, String?> photoCache = <String, String?>{};
  final Map<String, Future<String?>> _photoFutures = <String, Future<String?>>{};
  bool _photoFetchBusy = false;

  int _searchToken = 0;
  int _nameTranslitToken = 0;
  int _relativeTranslitToken = 0;
  bool _applyingTransliteration = false;

  bool get preferHindi =>
      AppServices.settings.locale.value.languageCode.toLowerCase() == 'hi';

  List<String?> get genderOptions => <String?>[null, 'M', 'F', 'O'];

  String genderLabel(String? code) {
    return switch (code) {
      'M' => LocaleKeys.nominationOptionMale.tr(),
      'F' => LocaleKeys.nominationOptionFemale.tr(),
      'O' => LocaleKeys.nominationOptionOther.tr(),
      _ => LocaleKeys.voterSearchGenderAny.tr(),
    };
  }

  @override
  void onInit() {
    super.onInit();
    electorNameController = TextEditingController();
    relativeNameController = TextEditingController();
    ageController = TextEditingController();
    epicController = TextEditingController();
    electorNameController.addListener(_onElectorNameChanged);
    relativeNameController.addListener(_onRelativeNameChanged);
    loadDistricts();
  }

  @override
  void onClose() {
    electorNameController.removeListener(_onElectorNameChanged);
    relativeNameController.removeListener(_onRelativeNameChanged);
    electorNameController.dispose();
    relativeNameController.dispose();
    ageController.dispose();
    epicController.dispose();
    super.onClose();
  }

  void _onElectorNameChanged() {
    if (_applyingTransliteration) return;
    final String text = electorNameController.text;
    if (!text.endsWith(' ') && !text.endsWith('\n')) return;
    _transliterateController(
      electorNameController,
      tokenSlot: 'name',
    );
  }

  void _onRelativeNameChanged() {
    if (_applyingTransliteration) return;
    final String text = relativeNameController.text;
    if (!text.endsWith(' ') && !text.endsWith('\n')) return;
    _transliterateController(
      relativeNameController,
      tokenSlot: 'relative',
    );
  }

  Future<void> _transliterateController(
    TextEditingController controller, {
    required String tokenSlot,
  }) async {
    final int token = tokenSlot == 'name'
        ? ++_nameTranslitToken
        : ++_relativeTranslitToken;
    final String original = controller.text;
    final bool keepTrailingSpace =
        original.endsWith(' ') || original.endsWith('\n');
    transliteratingName.value = true;
    try {
      String converted = await _transliteration.transliterateText(original);
      if (keepTrailingSpace && !converted.endsWith(' ')) {
        converted = '$converted ';
      }
      final bool stillCurrent = tokenSlot == 'name'
          ? token == _nameTranslitToken
          : token == _relativeTranslitToken;
      if (!stillCurrent || converted == original) return;
      _applyingTransliteration = true;
      controller.value = TextEditingValue(
        text: converted,
        selection: TextSelection.collapsed(offset: converted.length),
      );
    } finally {
      _applyingTransliteration = false;
      transliteratingName.value = false;
    }
  }

  /// Converts any remaining Latin words before search submit.
  Future<void> flushNameTransliteration() async {
    await Future.wait(<Future<void>>[
      _forceTransliterate(electorNameController),
      _forceTransliterate(relativeNameController),
    ]);
  }

  Future<void> _forceTransliterate(TextEditingController controller) async {
    final String original = controller.text;
    if (original.trim().isEmpty) return;
    final String converted = await _transliteration.transliterateText(original);
    if (converted == original) return;
    _applyingTransliteration = true;
    try {
      controller.value = TextEditingValue(
        text: converted,
        selection: TextSelection.collapsed(offset: converted.length),
      );
    } finally {
      _applyingTransliteration = false;
    }
  }

  Future<void> loadDistricts() async {
    loadingDistricts.value = true;
    formError.value = null;
    try {
      final List<VoterDistrict> list = await _repository.fetchDistricts();
      districts.assignAll(list);
    } on VoterSearchApiException catch (e) {
      formError.value = e.message;
    } catch (_) {
      formError.value = LocaleKeys.voterSearchErrorGeneric.tr();
    } finally {
      loadingDistricts.value = false;
    }
  }

  Future<void> refreshAll() async {
    selectedDistrict.value = null;
    selectedBlock.value = null;
    selectedUrbanBody.value = null;
    selectedGender.value = 'M';
    blocks.clear();
    urbanBodies.clear();
    results.clear();
    showingResults.value = false;
    formError.value = null;
    electorNameController.clear();
    relativeNameController.clear();
    ageController.clear();
    epicController.clear();
    await loadDistricts();
  }

  void setTab(VoterSearchTab tab) {
    if (activeTab.value == tab) return;
    activeTab.value = tab;
    formError.value = null;
    showingResults.value = false;
  }

  void setAreaType(VoterAreaType type) {
    if (areaType.value == type) return;
    areaType.value = type;
    selectedBlock.value = null;
    selectedUrbanBody.value = null;
    blocks.clear();
    urbanBodies.clear();
    final VoterDistrict? district = selectedDistrict.value;
    if (district != null) {
      _loadAreaMasters(district);
    }
  }

  Future<void> onDistrictChanged(VoterDistrict? district) async {
    selectedDistrict.value = district;
    selectedBlock.value = null;
    selectedUrbanBody.value = null;
    blocks.clear();
    urbanBodies.clear();
    formError.value = null;
    if (district == null) return;
    await _loadAreaMasters(district);
  }

  Future<void> _loadAreaMasters(VoterDistrict district) async {
    if (areaType.value == VoterAreaType.rural) {
      loadingBlocks.value = true;
      try {
        final List<VoterBlock> list = await _repository.fetchBlocks(district.id);
        blocks.assignAll(list);
      } on VoterSearchApiException catch (e) {
        formError.value = e.message;
      } catch (_) {
        formError.value = LocaleKeys.voterSearchErrorGeneric.tr();
      } finally {
        loadingBlocks.value = false;
      }
    } else {
      loadingUrbanBodies.value = true;
      try {
        final List<VoterUrbanBody> list =
            await _repository.fetchUrbanBodies(district.id);
        urbanBodies.assignAll(list);
      } on VoterSearchApiException catch (e) {
        formError.value = e.message;
      } catch (_) {
        formError.value = LocaleKeys.voterSearchErrorGeneric.tr();
      } finally {
        loadingUrbanBodies.value = false;
      }
    }
  }

  void onBlockChanged(VoterBlock? block) {
    selectedBlock.value = block;
  }

  void onUrbanBodyChanged(VoterUrbanBody? body) {
    selectedUrbanBody.value = body;
  }

  void onGenderChanged(String? gender) {
    selectedGender.value = gender;
  }

  void backToSearch() {
    showingResults.value = false;
    results.clear();
  }

  Future<void> search() async {
    if (searching.value) return;
    formError.value = null;

    await flushNameTransliteration();

    final bool ok = activeTab.value == VoterSearchTab.details
        ? _validateDetails()
        : _validateEpic();
    if (!ok) return;

    final ElectorSearchQuery? query = activeTab.value == VoterSearchTab.details
        ? _buildDetailsQuery()
        : _buildEpicQuery();
    if (query == null) return;

    final int token = ++_searchToken;
    searching.value = true;
    try {
      final List<VoterElector> list = await _repository.searchElectors(query);
      if (token != _searchToken) return;
      results.assignAll(list);
      showingResults.value = true;
    } on VoterSearchApiException catch (e) {
      if (token != _searchToken) return;
      formError.value = e.message;
    } catch (_) {
      if (token != _searchToken) return;
      formError.value = LocaleKeys.voterSearchErrorGeneric.tr();
    } finally {
      if (token == _searchToken) searching.value = false;
    }
  }

  bool _validateDetails() {
    final VoterDistrict? district = selectedDistrict.value;
    if (district == null) {
      formError.value = LocaleKeys.voterSearchErrorDistrict.tr();
      return false;
    }
    if (areaType.value == VoterAreaType.rural) {
      if (selectedBlock.value == null) {
        formError.value = LocaleKeys.voterSearchErrorBlock.tr();
        return false;
      }
    } else if (selectedUrbanBody.value == null) {
      formError.value = LocaleKeys.voterSearchErrorUrbanBody.tr();
      return false;
    }
    if (electorNameController.text.trim().isEmpty) {
      formError.value = LocaleKeys.voterSearchErrorName.tr();
      return false;
    }
    final String age = ageController.text.trim();
    if (age.isNotEmpty && int.tryParse(age) == null) {
      formError.value = LocaleKeys.voterSearchErrorAge.tr();
      return false;
    }
    return detailsFormKey.currentState?.validate() ?? true;
  }

  bool _validateEpic() {
    if (selectedDistrict.value == null) {
      formError.value = LocaleKeys.voterSearchErrorDistrict.tr();
      return false;
    }
    if (epicController.text.trim().isEmpty) {
      formError.value = LocaleKeys.voterSearchErrorEpic.tr();
      return false;
    }
    return epicFormKey.currentState?.validate() ?? true;
  }

  ElectorSearchQuery? _buildDetailsQuery() {
    final VoterDistrict? district = selectedDistrict.value;
    if (district == null) return null;

    final bool rural = areaType.value == VoterAreaType.rural;
    return ElectorSearchQuery(
      elecType: rural ? 'R' : 'U',
      distNo: district.distNo,
      ubType: rural ? '' : (selectedUrbanBody.value?.ubType ?? ''),
      ubNo: rural ? '' : (selectedUrbanBody.value?.ubNo ?? ''),
      blockNo: rural ? (selectedBlock.value?.blockNo ?? '') : '',
      panchayatNo: '',
      elecName: electorNameController.text.trim(),
      relName: relativeNameController.text.trim(),
      age: ageController.text.trim(),
      gender: selectedGender.value ?? '',
    );
  }

  ElectorSearchQuery? _buildEpicQuery() {
    final VoterDistrict? district = selectedDistrict.value;
    if (district == null) return null;
    final bool rural = areaType.value == VoterAreaType.rural;
    return ElectorSearchQuery(
      elecType: rural ? 'R' : 'U',
      distNo: district.distNo,
      epicNo: epicController.text.trim().toUpperCase(),
    );
  }

  bool isPhotoLoading(String electorId) =>
      _photoFutures.containsKey(electorId) && !photoCache.containsKey(electorId);

  /// Loads voter photo once and caches it. Concurrent callers share one request.
  /// Failed fetches (e.g. HTTP 403) are negative-cached so card + slip don't re-hit.
  Future<String?> loadPhoto(VoterElector elector) {
    final String key = elector.id;
    if (photoCache.containsKey(key)) {
      final String? cached = photoCache[key];
      return Future<String?>.value(
        (cached != null && cached.isNotEmpty) ? cached : null,
      );
    }
    return _photoFutures.putIfAbsent(key, () => _fetchAndCachePhoto(elector));
  }

  Future<String?> _fetchAndCachePhoto(VoterElector elector) async {
    final String key = elector.id;
    // Serialize photo downloads — parallel storms hang / starve the connection pool.
    while (_photoFetchBusy) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    _photoFetchBusy = true;
    try {
      final String? photo = await _repository.fetchPhoto(
        distNo: elector.distNo,
        electorId: elector.id,
      );
      // Empty string = known-unavailable (403 / empty). Keeps containsKey true.
      photoCache[key] = (photo != null && photo.isNotEmpty) ? photo : '';
      update(<Object>['photo_$key']);
      return (photo != null && photo.isNotEmpty) ? photo : null;
    } catch (_) {
      photoCache[key] = '';
      update(<Object>['photo_$key']);
      return null;
    } finally {
      _photoFetchBusy = false;
      // ignore: unawaited_futures
      _photoFutures.remove(key);
    }
  }
}
