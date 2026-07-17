import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/core/network/dio_factory.dart';
import 'package:evm_management_system/core/network/po_election_api_client.dart';
import 'package:evm_management_system/core/security/token_vault.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/features/presiding_concern/data/constants/po_election_api_fields.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/presiding_election_context_store.dart';
import 'package:evm_management_system/features/presiding_concern/di/presiding_concern_module.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_election_context.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:get/get.dart' hide Trans, Response;

/// Thrown when a service login fails; carries a user-facing message.
class ServiceAuthException implements Exception {
  const ServiceAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Holds the current service session (token) in memory and persists it to secure storage.
class ServiceAuthController extends GetxController {
  final Rxn<ServiceSession> session = Rxn<ServiceSession>();

  Dio? _surveyDio;

  bool get isLoggedIn {
    final ServiceSession? current = session.value;
    if (current == null) return false;
    if (current.isExpired) {
      signOut();
      return false;
    }
    return true;
  }

  @override
  void onInit() {
    super.onInit();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final String? raw = await AppServices.secureStorage.read(
      SecureStorageKeys.userSession,
    );
    if (raw != null) {
      try {
        final ServiceSession restored = ServiceSession.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (!restored.isExpired) {
          session.value = restored;
          await _persistPoAccessToken(
            accessToken: restored.token,
            ttlHours: restored.ttlHours ?? 24,
          );
          PresidingConcernModule.resetClients();
        } else {
          await signOut();
        }
      } catch (_) {
        await signOut();
      }
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

  /// Logs in a Presiding Officer using the specialized PO Election API.
  Future<ServiceSession> signInPresidingOfficer({
    required String userId,
    required String password,
  }) async {
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
    } on DioException {
      throw const ServiceAuthException(LocaleKeys.errorNetwork);
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

    final double? lat = _parseCoord(
      data[PoLoginResponseFields.lat] ?? data['lat'],
    );
    final double? long = _parseCoord(
      data[PoLoginResponseFields.long] ?? data['long'],
    );

    final ServiceSession next = ServiceSession(
      token: data[PoLoginResponseFields.accessToken].toString(),
      userId: data[PoLoginResponseFields.userId].toString(),
      name: data[PoLoginResponseFields.userName].toString(),
      districtName: data[PoLoginResponseFields.distName]?.toString(),
      ttlHours: ttlHours,
      lat: lat,
      long: long,
      createdAt: DateTime.now(),
    );

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
      areaType: PresidingElectionContext.normalizeAreaType(
        data[PoLoginResponseFields.urbanRural]?.toString(),
      ),
      pollingStationCode: data[PoLoginResponseFields.psNo]?.toString(),
      pollingStationName: data[PoLoginResponseFields.psName]?.toString(),
      boothLat: lat,
      boothLong: long,
    );

    final PresidingElectionContextStore store = PresidingElectionContextStore(
      AppServices.secureStorage,
    );
    await store.save(context);

    await _saveSession(next);
    PresidingConcernModule.resetClients();
    try {
      await PresidingConcernModule.repository.refreshFromServer();
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
    } on DioException {
      throw const ServiceAuthException(LocaleKeys.errorNetwork);
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
    final double? lat = _parseCoord(data['Lat'] ?? data['lat']);
    final double? long = _parseCoord(data['Long'] ?? data['long']);
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
      name: (data['Name'] ?? data['UserName'] ?? userName).toString(),
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
      SecureStorageKeys.userSession,
      jsonEncode(s.toJson()),
    );
  }

  double? _parseCoord(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString().trim());
  }

  Future<void> signOut() async {
    session.value = null;
    _surveyDio = null;
    PoElectionApiClient.reset();
    await AppServices.secureStorage.delete(SecureStorageKeys.userSession);
    await AppServices.tokenVault.clear();
    PresidingConcernModule.resetClients();
    final PresidingElectionContextStore store = PresidingElectionContextStore(
      AppServices.secureStorage,
    );
    await store.clear();
  }
}
