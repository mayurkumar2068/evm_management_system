abstract final class ApiEnvelope {
  static Map<String, dynamic>? unwrap(Object? body) {
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    final ok = map['Status'] == true || map['Success'] == true;
    if (!ok) return null;
    final data = map['Data'] ?? map['data'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  static bool isSuccess(Object? body) {
    if (body is! Map) return false;
    return body['Status'] == true || body['Success'] == true;
  }

  static String? message(Object? body) {
    if (body is! Map) return null;
    return (body['Message'] ?? body['message'])?.toString();
  }
}
