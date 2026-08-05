import 'dart:convert';

/// Shared SECSearchAPI request envelope.
class VoterSearchRequest {
  const VoterSearchRequest({required this.reqData, required this.passKey});

  final String reqData;
  final String passKey;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'ReqData': reqData,
    'PassKey': passKey,
  };
}

/// Shared SECSearchAPI response envelope (`Data` is a JSON string).
class VoterSearchEnvelope {
  const VoterSearchEnvelope({
    required this.status,
    required this.message,
    required this.data,
    this.pubKey,
  });

  factory VoterSearchEnvelope.fromJson(Map<String, dynamic> json) {
    return VoterSearchEnvelope(
      status: json['Status'] == true,
      message: (json['Message'] ?? '').toString(),
      data: _dataToString(json['Data']),
      pubKey: json['PubKey']?.toString(),
    );
  }

  /// API may return [Data] as a JSON string, or already-parsed Map/List.
  static String _dataToString(Object? data) {
    if (data == null) return '';
    if (data is String) return data;
    return jsonEncode(data);
  }

  final bool status;
  final String message;
  final String data;
  final String? pubKey;

  /// Decodes [data] JSON string into a List / Map / dynamic.
  dynamic decodeData() {
    if (data.trim().isEmpty) return null;
    return jsonDecode(data);
  }
}

class VoterDistrict {
  const VoterDistrict({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.distNo,
  });

  factory VoterDistrict.fromJson(Map<String, dynamic> json) {
    return VoterDistrict(
      id: (json['Id'] ?? '').toString(),
      name: (json['DistrictName'] ?? '').toString().trim(),
      nameEn: (json['DistrictNameEn'] ?? '').toString().trim(),
      distNo: (json['DistNo'] ?? '').toString(),
    );
  }

  final String id;
  final String name;
  final String nameEn;
  final String distNo;

  String displayName(bool preferHindi) =>
      preferHindi && name.isNotEmpty ? name : (nameEn.isNotEmpty ? nameEn : name);
}

class VoterBlock {
  const VoterBlock({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.blockNo,
  });

  factory VoterBlock.fromJson(Map<String, dynamic> json) {
    return VoterBlock(
      id: (json['Id'] ?? '').toString(),
      name: (json['BlockName'] ?? '').toString().trim(),
      nameEn: (json['BlockNameEn'] ?? '').toString().trim(),
      blockNo: (json['BlockNo'] ?? '').toString(),
    );
  }

  final String id;
  final String name;
  final String nameEn;
  final String blockNo;

  String displayName(bool preferHindi) =>
      preferHindi && name.isNotEmpty ? name : (nameEn.isNotEmpty ? nameEn : name);
}

class VoterUrbanBody {
  const VoterUrbanBody({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.ubType,
    required this.ubNo,
  });

  factory VoterUrbanBody.fromJson(Map<String, dynamic> json) {
    return VoterUrbanBody(
      id: (json['Id'] ?? '').toString(),
      name: (json['UBName'] ?? '').toString().trim(),
      nameEn: (json['UBNameEn'] ?? '').toString().trim(),
      ubType: (json['UBType'] ?? '').toString(),
      ubNo: (json['UBNo'] ?? '').toString(),
    );
  }

  final String id;
  final String name;
  final String nameEn;
  final String ubType;
  final String ubNo;

  String displayName(bool preferHindi) =>
      preferHindi && name.isNotEmpty ? name : (nameEn.isNotEmpty ? nameEn : name);
}

class VoterElector {
  const VoterElector({
    required this.id,
    required this.name,
    required this.rlnName,
    required this.rlnType,
    required this.gender,
    required this.age,
    required this.epicNo,
    required this.distNo,
    required this.houseNo,
    required this.psName,
    required this.psNo,
    required this.blockName,
    required this.panchayatName,
    required this.villName,
    required this.elecType,
    this.serNo = '',
    this.partNo = '',
    this.wardNo = '',
    this.wardName = '',
    this.ubName = '',
    this.ubTypeName = '',
  });

  factory VoterElector.fromJson(Map<String, dynamic> json) {
    final String rWard = (json['rWardNo'] ?? '').toString().trim();
    final String uWard = (json['uWardNo'] ?? '').toString().trim();
    final String uWardName = (json['uWardName'] ?? '').toString().trim();
    final String part =
        (json['uPartNo'] ?? json['secNo'] ?? '').toString().trim();
    return VoterElector(
      id: (json['ID'] ?? '').toString(),
      name: (json['name'] ?? '').toString().trim(),
      rlnName: (json['rlnName'] ?? '').toString().trim(),
      rlnType: (json['rlnType'] ?? '').toString().trim(),
      gender: (json['gender'] ?? '').toString().trim(),
      age: (json['age'] ?? '').toString().trim(),
      epicNo: (json['epicNo'] ?? '').toString().trim(),
      distNo: (json['DistNo'] ?? '').toString(),
      houseNo: (json['houseNo'] ?? '').toString().trim(),
      psName: (json['psName'] ?? '').toString().trim(),
      psNo: (json['psNo'] ?? '').toString().trim(),
      blockName: (json['blockName'] ?? '').toString().trim(),
      panchayatName: (json['panchayatName'] ?? '').toString().trim(),
      villName: (json['villName'] ?? '').toString().trim(),
      elecType: (json['ElecType'] ?? '').toString(),
      serNo: (json['serNo'] ?? '').toString().trim(),
      partNo: part,
      wardNo: uWard.isNotEmpty ? uWard : rWard,
      wardName: uWardName,
      ubName: (json['ubName'] ?? '').toString().trim(),
      ubTypeName: (json['ubTypeName'] ?? '').toString().trim(),
    );
  }

  final String id;
  final String name;
  final String rlnName;
  final String rlnType;
  final String gender;
  final String age;
  final String epicNo;
  final String distNo;
  final String houseNo;
  final String psName;
  final String psNo;
  final String blockName;
  final String panchayatName;
  final String villName;
  final String elecType;
  final String serNo;
  final String partNo;
  final String wardNo;
  final String wardName;
  final String ubName;
  final String ubTypeName;

  /// Relation label from API `rlnType`: F=father, M=mother, H=husband, W=wife, O=other.
  String get relativeLabel {
    return switch (rlnType.toUpperCase().trim()) {
      'F' => 'पिता का नाम',
      'M' => 'माता का नाम',
      'H' => 'पति का नाम',
      'W' => 'पत्नी का नाम',
      'O' => 'अन्य का नाम',
      _ => 'पिता/पति का नाम',
    };
  }

  /// Localized relation label for UI (EN/HI).
  String relativeLabelLocalized(bool preferHindi) {
    if (preferHindi) return relativeLabel;
    return switch (rlnType.toUpperCase().trim()) {
      'F' => "Father's name",
      'M' => "Mother's name",
      'H' => "Husband's name",
      'W' => "Wife's name",
      'O' => 'Other',
      _ => 'Father/Husband name',
    };
  }

  String get electionTitle {
    if (ubName.isNotEmpty) return '$ubName का निर्वाचन';
    if (ubTypeName.isNotEmpty) return '$ubTypeName का निर्वाचन';
    if (panchayatName.isNotEmpty) return '$panchayatName पंचायत का निर्वाचन';
    if (blockName.isNotEmpty) return '$blockName जनपद का निर्वाचन';
    return 'मतदाता वोटर स्लिप';
  }

  String get addressLine {
    final List<String> parts = <String>[
      if (houseNo.isNotEmpty) houseNo,
      if (villName.isNotEmpty) villName,
      if (wardName.isNotEmpty) wardName,
      if (panchayatName.isNotEmpty) panchayatName,
      if (blockName.isNotEmpty) blockName,
    ];
    return parts.join(', ');
  }

  String get boothLine {
    if (psNo.isEmpty && psName.isEmpty) return '—';
    if (psNo.isEmpty) return psName;
    if (psName.isEmpty) return psNo;
    return '$psNo - $psName';
  }

  String get wardLine {
    if (wardNo.isEmpty && wardName.isEmpty) return '—';
    if (wardName.isEmpty) return wardNo;
    if (wardNo.isEmpty) return wardName;
    return '$wardNo - $wardName';
  }

  /// Body / panchayat name for slip + result card.
  String get slipBodyName {
    if (panchayatName.isNotEmpty) return panchayatName;
    if (ubName.isNotEmpty) return ubName;
    if (villName.isNotEmpty) return villName;
    return '';
  }

  /// Compact address used on printed slip (house + body/village).
  String get slipAddressLine {
    final List<String> parts = <String>[
      if (houseNo.isNotEmpty) houseNo,
      if (panchayatName.isNotEmpty)
        panchayatName
      else if (villName.isNotEmpty)
        villName
      else if (ubName.isNotEmpty)
        ubName,
    ];
    if (parts.isEmpty) return addressLine;
    return parts.join(', ');
  }
}

/// Payload for `/api/Search/search-elector`.
class ElectorSearchQuery {
  const ElectorSearchQuery({
    required this.elecType,
    required this.distNo,
    this.ubType = '',
    this.ubNo = '',
    this.blockNo = '',
    this.panchayatNo = '',
    this.elecName = '',
    this.relName = '',
    this.age = '',
    this.gender = '',
    this.epicNo = '',
  });

  final String elecType;
  final String distNo;
  final String ubType;
  final String ubNo;
  final String blockNo;
  final String panchayatNo;
  final String elecName;
  final String relName;
  final String age;
  final String gender;
  final String epicNo;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'elecType': elecType,
    'distNo': distNo,
    'ubType': ubType,
    'ubNo': ubNo,
    'blockNo': blockNo,
    'panchayatNo': panchayatNo,
    'elecName': elecName,
    'relName': relName,
    'age': age,
    'gender': gender,
    if (epicNo.isNotEmpty) 'epicNo': epicNo,
  };
}
