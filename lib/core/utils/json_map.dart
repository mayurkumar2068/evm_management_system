Map<String, dynamic>? asStringKeyedMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((Object? k, Object? v) => MapEntry(k.toString(), v));
  }
  return null;
}

int? parseOptionalInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

double? parseOptionalDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim());
}

Object? mapValueByKeys(Map<String, dynamic> data, List<String> keys) {
  for (final String key in keys) {
    if (data.containsKey(key) && data[key] != null) return data[key];
  }
  for (final MapEntry<String, dynamic> entry in data.entries) {
    final String lower = entry.key.toLowerCase();
    for (final String key in keys) {
      if (lower == key.toLowerCase() && entry.value != null) {
        return entry.value;
      }
    }
  }
  return null;
}

bool? parseLooseBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  final String s = value.toString().trim().toLowerCase();
  if (s == 'true' || s == '1' || s == 'yes') return true;
  if (s == 'false' || s == '0' || s == 'no') return false;
  return null;
}

bool parseLooseBoolOr(Object? value, {bool defaultValue = false}) {
  return parseLooseBool(value) ?? defaultValue;
}

String? trimmedOrNull(Object? value) {
  final String trimmed = value?.toString().trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

String coercedString(Object? value, {String fallback = ''}) {
  return trimmedOrNull(value) ?? fallback;
}
