import 'package:dio/dio.dart';
import 'package:evm_management_system/config/environment_config.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/core/network/dio_factory.dart';
import 'package:evm_management_system/core/utils/json_map.dart';
import 'package:evm_management_system/features/dashboard/data/models/dashboard_card_model.dart';

class DashboardCardsRepository {
  DashboardCardsRepository({required EnvironmentConfig config, Dio? dio})
    : _config = config,
      _dio =
          dio ??
          DioFactory.create(
            config: config,
            baseUrl: config.poElectionApiBaseUrl,
          );

  final EnvironmentConfig _config;
  final Dio _dio;

  List<DashboardCardModel>? _cache;
  DateTime? _fetchedAt;

  List<DashboardCardModel>? get cached => _cache;

  Future<List<DashboardCardModel>> fetchCards({bool force = false}) async {
    if (!force &&
        _cache != null &&
        _fetchedAt != null &&
        DateTime.now().difference(_fetchedAt!) < const Duration(minutes: 5)) {
      return _cache!;
    }

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        PoElectionEndpoints.mastersCardList,
        options: Options(
          extra: <String, Object?>{'skipAuth': true},
          receiveTimeout: _config.receiveTimeout,
          sendTimeout: _config.sendTimeout,
          validateStatus: (int? status) =>
              status != null &&
              (status < 300 || status == 404 || status == 501),
        ),
      );

      final int? code = response.statusCode;
      if (code == 404 || code == 501) {
        AppLogger.d('Dashboard card-list not available ($code)');
        return _cache ?? const <DashboardCardModel>[];
      }

      final Map<String, dynamic>? envelope = asStringKeyedMap(response.data);
      if (envelope == null) {
        return _cache ?? const <DashboardCardModel>[];
      }

      final bool ok = envelope['Status'] == true || envelope['status'] == true;
      if (!ok && response.statusCode != 200) {
        return _cache ?? const <DashboardCardModel>[];
      }

      final Object? raw = envelope['Data'] ?? envelope['data'];
      final List<dynamic> list = raw is List<dynamic>
          ? raw
          : (raw is List ? raw.cast<dynamic>() : const <dynamic>[]);

      final List<DashboardCardModel> parsed = <DashboardCardModel>[
        for (final Object? item in list)
          if (asStringKeyedMap(item) != null)
            DashboardCardModel.fromJson(asStringKeyedMap(item)!),
      ].where((DashboardCardModel c) => c.isActive && c.id > 0).toList();

      _cache = parsed;
      _fetchedAt = DateTime.now();
      return parsed;
    } on DioException catch (e) {
      AppLogger.d(
        'Dashboard card-list fetch skipped (${e.response?.statusCode ?? e.type})',
      );
      return _cache ?? const <DashboardCardModel>[];
    } catch (e, s) {
      AppLogger.w('Dashboard card-list fetch failed', error: e, stackTrace: s);
      return _cache ?? const <DashboardCardModel>[];
    }
  }

  void clearCache() {
    _cache = null;
    _fetchedAt = null;
  }
}
