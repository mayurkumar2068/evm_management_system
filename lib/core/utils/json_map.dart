/// Shared JSON / scalar coercion for API payloads.
Map<String, dynamic>? asStringKeyedMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (Object? k, Object? v) => MapEntry(k.toString(), v),
    );
  }
  return null;
}

int? parseOptionalInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}
