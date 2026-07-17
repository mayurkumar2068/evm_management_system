/// Normalizes launch URLs so the WebView performs a single navigation.
///
/// iOS `WKWebView` and many dev servers rewrite `http://host?x=1` to
/// `http://host/?x=1`, which looks like a second load in logs.
String normalizeWebViewLaunchUrl(String rawUrl) {
  final String trimmed = rawUrl.trim();
  final Uri? parsed = Uri.tryParse(trimmed);
  if (parsed == null || !parsed.hasScheme) {
    return trimmed;
  }

  if (parsed.scheme != 'http' && parsed.scheme != 'https') {
    return parsed.toString();
  }

  if (parsed.path.isEmpty) {
    return parsed.replace(path: '/').toString();
  }

  return parsed.toString();
}

/// Appends or updates a query parameter in a WebView launch URL.
String appendWebViewQueryParam(
  String url, {
  required String key,
  required String value,
}) {
  final Uri uri = Uri.parse(normalizeWebViewLaunchUrl(url));
  final Map<String, String> params = Map<String, String>.from(
    uri.queryParameters,
  )..[key] = value;
  return uri.replace(queryParameters: params).toString();
}

/// Appends the service-auth token so web pages can restore session context.
String appendWebViewToken(String url, {required String token}) {
  final String clean = token.trim();
  if (clean.isEmpty) return normalizeWebViewLaunchUrl(url);
  return appendWebViewQueryParam(url, key: 'token', value: clean);
}

/// Forwards survey session context (token, user, district, area type) to Angular.
String appendWebViewSurveyContext(
  String url, {
  required String token,
  String? userId,
  String? districtId,
  String? bodyId,
  String? urbanRural,
}) {
  var result = appendWebViewToken(url, token: token);
  final String cleanUserId = userId?.trim() ?? '';
  if (cleanUserId.isNotEmpty) {
    result = appendWebViewQueryParam(result, key: 'userId', value: cleanUserId);
  }
  final String cleanDistrictId = districtId?.trim() ?? '';
  if (cleanDistrictId.isNotEmpty) {
    result = appendWebViewQueryParam(
      result,
      key: 'districtId',
      value: cleanDistrictId,
    );
  }
  final String cleanBodyId = bodyId?.trim() ?? '';
  if (cleanBodyId.isNotEmpty) {
    result = appendWebViewQueryParam(result, key: 'bodyId', value: cleanBodyId);
  }
  final String cleanUrbanRural = urbanRural?.trim() ?? '';
  if (cleanUrbanRural.isNotEmpty) {
    result = appendWebViewQueryParam(
      result,
      key: 'urbanRural',
      value: cleanUrbanRural,
    );
  }
  return result;
}
