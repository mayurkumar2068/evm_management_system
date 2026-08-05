import 'package:dio/dio.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/network/dio_factory.dart';
import 'package:evm_management_system/features/voter_search/data/datasources/voter_search_remote_datasource.dart';
import 'package:evm_management_system/features/voter_search/data/repositories/voter_search_repository.dart';
import 'package:evm_management_system/features/voter_search/data/voter_search_crypto.dart';
import 'package:evm_management_system/features/voter_search/presentation/controllers/voter_search_controller.dart';
import 'package:get/get.dart';

/// Lazy DI for native voter search (SECSearchAPI).
abstract final class VoterSearchModule {
  static Dio? _dio;
  static VoterSearchCrypto? _crypto;
  static VoterSearchRemoteDatasource? _datasource;
  static VoterSearchRepository? _repository;

  static Dio get dio {
    return _dio ??= DioFactory.create(
      config: AppServices.config,
      baseUrl: AppServices.config.voterSearchApiBaseUrl,
    );
  }

  static VoterSearchCrypto get crypto {
    return _crypto ??= VoterSearchCrypto(AppServices.config.voterSearchAesKey);
  }

  static VoterSearchRemoteDatasource get datasource {
    return _datasource ??= VoterSearchRemoteDatasource(
      dio: dio,
      passKey: AppServices.config.voterSearchPassKey,
      crypto: crypto,
    );
  }

  static VoterSearchRepository get repository {
    return _repository ??= VoterSearchRepository(datasource);
  }

  /// Ensures controller is registered for the voter-search screen.
  static VoterSearchController ensureController() {
    if (Get.isRegistered<VoterSearchController>()) {
      return Get.find<VoterSearchController>();
    }
    return Get.put(VoterSearchController(repository));
  }
}
