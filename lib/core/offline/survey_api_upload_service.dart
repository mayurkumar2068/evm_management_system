import 'package:dio/dio.dart';
import 'package:evm_management_system/core/network/interceptors/logging_interceptor.dart';
import 'package:evm_management_system/core/offline/web_form_submission.dart';

/// Uploads a [WebFormSubmission] to the survey / PSSurvey API (POElectionAPI).
///
/// Uses a dedicated Dio instance (not the main EVM [ApiClient]) because survey
/// traffic uses [EnvironmentConfig.surveyApiBaseUrl] and its own auth token.
class SurveyApiUploadService {
  SurveyApiUploadService({
    required String baseUrl,
    bool enableLogging = false,
    Dio? dio,
  }) : _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 30),
               receiveTimeout: const Duration(seconds: 60),
               sendTimeout: const Duration(seconds: 60),
               responseType: ResponseType.json,
             ),
           ) {
    _dio.interceptors.add(LoggingInterceptor(enabled: enableLogging));
  }

  final String _baseUrl;
  final Dio _dio;

  /// POSTs [submission] and returns the parsed server body.
  Future<Map<String, dynamic>> upload(WebFormSubmission submission) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '$_baseUrl${submission.endpoint}',
      data: submission.payload,
      options: Options(
        headers: <String, String>{
          if (submission.authToken.isNotEmpty)
            'Authorization': 'Bearer ${submission.authToken}',
          'Content-Type': 'application/json',
        },
      ),
    );
    final Object? data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{'success': true};
  }
}
