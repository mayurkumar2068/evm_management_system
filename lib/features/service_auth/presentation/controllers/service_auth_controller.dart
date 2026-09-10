import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/cache/app_startup_cache.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/core/network/dio_factory.dart';
import 'package:evm_management_system/core/network/po_election_api_client.dart';
import 'package:evm_management_system/core/security/token_vault.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/features/presiding_concern/data/constants/po_election_api_fields.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_party_remote_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:evm_management_system/features/presiding_concern/di/presiding_concern_module.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:get/get.dart' hide Trans, Response;
import 'package:evm_management_system/core/utils/json_map.dart';

class ServiceAuthException implements Exception {
  const ServiceAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ServiceAuthController extends GetxController {
  final Rxn<ServiceSession> session = Rxn<ServiceSession>();

  Dio? _surveyDio;

  bool get isLoggedIn {
    final ServiceSession? current = session.value;
    return current != null;
  }

  @override
  void onInit() {
    super.onInit();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final String? raw =
        await AppServices.secureStorage.read(
          SecureStorageKeys.serviceSession,
        ) ??
        await AppServices.secureStorage.read(SecureStorageKeys.userSession);
    if (raw != null) {
      try {
        final Map<String, dynamic> json =
            jsonDecode(raw) as Map<String, dynamic>;

        if (json['token'] is! String || (json['token'] as String).isEmpty) {
          return;
        }
        final ServiceSession restored = ServiceSession.fromJson(json);
        session.value = restored;
        await _persistPoAccessToken(
          accessToken: restored.token,
          ttlHours: restored.ttlHours ?? 24,
        );

        await AppServices.secureStorage.write(
          SecureStorageKeys.serviceSession,
          jsonEncode(restored.toJson()),
        );
        PresidingConcernModule.resetClients();
        if (restored.kind == ServiceLoginKind.presiding) {
          PresidingElectionContextStore.warmFromServiceSession(restored);
          unawaited(
            PresidingElectionContextStore(AppServices.secureStorage).read(),
          );
        }
      } catch (_) {}
    }
  }

  Dio _surveyDioClient() {
    final EnvironmentConfig config = AppServices.config;
    return _surveyDio ??= DioFactory.create(
      config: config,
      baseUrl: config.surveyApiBaseUrl,
    );
  }

  Dio _poElectionDio() => PoElectionApiClient.instance(AppServices.config);

  Future<ServiceSession> signInPresidingOfficer({
    required String userId,
    required String password,
  }) async {
    AppLogger.w('[PO API] login-po-pass starting userId=$userId');
    final Response<dynamic> res;

    try {
      res = await _poElectionDio().post<dynamic>(
        PoElectionEndpoints.loginPoPass,
        data: <String, dynamic>{
          'userName': userId.trim(),
          'password': password,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          extra: <String, dynamic>{'skipAuth': true},
        ),
      );
    } on DioException catch (e) {
      AppLogger.w(
        '[PO API] login-po-pass DioException http=${e.response?.statusCode} '
        'type=${e.type.name} msg=${e.message}',
      );
      throw ServiceAuthException(_networkOrServerMessage(e));
    }

    final dynamic body = res.data;
    if (res.statusCode != 200 ||
        body == null ||
        body[PoLoginResponseFields.status] != true) {
      final String message =
          (body?[PoLoginResponseFields.message] as String?) ??
          LocaleKeys.authPoInvalidCredentials;
      throw ServiceAuthException(message);
    }

    final Map<String, dynamic> data =
        (body[PoLoginResponseFields.data] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    int ttlHours = 24;
    try {
      final Object? expiration = data[PoLoginResponseFields.expiration];
      if (expiration != null) {
        final DateTime expiry = DateTime.parse(expiration.toString());
        ttlHours = expiry.difference(DateTime.now()).inHours;
      }
    } catch (_) {}

    final double? lat = parseOptionalDouble(
      data[PoLoginResponseFields.lat] ?? data['lat'],
    );
    final double? long = parseOptionalDouble(
      data[PoLoginResponseFields.long] ?? data['long'],
    );

    final String urbanRural =
        data[PoLoginResponseFields.urbanRural]?.toString().trim() ?? '';
    final String? bodyName = _firstNonEmptyString(<Object?>[
      data[PoLoginResponseFields.ubName],
      data[PoLoginResponseFields.blockName],
      data[PoLoginResponseFields.gpName],
    ]);

    final int? maleElectors = parseOptionalInt(
      mapValueByKeys(data, <String>[
        PoLoginResponseFields.maleElectors,
        'maleElectors',
        'male_electors',
      ]),
    );
    final int? femaleElectors = parseOptionalInt(
      mapValueByKeys(data, <String>[
        PoLoginResponseFields.femaleElectors,
        'femaleElectors',
        'female_electors',
      ]),
    );
    final int? otherElectors = parseOptionalInt(
      mapValueByKeys(data, <String>[
        PoLoginResponseFields.otherElectors,
        'otherElectors',
        'other_electors',
      ]),
    );
    final int? totalElectors = parseOptionalInt(
      mapValueByKeys(data, <String>[
        PoLoginResponseFields.totalElectors,
        'totalElectors',
        'total_electors',
      ]),
    );

    final bool isIpbms = _parseBool(
      mapValueByKeys(data, <String>[PoLoginResponseFields.isIpbms, 'isIPBMS']),
    );
    final bool isLivePoll = _parseBool(
      mapValueByKeys(data, <String>[
        PoLoginResponseFields.isLivePoll,
        'isLivePoll',
      ]),
    );

    final ServiceSession next = ServiceSession(
      token: data[PoLoginResponseFields.accessToken].toString(),
      userId: data[PoLoginResponseFields.userId].toString(),
      name: data[PoLoginResponseFields.userName].toString(),
      kind: ServiceLoginKind.presiding,
      section: urbanRural.isEmpty ? null : urbanRural,
      districtName: data[PoLoginResponseFields.distName]?.toString(),
      bodyName: bodyName,
      ttlHours: ttlHours,
      lat: lat,
      long: long,
      createdAt: DateTime.now(),
      maleElectors: maleElectors,
      femaleElectors: femaleElectors,
      otherElectors: otherElectors,
      totalElectors: totalElectors,
    );

    await _logoutStaleSessionIfSwitching(next.token);
    await _persistPoAccessToken(
      accessToken: next.token,
      ttlHours: ttlHours,
      expiration: data[PoLoginResponseFields.expiration]?.toString(),
    );

    final PresidingElectionContext context = PresidingElectionContext(
      electionId:
          int.tryParse(
            data[PoLoginResponseFields.electionId]?.toString() ?? '0',
          ) ??
          0,
      psId: data[PoLoginResponseFields.psId]?.toString() ?? '',
      userId: data[PoLoginResponseFields.userId]?.toString(),
      loginUserName: data[PoLoginResponseFields.userName]?.toString(),
      areaType: PresidingElectionContext.normalizeAreaType(
        data[PoLoginResponseFields.urbanRural]?.toString(),
      ),
      pollingStationCode: data[PoLoginResponseFields.psNo]?.toString(),
      pollingStationName: data[PoLoginResponseFields.psName]?.toString(),
      boothLat: lat,
      boothLong: long,
      maleElectors: maleElectors,
      femaleElectors: femaleElectors,
      otherElectors: otherElectors,
      totalElectors: totalElectors,
      isIpbms: isIpbms,
      isLivePoll: isLivePoll,
    );

    final PresidingElectionContextStore store = PresidingElectionContextStore(
      AppServices.secureStorage,
    );
    final PresidingElectionContext? previous = await store.read();
    await store.save(context);

    await _saveSession(next);
    PresidingElectionContextStore.warmFromServiceSession(next);

    final bool identityChanged =
        previous == null ||
        previous.electionId != context.electionId ||
        previous.psId != context.psId;
    if (identityChanged) {
      await PresidingConcernModule.clearLocalCache();
    } else {
      PresidingConcernModule.resetClients();
    }
    try {
      await PresidingConcernModule.repository.applyElectionContext(context);
    } catch (_) {}

    return next;
  }

  Future<ServiceSession> signInSurveyUser({
    required String userName,
    required String password,
  }) async {
    final Response<dynamic> res;
    try {
      res = await _surveyDioClient().post<dynamic>(
        ApiEndpoints.surveyLoginPass,
        data: <String, dynamic>{
          'userName': userName.trim(),
          'password': password,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          extra: <String, dynamic>{'skipAuth': true},
        ),
      );
    } on DioException catch (e) {
      throw ServiceAuthException(_networkOrServerMessage(e));
    }

    final dynamic body = res.data;
    final Map<String, dynamic> envelope = body is Map<String, dynamic>
        ? body
        : <String, dynamic>{};
    final Map<String, dynamic> data =
        (envelope['Data'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final bool ok = envelope['Status'] == true;
    final String? token = data['AccessToken']?.toString();

    if (res.statusCode != 200 || !ok || token == null || token.isEmpty) {
      final String message =
          (envelope['Message'] as String?) ??
          LocaleKeys.authDistrictInvalidCredentials;
      throw ServiceAuthException(message);
    }

    return _buildSurveySession(
      data: data,
      token: token,
      fallbackName: userName,
    );
  }

  Future<String> registerPsUser({
    required String mobileNo,
    required String name,
    required String designation,
  }) async {
    final Response<dynamic> res;
    try {
      res = await _surveyDioClient().post<dynamic>(
        ApiEndpoints.surveyRegisterPsUser,
        data: <String, dynamic>{
          'mobileNo': mobileNo.trim(),
          'name': name.trim(),
          'designation': designation.trim(),
        },
        options: Options(
          contentType: Headers.jsonContentType,
          extra: <String, dynamic>{'skipAuth': true},
        ),
      );
    } on DioException catch (e) {
      throw ServiceAuthException(_networkOrServerMessage(e));
    }
    return _requireRegistrationSuccess(res);
  }

  Future<String> registerPoUser({
    required String userName,
    required String password,
  }) async {
    final Response<dynamic> res;
    try {
      res = await _poElectionDio().post<dynamic>(
        PoElectionEndpoints.registerPoUser,
        data: <String, dynamic>{
          'userName': userName.trim(),
          'password': password,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          extra: <String, dynamic>{'skipAuth': true},
        ),
      );
    } on DioException catch (e) {
      throw ServiceAuthException(_networkOrServerMessage(e));
    }
    return _requireRegistrationSuccess(res);
  }

  String _requireRegistrationSuccess(Response<dynamic> res) {
    final dynamic body = res.data;
    final Map<String, dynamic> envelope = body is Map<String, dynamic>
        ? body
        : <String, dynamic>{};
    final bool ok = envelope['Status'] == true;
    final String message = (envelope['Message'] as String?)?.trim() ?? '';

    if (res.statusCode != 200 || !ok) {
      throw ServiceAuthException(
        message.isNotEmpty ? message : LocaleKeys.serviceAuthGenericError,
      );
    }
    return message.isNotEmpty ? message : LocaleKeys.serviceAuthRegisterSuccess;
  }

  Future<void> sendSurveyLoginOtp({required String mobileNo}) async {
    final Response<dynamic> res;
    try {
      res = await _surveyDioClient().post<dynamic>(
        ApiEndpoints.surveyIsPsUserExistsOtp,
        data: <String, dynamic>{'mobileNo': mobileNo.trim()},
        options: Options(
          contentType: Headers.jsonContentType,
          extra: <String, dynamic>{'skipAuth': true},
        ),
      );
    } on DioException catch (e) {
      throw ServiceAuthException(_networkOrServerMessage(e));
    }

    final dynamic body = res.data;
    final Map<String, dynamic> envelope = body is Map<String, dynamic>
        ? body
        : <String, dynamic>{};
    final bool ok = envelope['Status'] == true;

    if (res.statusCode != 200 || !ok) {
      final String message =
          (envelope['Message'] as String?) ?? LocaleKeys.authOtpSendFailed;
      throw ServiceAuthException(message);
    }
  }

  Future<ServiceSession> signInSurveyUserWithOtp({
    required String mobileNo,
    required String otp,
  }) async {
    final Response<dynamic> res;
    try {
      res = await _surveyDioClient().post<dynamic>(
        ApiEndpoints.surveyPsLoginWithOtp,
        data: <String, dynamic>{'mobileNo': mobileNo.trim(), 'otp': otp.trim()},
        options: Options(
          contentType: Headers.jsonContentType,
          extra: <String, dynamic>{'skipAuth': true},
        ),
      );
    } on DioException catch (e) {
      throw ServiceAuthException(_networkOrServerMessage(e));
    }

    final dynamic body = res.data;
    final Map<String, dynamic> envelope = body is Map<String, dynamic>
        ? body
        : <String, dynamic>{};
    final Map<String, dynamic> data =
        (envelope['Data'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final bool ok = envelope['Status'] == true;
    final String? token = data['AccessToken']?.toString();

    if (res.statusCode != 200 || !ok || token == null || token.isEmpty) {
      final String message =
          (envelope['Message'] as String?) ?? LocaleKeys.authOtpInvalid;
      throw ServiceAuthException(message);
    }

    return _buildSurveySession(
      data: data,
      token: token,
      fallbackName: mobileNo,
    );
  }

  Future<void> _logoutStaleSessionIfSwitching(String newToken) async {
    final ServiceSession? existing = session.value;
    if (existing == null ||
        existing.token == newToken ||
        existing.userId.trim().isEmpty) {
      return;
    }
    try {
      await PoPartyRemoteDatasource(AppServices.config).logout(
        poUserId: existing.userId,
        sessionId: null,
        isSurveyUser: existing.kind == ServiceLoginKind.survey,
      );
    } catch (e) {
      AppLogger.w('[ServiceAuth] stale session logout failed: $e');
    }
  }

  Future<ServiceSession> _buildSurveySession({
    required Map<String, dynamic> data,
    required String token,
    required String fallbackName,
  }) async {
    await _logoutStaleSessionIfSwitching(token);
    int? ttlHours;
    final String? expirationIso = data['Expiration']?.toString();
    if (expirationIso != null && expirationIso.isNotEmpty) {
      final DateTime? expiry = DateTime.tryParse(expirationIso);
      if (expiry != null) {
        ttlHours = expiry.difference(DateTime.now()).inHours;
      }
    }

    final String? districtId = data['DistID']?.toString();
    final String? bodyId = data['BodyID']?.toString();
    final double? lat = parseOptionalDouble(data['Lat'] ?? data['lat']);
    final double? long = parseOptionalDouble(data['Long'] ?? data['long']);
    final String? districtName = await _resolveDistrictName(
      districtId: districtId,
      accessToken: token,
      fallback: data['DistName']?.toString(),
    );
    final String? bodyName =
        data['UBName']?.toString() ?? data['BlockName']?.toString();

    final ServiceSession next = ServiceSession(
      token: token,
      userId: (data['UserId'] ?? '').toString(),
      name: (data['Name'] ?? data['UserName'] ?? fallbackName).toString(),
      kind: ServiceLoginKind.survey,
      section: data['UrbanRural']?.toString(),
      ttlHours: ttlHours,
      districtId: districtId,
      districtName: districtName,
      bodyId: bodyId,
      bodyName: bodyName,
      lat: lat,
      long: long,
      createdAt: DateTime.now(),
    );

    await _saveSession(next);
    return next;
  }

  Future<String?> _resolveDistrictName({
    required String? districtId,
    required String accessToken,
    String? fallback,
  }) async {
    if (districtId == null || districtId.isEmpty) {
      return fallback;
    }
    try {
      final Response<dynamic> res = await _surveyDioClient().get<dynamic>(
        ApiEndpoints.surveyDistrictById(districtId),
        options: Options(
          headers: <String, dynamic>{'Authorization': 'Bearer $accessToken'},
        ),
      );
      final dynamic body = res.data;
      final Map<String, dynamic> envelope = body is Map<String, dynamic>
          ? body
          : <String, dynamic>{};
      final List<dynamic> rows = envelope['Data'] is List
          ? envelope['Data'] as List<dynamic>
          : const <dynamic>[];
      final Map<String, dynamic>? first = rows.isNotEmpty && rows.first is Map
          ? (rows.first as Map).cast<String, dynamic>()
          : null;
      return first?['DistName']?.toString() ??
          first?['DistNameEn']?.toString() ??
          fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _persistPoAccessToken({
    required String accessToken,
    required int ttlHours,
    String? expiration,
  }) async {
    DateTime expiresAt = DateTime.now().add(Duration(hours: ttlHours));
    if (expiration != null) {
      final DateTime? parsed = DateTime.tryParse(expiration);
      if (parsed != null) expiresAt = parsed;
    }
    await AppServices.tokenVault.save(
      AuthTokens(
        accessToken: accessToken,
        refreshToken: accessToken,
        expiresAt: expiresAt,
      ),
    );
  }

  Future<void> _saveSession(ServiceSession s) async {
    session.value = s;
    await AppServices.secureStorage.write(
      SecureStorageKeys.serviceSession,
      jsonEncode(s.toJson()),
    );
  }

  bool _parseBool(Object? value) {
    if (value is bool) return value;
    if (value == null) return false;
    return value.toString().trim().toLowerCase() == 'true';
  }

  String? _firstNonEmptyString(List<Object?> values) {
    for (final Object? value in values) {
      final String trimmed = value?.toString().trim() ?? '';
      if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'null') {
        return trimmed;
      }
    }
    return null;
  }

  String _networkOrServerMessage(DioException e) {
    final dynamic data = e.response?.data;
    if (data is Map) {
      final Object? message = data['Message'] ?? data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    final int? code = e.response?.statusCode;
    if (code != null && code >= 500) {
      return LocaleKeys.errorServer;
    }
    return LocaleKeys.errorNetwork;
  }

  Future<bool> signOut() async {
    bool remoteOk = false;
    final ServiceSession? current = session.value;
    if (current != null && current.userId.trim().isNotEmpty) {
      remoteOk = await PoPartyRemoteDatasource(AppServices.config).logout(
        poUserId: current.userId,
        sessionId: null,
        isSurveyUser: current.kind == ServiceLoginKind.survey,
      );
    }

    session.value = null;
    _surveyDio = null;
    PoElectionApiClient.reset();
    await AppServices.tokenVault.clear();
    await AppServices.secureStorage.delete(SecureStorageKeys.serviceSession);

    await AppServices.secureStorage.delete(SecureStorageKeys.userSession);
    final PresidingElectionContextStore store = PresidingElectionContextStore(
      AppServices.secureStorage,
    );

    await store.clear();
    await PresidingConcernModule.clearLocalCache();
    await AppStartupCache.clearDisposableCaches();
    return remoteOk;
  }
}
