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

  if (parsed.path.endsWith('/SECSearchEngine')) {
    return parsed.replace(path: '${parsed.path}/').toString();
  }

  return parsed.toString();
}

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

String appendWebViewToken(String url, {required String token}) {
  final String clean = token.trim();
  if (clean.isEmpty) return normalizeWebViewLaunchUrl(url);
  return appendWebViewQueryParam(url, key: 'token', value: clean);
}

String appendWebViewSurveyContext(
  String url, {
  required String token,
  String? userId,
  String? districtId,
  String? distName,
  String? bodyId,
  String? bodyName,
  String? urbanRural,
  double? boothLat,
  double? boothLong,
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
  final String cleanDistName = distName?.trim() ?? '';
  if (cleanDistName.isNotEmpty) {
    result = appendWebViewQueryParam(
      result,
      key: 'distName',
      value: cleanDistName,
    );
  }
  final String cleanBodyId = bodyId?.trim() ?? '';
  if (cleanBodyId.isNotEmpty) {
    result = appendWebViewQueryParam(result, key: 'bodyId', value: cleanBodyId);
  }
  final String cleanBodyName = bodyName?.trim() ?? '';
  if (cleanBodyName.isNotEmpty) {
    result = appendWebViewQueryParam(
      result,
      key: 'bodyName',
      value: cleanBodyName,
    );
  }
  final String cleanUrbanRural = urbanRural?.trim() ?? '';
  if (cleanUrbanRural.isNotEmpty) {
    result = appendWebViewQueryParam(
      result,
      key: 'urbanRural',
      value: cleanUrbanRural,
    );
  }
  if (boothLat != null && boothLat != 0) {
    result = appendWebViewQueryParam(
      result,
      key: 'boothLat',
      value: boothLat.toString(),
    );
  }
  if (boothLong != null && boothLong != 0) {
    result = appendWebViewQueryParam(
      result,
      key: 'boothLong',
      value: boothLong.toString(),
    );
  }
  return result;
}

String appendWebViewCacheBust(String url) {
  return appendWebViewQueryParam(
    url,
    key: 'v',
    value: DateTime.now().millisecondsSinceEpoch.toString(),
  );
}
