/// DTOs for OLINAPI urban master lookups (`/Master/*`).
library;

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

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
        _pick<int>(json, <String>['election_Id', 'election_id', 'Election_Id'], _asInt) ??
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
        _pick<int>(json, <String>['postID', 'postId', 'PostID'], _asInt) ?? 0;
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
    final String id =
        _pick<String>(json, <String>['ubID', 'ubId', 'UBID'], (Object? v) {
          final String s = _asString(v);
          return s.isEmpty ? null : s;
        }) ??
        '';
    final int typeId =
        _pick<int>(json, <String>['typeID', 'typeId', 'TypeID'], _asInt) ?? 0;
    final String name =
        _pick<String>(json, <String>['ubName', 'UBName'], (Object? v) {
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
        _pick<int>(json, <String>['wardNO', 'wardNo', 'WardNO'], _asInt) ?? 0;
    return UrbanWardDto(wardId: id, wardNo: wardNo);
  }

  final String wardId;
  final int wardNo;
}
