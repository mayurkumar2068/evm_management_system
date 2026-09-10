import 'dart:convert';

enum WebThemeMode { light, dark, system }

class WebSessionContext {
  const WebSessionContext({
    this.accessToken,
    this.refreshToken,
    required this.language,
    required this.theme,
    required this.deviceId,
    this.officerId,
    this.districtId,
    this.distName,
    this.bodyId,
    this.bodyName,
    this.urbanRural,
    this.boothLat,
    this.boothLong,
    this.apiBaseUrl,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.environment,
    required this.timezone,
    required this.correlationId,
  });

  final String? accessToken;
  final String? refreshToken;
  final String language;
  final WebThemeMode theme;
  final String deviceId;
  final String? officerId;
  final String? districtId;
  final String? distName;
  final String? bodyId;
  final String? bodyName;
  final String? urbanRural;
  final double? boothLat;
  final double? boothLong;

  final String? apiBaseUrl;
  final String appVersion;
  final String buildNumber;
  final String platform;
  final String environment;
  final String timezone;
  final String correlationId;

  String get themeName => switch (theme) {
    WebThemeMode.light => 'light',
    WebThemeMode.dark => 'dark',
    WebThemeMode.system => 'system',
  };

  Map<String, String> toHeaders() {
    return <String, String>{
      if (accessToken != null && accessToken!.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
      'Accept-Language': language,
      'X-Platform': platform,
      'X-App-Version': appVersion,
      'X-Build-Number': buildNumber,
      'X-Device-Id': deviceId,
      if (officerId != null) 'X-Officer-Id': officerId!,
      if (districtId != null) 'X-District-Id': districtId!,
      'X-Timezone': timezone,
      'X-Environment': environment,
      'X-Request-Id': correlationId,
      'X-Correlation-Id': correlationId,
    };
  }

  Map<String, dynamic> toJsContext() {
    return <String, dynamic>{
      'language': language,
      'theme': themeName,
      'deviceId': deviceId,
      'officerId': officerId,
      'districtId': districtId,
      'distName': distName,
      'bodyId': bodyId,
      'bodyName': bodyName,
      'urbanRural': urbanRural,
      if (boothLat != null) 'boothLat': boothLat,
      if (boothLong != null) 'boothLong': boothLong,
      if (apiBaseUrl != null && apiBaseUrl!.isNotEmpty)
        'apiBaseUrl': apiBaseUrl,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'platform': platform,
      'environment': environment,
      'timezone': timezone,
      'correlationId': correlationId,
    };
  }

  String toJsContextJson() => jsonEncode(toJsContext());

  WebSessionContext copyWith({String? language, WebThemeMode? theme}) {
    return WebSessionContext(
      accessToken: accessToken,
      refreshToken: refreshToken,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      deviceId: deviceId,
      officerId: officerId,
      districtId: districtId,
      distName: distName,
      bodyId: bodyId,
      bodyName: bodyName,
      urbanRural: urbanRural,
      boothLat: boothLat,
      boothLong: boothLong,
      apiBaseUrl: apiBaseUrl,
      appVersion: appVersion,
      buildNumber: buildNumber,
      platform: platform,
      environment: environment,
      timezone: timezone,
      correlationId: correlationId,
    );
  }
}
