import 'package:evm_management_system/localization/locale_keys.dart';

class NominationOptionItem {
  const NominationOptionItem({
    required this.id,
    this.labelKey = '',
    this.label = '',
    this.meta = const <String, String>{},
  });

  /// API-sourced option (display [label] as-is, no i18n lookup).
  factory NominationOptionItem.api({
    required String id,
    required String label,
    Map<String, String> meta = const <String, String>{},
  }) => NominationOptionItem(id: id, label: label, meta: meta);

  final String id;

  /// EasyLocalization key for static/hardcoded options.
  final String labelKey;

  /// Raw display label from API (preferred when non-empty).
  final String label;

  /// Optional extra fields (e.g. typeId, wardNo).
  final Map<String, String> meta;

  bool get isApiLabel => label.isNotEmpty;
}

enum NominationElectionType { urban, panchayat }

enum NominationPostType {
  mahapaur,
  adhyaksh,
  parshad,
  districtPanchayatMember,
  janpadPanchayatMember,
  sarpanch,
}

/// Urban local-body category used to filter municipality / UB dropdowns.
enum UrbanBodyType { nagarNigam, nagarPalikaParishad, nagarParishad }

extension UrbanBodyTypeKey on UrbanBodyType {
  String get labelKey => switch (this) {
    UrbanBodyType.nagarNigam => LocaleKeys.nominationOptionBodyNagarNigam,
    UrbanBodyType.nagarPalikaParishad =>
      LocaleKeys.nominationOptionBodyNagarPalikaParishad,
    UrbanBodyType.nagarParishad => LocaleKeys.nominationOptionBodyNagarParishad,
  };
}

extension NominationPostTypeUrbanCascade on NominationPostType {
  bool get isUrbanPost =>
      this == NominationPostType.mahapaur ||
      this == NominationPostType.adhyaksh ||
      this == NominationPostType.parshad;

  /// नगरीय निकाय: महापौर / अध्यक्ष / पार्षद — निकाय प्रकार.
  bool get requiresUrbanBodyType => isUrbanPost;

  /// महापौर / अध्यक्ष — निकाय का नाम.
  bool get requiresUrbanBodyName =>
      this == NominationPostType.mahapaur ||
      this == NominationPostType.adhyaksh;

  /// जनपद पंचायत सदस्य / सरपंच — जनपद पंचायत.
  bool get requiresJanpadPanchayat =>
      this == NominationPostType.janpadPanchayatMember ||
      this == NominationPostType.sarpanch;

  /// सरपंच — ग्राम पंचायत.
  bool get requiresGramPanchayat => this == NominationPostType.sarpanch;

  /// पार्षद / जिला पंचायत सदस्य / जनपद पंचायत सदस्य — वार्ड क्रमांक.
  bool get requiresWard =>
      this == NominationPostType.parshad ||
      this == NominationPostType.districtPanchayatMember ||
      this == NominationPostType.janpadPanchayatMember;

  String get municipalityFieldLabelKey => LocaleKeys.nominationFieldUbName;
}

class NominationFlowArgs {
  const NominationFlowArgs({
    required this.electionType,
    required this.postType,
    this.applicationNumber,
    this.submittedAt,
    this.resumeDraft = false,
    this.urbanElectionId,
    this.urbanElectionName,
    this.urbanPostId,
    this.urbanPostName,
  });

  final NominationElectionType electionType;
  final NominationPostType postType;
  final String? applicationNumber;
  final DateTime? submittedAt;
  final bool resumeDraft;

  /// OLINAPI election id when urban masters are loaded from API.
  final int? urbanElectionId;
  final String? urbanElectionName;

  /// OLINAPI post id when urban masters are loaded from API.
  final int? urbanPostId;
  final String? urbanPostName;

  bool get usesUrbanMasterApi =>
      electionType == NominationElectionType.urban &&
      urbanElectionId != null &&
      urbanElectionId! > 0 &&
      urbanPostId != null &&
      urbanPostId! > 0;
}

extension NominationElectionTypeKey on NominationElectionType {
  String get labelKey => switch (this) {
    NominationElectionType.urban => LocaleKeys.nominationUrbanTitle,
    NominationElectionType.panchayat => LocaleKeys.nominationPanchayatTitle,
  };
}

extension NominationPostTypeKey on NominationPostType {
  String get labelKey => switch (this) {
    NominationPostType.mahapaur => LocaleKeys.nominationMahapaur,
    NominationPostType.adhyaksh => LocaleKeys.nominationAdhyaksh,
    NominationPostType.parshad => LocaleKeys.nominationParshad,
    NominationPostType.districtPanchayatMember =>
      LocaleKeys.nominationDistrictPanchayatMember,
    NominationPostType.janpadPanchayatMember =>
      LocaleKeys.nominationJanpadPanchayatMember,
    NominationPostType.sarpanch => LocaleKeys.nominationSarpanch,
  };
}

class NominationStepItem {
  const NominationStepItem({required this.id, required this.labelKey});

  final String id;
  final String labelKey;
}
