class PoApiException implements Exception {
  const PoApiException(this.message, {this.statusCode, this.offline = false});

  final String message;
  final int? statusCode;
  final bool offline;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isOffline => offline;

  bool get isInvalidOtp {
    final String n = message.toLowerCase();
    return n.contains('otp') || n.contains('ओटीपी') || n.contains('expire');
  }

  @override
  String toString() => message;
}
