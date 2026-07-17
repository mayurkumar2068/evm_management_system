import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_form_state.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/localization/locale_keys.dart';

/// Locally persisted in-progress nomination form.
class NominationDraft {
  const NominationDraft({
    required this.electionType,
    required this.postType,
    required this.currentStep,
    required this.savedAt,
    this.stateId,
    this.districtId,
    this.urbanBodyTypeId,
    this.municipalityId,
    this.wardId,
    this.reservationId,
    this.genderId,
    this.categoryId,
    this.fullName = '',
    this.parentName = '',
    this.dob = '',
    this.mobile = '',
    this.email = '',
    this.aadhaar = '',
    this.voterId = '',
    this.addressLine = '',
    this.pincode = '',
    this.declarationAccepted = false,
    this.documents = const <String, NominationDocumentUploadState>{},
  });

  final NominationElectionType electionType;
  final NominationPostType postType;
  final int currentStep;
  final DateTime savedAt;
  final String? stateId;
  final String? districtId;
  final String? urbanBodyTypeId;
  final String? municipalityId;
  final String? wardId;
  final String? reservationId;
  final String? genderId;
  final String? categoryId;
  final String fullName;
  final String parentName;
  final String dob;
  final String mobile;
  final String email;
  final String aadhaar;
  final String voterId;
  final String addressLine;
  final String pincode;
  final bool declarationAccepted;
  final Map<String, NominationDocumentUploadState> documents;

  bool get hasProgress {
    if (currentStep > 0) {
      return true;
    }
    if (fullName.trim().isNotEmpty ||
        parentName.trim().isNotEmpty ||
        mobile.trim().isNotEmpty ||
        email.trim().isNotEmpty ||
        addressLine.trim().isNotEmpty) {
      return true;
    }
    if (districtId != null ||
        urbanBodyTypeId != null ||
        municipalityId != null ||
        wardId != null ||
        reservationId != null) {
      return true;
    }
    return documents.values.any(
      (NominationDocumentUploadState state) =>
          state.status == NominationDocumentUploadStatus.uploaded,
    );
  }

  String stepLabelKeyFor(int step) {
    if (step < 0 || step >= _stepLabelKeys.length) {
      return _stepLabelKeys.first;
    }
    return _stepLabelKeys[step];
  }

  static const List<String> _stepLabelKeys = <String>[
    LocaleKeys.nominationAreaSelection,
    LocaleKeys.nominationCandidateDetails,
    LocaleKeys.nominationAddress,
    LocaleKeys.nominationElectionSummary,
    LocaleKeys.nominationDocumentUpload,
    LocaleKeys.nominationPreview,
    LocaleKeys.nominationDeclaration,
  ];

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'electionType': electionType.name,
      'postType': postType.name,
      'currentStep': currentStep,
      'savedAt': savedAt.toIso8601String(),
      'stateId': stateId,
      'districtId': districtId,
      'urbanBodyTypeId': urbanBodyTypeId,
      'municipalityId': municipalityId,
      'wardId': wardId,
      'reservationId': reservationId,
      'genderId': genderId,
      'categoryId': categoryId,
      'fullName': fullName,
      'parentName': parentName,
      'dob': dob,
      'mobile': mobile,
      'email': email,
      'aadhaar': aadhaar,
      'voterId': voterId,
      'addressLine': addressLine,
      'pincode': pincode,
      'declarationAccepted': declarationAccepted,
      'documents': documents.map(
        (String key, NominationDocumentUploadState value) =>
            MapEntry<String, dynamic>(key, _documentToJson(value)),
      ),
    };
  }

  static NominationDraft? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    final NominationElectionType? electionType = _electionTypeFrom(
      json['electionType']?.toString(),
    );
    final NominationPostType? postType = _postTypeFrom(
      json['postType']?.toString(),
    );
    if (electionType == null || postType == null) {
      return null;
    }
    final String? savedAtRaw = json['savedAt']?.toString();
    final DateTime savedAt = savedAtRaw == null
        ? DateTime.now()
        : DateTime.tryParse(savedAtRaw) ?? DateTime.now();

    final Map<String, NominationDocumentUploadState> documents =
        <String, NominationDocumentUploadState>{};
    final Object? rawDocuments = json['documents'];
    if (rawDocuments is Map) {
      rawDocuments.forEach((Object? key, Object? value) {
        if (key is String && value is Map) {
          documents[key] = _documentFromJson(value.cast<String, dynamic>());
        }
      });
    }

    return NominationDraft(
      electionType: electionType,
      postType: postType,
      currentStep: (json['currentStep'] as num?)?.toInt() ?? 0,
      savedAt: savedAt,
      stateId: json['stateId']?.toString(),
      districtId: json['districtId']?.toString(),
      urbanBodyTypeId: json['urbanBodyTypeId']?.toString(),
      municipalityId: json['municipalityId']?.toString(),
      wardId: json['wardId']?.toString(),
      reservationId: json['reservationId']?.toString(),
      genderId: json['genderId']?.toString(),
      categoryId: json['categoryId']?.toString(),
      fullName: json['fullName']?.toString() ?? '',
      parentName: json['parentName']?.toString() ?? '',
      dob: json['dob']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      aadhaar: json['aadhaar']?.toString() ?? '',
      voterId: json['voterId']?.toString() ?? '',
      addressLine: json['addressLine']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      declarationAccepted: json['declarationAccepted'] == true,
      documents: documents,
    );
  }

  static Map<String, dynamic> _documentToJson(
    NominationDocumentUploadState state,
  ) {
    return <String, dynamic>{
      'status': state.status.name,
      'fileName': state.fileName,
      'filePath': state.filePath,
      'errorMessage': state.errorMessage,
    };
  }

  static NominationDocumentUploadState _documentFromJson(
    Map<String, dynamic> json,
  ) {
    final String? statusName = json['status']?.toString();
    final NominationDocumentUploadStatus status =
        NominationDocumentUploadStatus.values.asNameMap()[statusName] ??
        NominationDocumentUploadStatus.idle;
    return NominationDocumentUploadState(
      status: status,
      fileName: json['fileName']?.toString(),
      filePath: json['filePath']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
    );
  }

  static NominationElectionType? _electionTypeFrom(String? raw) {
    return NominationElectionType.values.asNameMap()[raw];
  }

  static NominationPostType? _postTypeFrom(String? raw) {
    return NominationPostType.values.asNameMap()[raw];
  }
}
