/// Shared JSON map coercion for API envelopes.
Map<String, dynamic>? asStringKeyedMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map(
      (Object? k, Object? v) => MapEntry(k.toString(), v),
    );
  }
  return null;
}
