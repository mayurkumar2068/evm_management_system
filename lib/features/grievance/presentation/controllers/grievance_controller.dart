import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/location/location_service.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/media/app_image_picker_service.dart';
import 'package:evm_management_system/features/grievance/data/datasources/grievance_remote_datasource.dart';
import 'package:evm_management_system/features/grievance/data/models/grievance_models.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';

/// TEMPORARY: the Grievance backend isn't live yet, so debug builds skip the
/// real network calls and simulate success to let the UI flow be tested.
/// Flip to false (or delete) once GrievanceEndpoints point at a real API.
/// Guarded by kDebugMode so it can never be active in a release build.
const bool _bypassGrievanceApi = kDebugMode;

class GrievanceCategoryOption {
  const GrievanceCategoryOption({required this.value, required this.labelKey});

  final String value;
  final String labelKey;
}

const List<GrievanceCategoryOption> kGrievanceCategories =
    <GrievanceCategoryOption>[
      GrievanceCategoryOption(
        value: 'VOTER_LIST',
        labelKey: LocaleKeys.grievanceCategoryVoterList,
      ),
      GrievanceCategoryOption(
        value: 'EVM_BOOTH',
        labelKey: LocaleKeys.grievanceCategoryEvmBooth,
      ),
      GrievanceCategoryOption(
        value: 'OFFICER_CONDUCT',
        labelKey: LocaleKeys.grievanceCategoryOfficerConduct,
      ),
      GrievanceCategoryOption(
        value: 'OTHER',
        labelKey: LocaleKeys.grievanceCategoryOther,
      ),
    ];

class GrievanceController extends GetxController {
  GrievanceController(
    this._datasource, {
    LocationService? locationService,
    AppImagePickerService? imagePicker,
  }) : _locationService = locationService ?? LocationService(),
       _imagePicker = imagePicker ?? AppImagePickerService();

  final GrievanceRemoteDatasource _datasource;
  final LocationService _locationService;
  final AppImagePickerService _imagePicker;

  final TextEditingController mobileController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final RxBool busy = false.obs;
  final RxBool otpSent = false.obs;
  final RxnString error = RxnString();
  final Rx<GrievanceCategoryOption> selectedCategory =
      kGrievanceCategories.first.obs;
  final RxnString referenceNo = RxnString();
  final Rxn<GeoCoordinates> location = Rxn<GeoCoordinates>();
  final Rxn<AppPickedImage> photo = Rxn<AppPickedImage>();

  String get verifiedMobile => mobileController.text.trim();

  /// Tags the grievance with the device's current location without blocking.
  /// If [force] is true, fetches fresh live coordinates (e.g. when photo is picked).
  void captureLocationInBackground({bool force = false}) {
    if (!force && location.value != null) return;
    _locationService.getCurrentCoordinates().then((GeoCoordinates? coords) {
      if (coords != null) location.value = coords;
    });
  }

  Future<void> pickPhoto(ImageSource source) async {
    try {
      // Refresh location alongside the photo evidence — the user may have
      // moved since the form was opened.
      captureLocationInBackground(force: true);
      final AppPickedImage? picked = await _imagePicker.pickCompressedImage(
        source: source,
      );
      if (picked != null) {
        photo.value = picked;
        error.value = null;
      }
    } catch (e) {
      AppLogger.d('[Grievance] photo pick failed: $e');
      error.value = LocaleKeys.grievancePhotoPickFailed.tr();
    }
  }

  void removePhoto() => photo.value = null;

  @override
  void onClose() {
    mobileController.dispose();
    otpController.dispose();
    fullNameController.dispose();
    subjectController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void resetOtpState() {
    otpSent.value = false;
    otpController.clear();
    error.value = null;
  }

  /// Runs [real] against the live API, or simulates it via [bypass] while
  /// the backend isn't wired up (see [_bypassGrievanceApi]). Centralizes the
  /// busy/error toggling and error mapping shared by every API call below.
  Future<bool> _guarded({
    required String tag,
    required Duration bypassDelay,
    required Future<void> Function() bypass,
    required Future<void> Function() real,
  }) async {
    busy.value = true;
    error.value = null;
    try {
      if (_bypassGrievanceApi) {
        await Future<void>.delayed(bypassDelay);
        await bypass();
        AppLogger.d('[Grievance] $tag bypassed (API not wired yet)');
      } else {
        await real();
      }
      return true;
    } on GrievanceApiException catch (e) {
      error.value = e.message;
      return false;
    } catch (e) {
      AppLogger.d('[Grievance] $tag failed: $e');
      error.value = LocaleKeys.grievanceGenericError.tr();
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<bool> sendOtp() async {
    final String mobile = mobileController.text.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
      error.value = LocaleKeys.grievanceMobileInvalid.tr();
      return false;
    }

    return _guarded(
      tag: 'sendOtp',
      bypassDelay: const Duration(milliseconds: 400),
      bypass: () async => otpSent.value = true,
      real: () async {
        await _datasource.sendOtp(mobileNo: mobile);
        otpSent.value = true;
      },
    );
  }

  Future<bool> verifyOtp() async {
    final String mobile = mobileController.text.trim();
    final String otp = otpController.text.trim();
    if (otp.isEmpty) {
      error.value = LocaleKeys.grievanceOtpRequired.tr();
      return false;
    }

    return _guarded(
      tag: 'verifyOtp',
      bypassDelay: const Duration(milliseconds: 400),
      bypass: () async {},
      real: () => _datasource.verifyOtp(mobileNo: mobile, otp: otp),
    );
  }

  Future<bool> submitGrievance() async {
    final String name = fullNameController.text.trim();
    final String subject = subjectController.text.trim();
    final String description = descriptionController.text.trim();

    if (name.isEmpty) {
      error.value = LocaleKeys.grievanceNameRequired.tr();
      return false;
    }
    if (subject.isEmpty) {
      error.value = LocaleKeys.grievanceSubjectRequired.tr();
      return false;
    }
    if (description.isEmpty) {
      error.value = LocaleKeys.grievanceDescriptionRequired.tr();
      return false;
    }
    final AppPickedImage? attachedPhoto = photo.value;
    if (attachedPhoto == null) {
      error.value = LocaleKeys.grievancePhotoRequired.tr();
      return false;
    }

    return _guarded(
      tag: 'submit',
      bypassDelay: const Duration(milliseconds: 500),
      bypass: () async {
        referenceNo.value = 'TEST-${DateTime.now().millisecondsSinceEpoch}';
      },
      real: () async {
        final GeoCoordinates? coords = location.value;
        final GrievanceSubmissionResult result = await _datasource.register(
          GrievanceSubmission(
            mobileNo: verifiedMobile,
            fullName: name,
            category: selectedCategory.value.value,
            subject: subject,
            description: description,
            photoBase64: attachedPhoto.dataUrl,
            latitude: coords?.latitude,
            longitude: coords?.longitude,
          ),
        );
        referenceNo.value = result.referenceNo;
      },
    );
  }

  void reset() {
    mobileController.clear();
    otpController.clear();
    fullNameController.clear();
    subjectController.clear();
    descriptionController.clear();
    selectedCategory.value = kGrievanceCategories.first;
    otpSent.value = false;
    referenceNo.value = null;
    location.value = null;
    photo.value = null;
    error.value = null;
  }
}
