/// DTOs for OLINAPI urban master lookups (`/Master/*`).
library;

import 'package:evm_management_system/core/utils/json_map.dart';

String _asString(Object? value) {
  if (value == null) return '';
  return value.toString().trim();
}

T? _pick<T>(Map<String, dynamic> json, List<String> keys, T? Function(Object?) cast) {
  for (final String key in keys) {
    if (!json.containsKey(key) || json[key] == null) continue;
    final T? parsed = cast(json[key]);
    if (parsed != null) return parsed;
  }
  return null;
}

class ElectionUrbanDto {
  const ElectionUrbanDto({required this.electionId, required this.ename});

  factory ElectionUrbanDto.fromJson(Map<String, dynamic> json) {
    final int id =
        _pick<int>(json, <String>['election_Id', 'election_id', 'Election_Id'], parseOptionalInt) ??
        0;
    final String name =
        _pick<String>(json, <String>['ename', 'Ename', 'eName'], (Object? v) {
          final String s = _asString(v);
          return s.isEmpty ? null : s;
        }) ??
        '';
    return ElectionUrbanDto(electionId: id, ename: name);
  }

  final int electionId;
  final String ename;
}

class PostUrbanDto {
  const PostUrbanDto({required this.postId, required this.postName});

  factory PostUrbanDto.fromJson(Map<String, dynamic> json) {
    final int id =
        _pick<int>(json, <String>['postID', 'postId', 'PostID'], parseOptionalInt) ?? 0;
    final String name =
        _pick<String>(json, <String>['postName', 'PostName'], (Object? v) {
          final String s = _asString(v);
          return s.isEmpty ? null : s;
        }) ??
        '';
    return PostUrbanDto(postId: id, postName: name);
  }

  final int postId;
  final String postName;
}

class DistrictUrbanDto {
  const DistrictUrbanDto({required this.dstId, required this.dstName});

  factory DistrictUrbanDto.fromJson(Map<String, dynamic> json) {
    final String id =
        _pick<String>(json, <String>['dstID', 'dstId', 'DstID'], (Object? v) {
          final String s = _asString(v);
          return s.isEmpty ? null : s;
        }) ??
        '';
    final String name =
        _pick<String>(json, <String>['dstName', 'DstName'], (Object? v) {
          final String s = _asString(v);
          return s.isEmpty ? null : s;
        }) ??
        '';
    return DistrictUrbanDto(dstId: id, dstName: name);
  }

  final String dstId;
  final String dstName;
}

class UrbanBodyDto {
  const UrbanBodyDto({
    required this.ubId,
    required this.typeId,
    required this.ubName,
  });

  factory UrbanBodyDto.fromJson(Map<String, dynamic> json) {
    // OLINAPI returns `ubid` (all lowercase); also accept common casings.
    final String id =
        _pick<String>(json, <String>['ubid', 'ubID', 'ubId', 'UBID'], (
          Object? v,
        ) {
          final String s = _asString(v);
          return s.isEmpty ? null : s;
        }) ??
        '';
    final int typeId =
        _pick<int>(json, <String>['typeID', 'typeId', 'TypeID'], parseOptionalInt) ?? 0;
    final String name =
        _pick<String>(json, <String>['ubName', 'UBName', 'ubname'], (
          Object? v,
        ) {
          final String s = _asString(v);
          return s.isEmpty ? null : s;
        }) ??
        '';
    return UrbanBodyDto(ubId: id, typeId: typeId, ubName: name);
  }

  final String ubId;
  final int typeId;
  final String ubName;
}

class UrbanWardDto {
  const UrbanWardDto({required this.wardId, required this.wardNo});

  factory UrbanWardDto.fromJson(Map<String, dynamic> json) {
    final String id =
        _pick<String>(json, <String>['wardID', 'wardId', 'WardID'], (Object? v) {
          final String s = _asString(v);
          return s.isEmpty ? null : s;
        }) ??
        '';
    final int wardNo =
        _pick<int>(json, <String>['wardNO', 'wardNo', 'WardNO'], parseOptionalInt) ?? 0;
    return UrbanWardDto(wardId: id, wardNo: wardNo);
  }

  final String wardId;
  final int wardNo;
}

/// POST `/Master/Insert_Urban_Reg` body.
class UrbanRegistrationRequest {
  const UrbanRegistrationRequest({
    required this.eid,
    required this.dstID,
    required this.ubid,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.postID,
    required this.status,
    this.wardID,
  });

  final int eid;
  final String dstID;
  final String ubid;
  final String name;
  final String email;
  final String mobileNumber;
  final int postID;
  final int status;

  /// Required for postId == 3; null for postId 1/2.
  final String? wardID;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'eid': eid,
      'dstID': dstID,
      'ubid': ubid,
      'name': name,
      'email': email,
      'mobileNumber': mobileNumber,
      'postID': postID,
      'status': status,
    };
    final String? ward = wardID?.trim();
    // post 3 → send wardID; post 1/2 → explicit null (backend accepts null).
    json['wardID'] = (ward != null && ward.isNotEmpty) ? ward : null;
    return json;
  }
}

/// Response from `/Master/Insert_Urban_Reg`.
class UrbanRegistrationResponse {
  const UrbanRegistrationResponse({
    required this.regID,
    required this.userId,
    required this.password,
  });

  factory UrbanRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return UrbanRegistrationResponse(
      regID: _pick<String>(json, <String>['regID', 'regId', 'RegID'], (Object? v) {
            final String s = _asString(v);
            return s.isEmpty ? null : s;
          }) ??
          '',
      userId:
          _pick<String>(json, <String>['userId', 'UserId', 'userid'], (Object? v) {
                final String s = _asString(v);
                return s.isEmpty ? null : s;
              }) ??
              '',
      password:
          _pick<String>(json, <String>['password', 'Password'], (Object? v) {
                final String s = _asString(v);
                return s.isEmpty ? null : s;
              }) ??
              '',
    );
  }

  final String regID;
  final String userId;
  final String password;
}
